// NOTE: this script is mostly isolated from the optional modules, but there
// may be some cases where it's easier to write code here to support them.
// For example, for the IsLoot handling.

const MIN_ALPHA = 32;
const MAX_ALPHA = 100;
// NOTE: This also helps with various limitations. For example, NewDark
// v1.27 only allows 64 simultaneous overlays to exist.
const MAX_DIST = 150;
// While NewDark v1.27 allows a max of 64, we'll intentionally cap
// ourselves at a smaller value. After all, we don't want to hog all
// 64 and not leave any for other, more sanely-written mods!
const MAX_POI_RENDERED = 32;
const MAX_SCANNED_PER_LOOP = 100;
const MAX_INITIALIZED_PER_LOOP = 10;
const MAX_EMPTY_SCAN_GROUPS = 3;

// 1 (move) + 2 (script) + 128 (default)
const INTERESTING_FROB_FLAGS = 131;

// We just want a character not likely to be used in the text IDs.
const READ_LIST_SEPARATOR = ";";

// These correspond to the various RadarX64.png filenames.
const COLOR_DEFAULT = "W";
const COLOR_LOOT = "Y";
const COLOR_EQUIP = "G";
const COLOR_DEVICE = "P";
const COLOR_CONTAINER = "W";
const COLOR_CREATURE = "R";
const COLOR_READABLE = "B";

// Various class, metaproperty, and object name strings.
const OVERLAY_INTERFACE = "J4FRadarUiInterfacer";
const FEATURE_LOOT = "J4FRadarEnableLoot";
const FEATURE_PICKPOCKET = "J4FRadarEnablePickPocket";
const FEATURE_EQUIP = "J4FRadarEnableEquip";
const FEATURE_DEVICE = "J4FRadarEnableDevice";
const FEATURE_READABLE = "J4FRadarEnableReadable";
const FEATURE_CONTAINER = "J4FRadarEnableContainer";
const FEATURE_CREATURE = "J4FRadarEnableCreature";
const POI_ANY = "J4FRadarPointOfInterest";
const POI_GENERIC = "J4FRadarFallbackPOI";
const POI_CONTAINER = "J4FRadarContainerPOI";
const POI_DEVICE = "J4FRadarDevicePOI";
const POI_READABLE = "J4FRadarReadablePOI";
const POI_EQUIP = "J4FRadarEquipPOI";
const POI_LOOT = "J4FRadarLootPOI";
const POI_CREATURE = "J4FRadarCreaturePOI";
const POI_PROXY_MARKER = "J4FRadarProxyPOI";
const POI_PROXY_FLAG = "J4FRadarProxied";
const PROXY_ATTACH_METHOD = "PhysAttach";

// Between the lack of a true static/utility method class concept
// in squirrel and to avoid questions about when we do or don't
// have access to API-reference_services.txt stuff, we're using
// this superclass for any of our scripts that might benefit from
// these utility methods.
class J4FRadarUtilities extends SqRootScript
{
	// Some items are flagged to not inherit scripts. This applies
	// to their archetypes, as well as metaproperties assigned
	// directly to the object itself. In these cases, the meta-
	// property is useless to us. The item will not alert the
	// radar system that it exists, and we cannot benefit from any
	// bless functions on the item.
	function SetupProxyIfNeeded(forItem)
	{
		if (
			// It is a point of interest.
			Object.InheritsFrom(forItem, POI_ANY)
			// And it's not proxied yet.
			&& !Object.HasMetaProperty(forItem, POI_PROXY_FLAG)
			// But it has its very own scripts.
			&& Property.Possessed(forItem, "Scripts")
			// And it's ignoring our metaproperty-based scripts.
			&& Property.Get(forItem, "Scripts", "Don't Inherit")
		)
		{
			// Flag the target item as having been proxied.
			Object.AddMetaProperty(forItem, POI_PROXY_FLAG);
		
			// Create a new proxy marker on top of the item it is proxying.
			local proxyMarker = Object.BeginCreate(POI_PROXY_MARKER);
			Object.Teleport(proxyMarker, Object.Position(forItem), Object.Facing(forItem));
			Object.EndCreate(proxyMarker);
		
			// Link these items together.
			local proxyAttach = Link.Create(PROXY_ATTACH_METHOD, proxyMarker, forItem);
		
			// Give the proxy marker a POI metaproperty of the
			// target item. Giving it more than one seems to
			// cause issues, given the way we implemented things.
			if (Object.InheritsFrom(forItem, POI_ANY) && !Object.InheritsFrom(proxyMarker, POI_ANY))
			{
				if (Object.InheritsFrom(forItem, POI_LOOT))
				{
					Object.AddMetaProperty(proxyMarker, POI_LOOT);
				}
				else if (Object.InheritsFrom(forItem, POI_EQUIP))
				{
					Object.AddMetaProperty(proxyMarker, POI_EQUIP);
				}
				else if (Object.InheritsFrom(forItem, POI_DEVICE))
				{
					Object.AddMetaProperty(proxyMarker, POI_DEVICE);
				}
				else if (Object.InheritsFrom(forItem, POI_CONTAINER))
				{
					Object.AddMetaProperty(proxyMarker, POI_CONTAINER);
				}
				else if (Object.InheritsFrom(forItem, POI_CREATURE))
				{
					Object.AddMetaProperty(proxyMarker, POI_CREATURE);
				}
				else if (Object.InheritsFrom(forItem, POI_READABLE))
				{
					Object.AddMetaProperty(proxyMarker, POI_READABLE);
				}
				// last resort
				else
				{
					Object.AddMetaProperty(proxyMarker, POI_GENERIC);
				}
			}
			return true;
		}
		
		return false;
	}
}

// This script goes on an inventory item the player can use to turn the
// radar effect on and off.
class J4FRadarToggler extends SqRootScript
{
	function OnFrobInvEnd()
	{
		local newState = SendMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarToggle", self);
		if (newState)
		{
			Property.SetSimple(self, "GameName", "name_j4f_radar_active: \"Radar (Active)\"");
		}
		else
		{
			Property.SetSimple(self, "GameName", "name_j4f_radar_inactive: \"Radar (Inactive)\"");
		}
	}
}

class J4FRadarEchoReceiver extends J4FRadarUtilities
{
	// Most items of interest don't need this, and will instead directly
	// register themselves with the radar system. Other items are trickier,
	// and rely on the radius stim bursts to detect them as we draw near.
	function OnJ4FRadarStimStimulus()
	{
		// message() for a stimulus includes a source and a sensor property.
		// These are LinkIDs, not ObjIDs. So to get the objects themselves,
		// we need to turn the numeric link ID into an sLink object. Now
		// we can access the .source and .dest properties of the link.
		local newPointOfInterest = sLink(message().source).source;
		
		// Rather than keep all the loot-specific logic in its own module,
		// it's easier to keep it here. The loot module files are still
		// required to enable these effects, because otherwise the enable
		// metaproperty won't exist.
		
		if (
			// The optional loot module is installed.
			ObjID(FEATURE_LOOT) < 0
			// And it's a loot item.
			&& Object.InheritsFrom(newPointOfInterest, "IsLoot")
			// But it does not yet have any POI metaproperty.
			&& !Object.InheritsFrom(newPointOfInterest, POI_ANY)
		)
		{
			Object.AddMetaProperty(newPointOfInterest, POI_LOOT);
		}
		
		SetupProxyIfNeeded(newPointOfInterest);
	}
}

// This a superclass for all items that the radar can display.
class J4FRadarAbstractTarget extends J4FRadarUtilities
{
	constructor(color = COLOR_DEFAULT, uncapDistance = false)
	{
		SetData("J4FRadarColor", color);
		SetData("J4FRadarUncapDistance", uncapDistance);
	}
	
	// Our point-of-interest metaproperties and their scripts might
	// be attached to a proxy marker object instead. So the item of
	// interest may be self, or it may be something linked to self.
	function PoiTarget()
	{
		if (IsDataSet("J4FPoiTargetCache"))
		{
			return GetData("J4FPoiTargetCache");
		}
		
		local whoAmI;
		
		if (Object.InheritsFrom(self, POI_PROXY_MARKER))
		{
			// What are we pointing at? The attach link is from us
			// to the real point of interest.
			whoAmI = LinkDest(Link.GetOne(PROXY_ATTACH_METHOD, self));
		}
		else
		{
			whoAmI = self;
		}
		
		SetData("J4FPoiTargetCache", whoAmI);
		
		return whoAmI;
	}
	
	function DisplayTarget()
	{
		// Generally, we display the item itself.
		local target = PoiTarget();
		
		// But if the item is in a container in a non-visible way, we'll
		// display the container instead. Note that the link data for
		// "Contains" can indicate pickpocketable belt items, etc. All
		// negative enum values are rendered, while 0 and up are hidden
		// inside the container itself.
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		if (linkToMyContainer != 0 && LinkTools.LinkGetData(linkToMyContainer, "") >= 0)
		{
			// There's a handy LinkDest() function, but to get the source we need
			// to instantiate the whole link object.
			target = sLink(linkToMyContainer).source;
		}
		
		return target;
	}
	
	// Subclasses can override this to define how items can become temporarily
	// interesting or ininteresting. As opposed to a more permanent, one-time veto.
	function BlessItem()
	{
		local target = PoiTarget();
		
		// Ignore anything contained by the player.
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		// There's a handy LinkDest() function, but to get the source we need
		// to instantiate the whole link object.
		if (linkToMyContainer != 0 && Object.InheritsFrom(sLink(linkToMyContainer).source, "Avatar"))
			return false;
		
		return true;
	}
	
	// This isn't for pickpocketable things, but for chests and such.
	function IsInOpenableContainer()
	{
		local target = PoiTarget();
		
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		// Are we contained by something in a way that prevent us from rendering?
		if (
			// We are contained.
			linkToMyContainer != 0
			// In a non-visible way. (Negative values are for visible
			// contents, like on a creature's belt.)
			&& LinkTools.LinkGetData(linkToMyContainer, "") >= 0
			// And our container is a...Container.
			// As opposed to a creature or some other presumably
			// non-openable item.
			&& Object.InheritsFrom(sLink(linkToMyContainer).source, "Container")
		)
		{
			return true;
		}
		
		return false;
	}
	
	// This is a common need for many points of interest, and implemented
	// here so they can add it to their BlessItem() if desired.
	function IsPickup()
	{
		local target = PoiTarget();
		
		// If we're in a container (not in a pickpocket way, but a
		// regular chest kind of way), our frob status is irrelevant.
		if (IsInOpenableContainer())
			return true;
		
		// This property contains our frob flags, if any. We only
		// care if those flags include interesting options.
		return (Property.Get(target, "FrobInfo", "World Action") & INTERESTING_FROB_FLAGS) > 0;
	}
	
	// NOTE: This is not a truly reliable check for whether a given object
	// can be rendered. Instead, it just checks for certain things that
	// are known to prevent rendering. There are others, like being
	// contained inside a different object, not having a model, or
	// having a model which is effectively empty.
	function IsRendered()
	{
		local target = PoiTarget();
		
		// If we're in a container (not in a pickpocket way, but a
		// regular chest kind of way), our render status is irrelevant.
		if (IsInOpenableContainer())
			return true;
		
		// We'll assume invisible render statuses are irrelevant.
		if (Property.Possessed(target, "INVISIBLE") && Property.Get(target, "INVISIBLE"))
			return false;
		
		// Likewise ignore things with unusual, undesirable render types.
		// These include type 1 (not at all) and 3 (editor only).
		if (Property.Possessed(target, "RenderType"))
		{
			switch (Property.Get(target, "RenderType"))
			{
				// not-at-all
				case 1:
					// intentional fall-through to next case statement
				// editor-only
				case 3:
					return false;
			}
		}
		
		// Some types of containment make us invisible. Note that we
		// also checked IsInOpenableContainer() above, which means
		// it's okay if we're in a chest or something. This is to
		// hide us when we can't be rendered because we're inside
		// some other container, like a creature.
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		// Are we contained by something in a way that prevent us from rendering?
		if (
			// We are contained.
			linkToMyContainer != 0
			// In a non-visible way. (Negative values are for visible
			// contents, like on a creature's belt.)
			&& LinkTools.LinkGetData(linkToMyContainer, "") >= 0
		)
		{
			return false;
		}
		
		// I dunno, I guess it's rendered. I suppose we also need things
		// like a model and whatever.
		return true;
	}
	
	// This will fire on mission start and on reloading a save.
	function OnBeginScript()
	{
		// Default to unknown on a reload. Mostly so that we can be
		// sure to add or remove us from the overlay.
		ClearData("J4FRadarLastBless");
		
		// Depending on which order objects are set up, things like the
		// overlay marker may not be ready yet. We'll add a slight
		// startup delay before registering our existence with them.
		// We use our item ID to help stagger startup times when there
		// are a lot of items in the level. We could generate a random
		// delay, but that carries a CPU cost of its own.
		if (!IsDataSet("J4FRadarTargetReviewTimer"))
		{
			local beginTimer = SetOneShotTimer("J4FRadarTargetReview", ((self % 900) + 100) / 1000.0);
			SetData("J4FRadarTargetReviewTimer", beginTimer);
		}
	}
	
	function OnTimer()
	{
		if (message().name != "J4FRadarTargetReview")
			return;
		
		ClearData("J4FRadarTargetReviewTimer");
		
		local newBlessed = BlessItem();
		
		// If our blessing status changes, add or remove us from the list
		// of targets to review and display.
		if (!IsDataSet("J4FRadarLastBless") || (GetData("J4FRadarLastBless") != newBlessed))
		{
			if (newBlessed)
			{
				SendMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarDetected", self, DisplayTarget(), GetData("J4FRadarColor") + (GetData("J4FRadarUncapDistance") ? "1" : "0"));
			}
			else
			{
				SendMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarDestroyed", self);
			}
			
			SetData("J4FRadarLastBless", newBlessed);
		}
		
		// Periodically review our blessing status.
		SetOneShotTimer("J4FRadarTargetReview", 0.25);
	}
	
	// Because item IDs can be reused, we need to be sure a destroyed
	// item is removed from the list. Otherwise, we could treat some
	// random arrow or blood splatter as a point of interest.
	function OnDestroy()
	{
		SendMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarDestroyed", self);
	}
}

class J4FRadarCreatureTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_CREATURE, true);
	}
	
	// Ignore frozen, dead, and nonhostile creatures.
	function BlessItem()
	{
		if (!base.BlessItem() || !IsRendered())
			return false;
		
		local target = PoiTarget();
		
		// Other states: Asleep, Efficient, Super Efficient, Normal, and Combat
		if (Property.Get(target, "AI_Mode") == eAIMode.kAIM_Dead)
			return false;
		
		// Ignore nonhostiles. Of course, mission scripts and such can
		// turn neutrals and allies into enemies, but this should help
		// avoid drawing our attention to rats and such in Thief 2.
		// TODO: what if people want to see neutrals? good? both? for the "scorched earth" completionists
		switch (Property.Get(target, "AI_Team"))
		{
			case eAITeam.kAIT_Good:
				// intentional fall-through
			case eAITeam.kAIT_Neutral:
				return false;
		}
		
		return true;
	}
}

// Various things only matter if we can pick them up (or they're in
// a container and we can grab them from there, etc.)
class J4FRadarGrabbableTarget extends J4FRadarAbstractTarget
{
	constructor(color = COLOR_DEFAULT, uncapDistance = false)
	{
		base.constructor(color, uncapDistance);
	}
	
	// Ignore decorative/etc. things we can't pick up.
	function BlessItem()
	{
		return base.BlessItem() && IsPickup() && IsRendered();
	}
}

// This script goes on the container of interest.
class J4FRadarContainerTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_CONTAINER, true);
	}
	
	// Ignore empty containers and containers with points of interest.
	// If we contain a POI item, the item should already be displaying
	// us as its visual indicator, so the container itself doesn't
	// need one of its own.
	function BlessItem()
	{
		// Also require IsPickup() to be sure we can try to open it.
		if (!base.BlessItem() || !IsPickup() || !IsRendered())
			return false;
		
		local target = PoiTarget();
		local hasAny = false;
		
		local myInventory = Link.GetAll("Contains", target);
		local anyKindOfPoi = ObjID(POI_ANY);
		
		foreach (link in myInventory)
		{
			hasAny = true;
			
			// If the item is already some kind of indicator,
			// we'll assume it's going to bless itself and
			// use us (the container) to display its location.
			if (Object.InheritsFrom(LinkDest(link), anyKindOfPoi))
			{
				return false;
			}
		}
		
		// Bless if has at least one item inside.
		return hasAny;
	}
}

// This script goes on the device of interest.
class J4FRadarDeviceTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_DEVICE);
	}
	
	// Ignore invisible devices, which are sometimes used by
	// mission authors to trigger scripted events. Note that
	// we don't check IsPickup(), because that would prevent
	// pressure plates from being indicated.
	function BlessItem()
	{
		return base.BlessItem() && IsRendered();
	}
}

// This script goes on the equipment of interest.
class J4FRadarEquipTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_EQUIP, true);
	}
}

// This script goes on the loot of interest.
class J4FRadarLootTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_LOOT, true);
	}
}

// This script goes on the readable of interest. We're applying this only to
// grabbables, because we need them to be interactable in some way.
class J4FRadarReadableTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_READABLE, true);
	}
	
	// Looking for a frob event is the only way we can tell when we've been
	// read. Even that might have weird corner cases through scripting, but
	// this should be at least 99% effective.
	
	function OnFrobWorldEnd()
	{
		local myText = Property.Possessed(self, "Book") ? Property.Get(self, "Book") : "";
		if (myText != "")
		{
			PostMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarReadFlag", myText)
		}
	}
	
	function OnFrobInvEnd()
	{
		local myText = Property.Possessed(self, "Book") ? Property.Get(self, "Book") : "";
		if (myText != "")
		{
			PostMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarReadFlag", myText)
		}
	}
	
	function BlessItem()
	{
		if (!base.BlessItem())
			return false;
		
		local target = PoiTarget();
		
		// Proper readables should have both book text and book art. Otherwise
		// they're probably just little name tags, brief plaques, etc.
		
		// Lack of BookArt means the text just displays briefly at the top
		// of the screen. This is probably brief and uninteresting text, so
		// skip those.
		if (!Property.Possessed(target, "BookArt") || Property.Get(target, "BookArt") == "")
			return false;
		
		// We need to have text to be a proper readable.
		local myText = Property.Possessed(target, "Book") ? Property.Get(target, "Book") : "";
		if (myText == "")
			return false;
		
		// Have we read this one yet? Note that because some readables can
		// be duplicates, we'll try to track this globally rather than for
		// individual items.
		if (SendMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarReadCheck", myText))
			return false;
		
		return true;
	}
}

// This script goes on anything we think might contain loot, like
// containers and creatures.
class J4FRadarChildDetector extends J4FRadarUtilities
{
	function OnBeginScript()
	{
		// Stagger these out with timers. If there's a ton of containers
		// with this script going off at the same time, there's a chance
		// the game will overstress itself and crash.
		if (!IsDataSet("J4FRadarContentReviewTimer"))
		{
			local beginTimer = SetOneShotTimer("J4FRadarContentReview", ((self % 900) + 100) / 1000.0);
			SetData("J4FRadarContentReviewTimer", beginTimer);
		}
	}
	
	function OnTimer()
	{
		if (message().name != "J4FRadarContentReview")
			return;
		
		ClearData("J4FRadarContentReviewTimer");
		
		local myInventory = Link.GetAll("Contains", self);
		
		local anyKindOfPoi = ObjID(POI_ANY);
		local fallbackPoi = ObjID(POI_GENERIC);
		local lootEnabled = ObjID(FEATURE_LOOT) < 0;
		local pickPocketEnabled = ObjID(FEATURE_PICKPOCKET) < 0;
		local lootMetaProperty = ObjID("IsLoot");
		local lootPoiProperty = ObjID(POI_LOOT);
		
		foreach (link in myInventory)
		{
			local invItem = LinkDest(link);
			
			// Check to see if we need to add metaproperties directly
			// to the contained item.
			if (!Object.InheritsFrom(invItem, anyKindOfPoi))
			{
				if (
					// The optional loot module is installed.
					lootEnabled
					// And it's a loot item.
					&& Object.InheritsFrom(invItem, lootMetaProperty)
				)
				{
					Object.AddMetaProperty(invItem, lootPoiProperty);
				}
				else if (
					// The optional pickpocket module is installed.
					pickPocketEnabled
					// And it's on the creature's belt or alternate slot.
					// Those are what the game uses to track the pockets
					// picked for the end-of-mission stats.
					&& (
						// Belt
						LinkTools.LinkGetData(link, "") == -1
						// Alternate (quiver arrows, etc.)
						|| LinkTools.LinkGetData(link, "") == -3
					)
				)
				{
					Object.AddMetaProperty(invItem, fallbackPoi);
				}
			}
			
			// If needed, create a proxy item to represent the target for
			// radar system purposes.
			SetupProxyIfNeeded(invItem);
		}
	}
}

// This script will be called on the player when the game starts, giving them the radar item.
class J4FGiveRadarItem extends SqRootScript
{
	// We only need this script to fire once, when the game simulation first starts.
    function OnSim()
	{
        if (message().starting)
		{
			// Assuming this script is attached to the player, "self" refers
			// to that player. Every object with a "Contains" type link is
			// stuff in the player's inventory.
			local playerInventory = Link.GetAll("Contains", self);
			
			// Assume they don't have the radar item until we prove otherwise.
			local hasRadarItem = false;
			// It may be possible to use the string directly everywhere we use
			// this variable, but it's probably less efficient than doing the
			// ID lookup once and storing the result. This approach was used
			// in the HolyH2O script sample as well.
			local radarItemId = ObjID("J4FRadarControlItem");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the radar item?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FRadarControlItem as well, but that's not relevant
				// to this mod.)
				if ( Object.InheritsFrom(LinkDest(link), radarItemId) )
				{
					// The player already has the radar item!
					hasRadarItem = true;
					// So we can stop looking through their inventory.
					break;
				}
			}
			
			// If the player doesn't already have the radar item...
			if (!hasRadarItem)
			{
				// Then create one and give it to them.
				Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(radarItemId));
			}
        }
    }
}

// This script goes on the marker we add to every mission. It sets up and
// tears down the overlay handler. We also use it to pass along messages
// to the overlay handler, including persisted data with SetData()/GetData()
class J4FRadarUi extends J4FRadarUtilities
{
	// A destructor function that removes the handler is a best practice
	// recommended by the sample overlay code that comes with NewDark.
	// Both the OnEndScript and destructor will generally do the same,
	// or nearly the same things.
	function destructor()
	{
		// Per NewDark's documentation, there's no danger in removing
		// an overlay that's already been removed. So this is just an
		// extra safety net to be absolutely sure the overlay is removed,
		// even if the EndScript message never triggers for some reason.
		DarkOverlay.RemoveHandler(j4fRadarOverlayInstance);
		
		// As we've coded it, there's no harm in calling this more than
		// once either.
		j4fRadarOverlayInstance.Teardown();
	}

	function OnBeginScript()
	{
		// Call our custom setup method, to do whatever we need to do
		// when preparing the overlay in a new mission, after loading
		// a save, or when re-loading a save or moving to next mission.
		j4fRadarOverlayInstance.Setup();
		
		// This is part of NewDark+Squirrel's method of attaching an
		// overlay handler to the game.
		DarkOverlay.AddHandler(j4fRadarOverlayInstance);
		
		// Remember our enabled state.
		j4fRadarOverlayInstance.enabled = IsDataSet("J4FRadarEnableState") && GetData("J4FRadarEnableState");
	}

	function OnEndScript()
	{
		// Given that we have multiple things to do when tearing down
		// the handler, all that code was moved to the destructor, which
		// we can call by hand.
		destructor();
	}
	
	// Some items are stubbornly difficult to detect. In addition to
	// flagging certain things with metaproperties, some require proxy
	// objects because we still can't safely add scripts to them. And
	// all sorts of IsLoot items are unsafe to script directly. So to
	// help detect all items in the level, even at a distance, we'll
	// loop through every object in the game world. Sort of. For now,
	// we'll initialize the looping process. We only need this to
	// happen once, when the mission starts.
    function OnSim()
	{
        if (message().starting)
		{
			// Start with objects 1 through whatever.
			SetData("AddToScanId", 1);
			SetData("ConsecutiveEmptyGroups", 0);
			
			SetOneShotTimer("J4FRadarMissionScan", 0.01);
        }
    }
	
	// So the thing is, we don't know how many objects are in the
	// mission. We know they have numeric IDs, generally starting
	// from about 1 or so, and they count up from there. However,
	// gaps are possible if items are ever deleted. So we'll loop
	// through until we find enough "missing" items to feel like
	// we've found everything we're ever going to find.
	function OnTimer()
	{
		if (message().name != "J4FRadarMissionScan")
			return;
		
		// We will scan objects down to and including this value.
		local scanFromInclusive = GetData("AddToScanId");
		// We will scan objects up to and excluding this value.
		local scanCapExclusive = scanFromInclusive + MAX_SCANNED_PER_LOOP;
		SetData("AddToScanId", scanCapExclusive);
		local consecutiveEmptyGroups = GetData("ConsecutiveEmptyGroups");
		local scannedAny = false;
		// The game really, really struggles (or even crashes) when a
		// ton of scripts initialize themselves at the same time. So
		// limit how many scanned items we enable for radar here.
		local initializeCount = 0;
		
		// We need these IDs several times throughout the loop, so
		// let's grab them once instead.
		
		local keysEnabled = ObjID(FEATURE_EQUIP) < 0;
		local keyPoiProperty = ObjID(POI_EQUIP);
		
		local readablesEnabled = ObjID(FEATURE_READABLE) < 0;
		local readablePoiProperty = ObjID(POI_READABLE);
		
		local lootEnabled = ObjID(FEATURE_LOOT) < 0;
		local lootMetaProperty = ObjID("IsLoot");
		local lootPoiProperty = ObjID(POI_LOOT);
		
		local anyKindOfPoi = ObjID(POI_ANY);
		
		// Loop through all the item IDs we're going to test this time.
		for (local i = scanFromInclusive - 1; ++i < scanCapExclusive; )
		{
			// If we exceeded our limit, save this index for later.
			if (initializeCount > MAX_INITIALIZED_PER_LOOP)
			{
				SetData("AddToScanId", i);
				break;
			}
			
			if (Object.Exists(i))
			{
				scannedAny = true;
				
				local checkProxy = false;
				
				// Do we need to manually add a POI metaproperty to the
				// scanned item? Useful for weird kinds of loot, keys,
				// and readables.
				if (Object.InheritsFrom(i, anyKindOfPoi))
				{
					checkProxy = true;
				}
				else
				{
					// IsLoot items are hard to target directly, because
					// we can never safely script them nor add a metaproperty,
					// because IsLoot *is* a metaproperty.
					if (
						// The optional loot module is installed.
						lootEnabled
						// And it's a loot item.
						&& (
							// "IsLoot" items might be repurposed as valueless
							// decorations, but we can worry about that in the
							// bless functions.
							Object.InheritsFrom(i, lootMetaProperty)
							// It's possible that the loot will have no value
							// and no special flags, but we can worry about
							// that in the bless functions.
							|| Property.Possessed(i, "Loot")
						)
					)
					{
						Object.AddMetaProperty(i, lootPoiProperty);
						checkProxy = true;
						++initializeCount;
					}
					else if (
						// The optional keys (equipment) module is installed.
						keysEnabled
						// And the item can be used as a kind of key.
						&& Property.Possessed(i, "KeySrc")
						// And is enabled in at least one region.
						&& Property.Get(i, "KeySrc", "RegionMask") != 0
					)
					{
						Object.AddMetaProperty(i, keyPoiProperty);
						checkProxy = true;
						++initializeCount;
					}
					else if (
						// The optional readables module is installed.
						readablesEnabled
						// And the item has something worth reading.
						&& Property.Possessed(i, "Book")
						&& Property.Possessed(i, "BookArt")
						&& Property.Get(i, "Book") != ""
						&& Property.Get(i, "BookArt") != ""
					)
					{
						Object.AddMetaProperty(i, readablePoiProperty);
						checkProxy = true;
						++initializeCount;
					}
				}
				
				if (checkProxy && SetupProxyIfNeeded(i))
				{
					++initializeCount;
				}
			}
		}
		
		// Track how many consecutive scan groups came up empty and,
		// if needed, halt scanning.
		if (!scannedAny)
		{
			// Increment and test consecutiveEmptyGroups.
			if (++consecutiveEmptyGroups > MAX_EMPTY_SCAN_GROUPS)
			{
				// We're done! Break the loop.
				return;
			}
			
			SetData("ConsecutiveEmptyGroups", consecutiveEmptyGroups);
		}
		else if (consecutiveEmptyGroups > 0)
		{
			// Back to a clean slate.
			SetData("ConsecutiveEmptyGroups", 0);
		}
		
		// Repeat! We're staggering the scans over time to avoid a
		// huge lag spike at the beginning of large levels.
		SetOneShotTimer("J4FRadarMissionScan", 0.1);
	}
	
	// Rather than have radar points of interest communicate directly
	// with the overlay instance, we'll have them communicate with us.
	function OnJ4FRadarDetected()
	{
		// We sent the point-of-interest item object ID in "data"
		local detectedId = message().data;
		
		// If the POI item is not already in the list, put it there.
		if (!(detectedId in j4fRadarOverlayInstance.displayTargets))
		{
			local poiMetadata = J4FRadarPointOfInterest();
			// We sent the display item ID in "data2"
			poiMetadata.displayId = message().data2;
			// We sent the radar color indicator in "data3".
			// Later we abused this to include the uncapped
			// distance indicator as well. So instead of
			// "W" for white, it's "W0" for white with capped
			// distance and "W1" for white with uncapped.
			poiMetadata.displayColor = message().data3.slice(0, 1);
			poiMetadata.uncappedDistance = message().data3.slice(1, 2) == "1";
			
			j4fRadarOverlayInstance.displayTargets[detectedId] <- poiMetadata;
		}
	}
	
	// Rather than have radar points of interest communicate directly
	// with the overlay instance, we'll have them communicate with us.
	function OnJ4FRadarDestroyed()
	{
		// We sent the point-of-interest item object ID in "data"
		local destroyedId = message().data;
		
		// If the POI item is in the list, remove it.
		if (destroyedId in j4fRadarOverlayInstance.displayTargets)
		{
			delete j4fRadarOverlayInstance.displayTargets[destroyedId];
		}
	}
	
	function OnJ4FRadarToggle()
	{
		local newState = !(IsDataSet("J4FRadarEnableState") && GetData("J4FRadarEnableState"));
		j4fRadarOverlayInstance.enabled = newState;
		SetData("J4FRadarEnableState", newState);
		Reply(newState);
	}
	
	function OnJ4FRadarReadCheck()
	{
		// If we've never read anything, we haven't read you.
		if (!IsDataSet("J4FRadarReadList"))
		{
			Reply(false);
			return;
		}
		
		// What have we read?
		local readText = GetData("J4FRadarReadList");
		
		// What are you? The text ID should have been sent in "data"
		// but we'll wrap it in the divider to help our string search.
		local checkText = READ_LIST_SEPARATOR + message().data + READ_LIST_SEPARATOR;
		
		// We'll use .find() rather than splitting the string into an
		// array. We only need to find one value and can stop immediately
		// upon finding it. Splitting into an array is just extra effort.
		Reply(readText.find(checkText) != null);
	}
	
	function OnJ4FRadarReadFlag()
	{
		// What we've read so far (if any).
		local readText = IsDataSet("J4FRadarReadList") ? GetData("J4FRadarReadList") : READ_LIST_SEPARATOR;
		
		// What are we reading now? Append a separator in case we store this later.
		local checkText = message().data + READ_LIST_SEPARATOR;
		
		// If already in the list, no need to make it bigger.
		// NOTE: We have to prepend the separator because we didn't
		// do that earlier.
		if (readText.find(READ_LIST_SEPARATOR + checkText) != null)
			return;
		
		// Append to the list. The separator characters are already
		// taken care of.
		SetData("J4FRadarReadList", readText + checkText);
	}
}

// According to https://developer.electricimp.com/resources/efficientsquirrel it
// should be better to have classes rather than generic tables, if we're going
// to have two or more instances of them. At least, it's more memory efficient.
// Not sure what's more CPU efficient, but we're probably splitting hairs there.
class J4FRadarPointOfInterest
{
	x = 0;
	y = 0;
	displayId = 0;
	displayColor = COLOR_DEFAULT;
	uncappedDistance = false;
	distance = 0;
}

// This is the actual overlay handler, following along with both squirrel
// documentation and things like T2OverlaySample.nut. Rather than a generic
// list of elements, we use a variable-sized pool of elements we manage on
// each frame.
//
// NOTE: Documentation says that only one IDarkOverlayHandler can be defined
// per OSM. However, I can confirm multiple IDarkOverlayHandler implementations
// can be defined in squirrel .nut files, and all of them can be set up and
// used by their respective mods. So our using an IDarkOverlayHandler in this
// radar mod does *not* prevent other squirrel-based mods from having theirs.
class J4FRadarOverlayHandler extends IDarkOverlayHandler
{
	// Having various int_ref objects stored centrally avoids having to
	// create a bunch of these on every frame rendered. The T2OverlaySample.nut
	// takes a similar approach.
	x1_ref = int_ref();
	y1_ref = int_ref();
	x2_ref = int_ref();
	y2_ref = int_ref();
	
	// These are for internal state tracking. All of these variables are
	// safe to lose track of on save/load, and we don't try to persist them.
	canvasWidth = 0;
	canvasHeight = 0;
	useBitmapSize = 0;
	// Filename keys, bitmap handle values.
	bitmaps = {};
	// Object ID integer keys (potentially pointing to proxy marker objects)
	// with J4FRadarPointOfInterest instances for values.
	displayTargets = {};
	// This is a table whose keys are strings, indicating the color of the
	// overlay. For example, "W" for white, "Y" for yellow, etc. The keys are
	// arrays of overlay handles created with DarkOverlay.CreateTOverlayItem()
	// or DarkOverlay.CreateTOverlayItemFromBitmap()
	overlayPool = {};
	poolUsedThisFrame = {};
	// Contains a list of points of interest to render on the current frame.
	// See comments in DrawHUD() for an explanation of why we need to feed
	// data into DrawTOverlay like this.
	toDrawThisFrame = [];
	// Used for alpha/opacity/transparency cycling effect.
	currentWaveStep = 0;
	// This is persisted elsewhere, on the marker object's script.
	enabled = false;
	
	// This is used instead of log() functions to check for the power-
	// of-twoness of a given value. Used in checking bitmap sizes.
	powersOfTwo = {[1]=true,[2]=true,[4]=true,[8]=true,[16]=true,[32]=true,[64]=true};
	// We may need this "constant" repeatedly, so grab it once.
	logOfTwo = log(2);
	
	function Teardown()
	{
		enabled = false;
		displayTargets = {};
	}
	
	function Setup()
	{
		enabled = false;
		displayTargets = {};
	}
	
	// OnUIEnterMode implements an IDarkOverlayHandler method.
	// This is the best spot to figure out our canvas size, which is related to
	// but different than the user's resolution settings. If they change res
	// mid-game, this function will fire again, and we can resize our overlays.
	function OnUIEnterMode()
	{
		Engine.GetCanvasSize(x1_ref, y1_ref);
		
		local newCanvasWidth = x1_ref.tointeger();
		local newCanvasHeight = y1_ref.tointeger();
		
		if (newCanvasWidth != canvasWidth)
		{
			canvasWidth = newCanvasWidth;
		}
		
		if (newCanvasHeight != canvasHeight)
		{
			canvasHeight = newCanvasHeight;
		}
	}
	
	// DrawHUD implements an IDarkOverlayHandler method.
	// We don't draw anything here, but instead use it to gather
	// data for DrawTOverlay later on.
	function DrawHUD()
	{
		if (!enabled)
			return;
		
		// Well, this is really, really awkward. Turns out that WorldToScreen()
		// and GetObjectScreenBounds() only work in DrawHUD, not in DrawTOverlay.
		// But if we want things like alpha/opacity, we have to rely on overlays.
		// So we do some work in DrawHUD, but no drawing. Then in the overlay
		// drawing phase, we use the information we gathered here to manage the
		// visible overlays.
		toDrawThisFrame = [];
		
		// I'm unclear how squirrel handles modifying an object while
		// enumerating through it. Given that some programming languages
		// consider this a problem and either error out or behave
		// unpredictably, we'll keep track of removed items here and
		// then do the actual removing later.
		local removeIds = [];
		
		// We'll use this for distance checking.
		local cameraPos = Camera.GetPosition();
		
		foreach (managerId, poiMetadata in displayTargets)
		{
			local targetId = poiMetadata.displayId;
			local displayColor = poiMetadata.displayColor;
			
			// If we wanted to keep track of a running total of detected,
			// interesting loot, this would be a way. However, we should
			// probably add another property to J4FRadarPointOfInterest
			// for this kind of stuff, because managerId could be a
			// proxy marker, and targetId (poiData.displayId) could be
			// a chest. So neither object ID we have when this comment
			// was written had guaranteed access to the loot item itself.
			/*
			if (Property.Possessed(managerId, "Loot"))
			{
				lootTotal += Property.Get(managerId, "Loot", "Gold");
				lootTotal += Property.Get(managerId, "Loot", "Gems");
				lootTotal += Property.Get(managerId, "Loot", "Art");
			}
			*/
			
			// Well, WorldToScreen() looked promising, but it appears to pick a corner
			// of the object. If we want something more...centered, we'll have to use
			// GetObjectScreenBounds() instead.
			//local targetPos = Object.Position(targetId);
			//if (!DarkOverlay.WorldToScreen(targetPos, x1_ref, y1_ref))
			//	continue;
			
			// This sets the x/y pairs to the left, top, right, and bottom edges of the
			// object. Or it returns false if the object is completely offscreen.
			if (!DarkOverlay.GetObjectScreenBounds(targetId, x1_ref, y1_ref, x2_ref, y2_ref))
				continue;
			
			// For debugging purposes, we can also draw directly in the HUD this frame.
			// This will draw the bounding box we just retrieved.
			/*
			DarkOverlay.DrawLine(x1_ref.tointeger(), y1_ref.tointeger(), x1_ref.tointeger(), y2_ref.tointeger());
			DarkOverlay.DrawLine(x1_ref.tointeger(), y2_ref.tointeger(), x2_ref.tointeger(), y2_ref.tointeger());
			DarkOverlay.DrawLine(x2_ref.tointeger(), y2_ref.tointeger(), x2_ref.tointeger(), y1_ref.tointeger());
			DarkOverlay.DrawLine(x2_ref.tointeger(), y1_ref.tointeger(), x1_ref.tointeger(), y1_ref.tointeger());
			//*/
			
			// Only include rendered items (presumably they're visible) and
			// nearby items.
			local targetDistance = (Object.Position(targetId) - cameraPos).Length();
			if (!poiMetadata.uncappedDistance && !Object.RenderedThisFrame(targetId) && targetDistance > MAX_DIST)
				continue;
			
			// Pick a point in the center of the object bounds.
			poiMetadata.x = (x1_ref.tointeger() + x2_ref.tointeger()) / 2;
			poiMetadata.y = (y1_ref.tointeger() + y2_ref.tointeger()) / 2;
			poiMetadata.displayColor = displayColor;
			poiMetadata.distance = targetDistance;
			toDrawThisFrame.append(poiMetadata);
		}
		
		// If we've slated any items for removal, process that list.
		// Since the order doesn't matter, may as well loop through
		// backwards. This is marginally more efficient, since we only
		// have to grab the array length once, and we reference fewer
		// variable values and more constant/literal values.
		for (local i = removeIds.len(); --i > -1; )
		{
			delete displayTargets[removeIds[i]];
		}
    }
	
	// The extra overhead of calling another function may not be
	// desirable, but it's probably worth it just to separate out
	// all this logic.
	// Returns an int handle to the overlay, and updates poolUsedThisFrame.
	function CreateOrUpdateOverlay(color, alpha, bitmapSize, targetX, targetY)
	{
		// The bitmaps can be whatever, but we'll flood the log file
		// with "fatal" errors if the overlay's width or height is not
		// a power of 2. So some bitmaps require overlays larger than
		// the bitmap itself.
		local overlaySize = bitmapSize;
		
		if (!(bitmapSize in powersOfTwo))
		{
			// We want to solve for 2^x=size, which is x = log(size) / log(2)
			// We then ceil() that value to round up to a whole power of 2.
			// Then grab an integer because floating point precision is
			// nasty stuff in any language.
			overlaySize = pow(2, ceil(log(bitmapSize) / logOfTwo).tointeger());
		}
		
		// Subtracted from x/y coordinate to place the center of the
		// bitmap on those coordinates, instead of the top-left corner.
		local overlayOffset = (overlaySize / 2);
		
		local bitmapName = "Radar" + color + bitmapSize;
		
		// We need to find or create an overlay to use for this item.
		// Start by getting the array of overlays for this type. Create
		// it if needed.
		local overlayArray;
		local usedInPool = 0;
		if (bitmapName in overlayPool)
		{
			// The array exists, so grab it.
			overlayArray = overlayPool[bitmapName];
			
			// But is this the first time we've grabbed it this frame?
			// If not, we need to load the appropriate usedInPool value.
			if (bitmapName in poolUsedThisFrame)
			{
				usedInPool = poolUsedThisFrame[bitmapName];
			}
			// Otherwise, we defaulted usedInPool to 0 earlier.
		}
		else
		{
			// First time we've ever seen this one. Create a new,
			// empty array to work with.
			overlayArray = [];
			// And remember it for future use.
			overlayPool[bitmapName] <- overlayArray;
			// NOTE: We defaulted usedInPool to 0 earlier.
		}
		
		// Now overlayArray and usedInPool are populated. Next step is to
		// either pick an existing overlay we haven't used this frame,
		// or we create a new overlay and add it to the array for current
		// and future use.
		local currentOverlay;
		if (usedInPool < overlayArray.len())
		{
			// We can reuse an overlay. Start by grabbing it.
			currentOverlay = overlayArray[usedInPool];
			
			// Position it on top of its new target.
			DarkOverlay.UpdateTOverlayPosition(currentOverlay, targetX - overlayOffset, targetY - overlayOffset);
			// And update its transparency.
			DarkOverlay.UpdateTOverlayAlpha(currentOverlay, alpha);
			
			// NOTE: The engine remembers the contents of the overlay,
			// so we don't need to re-draw them. We only need to tell
			// it to draw the overlay itself later.
		}
		else
		{
			// We need to create a new overlay. This requires some initial
			// setup.
			
			// First, grab a bitmap handle as needed.
			local newBitmap;
			if (bitmapName in bitmaps)
			{
				newBitmap = bitmaps[bitmapName];
			}
			else
			{
				newBitmap = DarkOverlay.GetBitmap(bitmapName, "j4fres\\");
				
				// Images not installed in the needed location? Fallback. This
				// bubble image has nothing to do with anything, but it does
				// exist in both Thief games....
				if (newBitmap == -1)
				{
					newBitmap = DarkOverlay.GetBitmap("BUBB00", "bitmap\\txt\\");
				}
				
				bitmaps[bitmapName] <- newBitmap;
			}
			
			// Power-of-2 bitmaps are easier, since we can turn them directly
			// into an overlay.
			if (bitmapSize == overlaySize)
			{
				currentOverlay = DarkOverlay.CreateTOverlayItemFromBitmap(targetX - overlayOffset, targetY - overlayOffset, alpha, newBitmap, true);
				
				// If we failed, best to abort now.
				if (currentOverlay == -1)
					return - 1;
			}
			else
			{
				// Otherwise, we need to round up to the nearest power of
				// two, create an empty overlay, and draw the bitmap in its
				// center by hand.
				
				currentOverlay = DarkOverlay.CreateTOverlayItem(targetX - overlayOffset, targetY - overlayOffset, overlaySize, overlaySize, alpha, true);
				
				// If we failed, best to abort now.
				if (currentOverlay == -1)
					return - 1;
				
				// We'll need this to center the bitmap inside the new overlay.
				local upgradedOffset = (overlaySize - bitmapSize) / 2;
				
				if (DarkOverlay.BeginTOverlayUpdate(currentOverlay))
				{
					// These x/y coordinates are relative to the overlay itself.
					// So 0,0 is the top-left corner of the overlay, no matter
					// where we end up drawing it on the screen later.
					DarkOverlay.DrawBitmap(newBitmap, upgradedOffset, upgradedOffset);
				
					// Tell the engine we're done drawing the overlay contents.
					DarkOverlay.EndTOverlayUpdate();
				}
			}
			
			// If we succeeded, keep a reference to the new handle.
			overlayArray.append(currentOverlay);
		}
		
		// Regardless of how we got here, we're using another overlay of
		// this type and need to make note of that.
		poolUsedThisFrame[bitmapName] <- usedInPool + 1;
		
		return currentOverlay;
	}
	
	// This function tries to pick a bitmap size that will fill
	// X% of the screen height. However, it will round to the
	// available bitmap sizes (multiples of 8, from 8 to 64).
	function GetTargetBitmapSizeFromScreenPercent(forScreenPercent)
	{
		// Let's aim for X% of the screen height. We have images
		// available in multiples of: 8, 16, 24, 32, etc. up to 64.
		// After applying forScreenPercent, we want to round
		// so that 13-20 are 16, 21-28 is 24, etc. Ignoring the
		// round to 0 possibility for a moment, this scale starts
		// at 5-12 becoming 8. Subtracting 5, that scale becomes
		// 0-7, 8-15, etc. That allows us to divide by 8, floor()
		// the result, add 1, then multiply by 8 again. Or to make
		// things a little simpler, instead of subtracting 5, we
		// can add 3. That saves the "add 1" step above.
		// tl;dr This math picks a multiple of 8 nearest 5% of the
		// screen height.
		// We then cap to a min of 8 and max of 64.
		local r = floor(((canvasHeight * forScreenPercent) + 3) / 8).tointeger() * 8;
		if (r < 8)
		{
			return 8;
		}
		else if (r > 64)
		{
			return 64;
		}
		return r;
	}
	
	// This function tries to pick a bitmap size based on the
	// range of available bitmap sizes (multiples of 8, from 8 to 64).
	// So 100% will return 64, 0% will return 8, 50% is around 32, etc.
	function GetTargetBitmapSizeFromRangePercent(forRangePercent)
	{
		// Start by getting a target pixel value. We then round
		// so that 13-20 are 16, 21-28 is 24, etc. Ignoring the
		// round to 0 possibility for a moment, this scale starts
		// at 5-12 becoming 8. Subtracting 5, that scale becomes
		// 0-7, 8-15, etc. That allows us to divide by 8, floor()
		// the result, add 1, then multiply by 8 again. Or to make
		// things a little simpler, instead of subtracting 5, we
		// can add 3. That saves the "add 1" step above.
		// We then cap to a min of 8 and max of 64.
		local r = floor(((64 * forRangePercent) + 3) / 8).tointeger() * 8;
		if (r < 8)
		{
			return 8;
		}
		else if (r > 64)
		{
			return 64;
		}
		return r;
	}
	
	function SortTargetByDistance(a, b)
	{
		if (a.distance < b.distance) return -1;
		if (a.distance > b.distance) return 1;
		return 0;
	}
	
	// DrawTOverlay implements an IDarkOverlayHandler method.
	//
	// Our best option seems to be creating a separate overlay for each
	// visible indicator, repositioning them as needed. As opposed to,
	// say, creating a single overlay that covers the whole screen and
	// rearranging elements within that master overlay.
	//
	// Using overlays rather than HUD elements gives us more flexibility.
	// For example, we can set transparencies. However, there are some
	// oddities in how coordiantes and such work. Because an overlay must
	// have power-of-2 widths and heights, odds are slim that a single
	// overlay could ever cover the entire screen. So rather than treat
	// the overlay as a shared canvas for all indicators, each indicator
	// will be its own overlay. We'll just create, destroy, and relocate
	// them as needed.
	//
	// NOTE: I've observed in Calendra's Legacy mission 2 (Midnight at
	// Murkbell, a rather large map) that there are no performance issues
	// on my machine, even if handling all radar-enabled items at all
	// distances, including non-physical items that would otherwise be
	// ignored. However, things like NewDark 1.27's limit of 64 overlay
	// handles probably contributes to keeping that performing well.
	function DrawTOverlay()
	{
		if (!enabled)
			return;
		
		// NOTE: this count may be reduced if we truncate the array.
		local toDrawCount = toDrawThisFrame.len();
		
		// Nothing to draw? Then we're done here. At worst, we'll
		// skip destroying all those overlays we didn't use.
		if (toDrawCount < 1)
			return;
		
		// If we're over our limit, keep the closest values and
		// discard the farther ones.
		if (toDrawCount > MAX_POI_RENDERED)
		{
			toDrawThisFrame.sort(SortTargetByDistance);
			toDrawThisFrame.resize(MAX_POI_RENDERED);
			toDrawCount = toDrawThisFrame.len();
		}
		
		// Because the number of tracked items will usually be much
		// bigger than the number of visible items, rather than giving
		// each tracked item its own overlay, we'll have them share a
		// pool of overlays. Instead of an overlay permanently belonging
		// to a point of interest, they will be *temporarily* assigned
		// for the duration of a single frame.
		
		// This variable keeps track of how many overlays of each type
		// we needed this frame, so we can either hide or destroy the
		// rest. The keys match those of overlayPool, but the value is
		// just an integer counter.
		poolUsedThisFrame = {};
		
		// We'll do a complete alpha cycle in 120 frames. If and only
		// if running at 60fps will that take 2 seconds.
		// TODO: is there a function we can use to track time instead?
		if (++currentWaveStep > 119)
		{
			currentWaveStep = 0;
		}
		
		// Max opacity is 127, min is 0. We'll cycle between our desired
		// min and max instead, using sine waves to give a more visually
		// pleasant pulsing effect. The sin() sine function expects
		// values in radians, ranging from 0 to 2*pi. It returns values
		// ranging from -1 to 1. We want -1 to result in MIN_ALPHA and
		// 1 to result in MAX_ALPHA. One option is to start with the
		// midpoint between the two. Another option is to add 1 to the
		// sin() result so it becomes 0 to 2.
		// NOTE: We slightly simplify the 2pi * step/120 to become
		// pi * step / 60. In any case, the step/120 is meant to act as
		// a percentage value from 0.0 to 1.0
		local currentAlpha = MIN_ALPHA + ((sin(PI * currentWaveStep / 60) + 1) * ((MAX_ALPHA - MIN_ALPHA) / 2));
		
		// Since draw order doesn't matter, may as well loop through
		// backwards. This is marginally more efficient, since we only
		// have to grab the array length once, and we reference fewer
		// variable values and more constant/literal values.
		for (local i = toDrawCount; --i > -1; )
		{
			local drawMetadata = toDrawThisFrame[i];
			
			// Consider the following. If an object takes up 50% of the screen
			// height at distance X, it takes up 25% at distance 2X, and only
			// 1/8th the screen at distance 4X. That's an inverse linear
			// relationship. It also means that if we follow that for
			// determining our desired screen %, most of the bitmap sizes will
			// be completely wasted. For example, staying at 8px until you
			// get within 10', then rapidly swelling through the other seven
			// sizes as you close that meager distance.
			// Example: 50% of screen size at a distance of 1 unit
			//	local useBitmapSize = GetTargetBitmapSizeFromScreenPercent(0.5 / drawMetadata.distance);
			//
			// The upside is that this is what feels most natural to us, and
			// has the simplest math. We could possibly do something different
			// to spread each bitmap size over various ranges. For example, if
			// our max distance were 128, each bitmap size would correspond to
			// a range of 16 units. But translated into screen size %, that's
			// basically saying we want 0-7 to be X, 8-15 to be 0.875X, 16-23
			// to be 0.75X, 24-31 to be 0.625X, and so on. This is also a linear
			// relationship, where the multiplier to X is (1 - distance/max_distance).
			local useBitmapSize = GetTargetBitmapSizeFromRangePercent(1 - (drawMetadata.distance / MAX_DIST));
			
			// Our method will make sure the X/Y/alpha/etc. is all sorted
			// out for us.
			local currentOverlay = CreateOrUpdateOverlay(drawMetadata.displayColor, currentAlpha, useBitmapSize, drawMetadata.x, drawMetadata.y);
			
			// I've seen -1 returned when we try to create an overlay after
			// too many already exist :(
			if (currentOverlay != -1)
			{
				// And whether or not we drew the contents of the overlay earlier,
				// we need to instruct it to draw the overlay itself this frame.
				DarkOverlay.DrawTOverlayItem(currentOverlay);
			}
		}
		
		// Destroy any pool overlays we didn't need this frame.
		foreach (poolKey, poolArray in overlayPool)
		{
			local keepThisIndexAndBelow = -1;
			
			// If we used this pool this frame, figure out how many times.
			if (poolKey in poolUsedThisFrame)
			{
				// This is a 1-based counter, but we're dealing in 0-based
				// array indexes, so adjust down by one.
				keepThisIndexAndBelow = poolUsedThisFrame[poolKey] - 1;
			}
			
			// More backwards looping. This time it also lets us take
			// advantage of pop() to reduce the array size as we go.
			for (local i = poolArray.len(); --i > keepThisIndexAndBelow; )
			{
				DarkOverlay.DestroyTOverlayItem(poolArray.pop());
			}
		}
	}
}

// Create a single instance of the handler. This is squirrel's "new slot"
// operator "<-" which adds a slot named myOverlay to a table and then sets the
// value in that slot. Because we're not prefixing myOverlay, presumably this is
// creating a slot in some kind of special table for the entire .nut file or
// something. I'm unclear on the scope of this operation, but it follows the
// sample documentation that comes with NewDark, which states this is a "global"
// instance. I'm not sure if there's any difference between this approach and
// global variables, but in any case it gets the job done.
j4fRadarOverlayInstance <- J4FRadarOverlayHandler();
