// NOTE: To keep installation simpler, all scripting is handled in this file.
// However, some functionality only kicks in when extra DML files are installed
// to enable those features.

// The point-of-interest overlays will bounce between these two transparencies.
const MIN_ALPHA = 40;
const MAX_ALPHA = 132;
// NOTE: This can help performance in some cases, but is mostly a user
// convenience. With the device radar, for example, there's no way to know when
// a switch or lever has become uninteresting. Rather than bother the player
// about a switch halfway across the map, we can limit their display to nearby
// items instead.
const MAX_DIST = 100;
// While NewDark v1.27 allows a max of 64, we'll intentionally cap
// ourselves at a smaller value. After all, we don't want to hog all
// 64 and not leave any for other, more sanely-written mods!
const MAX_POI_RENDERED = 32;
// While I've been able to scan *all* object IDs in a level in a single tick
// of a script timer without issue, it might be wise to spread that out over
// time for performance or other reason.
const MAX_SCANNED_PER_LOOP = 500;
// Set this to lower than MAX_SCANNED_PER_LOOP to limit how many points of
// interest will be registered in a single pass through the level scanning.
const MAX_INITIALIZED_PER_LOOP = 500;
// If our object scanning has this many completely empty loops in a row, we
// consider the scan complete. There's no way I can see to know how many
// objects exist in a level, object IDs can have gaps in them, and object IDs
// can even be reused as objects are destroyed and created. This should be set
// high enough to be thorough, but not so high as to waste time on empty space.
const MAX_EMPTY_SCAN_GROUPS = 3;

// 1 (move) + 2 (script) + 128 (default) = 131
const INTERESTING_FROB_FLAGS = 131;

// We just want a character not likely to be used in the text IDs.
const READ_LIST_SEPARATOR = ";";

// These correspond to the various RadarX64.png filenames.
const COLOR_CONTAINER = "W";
const COLOR_CREATURE = "R";
const COLOR_CYBERMODULE = "G";
const COLOR_DEFAULT = "W";
const COLOR_DEVICE = "P";
const COLOR_EQUIP = "G";
const COLOR_EQUIP_STACKED = "K";
const COLOR_EQUIP_SLOTTED = "P";
const COLOR_EQUIP_UNLIMITED = "Y";
const COLOR_LOOT = "Y";
const COLOR_NANITE = "Y";
const COLOR_QUEST = "K";
const COLOR_READABLE = "B";

// These are used to allow subclasses to keep their data separate when applied
// to the same object.
const DATA_SUFFIX_CONTAINER = "_B";
const DATA_SUFFIX_CREATURE = "_C";
const DATA_SUFFIX_CREATUREBOX = "_CB";
const DATA_SUFFIX_CYBERMODULE = "_M";
const DATA_SUFFIX_DEVICE = "_D";
const DATA_SUFFIX_EQUIP = "_E";
const DATA_SUFFIX_GRAB = "_G";
const DATA_SUFFIX_LOOT = "_L";
const DATA_SUFFIX_NANITE = "_N";
const DATA_SUFFIX_QUEST = "_Q";
const DATA_SUFFIX_READABLE = "_R";
const DATA_SUFFIX_SECRET = "_S";

// An item can match multiple criteria, and this determines how to display it.
// Lower numbers are preferred. Duplicates may cause weirdness. Gaps permitted.
const POI_RANK_QUEST = 1;
const POI_RANK_SECRET = 2;
const POI_RANK_LOOT = 3;
const POI_RANK_CYBERMODULE = 4;
const POI_RANK_NANITE = 5;
const POI_RANK_EQUIP = 6;
const POI_RANK_READABLE = 7;
const POI_RANK_CONTAINER = 8;
const POI_RANK_CREATURE = 9;
const POI_RANK_DEVICE = 10;
const POI_RANK_GRAB = 99;

// Various class, metaproperty, and object name strings.
// This one Marker instance is placed in each level. It sets up the UI overlay.
// It can also be used to track any kind of global state we need to persist
// between saving and loading.
const OVERLAY_INTERFACE = "J4FRadarUiInterfacer";

// If these metaproperties exist, they enable certain optional features. They
// don't need to be assigned to anything.
const FEATURE_CONTAINER = "J4FRadarEnableContainer";
const FEATURE_CREATURE = "J4FRadarEnableCreature";
const FEATURE_CREATURE_GOOD = "J4FRadarEnableCreatureG";
const FEATURE_CREATURE_NEUTRAL = "J4FRadarEnableCreatureN";
const FEATURE_CYBERMODULE = "J4FRadarEnableCyberModule";
const FEATURE_DEVICE = "J4FRadarEnableDevice";
const FEATURE_DIRECT_SCRIPT = "J4FRadarEnableDirectScript";
const FEATURE_EQUIP = "J4FRadarEnableEquip";
const FEATURE_KEYCODE = "J4FRadarEnableCurrentKeycode";
const FEATURE_LOOT = "J4FRadarEnableLoot";
const FEATURE_NANITE = "J4FRadarEnableNanite";
const FEATURE_PICKPOCKET = "J4FRadarEnablePickPocket";
const FEATURE_QUEST = "J4FRadarEnableQuest";
const FEATURE_READABLE = "J4FRadarEnableReadable";

// These metaproperties are used to flag items as interesting to the radar.
const POI_ANY = "J4FRadarPointOfInterest";
const POI_CONTAINER = "J4FRadarContainerPOI";
const POI_CREATURE = "J4FRadarCreaturePOI";
const POI_CREATUREBOX = "J4FRadarCreatureBoxPOI";
const POI_CYBERMODULE = "J4FRadarCyberModulePOI";
const POI_CYBERTRAP = "J4FRadarCyberModuleTrapPOI";
const POI_DEVICE = "J4FRadarDevicePOI";
const POI_EQUIP = "J4FRadarEquipPOI";
const POI_EQUIP_SLOTTED = "J4FRadarEquipSlottedPOI";
const POI_EQUIP_STACKED = "J4FRadarEquipStackedPOI";
const POI_EQUIP_UNLIMITED = "J4FRadarEquipUnlimitedPOI";
const POI_GENERIC = "J4FRadarFallbackPOI";
const POI_LOOT = "J4FRadarLootPOI";
const POI_NANITE = "J4FRadarNanitePOI";
const POI_QUEST = "J4FRadarQuestPOI";
const POI_READABLE = "J4FRadarReadablePOI";
const POI_READABLE_SIMPLE = "J4FRadarSimpleReadablePOI";
const POI_READABLE_TRAP = "J4FRadarReadableTrapPOI";
const POI_SECRET = "J4FRadarSecretPOI";

// Objects of this type are spawned to represent tricky items to the
// radar system instead.
const POI_PROXY_MARKER = "J4FRadarProxyPOI";
// This metaproperty has the script which manages our bless checking timer.
const POI_CLOCK = "J4FRadarPOITimer";

// This indicates an item has been processed as a point of interest and can be
// ignored from now on.
const POI_INIT_FLAG = "J4FRadarPoiInitted";
const POI_INIT_WITH_PROXY_FLAG = "J4FRadarPoiProxyInitted";

// This indicates a previously-processed item was ended. If we see it hanging
// around on the next scan, it probably needs to be re-initialized with a
// proxy.
const POI_NEUTERED_FLAG = "J4FRadarPoiNeutered";

// Link flavour used to associate a POI proxy marker with its target.
const PROXY_ATTACH_METHOD_TO_TARGET = "PhysAttach";
const PROXY_ATTACH_METHOD_TO_PROXY = "~PhysAttach";

// Used to figure out difficulty level, for want of a clear function to do so.
const DIFFICULTY_0 = "M-GarrettDiffNormal";
const DIFFICULTY_1 = "M-GarrettDiffHard";
const DIFFICULTY_2 = "M-GarrettDiffExpert";

// See convict.osm documentation for details.
const OBJECTIVE_ANY = "goal_";
const OBJECTIVE_BONUS = "goal_bonus_";
const OBJECTIVE_IRREVERSIBLE = "goal_irreversible_";
const OBJECTIVE_MAX_DIFFICULTY = "goal_max_diff_";
const OBJECTIVE_MIN_DIFFICULTY = "goal_min_diff_";
const OBJECTIVE_OPTIONAL = "goal_optional_";
const OBJECTIVE_REVERSED = "goal_reverse_";
const OBJECTIVE_SPECIAL_BITS = "goal_special_";
const OBJECTIVE_STATE = "goal_state_";
const OBJECTIVE_TARGET = "goal_target_";
const OBJECTIVE_TYPE = "goal_type_";
const OBJECTIVE_VISIBLE = "goal_visible_";

// See convict.osm documentation for details.
const OBJECTIVE_TYPE_CONTAIN = 1;
const OBJECTIVE_TYPE_SLAY = 2;
const OBJECTIVE_TYPE_LOOT = 3;
const OBJECTIVE_TYPE_ROOM = 4;

// There's a bitwise field on items, and this bit indicates it's a secret that
// can be found.
const STATBIT_HIDDEN = 4;

const AINonHostilityEnum_kAINH_Always = 6;

j4fIsShock <- (GetDarkGame() == 1);
j4fIsThief <- (GetDarkGame() != 1);
j4fPlayerArchetype <- j4fIsShock ? "The Player" : "Avatar";

// Between the lack of a true static/utility method class concept
// in squirrel and to avoid questions about when we do or don't
// have access to API-reference_services.txt stuff, we're using
// this superclass for any of our scripts that might benefit from
// these utility methods.
class J4FRadarUtilities extends SqRootScript
{
	// While we can attach scripts to existing objects, sometimes
	// that's a challenge. Stuff like IsLoot is a metaproperty, so
	// we can't just attach a metaproperty to IsLoot. Other
	// objects are set to not inherit scripts, so even if we did
	// attach a metaproperty with a new script, it would have no
	// effect.
	//
	// Sometimes, we create invisible markers and attach scripts to
	// them. We could leave them completely disconnected from the
	// target object if we wanted, and tell them what they're
	// representing by sending script messages after we create it.
	// However, we use a particular kind of Link, to ensure that
	// if the target object is destroyed, the game automatically
	// destroys our marker as well. If we wanted to manage that
	// manually, we'd have to be mindful of the possibility that
	// object IDs are reused over time. Every time someone shoots
	// an arrow, that creates and new object. When that arrow
	// hits flesh or stone, it gets destroyed. The game does not
	// continually use higher and higher object IDs, and is
	// capable of reusing smaller ones that have been freed up.
	// If we weren't mindful of all that, a POI could suddenly
	// point to an inappropriate or irrelevant object.
	function InitPointOfInterestIfNeeded(forItem, reviewExisting, objectiveNumber = -1)
	{
		// Do some quick checks up front.
		if (
			// Stopped existing.
			!Object.Exists(forItem)
			// Or it's not a point of interest.
			|| !Object.InheritsFrom(forItem, POI_ANY)
			// Or it's already been processed, without a proxy.
			|| Object.HasMetaProperty(forItem, POI_INIT_FLAG)
			// Or it's a proxy to some other item.
			|| Object.InheritsFrom(forItem, POI_PROXY_MARKER)
		)
		{
			return false;
		}
		
		// Was this handled via proxy?
		if (Object.HasMetaProperty(forItem, POI_INIT_WITH_PROXY_FLAG))
		{
			// Cool. If we're not specifically reviewing stuff, count it
			// good and move on.
			if (!reviewExisting)
			{
				return false;
			}
			
			// Otherwise, is the proxy intact?
			local possibleProxyLinks = Link.GetAll(PROXY_ATTACH_METHOD_TO_PROXY, forItem);
			foreach (checkLink in possibleProxyLinks)
			{
				if (Object.InheritsFrom(LinkDest(checkLink), POI_PROXY_MARKER))
				{
					// Proxy still working.
					return false;
				}
			}
			
			// Uh-oh. Proxy is gone now. Do-over.
			print(format("Proxy lost %s %s %i",  Object.GetName(Object.Archetype(forItem)), Object.GetName(forItem), forItem));
			Object.RemoveMetaProperty(forItem, POI_INIT_WITH_PROXY_FLAG);
		}
		
		// By default, assume we're going to attach scripts to the
		// item itself.
		local scriptWhat = forItem;
		local proxyNeeded = false;
		local directScriptNeeded = false;
		local directScriptEnabled = ObjID(FEATURE_DIRECT_SCRIPT) < 0;
		
		// Although, for a previously neutered item we're processing
		// again, we must use a proxy this time.
		if (Object.HasMetaProperty(forItem, POI_NEUTERED_FLAG))
		{
			print(format("J4FRadar: Re-initializing %s %i \"%s\" %i", Object.GetName(Object.Archetype(forItem)), Object.Archetype(forItem), Object.GetName(forItem), forItem));
			proxyNeeded = false;
		}
		
		if (
			// If the item is not allowed to inherit scripts, we
			// should proxy it.
			Property.Possessed(forItem, "Scripts")
			&& Property.Get(forItem, "Scripts", "Don't Inherit")
		)
		{
			proxyNeeded = true;
		}
		
		// Do we need a proxy marker instead?
		if (proxyNeeded)
		{
			// Create a new proxy marker on top of the item it is proxying.
			// The location shouldn't actually matter, but there's no harm
			// in setting it.
			local proxyMarker = Object.BeginCreate(POI_PROXY_MARKER);
			Object.Teleport(proxyMarker, Object.Position(forItem), Object.Facing(forItem));
			Object.EndCreate(proxyMarker);
			
			// Link these items together.
			local proxyAttach = Link.Create(PROXY_ATTACH_METHOD_TO_TARGET, proxyMarker, forItem);
			
			// We'll attach the scripts to the proxy instead of the target.
			scriptWhat = proxyMarker;
		}
		
		// Flag the item as having been set up.
		Object.AddMetaProperty(forItem, proxyNeeded ? POI_INIT_WITH_PROXY_FLAG : POI_INIT_FLAG);
		
		// Copy the POI metaproperty of the target item, then activate
		// the appropriate script on the proxy. We could have also
		// created more metaproperties, some with scripts (for the marker),
		// and some without scripts (for the interesting objects).
		local handledAny = false;
		
		if (Object.InheritsFrom(forItem, POI_SECRET))
		{
			Object.AddMetaProperty(scriptWhat, POI_SECRET + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_QUEST))
		{
			Object.AddMetaProperty(scriptWhat, POI_QUEST + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_LOOT))
		{
			Object.AddMetaProperty(scriptWhat, POI_LOOT + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_CYBERMODULE))
		{
			Object.AddMetaProperty(scriptWhat, POI_CYBERMODULE + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_CYBERTRAP))
		{
			Object.AddMetaProperty(scriptWhat, POI_CYBERTRAP + "_S");
			handledAny = true;
			
			// May need direct scripting to know when the trap has been triggered.
			if (
				directScriptEnabled
				&& scriptWhat != forItem
			)
			{
				directScriptNeeded = true;
			}
		}
		
		if (Object.InheritsFrom(forItem, POI_NANITE))
		{
			Object.AddMetaProperty(scriptWhat, POI_NANITE + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_EQUIP))
		{
			local whichEquipScript = POI_EQUIP + "_S";
			
			if (j4fIsShock)
			{
				if (Object.InheritsFrom(forItem, POI_EQUIP_UNLIMITED))
				{
					whichEquipScript = whichEquipScript + "U";
				}
				else if (Object.InheritsFrom(forItem, POI_EQUIP_SLOTTED))
				{
					whichEquipScript = whichEquipScript + "S";
				}
				else if (Object.InheritsFrom(forItem, POI_EQUIP_STACKED))
				{
					whichEquipScript = whichEquipScript + "T";
				}
				else if (Property.Possessed(forItem, "CombineType") && !!Property.Get(forItem, "CombineType"))
				{
					whichEquipScript = whichEquipScript + "T";
				}
				else
				{
					whichEquipScript = whichEquipScript + "S";
				}
			}
			
			Object.AddMetaProperty(scriptWhat, whichEquipScript);
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_DEVICE))
		{
			Object.AddMetaProperty(scriptWhat, POI_DEVICE + "_S");
			
			// It'd be nice to flag devices as used when frobbed,
			// even with proxies.
			if (
				directScriptEnabled
				&& scriptWhat != forItem
			)
			{
				directScriptNeeded = true;
			}
			
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_CONTAINER))
		{
			Object.AddMetaProperty(scriptWhat, POI_CONTAINER + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_CREATURE))
		{
			Object.AddMetaProperty(scriptWhat, POI_CREATURE + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_CREATUREBOX))
		{
			Object.AddMetaProperty(scriptWhat, POI_CREATUREBOX + "_S");
			handledAny = true;
		}
		
		if (Object.InheritsFrom(forItem, POI_READABLE))
		{
			// The read/unread tracking won't work for proxies,
			// unless direct scripting is enabled.
			if (scriptWhat == forItem)
			{
				Object.AddMetaProperty(scriptWhat, POI_READABLE + "_S");
			}
			else if (directScriptEnabled)
			{
				Object.AddMetaProperty(scriptWhat, POI_READABLE + "_S");
				directScriptNeeded = true;
			}
			
			handledAny = true;
		}
		else if (Object.InheritsFrom(forItem, POI_READABLE_SIMPLE))
		{
			Object.AddMetaProperty(scriptWhat, POI_READABLE_SIMPLE + "_S");
			handledAny = true;
		}
		else if (Object.InheritsFrom(forItem, POI_READABLE_TRAP))
		{
			Object.AddMetaProperty(scriptWhat, POI_READABLE_TRAP + "_S");
			handledAny = true;
			
			// May need direct scripting to know when the trap has been triggered.
			if (
				directScriptEnabled
				&& scriptWhat != forItem
			)
			{
				directScriptNeeded = true;
			}
		}
		
		// If no more specific POI type applies, fall back to the generic one.
		if (!handledAny)
		{
			Object.AddMetaProperty(scriptWhat, POI_GENERIC + "_S");
		}
		
		// If the item is associated with an objective, let it know which one.
		if (objectiveNumber > -1)
		{
			PostMessage(scriptWhat, "J4FSetObjective", objectiveNumber);
		}
		
		if (directScriptEnabled && directScriptNeeded)
		{
			AddScriptDirectly(forItem, "J4FPassToProxy");
		}
		
		// With all that stuff out of the way, we can start the timer.
		Object.AddMetaProperty(scriptWhat, POI_CLOCK);
		
		return true;
	}
	
	function AddScriptDirectly(toItem, scriptName)
	{
		local firstEmptySlot = -1;
		
		// Loop through all slots to see if the script is already
		// attached, but make note of the first empty slot if any.
		// This gracefully handles gaps in script slots.
		for (local i = -1; ++i < 4; )
		{
			local currentScript = Property.Get(toItem, "Scripts", "Script " + i);
			
			// We already have the script! Abort.
			if (currentScript == scriptName)
				return;
			
			if (currentScript == null || currentScript == "")
			{
				if (firstEmptySlot < 0)
				{
					firstEmptySlot = i;
				}
			}
		}
		
		// We don't already have the script.
		// Do we have an empty slot to put it in?
		if (firstEmptySlot > -1)
		{
			Property.Set(toItem, "Scripts", "Script " + firstEmptySlot, scriptName);
		}
		else
		{
			print(format("Unable to directly script %s %s %i", Object.GetName(Object.Archetype(toItem)), Object.GetName(toItem), toItem));
		}
	}
	
	// Returns checkId if it has no POI proxy marker,
	// or returns the object ID of its marker.
	function GetObjectOrProxy(checkId)
	{
		// What are we pointing at? The attach link is from the
		// proxy to us.
		local possibleProxyLinks = Link.GetAll(PROXY_ATTACH_METHOD_TO_PROXY, checkId);
		foreach (checkLink in possibleProxyLinks)
		{
			local linkedTo = LinkDest(checkLink);
			if (Object.InheritsFrom(linkedTo, POI_PROXY_MARKER))
			{
				SetData("J4FRadarProxyCache", linkedTo);
				return linkedTo;
			}
		}
		
		return checkId;
	}
	
	// Negative values are rendered, like belt and quiver items that
	// can be pickpocketed.
	function IsVisiblyContained(linkId)
	{
		// Even attempting to call LinkGetData on this in SS2
		// causes a hang-and-crash issue. Doesn't seem like
		// pickpocketing is SS2's thing anyway.
		return j4fIsThief && (LinkTools.LinkGetData(linkId, "") < 0);
	}
	
	// In transitions between hub missions, objects can make a
	// transition between levels, but their proxy attachments
	// do not. However, when returning to a previous area, the
	// proxy may discover its attachment is no longer valid.
	// Maybe the object was destroyed, or a different item has
	// the item ID we were attached to!
	function IsProxyOnOriginalTarget()
	{
		// So far, haven't encountered issues with non-proxy
		// objects.
		if (!Object.InheritsFrom(self, POI_PROXY_MARKER))
			return true;
		
		local attachLinkId = Link.GetOne(PROXY_ATTACH_METHOD_TO_TARGET, self);
		local linkedToId = LinkDest(attachLinkId);
		local isIntact = true;
		
		if (!Object.Exists(linkedToId))
		{
			print("Proxy's target no longer exists.");
			isIntact = false;
		}
		else
		{
			// It's still technically possible that the archetype
			// will be the same and we end up pointing at a
			// different instance of it, but that corner case
			// should be relatively harmless. Compared to, say,
			// indicating a grub pod organ as a readable.
			local linkedToArchetype = Object.Archetype(linkedToId);
			
			if (!IsDataSet("J4FOriginalTargetArchetype"))
			{
				SetData("J4FOriginalTargetArchetype", linkedToArchetype);
			}
			else if (GetData("J4FOriginalTargetArchetype") != linkedToArchetype)
			{
				print(format("Proxy target changed from %s %i to %s %i", Object.GetName(GetData("J4FOriginalTargetArchetype")), GetData("J4FOriginalTargetArchetype"), Object.GetName(linkedToArchetype), linkedToArchetype));
				isIntact = false;
			}
		}
		
		return isIntact;
	}
	
	// Well, Quest.BinSetTable/Quest.BinGetTable look promising, but
	// are buggy. They claim they use or relate to campaign QVars, yet
	// they persist across unexpected boundaries. For example, you can
	// BinSetTable, then start a new game, and that new game will
	// have access to the QVar you set in the previous game. You can
	// also load up an old save game. Even if it never had set this
	// quest data, BinExists will return true, and BinGetTable will
	// return the new data. This is as of NewDark v1.27/v2.48 :(
	//
	// So to store a string in an actual campaign QVar, without these
	// weird scope bugs, we'll have to deal with all QVars being ints.
	// So storing a string requires storing a QVar per each character,
	// in a numeric ASCII or Unicode value.
	function SetQuestDataString(prefix, value)
	{
		if (value == null)
		{
			if (Quest.Exists(prefix))
			{
				Quest.Delete(prefix);
			}
			return;
		}
		
		local len = value.len();
		
		Quest.Set(prefix, len, eQuestDataType.kQuestDataCampaign);
		
		// Looping backwards, set each character. Apparently, strings
		// can be treated as arrays of characters. And they'll either
		// be 8-bit ASCII or 16-bit unicode, depending on how Squirrel
		// was compiled. Let's hope for ASCII, because as far as I can
		// tell, even in unicode mode format("%c", i) and i.tochar()
		// both only expect 8-bit ASCII. Maybe understandable for a
		// language birthed in the aughties, but feels weird this
		// day and age. Or maybe it's a difference between the
		// Squirrel standard and ElectricImp's variant? In any case,
		// value[x] should be either a C char type or an int 0-255.
		for (local i = len; --i > -1; )
		{
			Quest.Set(prefix + "_" + i, value[i], eQuestDataType.kQuestDataCampaign);
		}
	}
	
	// Counterpart to SetQuestDataString. See that for details.
	function GetQuestDataString(prefix)
	{
		if (!Quest.Exists(prefix))
			return null;
		
		local len = Quest.Get(prefix);
		
		if (len == 0)
			return "";
		
		local r = "";
		
		// Loop through until we've built the whole string.
		// Since strings are immutable, I'm not aware of a
		// standard join() function, and I don't see any
		// kind of stringbuilder concept, we're going to do
		// this through concatenation. At that point, it
		// really doesn't matter whether we tack a tiny
		// string onto the end of a longer one or a longer
		// one after a tiny one. So we'll loop backwards
		// and prepend characters until done.
		// See also comments in SetQuestDataString for
		// Squirrel character behaviors.
		for (local i = len; --i > -1; )
		{
			r = Quest.Get(prefix + "_" + i).tochar() + r;
		}
		
		return r;
	}
}

// This script goes on an inventory item the player can use to turn the
// radar effect on and off.
class J4FRadarToggler extends SqRootScript
{
	function OnFrobInvEnd()
	{
		// We'll rely on the central marker to remember our on/off state.
		// Tell it we're toggling it, and it will tell us what our new
		// state is.
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

class J4FRadarSpawnToggler extends SqRootScript
{
	function OnCreate()
	{
		SendMessage(ObjID(OVERLAY_INTERFACE), "J4FRadarToggle", self);
		SetOneShotTimer("J4FDestroyMe", 0.01);
	}
	
	function OnTimer()
	{
		Object.Destroy(self);
	}
}

class J4FRadarPOIClock extends J4FRadarUtilities
{
	// This will fire on mission start, on reloading a save, and when
	// an object with this script is created after the game has started.
	function OnBeginScript()
	{
		// Depending on which order objects are set up, things like the
		// overlay marker may not be ready yet. We'll add a slight
		// startup delay before registering our existence with them.
		// NOTE: Multiple POI target scripts on the same object will
		// share the same timer.
		if (!IsDataSet("J4FRadarReviewStarted"))
		{
			SetData("J4FRadarReviewStarted", true);
			SetOneShotTimer("J4FRadarTargetReview", 0.25);
		}
	}
	
	function OnTimer()
	{
		if (message().name != "J4FRadarTargetReview")
			return;
		
		// Repeat. We don't need to do anything else.
		// Instead, the individual target scripts will
		// have their own logic. Everyone will hear this
		// timer event and can react as they please.
		SetOneShotTimer("J4FRadarTargetReview", 0.25);
	}
	
	// I've encountered cases where an object contines to exist, but
	// something kills all the scripts on it. For example, opening a
	// desk container in SS2's first real game area.
	// WARNING: OnEndScript fires in at least four cases I've seen.
	//	1) When ending a game.
	//	2) When destroying an object with scripts on it. At least,
	//		I think I've seen that. Granted, I was paying more
	//		attention to the other cases listed here....
	//	3) When loading a save game, EndScript will be passed to
	//		everything before a BeginScript. Just try adding
	//		Object.Destroy(self) to an OnEndScript and watch things
	//		disappear when you load your saves. Fun.
	//	4) When scripts are removed, such as when metaproperty-
	//		inherited scripts are killed because something turned
	//		"Don't Inherit" on after the fact.
	// So many things aren't safe to do during OnEndScript, because
	// it happens for so many reasons and we can't tell them apart.
	function OnEndScript()
	{
		// If the proxy dies, chances are it's because we're deleting
		// it or something. We shouldn't need to care.
		if (Object.InheritsFrom(self, POI_PROXY_MARKER))
			return;
		
		// Someone turned on Don't Inherit? That's a little mean.
		if (Property.Possessed(self, "Scripts") && Property.Get(self, "Scripts", "Don't Inherit"))
		{
			print(format("J4FRadar: Clock neutered %s %i \"%s\" %i", Object.GetName(Object.Archetype(self)), Object.Archetype(self), Object.GetName(self), self));
			
			// Make sure the clock stays neutered. We don't want to
			// end up with both a proxy and a direct POI for the same
			// thing.
			Object.RemoveMetaProperty(self, POI_CLOCK);
			
			// Make sure we use a proxy next time.
			Object.AddMetaProperty(self, POI_NEUTERED_FLAG);
			// Allow us to be re-initialized on the next scan.
			Object.RemoveMetaProperty(self, POI_INIT_FLAG);
		}
	}
}

// This goes on the original item, but passes certain events to its proxy.
class J4FPassToProxy extends J4FRadarUtilities
{
	function GetProxy()
	{
		if (IsDataSet("J4FRadarProxyCache"))
		{
			return GetData("J4FRadarProxyCache");
		}
		
		local myProxy = GetObjectOrProxy(self);
		SetData("J4FRadarProxyCache", myProxy);
		return myProxy;
	}
	
	function OnFrobWorldEnd()
	{
		if (Object.InheritsFrom(message().Frobber, j4fPlayerArchetype))
			PostMessage(GetProxy(), "J4FPlayerFrob");
	}
	
	function OnFrobInvEnd()
	{
		if (Object.InheritsFrom(message().Frobber, j4fPlayerArchetype))
			PostMessage(GetProxy(), "J4FPlayerFrob");
	}
	
	function OnTurnOn()
	{
		PostMessage(GetProxy(), "J4FTurnedOn");
	}
}

// This a superclass for all items that the radar can display.
class J4FRadarAbstractTarget extends J4FRadarUtilities
{
	constructor(color = COLOR_DEFAULT, uncapDistance = false, rank = -1)
	{
		SetDataSub("J4FRadarColor", color);
		SetDataSub("J4FRadarUncapDistance", uncapDistance);
		SetDataSub("J4FRadarRank", rank);
	}
	
	// Once we started putting multiple target classes on the same
	// item, it became necessary to separate some of their data
	// from each other.
	// NOTE: Having seen some strangeness with local variables
	// seemingly shared between multiple instances of a class,
	// I'm avoiding use of local variables to modify these
	// functions. Subclasses will have to hardcode variations
	// instead :(
	function GetDataSub(key) {return GetData(key);}
	function SetDataSub(key, value) {SetData(key, value);}
	function ClearDataSub(key) {ClearData(key);}
	function IsDataSetSub(key) {return IsDataSet(key);}
	
	// A proxy marker keeps track of the actual target item of
	// interest. In older versions of this mod, we would also
	// script target items directly in some cases, in which case
	// "self" would be the target.
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
			whoAmI = LinkDest(Link.GetOne(PROXY_ATTACH_METHOD_TO_TARGET, self));
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
		// display the container instead.
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		if (linkToMyContainer != 0 && !IsVisiblyContained(linkToMyContainer))
		{
			// There's a handy LinkDest() function, but to get the source we need
			// to instantiate the whole link object.
			target = sLink(linkToMyContainer).source;
		}
		
		return target;
	}
	
	// The game does not always update the locations of linked
	// pickpocketable items, if the creature itself is not rendered.
	// For corner cases like this, we can fall back to the
	// creature's location to display the point of interest.
	function AltDisplayTarget()
	{
		local linkToMyContainer = Link.GetOne("Contains", 0, PoiTarget());
		if (linkToMyContainer != 0 && IsVisiblyContained(linkToMyContainer))
		{
			// There's a handy LinkDest() function, but to get the source we need
			// to instantiate the whole link object.
			return sLink(linkToMyContainer).source;
		}
		
		return "";
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
		if (linkToMyContainer != 0 && Object.InheritsFrom(sLink(linkToMyContainer).source, j4fPlayerArchetype))
			return false;
		
		// Ignore things involved in certain other kinds of relationship,
		// with anyone.
		if (
			Link.GetOne("~AIProjectile", target) != 0
			|| Link.GetOne("~AIRangedWeapon", target) != 0
			|| Link.GetOne("~Projectile", target) != 0
			|| Link.GetOne("~Weapon", target) != 0
			|| Link.GetOne("~CurWeapon", target) != 0
		)
		{
			return false;
		}
		
		return true;
	}
	
	// This isn't for pickpocketable things, but for chests and such.
	function IsInOpenableContainer(target = null)
	{
		if (target == null)
			target = PoiTarget();
		
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		
		// Are we contained by something in a way that prevent us from rendering?
		if (
			// We are contained.
			linkToMyContainer != 0
			// But not visibly, like on a belt for pickpocketing.
			&& !IsVisiblyContained(linkToMyContainer)
		)
		{
			local linkSource = sLink(linkToMyContainer).source;
			
			if (
				(
					j4fIsThief
					&& Object.InheritsFrom(linkSource, "Container")
				)
				|| (
					j4fIsShock
					&& (
						Object.InheritsFrom(linkSource, "Usable Containers")
						|| Object.InheritsFrom(linkSource, "Corpses")
						// Well, they should become openable when they're dead, anyway.
						|| Object.InheritsFrom(linkSource, "Monsters")
					)
				)
			)
			{
				return true;
			}
		}
		
		return false;
	}
	
	// This is a common need for many points of interest, and implemented
	// here so they can add it to their BlessItem() if desired.
	function IsWorldFrobbable(target = null)
	{
		if (target == null)
			target = PoiTarget();
		
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
	// having a model which is effectively empty. Of course, the game
	// can also skip rendering out-of-sight items, but we're specifically
	// *not* concerned about that here. We want to know if the item
	// would probably be rendered if we were staring at its location.
	function IsRendered(target = null)
	{
		if (target == null)
			target = PoiTarget();
		
		// If we're in a container (not in a pickpocket way, but a
		// regular chest kind of way), our render status is irrelevant.
		if (IsInOpenableContainer(target))
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
		// we don't care about being in a chest or something. The
		// logic below is for creatures or other "containers" who
		// may or may not render us.
		local linkToMyContainer = Link.GetOne("Contains", 0, target);
		local visiblyContained = false;
		// Are we contained by something in a way that prevent us from rendering?
		if (
			// We are contained...
			linkToMyContainer != 0
		)
		{
			// ...in a visible way
			if (IsVisiblyContained(linkToMyContainer))
			{
				visiblyContained = true;
			}
			// ...in a non-visible way
			else
			{
				return false;
			}
		}
		
		// HasRefs is often used to "disable" items, making them not
		// render or collide. Note that pickpocketable items have this
		// attribute as well.
		if (!visiblyContained && Property.Possessed(target, "HasRefs") && !Property.Get(target, "HasRefs"))
			return false;
		
		// I dunno, I guess it's rendered. I suppose we also need things
		// like a model and whatever.
		return true;
	}
	
	// This will fire on mission start, on reloading a save, and when
	// an object with this script is created after the game has started.
	function OnBeginScript()
	{
		// Default to unknown on a reload. Mostly so that we can be
		// sure to add or remove us from the overlay.
		ClearDataSub("J4FRadarLastBless");
	}
	
	function OnTimer()
	{
		if (message().name != "J4FRadarTargetReview")
			return;
		
		if (!IsProxyOnOriginalTarget())
		{
			print("Destroying invalidated proxy.");
			Object.Destroy(self);
			return;
		}
		
		// Does our interface exist yet?
		local interfaceId = ObjID(OVERLAY_INTERFACE);
		if (interfaceId < 1)
		{
			// Try again later.
			return;
		}
		
		// Is it okay to display this item right now? Note that
		// this doesn't include all checks, like showing only
		// nearby items or items the camera is facing. This only
		// determines whether we would want to show the item
		// if it were right in front of us.
		local newBlessed = BlessItem();
		
		// NOTE: SetData/GetData can work with ints, but not
		// booleans. Booleans get converted to ints. But
		// later on, when we check !=, a boolean true and
		// an int 1 are different, as are a boolean false
		// and an int 0. So we're trying to normalize all
		// that here.
		local wasBlessed = null;
		
		if (IsDataSetSub("J4FRadarLastBless"))
		{
			// A double negation will turn it into a boolean,
			// if it wasn't already.
			wasBlessed = !!GetDataSub("J4FRadarLastBless");
		}
		
		// If our blessing status changes, add or remove us from the list
		// of targets to review and display.
		if (
			// If we don't know our previous condition.
			wasBlessed == null
			// Or we do know and it has changed.
			|| wasBlessed != newBlessed
		)
		{
			if (newBlessed)
			{
				SendMessage(interfaceId,
					"J4FRadarDetected",
					// data
					self,
					// data2
					"" + DisplayTarget() + "," + GetDataSub("J4FRadarRank"),
					// data3
					GetDataSub("J4FRadarColor") + (GetDataSub("J4FRadarUncapDistance") ? "1" : "0") + AltDisplayTarget()
					);
			}
			else
			{
				SendMessage(interfaceId, "J4FRadarDestroyed", self, GetDataSub("J4FRadarRank"));
			}
			
			SetDataSub("J4FRadarLastBless", newBlessed);
		}
	}
	
	// Because item IDs can be reused, we need to be sure a destroyed
	// item is removed from the list. Otherwise, we could treat some
	// random arrow or blood splatter as a point of interest.
	function OnDestroy()
	{
		SendDestroyMessage();
	}
	
	// I've encountered cases where an object contines to exist, but
	// something kills all the scripts on it. For example, opening a
	// desk container in SS2's first real game area.
	// WARNING: OnEndScript fires in at least four cases I've seen.
	//	1) When ending a game.
	//	2) When destroying an object with scripts on it. At least,
	//		I think I've seen that. Granted, I was paying more
	//		attention to the other cases listed here....
	//	3) When loading a save game, EndScript will be passed to
	//		everything before a BeginScript. Just try adding
	//		Object.Destroy(self) to an OnEndScript and watch things
	//		disappear when you load your saves. Fun.
	//	4) When scripts are removed, such as when metaproperty-
	//		inherited scripts are killed because something turned
	//		"Don't Inherit" on after the fact.
	// So many things aren't safe to do during OnEndScript, because
	// it happens for so many reasons and we can't tell them apart.
	function OnEndScript()
	{
		// Someone turned on Don't Inherit? That's a little mean.
		if (Property.Possessed(self, "Scripts") && Property.Get(self, "Scripts", "Don't Inherit"))
		{
			print(format("J4FRadar: Target neutered %s %i \"%s\" %i", Object.GetName(Object.Archetype(self)), Object.Archetype(self), Object.GetName(self), self));
			SendDestroyMessage();
		}
	}
	
	function SendDestroyMessage()
	{
		// Does our interface exist yet?
		local interfaceId = ObjID(OVERLAY_INTERFACE);
		if (interfaceId < 1)
			return;
		
		SendMessage(interfaceId, "J4FRadarDestroyed", self, -1);
	}
}

class J4FRadarQuestTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_QUEST, true, POI_RANK_QUEST);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_QUEST);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_QUEST, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_QUEST);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_QUEST);}
	
	function OnJ4FSetObjective()
	{
		SetData("J4FRadarObjective", message().data);
	}
	
	function BlessItem()
	{
		if (!base.BlessItem())
			return false;
		
		// Do we have quest variables we can refer to?
		if (!IsDataSet("J4FRadarObjective"))
			return true;
		
		local objectiveNumber = GetData("J4FRadarObjective");
		
		// Only ongoing quests matter. Completed do not.
		if (Quest.Exists(OBJECTIVE_STATE + objectiveNumber) && Quest.Get(OBJECTIVE_STATE + objectiveNumber) != 0)
			return false;
		
		// If the quest isn't visible, should we even care? Safest
		// bet is no, because that can be used for "optional"
		// objectives. For example, buying a tip or sidequest from
		// the store screen. The objective may well *never*
		// become visible, and the quest target might be in an
		// inaccessible spot unless the objective is triggered.
		// NOTE: There are also cases where an objective is
		// leftover/cut data from a mission and will never be
		// relevant in any circumstance ever.
		// NOTE: A OBJECTIVE_BONUS type objective won't be
		// visible to the user, but it's still marked as
		// visible to make it active.
		if (Quest.Exists(OBJECTIVE_VISIBLE + objectiveNumber) && Quest.Get(OBJECTIVE_VISIBLE + objectiveNumber) == 0)
			return false;
		
		return true;
	}
}

class J4FRadarSecretTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_QUEST, true, POI_RANK_SECRET);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_SECRET);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_SECRET, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_SECRET);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_SECRET);}
	
	function DisplayTarget()
	{
		local target = PoiTarget();
		
		// If we have a ~ControlDevice to us, the destination of that
		// reverse link is the thing which will trigger us. Usually
		// seen with FindSecretTrap traps and the TrapFindSecret script.
		// NOTE: This could even be a room with a script to trigger
		// when the player enters it!
		local linkToMyController = Link.GetOne("~ControlDevice", target);
		if (linkToMyController != 0)
		{
			local myController = LinkDest(linkToMyController);
			
			// We can't display the position of rooms properly. Their
			// positions are stored through some alternative means.
			// At that point, we may as well show the original target
			// instead.
			
			// If it's not a room, it's okay to display.
			if (!Object.InheritsFrom(myController, "Base Room"))
				return myController;
		}
		
		// In other cases, picking up the item works (FrobFind script,
		// etc.).
		return base.DisplayTarget();
	}
	
	function BlessItem()
	{
		if (!base.BlessItem())
			return false;
		
		local target = PoiTarget();
		
		// My hidden bit needs to still be on.
		if (
			Property.Possessed(target, "DarkStat")
			&& (Property.Get(target, "DarkStat") & STATBIT_HIDDEN) != STATBIT_HIDDEN
		)
		{
			return false;
		}
		
		return true;
	}
}

class J4FRadarCreatureTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_CREATURE, j4fIsThief, POI_RANK_CREATURE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_CREATURE);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_CREATURE, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_CREATURE);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_CREATURE);}
	
	// Ignore frozen, dead, and nonhostile creatures.
	function BlessItem()
	{
		if (!base.BlessItem() || !IsRendered())
			return false;
		
		local target = PoiTarget();
		
		// Other states: Asleep, Efficient, Super Efficient, Normal, and Combat
		if (Property.Get(target, "AI_Mode") == eAIMode.kAIM_Dead)
			return false;
		
		// Lobotomized AI are commonly used for corpses placed in
		// the mission editor.
		if (Property.Get(target, "AI") == "null")
			return false;
		
		// Ignore nonhostiles unless the user has specifically enabled
		// those features.
		
		local team = Property.Possessed(target, "AI_Team") ? Property.Get(target, "AI_Team") : -1;
		
		if (team == eAITeam.kAIT_Good && ObjID(FEATURE_CREATURE_GOOD) > -1)
			return false;
		
		if (ObjID(FEATURE_CREATURE_NEUTRAL) > -1)
		{
			if (team == eAITeam.kAIT_Neutral)
				return false;
			
			// Hacks below. Some things aren't technically neutral,
			// but a player probably thinks of them that way.
			
			// Disabled security systems are kinda-sorta
			// neutral, in that they don't care about anything.
			if (
				// Sleeping
				Property.Possessed(target, "AI_Mode")
				&& Property.Get(target, "AI_Mode") == eAIMode.kAIM_Asleep
				// Disabled camera or turret.
				&& (
					// Disabled camera.
					(
						Property.Get(target, "AI", "Behavior set") == "DarkCamera"
						&& Object.InheritsFrom(target, "M-AI-Stasis")
					)
					// Disabled turret.
					|| (
						Property.Get(target, "AI", "Behavior set") == "turret"
						&& Property.Get(target, "AI_AlertCap", "Max level") == eAIScriptAlertLevel.kNoAlert
					)
				)
			)
			{
				return false;
			}
			
			// Rats aren't neutral, but may as well be.
			// Inform others is false, non-hostile is Always,
			// and uses doors is false. AI is SimpleNC. Plus
			// Small Creature: true, this recipe should make
			// any creature effectively neutral. There may be
			// some weird scripting or source/receptron stuff,
			// but in general, better to treat them as neutral.
			if (
				// Smol == true.
				!!Property.Get(target, "AI_IsSmall")
				// Never hostile.
				&& Property.Get(target, "AI_NonHst") == AINonHostilityEnum_kAINH_Always
				// Informs others == false.
				&& !Property.Get(target, "AI_InfOtr")
				// Opens doors == false.
				&& !Property.Get(target, "AI_UsesDoors")
				// Simple noncombatant AI.
				&& Property.Get(target, "AI", "Behavior set") == "SimpleNC"
			)
			{
				return false;
			}
		}
		
		return true;
	}
}

class J4FRadarCreatureBoxTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_CREATURE, j4fIsThief, POI_RANK_CREATURE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_CREATUREBOX);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_CREATUREBOX, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_CREATUREBOX);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_CREATUREBOX);}
	
	function BlessItem()
	{
		if (!base.BlessItem() || !IsRendered())
			return false;
		
		local target = PoiTarget();
		
		local corpses = Link.GetAll("Corpse", target);
		foreach (corpseLink in corpses)
		{
			// Assume hostile.
			if (Object.InheritsFrom(LinkDest(corpseLink), POI_CREATURE))
				return true;
		}
		
		local targetArchetype = Object.Archetype(target);
		if (targetArchetype != 0)
		{
			corpses = Link.GetAll("Corpse", targetArchetype);
			foreach (corpseLink in corpses)
			{
				// Assume hostile.
				if (Object.InheritsFrom(LinkDest(corpseLink), POI_CREATURE))
					return true;
			}
		}
		
		return false;
	}
}

// Various things only matter if we can pick them up (or they're in
// a container and we can grab them from there, etc.)
class J4FRadarGrabbableTarget extends J4FRadarAbstractTarget
{
	constructor(color = COLOR_DEFAULT, uncapDistance = false, rank = POI_RANK_GRAB)
	{
		base.constructor(color, uncapDistance, rank);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_GRAB);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_GRAB, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_GRAB);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_GRAB);}
	
	// Ignore decorative/etc. things we can't pick up.
	function BlessItem()
	{
		return base.BlessItem() && IsWorldFrobbable() && IsRendered();
	}
}

class J4FRadarUntilTurnOnTarget extends J4FRadarAbstractTarget
{
	constructor(color = COLOR_DEFAULT, uncapDistance = false, rank = POI_RANK_GRAB)
	{
		base.constructor(color, uncapDistance, rank);
	}
	
	// Some traps may be triggered by a usable switch, keypad, etc.
	// These will have a ~SwitchLink. But for all I know, people can
	// use invisible switches and buttons like people often used
	// them in thief FMs.
	function DisplayTarget()
	{
		local target = PoiTarget();
		
		// If we have a ~ControlDevice to us, the destination of that
		// reverse link is the thing which will trigger us. Usually
		// seen with FindSecretTrap traps and the TrapFindSecret script.
		// NOTE: This could even be a room with a script to trigger
		// when the player enters it!
		local linkToMyController = Link.GetOne("~SwitchLink", target);
		if (linkToMyController != 0)
		{
			local myController = LinkDest(linkToMyController);
			
			if (IsWorldFrobbable(myController) && IsRendered(myController))
				return myController;
		}
		
		// Fall back to standard behavior.
		return base.DisplayTarget();
	}
	
	function OnTurnOn()
	{
		MarkAsTurnedOn();
	}
	
	function OnJ4FTurnedOn()
	{
		MarkAsTurnedOn();
	}
	
	function MarkAsTurnedOn()
	{
		// If we've already been marked, do nothing.
		// Might help avoid infinite loops if there are
		// circular references via relay traps.
		if (IsDataSet("J4FEverTurnedOn"))
			return;
		
		SetData("J4FEverTurnedOn", true);
	}
	
	function BlessItem()
	{
		if (!base.BlessItem() || IsDataSet("J4FEverTurnedOn"))
			return false;
		
		return true;
	}
}

// This script goes on the container of interest.
class J4FRadarContainerTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_CONTAINER, true, POI_RANK_CONTAINER);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_CONTAINER);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_CONTAINER, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_CONTAINER);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_CONTAINER);}
	
	// Ignore empty containers and containers with points of interest.
	// If we contain a POI item, the item should already be displaying
	// us as its visual indicator, so the container itself doesn't
	// need one of its own. (We're presuming that the contained item
	// will bless itself. That's *not* a guarantee, and we could end
	// up wrongfully hiding the container in some cases.)
	function BlessItem()
	{
		// Also require IsWorldFrobbable() to be sure we can try to open it.
		if (!base.BlessItem() || !IsWorldFrobbable() || !IsRendered())
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
		base.constructor(COLOR_DEVICE, false, POI_RANK_DEVICE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_DEVICE);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_DEVICE, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_DEVICE);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_DEVICE);}
	
	function OnBeginScript()
	{
		base.OnBeginScript();
		
		local target = PoiTarget();
		
		if (!IsDataSet("J4FRadarInitialLocked") && Property.Possessed(target, "Locked"))
		{
			SetData("J4FRadarInitialLocked", Property.Get(target, "Locked"));
		}
	}
	
	function OnFrobWorldEnd()
	{
		if (Object.InheritsFrom(message().Frobber, j4fPlayerArchetype))
			MarkAsTouched();
	}
	
	function OnJ4FPlayerFrob()
	{
		MarkAsTouched();
	}
	
	function MarkAsTouched()
	{
		// If we've already been marked, do nothing.
		// Might help avoid infinite loops if there are
		// circular references via FrobProxy links.
		if (IsDataSet("J4FRadarDeviceUsed"))
			return;
		
		SetData("J4FRadarDeviceUsed", true);
		
		// FrobProxy links can be used to have many switches
		// act as one. So maybe the player frobbed us, or
		// maybe they frobbed one of our ~FrobProxy links
		// instead. So let's inform any ~FrobProxy reverse
		// links that we've been touched, so they can flag
		// themselves as well.
		// Of course, these ~FrobProxy links may be point to
		// objects with POI proxies. So we may have to hop
		// through two links: the FrobProxy and the POI proxy.
		local myFrobbers = Link.GetAll("~FrobProxy", PoiTarget());
		foreach (frobberLink in myFrobbers)
		{
			PostMessage(GetObjectOrProxy(LinkDest(frobberLink)), "J4FPlayerFrob");
		}
	}
	
	// Ignore invisible devices, which are sometimes used by
	// mission authors to trigger scripted events. Note that
	// we don't check IsWorldFrobbable(), because that would
	// prevent pressure plates from being indicated.
	function BlessItem()
	{
		if (!base.BlessItem() || !IsRendered() || IsDataSet("J4FRadarDeviceUsed"))
			return false;
		
		local target = PoiTarget();
		
		// If the lock status has changed since mission start,
		// hide it. This may be undesirable in some rare cases,
		// like when an AI unlocks something to walk through it,
		// etc. Should be preferable most of the time, though.
		if (
			IsDataSet("J4FRadarInitialLocked")
			// Using !! to coerce these both to booleans, if
			// they aren't already. SetData() turns booleans
			// into ints, because boolean is unsupported.
			&& (!!Property.Get(target, "Locked")) != (!!GetData("J4FRadarInitialLocked"))
		)
		{
			return false;
		}
		
		// Things other than pressure plates should be interactable.
		if (!IsWorldFrobbable() && !Object.InheritsFrom(target, "PressPlate"))
		{
			return false;
		}
		
		// Sometimes switches and buttons are placed outside
		// the level geometry rather than made invisible.
		// However, sometimes objects are perfectly usable
		// despite being partially outside the boundaries.
		// For example, the LC_Lever (object 452) in Thief
		// Gold miss9.mis can still be seen and picked up.
		// Plus, it's not really a lever so much as a key-
		// or-part object. In any case, this physics check
		// is a good thing, more often than not.
		return Physics.ValidPos(target);
	}
}

// This script goes on the equipment of interest.
class J4FRadarEquipTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_EQUIP, true, POI_RANK_EQUIP);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_EQUIP);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_EQUIP, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_EQUIP);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_EQUIP);}
}

class J4FRadarEquipUnlimitedTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_EQUIP_UNLIMITED, true, POI_RANK_EQUIP);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_EQUIP);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_EQUIP, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_EQUIP);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_EQUIP);}
}

class J4FRadarEquipStackTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_EQUIP_STACKED, true, POI_RANK_EQUIP);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_EQUIP);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_EQUIP, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_EQUIP);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_EQUIP);}
}

class J4FRadarEquipSlottedTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_EQUIP_SLOTTED, false, POI_RANK_EQUIP);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_EQUIP);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_EQUIP, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_EQUIP);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_EQUIP);}
}

// This script goes on the loot of interest.
class J4FRadarLootTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_LOOT, true, POI_RANK_LOOT);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_LOOT);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_LOOT, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_LOOT);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_LOOT);}
}

class J4FRadarCyberModuleTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		base.constructor(COLOR_CYBERMODULE, true, POI_RANK_CYBERMODULE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	// NOTE: This overlaps with J4FRadarCyberModuleTrapTarget data, but
	// we shouldn't have both scripts on one object.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_CYBERMODULE);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_CYBERMODULE, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_CYBERMODULE);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_CYBERMODULE);}
}

class J4FRadarCyberModuleTrapTarget extends J4FRadarUntilTurnOnTarget
{
	constructor()
	{
		base.constructor(COLOR_CYBERMODULE, true, POI_RANK_CYBERMODULE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	// NOTE: This overlaps with J4FRadarCyberModuleTarget data, but
	// we shouldn't have both scripts on one object.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_CYBERMODULE);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_CYBERMODULE, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_CYBERMODULE);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_CYBERMODULE);}
}

class J4FRadarNaniteTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_NANITE, true, POI_RANK_NANITE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_NANITE);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_NANITE, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_NANITE);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_NANITE);}
}

// This script goes on the readable of interest. We're applying this only to
// grabbables, because we need them to be interactable in some way.
class J4FRadarReadableTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_READABLE, true, POI_RANK_READABLE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + DATA_SUFFIX_READABLE);}
	function SetDataSub(key, value) {SetData(key + DATA_SUFFIX_READABLE, value);}
	function ClearDataSub(key) {ClearData(key + DATA_SUFFIX_READABLE);}
	function IsDataSetSub(key) {return IsDataSet(key + DATA_SUFFIX_READABLE);}
	
	// Looking for a frob event is the only way we can tell when we've been
	// read. Even that might have weird corner cases through scripting, but
	// this should be at least 99% effective.
	
	function OnFrobWorldEnd()
	{
		MarkAsRead();
	}
	
	function OnFrobInvEnd()
	{
		MarkAsRead();
	}
	
	function OnJ4FPlayerFrob()
	{
		MarkAsRead();
	}
	
	function MarkAsRead()
	{
		local target = PoiTarget();
		local myText = Property.Possessed(target, "Book") ? Property.Get(target, "Book") : "";
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

class J4FRadarSimpleReadableTarget extends J4FRadarGrabbableTarget
{
	constructor()
	{
		base.constructor(COLOR_READABLE, true, POI_RANK_READABLE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + POI_RANK_READABLE);}
	function SetDataSub(key, value) {SetData(key + POI_RANK_READABLE, value);}
	function ClearDataSub(key) {ClearData(key + POI_RANK_READABLE);}
	function IsDataSetSub(key) {return IsDataSet(key + POI_RANK_READABLE);}
}

class J4FRadarReadableTrapTarget extends J4FRadarUntilTurnOnTarget
{
	constructor()
	{
		base.constructor(COLOR_READABLE, true, POI_RANK_READABLE);
	}
	
	// See comments in J4FRadarAbstractTarget for details.
	function GetDataSub(key) {return GetData(key + POI_RANK_READABLE);}
	function SetDataSub(key, value) {SetData(key + POI_RANK_READABLE, value);}
	function ClearDataSub(key) {ClearData(key + POI_RANK_READABLE);}
	function IsDataSetSub(key) {return IsDataSet(key + POI_RANK_READABLE);}
}

// This script will be called on the player when the game starts, giving them a particular item.
class J4FGiveAnItem extends SqRootScript
{
	function GiveItemIfNeeded(whatItem)
	{
		// See comments below about the infinite recursion this addresses.
		local dataKey = "J4FGiving_" + whatItem;
		if (IsDataSet(dataKey))
			return;
		
		// Assuming this script is attached to the player, "self" refers
		// to that player. Every object with a "Contains" type link is
		// stuff in the player's inventory.
		local playerInventory = Link.GetAll("Contains", self);
		
		// Assume they don't have the desired item until we prove otherwise.
		local hasTheItem = false;
		// It may be possible to use the string directly everywhere we use
		// this variable, but it's probably less efficient than doing the
		// ID lookup once and storing the result. This approach was used
		// in the HolyH2O script sample as well.
		local theItemId = ObjID(whatItem);
		
		// Loop through everything in the player's inventory to find the token.
		foreach (link in playerInventory)
		{
			// Is the inventory item an instance of the wanted item?
			// (InheritsFrom *might* also detect other kinds of items based
			// on the archetype as well, but that's not relevant to this mod.)
			if ( Object.InheritsFrom(LinkDest(link), theItemId) )
			{
				// The player already has the item!
				hasTheItem = true;
				// So we can stop looking through their inventory.
				break;
			}
		}
		
		// If the player doesn't already have the item...
		if (!hasTheItem)
		{
			// Then create one and give it to them.
			
			SetData(dataKey, true);
			
			// NOTE: In SS2, for some reason this resulted in a
			// stack overflow going from OnBeginScript to GiveItemIfNeeded
			// to native code, and repeating those three infinitely :/
			Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(theItemId));
			
			ClearData(dataKey);
		}
	}
}

// This script will be called on the player when the game starts, giving them the radar item.
class J4FGiveRadarItem extends J4FGiveAnItem
{
	// We only need this script to fire once, when the game simulation first starts.
    function OnSim()
	{
        if (message().starting)
		{
			GiveItemIfNeeded("J4FRadarControlItem");
        }
    }
}

// This script goes on one marker we add to every mission. It sets up and
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
		(j4fIsShock ? ShockOverlay : DarkOverlay).RemoveHandler(j4fRadarOverlayInstance);
		
		// As we've coded it, there's no harm in calling this more than
		// once either.
		j4fRadarOverlayInstance.logic.Teardown();
	}
	
	// Per sample documentation, it's best practice to tear down the
	// overlay both when this instance is destroyed and when it
	// receives an EndScript message.
	function OnEndScript()
	{
		// Given that we have multiple things to do when tearing down
		// the handler, all that code was moved to the destructor, which
		// we can call by hand.
		destructor();
	}
	
	// Because some items can be difficult to detect directly, through
	// radius stims (limited range and limited number of recipients
	// per burst), through metaproperties (can't be added to other
	// metaproperties, can't attach scripts to Don't-Inherit items),
	// etc., the most foolproof way of detecting all items of interest
	// is to scan the entire level.
	// When the level first starts, we'll queue up a scan of all the
	// objects. The actual scanning happens in the timer function.
	
	// This will trigger in Thief-like games, but not Shock-engine ones.
    function OnSim()
	{
        if (message().starting)
		{
			QueueNewScan(0.01);
        }
    }
	
	// This will fire on start of mission and after reloading saves.
	function OnBeginScript()
	{
		// Call our custom setup method, to do whatever we need to do
		// when preparing the overlay in a new mission, after loading
		// a save, or when re-loading a save or moving to next mission.
		j4fRadarOverlayInstance.logic.Setup();
		
		// This is part of NewDark+Squirrel's method of attaching an
		// overlay handler to the game.
		(j4fIsShock ? ShockOverlay : DarkOverlay).AddHandler(j4fRadarOverlayInstance);
		
		// In SS2, we may start the game unable to toggle the radar
		// due to lack of UI, HUD, and various console commands and
		// keybinds. So default to enabled.
		if (!IsDataSet("J4FRadarEnableState") && j4fIsShock)
		{
			SetData("J4FRadarEnableState", true);
		}
		
		// Remember our enabled state.
		j4fRadarOverlayInstance.logic.enabled = IsDataSet("J4FRadarEnableState") && GetData("J4FRadarEnableState");
		
		QueueNewScan(0.01);
	}
	
	function QueueNewScan(afterDelay)
	{
		// Don't do anything if a scan is already scheduled.
		if (IsDataSet("ConsecutiveEmptyGroups"))
			return;
		
		// Start with objects 1 through whatever.
		SetData("AddToScanId", 1);
		SetData("ConsecutiveEmptyGroups", 0);
		
		// Special handling may be needed when transitioning
		// existing objects to or from a map, like in SS2.
		// These checks can be expensive, so we generally
		// avoid them.
		local mapName = string();
		Version.GetMap(mapName);
		mapName = mapName.tostring();
		
		local wasMap = GetQuestDataString("j4f_rdr_mis") || "";
		SetQuestDataString("j4f_rdr_mis", mapName);
		
		local hasChanged = (mapName == wasMap) ? 0 : 1;
		SetData("MapHasChanged", hasChanged);
		//print(format("Current map is \"%s\", old was \"%s\", changed %i", mapName, wasMap, hasChanged));
		
		SetOneShotTimer("J4FRadarMissionScan", afterDelay);
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
		
		//print("Scanning area...");
		
		// We will scan objects down to and including this value.
		local scanFromInclusive = GetData("AddToScanId");
		
		// If true, we will review some previously-scanned items.
		local reviewExistingItems = IsDataSet("MapHasChanged") && (GetData("MapHasChanged") > 0);
		
		//if (scanFromInclusive == 1) DarkUI.TextMessage("Scanning area....", 0, 1000);
		
		// We will scan objects up to and excluding this value.
		local scanCapExclusive = scanFromInclusive + MAX_SCANNED_PER_LOOP;
		// Unless we bail out early, the next round of scans
		// will start here.
		SetData("AddToScanId", scanCapExclusive);
		
		// We need these variables to help track our loop ending
		// logic.
		local consecutiveEmptyGroups = GetData("ConsecutiveEmptyGroups");
		local scannedAny = false;
		
		// If creating a lot of POI items becomes a performance
		// or other concern, MAX_INITIALIZED_PER_LOOP can limit
		// how many of those we spin up on each loop.
		local initializeCount = 0;
		
		// We need these IDs several times throughout the loop, so
		// let's grab them once instead.
		
		local keysEnabled = ObjID(FEATURE_EQUIP) < 0;
		local keyPoiProperty = ObjID(POI_EQUIP);
		
		local thiefReadablesEnabled = (ObjID(FEATURE_READABLE) < 0) && j4fIsThief;
		local readablePoiProperty = ObjID(POI_READABLE);
		
		local lootEnabled = ObjID(FEATURE_LOOT) < 0;
		local lootMetaProperty = ObjID("IsLoot");
		local lootPoiProperty = ObjID(POI_LOOT);
		
		local questEnabled = ObjID(FEATURE_QUEST) < 0;
		local questPoiProperty = ObjID(POI_QUEST);
		local secretPoiProperty = ObjID(POI_SECRET);
		
		local anyKindOfPoi = ObjID(POI_ANY);
		
		// It can be a pain to examine properties of objects
		// every time we scan the level. In most all cases,
		// it should be thorough enough to do so once. It is
		// possible interesting objects will be created mid-
		// mission without POI metaproperties added through
		// DML, but it's less likely. The alternative is to
		// track which objects have been scanned already, but
		// since object IDs are reused when destroying and
		// creating stuff mid-mission, the only way to really
		// do that is by adding a flag metaproperty to every
		// object in the whole mission. That feels like
		// overkill.
		// TODO: Periodically do deep scans, or try out the flagging approach?
		//	Given its tendency to spawn things in, more relevant in SS2.
		//	But are we really doing any useful deep scanning in SS2 yet?
		local shouldExamineProperties = !IsDataSet("J4FHasDeepScanned");
		
		// Table of integer keys.
		// Positive integers are concrete objects.
		// Negative integers are archetypes.
		// In either case, the value is another integer,
		// referring to the 0-based objective number it
		// relates to. (If multiple objectives target
		// the same things, it's undefined which one will
		// win.)
		local questTargets = {};
		// Array of archetypes to enumerate through.
		// These negative values should appear in
		// questTargets as well.
		local questArchetypes = [];
		// This is the bitwise OR of all specials found in goals.
		// Loot with these flags set is a quest item.
		local questSpecials = 0;
		
		if (questEnabled)
		{
			// I'm not sure of a better way to get difficulty level via script :/
			local difficultyObjectId = ObjID("Player");
			local difficultyLevel = 2;
			if (Object.InheritsFrom(difficultyObjectId, DIFFICULTY_0))
			{
				difficultyLevel = 0;
			}
			else if (Object.InheritsFrom(difficultyObjectId, DIFFICULTY_1))
			{
				difficultyLevel = 1;
			}
			else if (Object.InheritsFrom(difficultyObjectId, DIFFICULTY_2))
			{
				difficultyLevel = 2;
			}
			
			// Because we have to grab variables one-by-one, we'll need
			// to slowly build up objective data as we go. This table
			// will hold the in-progress J4FRadarQuestDetails objects.
			// The keys will be objective number integers.
			local questData = {};
			
			foreach (qKey,qVal in Quest.GetAllVars(eQuestDataType.kQuestDataMission))
			{
				// All the variables we can do anything with should be integers.
				if (typeof qVal != "integer")
					continue;
				
				qKey = qKey.tolower();
				
				// We only care about goal_XXXXX variables.
				if (qKey.find(OBJECTIVE_ANY) != 0)
					continue;
				
				// Which property of the class will we set?
				local questProperty = null;
				local questId = -1;
				
				if (qKey.find(OBJECTIVE_TYPE) == 0)
				{
					questId = qKey.slice(OBJECTIVE_TYPE.len()).tointeger();
					questProperty = "type";
				}
				else if (qKey.find(OBJECTIVE_STATE) == 0)
				{
					questId = qKey.slice(OBJECTIVE_STATE.len()).tointeger();
					questProperty = "state";
				}
				else if (qKey.find(OBJECTIVE_TARGET) == 0)
				{
					questId = qKey.slice(OBJECTIVE_TARGET.len()).tointeger();
					questProperty = "target";
				}
				else if (qKey.find(OBJECTIVE_MIN_DIFFICULTY) == 0)
				{
					questId = qKey.slice(OBJECTIVE_MIN_DIFFICULTY.len()).tointeger();
					questProperty = "minDiff";
				}
				else if (qKey.find(OBJECTIVE_MAX_DIFFICULTY) == 0)
				{
					questId = qKey.slice(OBJECTIVE_MAX_DIFFICULTY.len()).tointeger();
					questProperty = "maxDiff";
				}
				else if (qKey.find(OBJECTIVE_SPECIAL_BITS) == 0)
				{
					questId = qKey.slice(OBJECTIVE_SPECIAL_BITS.len()).tointeger();
					questProperty = "specials";
				}
				else if (qKey.find(OBJECTIVE_IRREVERSIBLE) == 0)
				{
					questId = qKey.slice(OBJECTIVE_IRREVERSIBLE.len()).tointeger();
					questProperty = "irreversible";
				}
				else if (qKey.find(OBJECTIVE_REVERSED) == 0)
				{
					questId = qKey.slice(OBJECTIVE_REVERSED.len()).tointeger();
					questProperty = "reversed";
				}
				else if (qKey.find(OBJECTIVE_OPTIONAL) == 0)
				{
					questId = qKey.slice(OBJECTIVE_OPTIONAL.len()).tointeger();
					questProperty = "optional";
				}
				else if (qKey.find(OBJECTIVE_BONUS) == 0)
				{
					questId = qKey.slice(OBJECTIVE_BONUS.len()).tointeger();
					questProperty = "bonus";
				}
				
				// If we know what to do with this qvar, then do so.
				if (questProperty != null)
				{
					// Get or create a quest data object to modify.
					local currentQuest;
					if (questId in questData)
					{
						currentQuest = questData[questId];
					}
					else
					{
						currentQuest = J4FRadarQuestDetails();
						questData[questId] <- currentQuest;
					}
				
					// Change the property this QVar represents for that quest.
					currentQuest[questProperty] = qVal;
				}
			}
			
			// Now questData is fully populated, and we can analyze it.
			foreach (checkQuestId,checkQuestData in questData)
			{
				// Ignore completed, soft-failed ("inactive"), and hard-failed ("failed") objectives.
				// That just leaves 0 / incomplete.
				if (checkQuestData.state != 0)
					continue;
				
				// Ignore objectives outside our difficulty level.
				if (difficultyLevel < checkQuestData.minDiff || difficultyLevel > checkQuestData.maxDiff)
					continue;
				
				local wantTarget = false;
				
				// Goal-type-specific logic:
				switch (checkQuestData.type)
				{
					case OBJECTIVE_TYPE_CONTAIN:
						// We care only about "pick this up" objectives, not
						// "don't pick this up" objectives.
						if (checkQuestData.reversed == 0)
						{
							wantTarget = true;
						}
						break;
					case OBJECTIVE_TYPE_SLAY:
						// We care about both slay and don't-slay objectives.
						// However, we probably only care about specific concrete
						// objects. Yes, it's possible to have an objective to
						// slay or not slay a Human, and there's only one Human
						// creature in the level, but we'll ignore that possibility
						// for now.
						if (checkQuestData.target > 0)
						{
							wantTarget = true;
						}
						break;
					case OBJECTIVE_TYPE_LOOT:
						if (
							// Don't care about "avoid this loot" objectives.
							checkQuestData.reversed == 0
							// In fact, we only care about special bit flags.
							// For loot in general, there's always lootdar.
							&& checkQuestData.specials != 0
						)
						{
							// Include those bits as interesting.
							questSpecials = questSpecials | checkQuestData.specials;
						}
						break;
					case OBJECTIVE_TYPE_ROOM:
						if (
							// Don't care about "stay out of my shed" objectives.
							checkQuestData.reversed == 0
							// Only care about "enter-once" objectives.
							&& checkQuestData.irreversible != 0
							// And even then, only optional and bonus objectives.
							&& (
								checkQuestData.optional != 0
								|| checkQuestData.bonus != 0
							)
						)
						{
							wantTarget = true;
						}
						break;
				}
				
				// If the above logic decided we care about the
				// target object or archetype, add it to the list.
				if (wantTarget && checkQuestData.target != 0)
				{
					questTargets[checkQuestData.target] <- checkQuestId;
					
					if (checkQuestData.target < 0)
					{
						questArchetypes.push(checkQuestData.target);
					}
				}
			}
		}
		
		// Grabbing this once as a trivial efficiency boost.
		local checkQuestArchetypes = questArchetypes.len() > 0;
		
		// Loop through all the item IDs we're going to test this time.
		for (local i = scanFromInclusive - 1; ++i < scanCapExclusive; )
		{
			// If we exceeded our limit, save this index for the next
			// loop pass instead.
			if (initializeCount > MAX_INITIALIZED_PER_LOOP)
			{
				SetData("AddToScanId", i);
				break;
			}
			
			if (Object.Exists(i))
			{
				scannedAny = true;
				
				// If the item seems related to an objective, let's see which one.
				local relatedObjective = -1;
				
				// Do we need to manually add a POI metaproperty to the
				// scanned item? Useful for weird kinds of loot, keys,
				// and readables.
				if (shouldExamineProperties)
				{
					// Secrets can be anything at all, really.
					if (
						// Let's also detect secrets when quests are enabled.
						questEnabled
						// This isn't isn't flagged yet.
						&& !Object.InheritsFrom(i, secretPoiProperty)
						// The ultimate object of interest will have the
						// hidden bit set. That comes from "DarkStat" property,
						// but we need bitwise logic to check for the hidden
						// flag specifically.
						&& Property.Possessed(i, "DarkStat")
						&& (Property.Get(i, "DarkStat") & STATBIT_HIDDEN) == STATBIT_HIDDEN
					)
					{
						Object.AddMetaProperty(i, secretPoiProperty);
					}
					
					// IsLoot items are hard to target directly, because
					// we can never safely script them nor add a metaproperty,
					// because IsLoot *is* a metaproperty.
					if (
						// The optional loot or quest module is installed.
						lootEnabled
						// This isn't isn't flagged yet.
						&& !Object.InheritsFrom(i, lootPoiProperty)
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
					}
					
					// Sometimes weird items are used as "keys" or parts.
					if (
						// The optional keys (equipment) module is installed.
						keysEnabled
						// This isn't isn't flagged yet.
						&& !Object.InheritsFrom(i, keyPoiProperty)
						// And the item can be used as a kind of key.
						&& Property.Possessed(i, "KeySrc")
						// And is enabled in at least one region.
						&& Property.Get(i, "KeySrc", "RegionMask") != 0
					)
					{
						Object.AddMetaProperty(i, keyPoiProperty);
					}
					
					// Sometimes weird items can be made readable.
					if (
						// The optional readables module is installed.
						thiefReadablesEnabled
						// This isn't isn't flagged yet.
						&& !Object.InheritsFrom(i, readablePoiProperty)
						// And the item has something worth reading.
						&& Property.Possessed(i, "Book")
						&& Property.Possessed(i, "BookArt")
						&& Property.Get(i, "Book") != ""
						&& Property.Get(i, "BookArt") != ""
					)
					{
						Object.AddMetaProperty(i, readablePoiProperty);
					}
					
					// Quest objects are extra tricky, and require several
					// layers of logic to get just right.
					// NOTE: We're deliberately adding on the quest POI metaproperty
					// on top of whatever baseline metaproperty the object might have.
					if (
						questEnabled
						// We might have flagged this some other way, like
						// by DML or in the loot checks, or previous scans.
						&& !Object.InheritsFrom(i, questPoiProperty)
					)
					{
						local isQuest = false;
						
						// Start with the quickest check: is this specific object
						// in the list of quest items?
						if (i in questTargets)
						{
							isQuest = true;
							relatedObjective = questTargets[i];
						}
						
						// If needed, try checking special loot bits instead.
						if (
							!isQuest
							// Are we looking for special bits?
							&& questSpecials != 0
							// Can this object even have any?
							&& Property.Possessed(i, "Loot")
							// Does it have any of the right ones?
							&& (Property.Get(i, "Loot", "Special") & questSpecials) != 0
						)
						{
							// TODO: objective number tracking for loot special flags?
							isQuest = true;
						}
						
						// If needed, try checking matching archetypes.
						// Hopefully this isn't enabled, because it kinda
						// sucks. We have to either advance up through the
						// object's parent hierarchy checking everything
						// against questTargets keys, or we enumerate
						// through the questArchetypes array to see if it
						// inherits from any of those.
						// Multiply that work across every single object
						// we scan, and that's a lot of wasted work :(
						if (
							!isQuest
							// Do we even want this logic?
							&& checkQuestArchetypes
						)
						{
							// What's quicker, do you think? If we're
							// dealing with an Object, that's pretty
							// damned quick. No parent archetypes.
							// Marker -> fnord -> Object has just three.
							// But how about MaleNoble2 -> MaleNoble ->
							// aristo -> bystander -> Human -> Animal ->
							// Creature -> physical -> Object? That's
							// nine. It's almost certainly better to
							// enumerate through the questArchetypes
							// array and check InheritsFrom, unless
							// a mission has a truly absurd number of
							// archetype-based objective targets.
							for (local qt = questArchetypes.len(); --qt > -1; )
							{
								if (Object.InheritsFrom(i, questArchetypes[qt]))
								{
									isQuest = true;
									relatedObjective = questTargets[questArchetypes[qt]];
									break;
								}
							}
						}
						
						if (isQuest)
						{
							Object.AddMetaProperty(i, questPoiProperty);
						}
					}
				}
				
				if (
					// If the object is a POI of one or more types
					Object.InheritsFrom(i, anyKindOfPoi)
					// Attempt to initialize it.
					&& InitPointOfInterestIfNeeded(i, reviewExistingItems, relatedObjective)
				)
				{
					// And increment the counter if we did initialize it.
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
				// Now that we're done with the first loop, we've
				// also done any deep scannig needing in that loop.
				SetData("J4FHasDeepScanned", true);
				
				// We're done! Break the loop. We'll re-scan all
				// the objects again periodically, to cover any
				// new-to-the-mission items.
				ClearData("ConsecutiveEmptyGroups");
				
				//DarkUI.TextMessage("Scan complete.", 0, 1000);
				
				QueueNewScan(5.00);
				return;
			}
			
			// Remember the incremented value for later.
			SetData("ConsecutiveEmptyGroups", consecutiveEmptyGroups);
		}
		else if (consecutiveEmptyGroups > 0)
		{
			// We had an empty patch, but we found something this
			// time. Go back to a clean slate.
			SetData("ConsecutiveEmptyGroups", 0);
		}
		
		// Repeat! We're staggering the scans over time to avoid a
		// potential start-of-level lag spike, but in practice that
		// doesn't seem to be an issue. Still, better safe than sorry.
		SetOneShotTimer("J4FRadarMissionScan", 0.1);
	}
	
	// Rather than have radar points of interest communicate directly
	// with the overlay instance, we'll have them communicate with us.
	function OnJ4FRadarDetected()
	{
		// We sent the point-of-interest item object ID in "data"
		local detectedId = message().data;
		// We sent the display item ID and rank in "data2",
		// as a comma-delimited list.
		local displayAndRank = split(message().data2, ",");
		local newRank = displayAndRank[1].tointeger();
		
		// To handle multi-category POI targets, displayTargets
		// contains arrays of J4FRadarPointOfInterest values.
		local myIndicators;
		
		// Fetch or create an array to store our data.
		if (detectedId in j4fRadarOverlayInstance.logic.displayTargets)
		{
			myIndicators = j4fRadarOverlayInstance.logic.displayTargets[detectedId];
		}
		else
		{
			myIndicators = [];
			j4fRadarOverlayInstance.logic.displayTargets[detectedId] <- myIndicators;
		}
		
		// No choice but to scan to array to find ourselves.
		// Since the array is sorted, I guess we could
		// binary search it, but that's overkill for our
		// needs.
		local foundMe = false;
		if (myIndicators.len() > 0)
		{
			for (local i = myIndicators.len(); --i > -1; )
			{
				if (myIndicators[i].rank == newRank)
				{
					foundMe = true;
					break;
				}
			}
		}
		
		// If we're not in the array yet, we need to be.
		if (!foundMe)
		{
			local poiMetadata = J4FRadarPointOfInterest();
			
			poiMetadata.displayId = displayAndRank[0].tointeger();
			
			// We sent the radar color indicator in "data3".
			// Later we abused this to include the uncapped
			// distance indicator as well. So instead of
			// "W" for white, it's "W0" for white with capped
			// distance and "W1" for white with uncapped.
			// After that, an optional "alternative display
			// item" feature was added to help with pickpocket
			// items. So W1789 uses a white indicator, has
			// no distance cap, and has an alternative display
			// ID of 789.
			local extraData = message().data3;
			poiMetadata.displayColor = extraData.slice(0, 1);
			poiMetadata.uncappedDistance = extraData.slice(1, 2) == "1";
			poiMetadata.altDisplayId = extraData.len() > 2 ? extraData.slice(2).tointeger() : 0;
			poiMetadata.rank = newRank;
			
			myIndicators.push(poiMetadata);
			
			// If there's more than one, sort it.
			if (myIndicators.len() > 1)
			{
				myIndicators.sort(SortTargetByRank);
			}
		}
	}
	
	// We can pass this function name into the squirrel's native
	// array sort() function.
	function SortTargetByRank(a, b)
	{
		if (a.rank < b.rank) return -1;
		if (a.rank > b.rank) return 1;
		return 0;
	}
	
	// Rather than have radar points of interest communicate directly
	// with the overlay instance, we'll have them communicate with us.
	function OnJ4FRadarDestroyed()
	{
		// We sent the point-of-interest item object ID in "data"
		local destroyedId = message().data;
		
		// Not in the list? Great!
		if (!(destroyedId in j4fRadarOverlayInstance.logic.displayTargets))
		{
			return;
		}
		
		// We sent the rank in data2, or passed a negative when the
		// whole target is destroyed and we're scorching the earth.
		local destroyedRank = message().data2;
		
		if (destroyedRank < 0)
		{
			// Destroy everything.
			delete j4fRadarOverlayInstance.logic.displayTargets[destroyedId];
		}
		else
		{
			// Remove a single thing from the array. If the result would
			// be an empty array, then remove the whole thing.
			local checkArray = j4fRadarOverlayInstance.logic.displayTargets[destroyedId];
			local checkLen = checkArray.len();
			
			// Quick check: single-element array.
			if (checkLen == 1)
			{
				if (checkArray[0].rank == destroyedRank)
				{
					delete j4fRadarOverlayInstance.logic.displayTargets[destroyedId];
				}
			}
			else
			{
				// Gotta loop through to see if we're in here, and even if we
				// are, the array itself will remain intact. Just smaller.
				for (local i = checkLen; --i > -1; )
				{
					if (checkArray[i].rank == destroyedRank)
					{
						checkArray.remove(i);
						break;
					}
				}
			}
		}
	}
	
	// The radar toggler inventory item sends these messages to us,
	// so we can track the on/off state here.
	function OnJ4FRadarToggle()
	{
		local newState = !(IsDataSet("J4FRadarEnableState") && GetData("J4FRadarEnableState"));
		j4fRadarOverlayInstance.logic.enabled = newState;
		SetData("J4FRadarEnableState", newState);
		Reply(newState);
	}
	
	// Checks whether we've already read a given book/scroll/etc. or not.
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
	
	// Records that a book/scroll/etc. has just been read.
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
	// Object.RenderedThisFrame() cannot be used in all contexts, so the
	// overlay handler will check this last minute. If the displayId
	// item is not rendered, we will place the indicator at this object's
	// location instead. Optional extra for things like pickpocket items,
	// whose location the game may not update if the creature is out of
	// sight.
	altDisplayId = 0;
	displayColor = COLOR_DEFAULT;
	uncappedDistance = false;
	distance = 0;
	// If a single item meets multiple criteria, all of them will ask to
	// be displayed. The rank determines which one wins.
	rank = 0;
}

class J4FRadarQuestDetails
{
	state = -1;
	type = -1;
	target = 0;
	irreversible = 0;
	reversed = 0;
	specials = 0;
	minDiff = 0;
	maxDiff = 2;
	optional = 0;
	bonus = 0;
	
	function _tostring()
	{
		return format("type %s (%s) for %s, %i to %i, currently %s", type.tostring(), reversed.tostring(), target.tostring(), minDiff, maxDiff, state.tostring());
	}
}

// This is the actual overlay handler, following along with both squirrel
// documentation and things like T2OverlaySample.nut. Rather than a list of
// specific overlays for each interesting item, we use a variable-sized pool
// of overlay we manage on each frame.
//
// NOTE: Documentation says that only one IDarkOverlayHandler can be defined
// per OSM. However, I can confirm multiple IDarkOverlayHandler implementations
// can be defined in squirrel .nut files, and all of them can be set up and
// used by their respective mods. So our using an IDarkOverlayHandler in this
// radar mod does *not* prevent other squirrel-based mods from having theirs.
class J4FRadarOverlayHandlerBase
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
	// with arrays of one or more J4FRadarPointOfInterest instances for values.
	displayTargets = {};
	// This is a table whose keys are strings, indicating the indicator image
	// they use. For example, RadarW64 for the large, white indicator, etc.
	// The keys are arrays of overlay handles created with
	// gameOverlay.CreateTOverlayItem()
	// or gameOverlay.CreateTOverlayItemFromBitmap()
	overlayPool = {};
	// This uses the same keys as overlayPool, but the values are integers
	// counting how many overlays of that type we've used this frame.
	poolUsedThisFrame = {};
	// Contains a list of points of interest to render on the current frame.
	// See comments in DrawHUD() for an explanation of why we need to feed
	// data into DrawTOverlay like this.
	toDrawThisFrame = [];
	// Used for alpha/opacity/transparency cycling effect.
	currentWaveStep = 0;
	// Determines whether the display is enabled or not. We can't persist this
	// through savegames here, so the marker object's script does that for us.
	enabled = false;
	
	// What might be static methods in other languages are really just
	// properties on an object in Squirrel. We can hold a reference to the
	// entire class here, which is handy since the features we actually use
	// have the same function signatures in both classes.
	gameOverlay = j4fIsShock ? ShockOverlay : DarkOverlay;
	
	// This is used instead of log() functions to quickly check for the
	// power-of-twoness of a given value. Used in checking bitmap sizes.
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
			// If we wanted, we could also set a flag indicating that
			// we should recalculate other stuff elsewhere.
		}
		
		if (newCanvasHeight != canvasHeight)
		{
			canvasHeight = newCanvasHeight;
			// If we wanted, we could also set a flag indicating that
			// we should recalculate other stuff elsewhere.
		}
	}
	
	// DrawHUD implements an IDarkOverlayHandler method.
	// We don't draw anything here, but instead use it to gather
	// data for DrawTOverlay later on.
	function DrawHUD()
	{
		// Well, this is really, really awkward. Turns out that WorldToScreen()
		// and GetObjectScreenBounds() only work in DrawHUD, not in DrawTOverlay.
		// But if we want things like alpha/opacity, we have to rely on overlays.
		// So we do some work in DrawHUD, but no drawing. Then in the overlay
		// drawing phase, we use the information we gathered here to manage the
		// visible overlays.
		toDrawThisFrame = [];
		
		// Only try to populate the array if turned on.
		if (!enabled)
			return;
		
		// We'll use this for distance checking.
		local cameraPos = Camera.GetPosition();
		
		foreach (managerId, poiMetadataArray in displayTargets)
		{
			// This array is sorted by rank as we modify it, so we can
			// always refer to the first element to get the top-
			// priority indicator type.
			local poiMetadata = poiMetadataArray[0];
			
			// The target to display. Usually the displayId, but can
			// be an optional altDisplayId in some cases.
			local targetId = (poiMetadata.altDisplayId > 0 && !Object.RenderedThisFrame(poiMetadata.displayId)) ? poiMetadata.altDisplayId : poiMetadata.displayId;
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
			//if (!gameOverlay.WorldToScreen(targetPos, x1_ref, y1_ref))
			//	continue;
			
			// This sets the x/y pairs to the left, top, right, and bottom edges of the
			// object. Or it returns false if the object is completely offscreen.
			// NOTE: GetObjectScreenBounds doesn't work for rooms, or at least doesn't
			// work correctly. Then again, their Object.Position is 0,0,0 and their
			// position properties in DromEd are also 0,0,0. The room's X/Y/Z is
			// stored somewhere other than ordinary object properties.
			if (!gameOverlay.GetObjectScreenBounds(targetId, x1_ref, y1_ref, x2_ref, y2_ref))
				continue;
			
			// For debugging purposes, we can also draw directly in the HUD this frame.
			// This will draw the bounding box we just retrieved.
			/*
			gameOverlay.DrawLine(x1_ref.tointeger(), y1_ref.tointeger(), x1_ref.tointeger(), y2_ref.tointeger());
			gameOverlay.DrawLine(x1_ref.tointeger(), y2_ref.tointeger(), x2_ref.tointeger(), y2_ref.tointeger());
			gameOverlay.DrawLine(x2_ref.tointeger(), y2_ref.tointeger(), x2_ref.tointeger(), y1_ref.tointeger());
			gameOverlay.DrawLine(x2_ref.tointeger(), y1_ref.tointeger(), x1_ref.tointeger(), y1_ref.tointeger());
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
		
		// This is the bitmap we'll display inside the overlay. We also
		// use it as the key value for overlayPool and related tables.
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
			gameOverlay.UpdateTOverlayPosition(currentOverlay, targetX - overlayOffset, targetY - overlayOffset);
			// And update its transparency.
			gameOverlay.UpdateTOverlayAlpha(currentOverlay, alpha);
			
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
				newBitmap = gameOverlay.GetBitmap(bitmapName, "j4fres\\");
				
				// Images not installed in the needed location? Fallback.
				if (newBitmap == -1)
				{
					if (j4fIsShock)
					{
						newBitmap = gameOverlay.GetBitmap("DHKONG0", "iface\\");
					}
					else
					{
						// There's no particular reason to choose this, except
						// that it happens to exist in both Thief games.
						newBitmap = gameOverlay.GetBitmap("BUBB00", "bitmap\\txt\\");
					}
				}
				
				bitmaps[bitmapName] <- newBitmap;
			}
			
			// Power-of-2 bitmaps are easier, since we can turn them directly
			// into an overlay.
			if (bitmapSize == overlaySize)
			{
				currentOverlay = gameOverlay.CreateTOverlayItemFromBitmap(targetX - overlayOffset, targetY - overlayOffset, alpha, newBitmap, true);
				
				// If we failed, best to abort now.
				if (currentOverlay == -1)
					return - 1;
			}
			else
			{
				// Otherwise, we need to round up to the nearest power of
				// two, create an empty overlay, and draw the bitmap in its
				// center by hand.
				
				currentOverlay = gameOverlay.CreateTOverlayItem(targetX - overlayOffset, targetY - overlayOffset, overlaySize, overlaySize, alpha, true);
				
				// If we failed, best to abort now.
				if (currentOverlay == -1)
					return - 1;
				
				// We'll need this to center the bitmap inside the new overlay.
				local upgradedOffset = (overlaySize - bitmapSize) / 2;
				
				// This redirects generic functions like DrawBitmap so that
				// they draw *inside* the overlay we're setting up.
				if (gameOverlay.BeginTOverlayUpdate(currentOverlay))
				{
					// These x/y coordinates are relative to the overlay itself.
					// So 0,0 is the top-left corner of the overlay, no matter
					// where we end up drawing it on the screen later.
					gameOverlay.DrawBitmap(newBitmap, upgradedOffset, upgradedOffset);
				
					// Tell the engine we're done drawing the overlay contents.
					gameOverlay.EndTOverlayUpdate();
				}
			}
			
			// If we succeeded, keep a reference to the new handle.
			overlayArray.append(currentOverlay);
		}
		
		// Regardless of how we got here, we're using another overlay of
		// this type and need to make note of that.
		poolUsedThisFrame[bitmapName] <- usedInPool + 1;
		
		// Return the overlay hander to our caller.
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
	
	// We can pass this function name into the squirrel's native
	// array sort() function.
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
	// distances. Even when I ignore the BlessItem() function to display
	// as many things as possible, but still invoke it to suffer the
	// overhead of those bless checks. It could be that NewDark v1.27's
	// limit of 64 overlay handles contributes to that performance.
	function DrawTOverlay()
	{
		// For the same reason as the removed toDrawCount < 1 mentioned
		// below it's safest to avoid this. We should ensure every
		// overlay in our pool is either drawn or destroyed.
		//if (!enabled)
		//	return;
		
		// NOTE: this count may be reduced later, if we truncate the array.
		local toDrawCount = toDrawThisFrame.len();
		
		// At one time, we checked whether toDrawCount < 1 and
		// did an early return. However, there are instability
		// issues that can occur if an overlay handle exists and
		// is not used. This was not a reliably reproducible
		// issue in the original code, but was easily doable
		// when commenting out the gameOverlay.DrawTOverlayItem()
		// line. Plenty of overlays would exist and be set up
		// and not a one of them would be drawn, and the crash
		// would happen regularly. In the original code, I
		// could *semi* reliably cause a crash in the following
		// circumstances:
		// 1) *Re*load a savegame. Not a requirement, but it
		// seemed more likely to occur on the second or
		// subsequent game load.
		// 2) Get a radar indicator to appear on the screen.
		// 3) Look in a direction with no indicators.
		// 4) Open the menu.
		// 5) Return to the game.
		// 6) Very quickly look in the direction of a radar
		// POI indicator again. The game will freeze on the frame
		// before the indicator would be in view, then crash.
		//
		// With the early return removed, we now 100% guarantee
		// that every overlay is either drawn or destroyed. I'd
		// highly recommend that any overlay-related code in any
		// mod do the same, to avoid potential instabilities.
		// Issues may not occur 100% of the time, but it seems
		// they can occur to unlucky players, so best to play it
		// safe.
		
		// If we're over our limit, keep the closest POIs and
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
		if (++currentWaveStep > 119)
		{
			currentWaveStep = 0;
		}
		
		// Max opacity is 255, min is 0. We'll cycle between our desired
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
			// has the simplest math. However, to make the overlay a more
			// useful indicator of distance, we can divide up the available
			// bitmap sizes evenly across distances. For example, if
			// our max distance were 128, each bitmap size would correspond to
			// a range of 16 units. But translated into screen size %, that's
			// basically saying we want 0-7 to be X, 8-15 to be 0.875X, 16-23
			// to be 0.75X, 24-31 to be 0.625X, and so on. This is also a linear
			// relationship, where the multiplier to X is (1 - distance/max_distance).
			local useBitmapSize = GetTargetBitmapSizeFromRangePercent(1 - (drawMetadata.distance / MAX_DIST));
			
			// Our method will make sure the X/Y/alpha/etc. is all sorted
			// out for us. We only need to tell DarkOverlay to draw it later.
			local currentOverlay = CreateOrUpdateOverlay(drawMetadata.displayColor, currentAlpha, useBitmapSize, drawMetadata.x, drawMetadata.y);
			
			// Functions like CreateTOverlayItem() return -1 if too many
			// overlays exist. Our CreateOrUpdateOverlay() does the same.
			if (currentOverlay != -1)
			{
				// And whether or not we drew the contents of the overlay earlier,
				// we need to instruct it to draw the overlay itself this frame.
				gameOverlay.DrawTOverlayItem(currentOverlay);
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
				gameOverlay.DestroyTOverlayItem(poolArray.pop());
			}
		}
	}
}

class J4FRadarOverlayHandler extends IDarkOverlayHandler
{
	logic = J4FRadarOverlayHandlerBase();
	
	function OnUIEnterMode()
	{
		logic.OnUIEnterMode();
	}
	
	function DrawHUD()
	{
		logic.DrawHUD();
	}
	
	function DrawTOverlay()
	{
		logic.DrawTOverlay();
	}
}

class J4FShockdarOverlayHandler extends IShockOverlayHandler
{
	// Having various int_ref objects stored centrally avoids having to
	// create a bunch of these on every frame rendered. The T2OverlaySample.nut
	// takes a similar approach.
	i0_ref = int_ref();
	i1_ref = int_ref();
	
	logic = J4FRadarOverlayHandlerBase();
	
	function OnUIEnterMode()
	{
		logic.OnUIEnterMode();
	}
	
	function DrawHUD()
	{
		logic.DrawHUD();
		
		// TODO: Can we limit keycode display to known codes?
		// By looking the logs the player has, to see if any
		// contain the code. If that's not possible, this
		// could just encourage accidental sequence breaking :(
		// NOTE: Can't use ObjID() in this context. But all
		// feature flag metaproperties should inherit from
		// MetaProperty itself, which means they have a non-
		// zero archetype.
		if (Object.Archetype(FEATURE_KEYCODE) != 0)
		{
			local overlayObject = ShockGame.OverlayGetObj();
			if (
				// It exists.
				overlayObject > 0
				// It has a keycode.
				&& Property.Possessed(overlayObject, "KeypadCode")
			)
			{
				local showCode = Property.Get(overlayObject, "KeypadCode");
				
				// Centered.
				Engine.GetCanvasSize(i0_ref, i1_ref);
				local x = i0_ref.tointeger() / 2;
				local y = i1_ref.tointeger() / 2;
				
				ShockOverlay.GetStringSize(showCode, i0_ref, i1_ref);
				
				x = x + (i0_ref.tointeger() / 2);
				y = y + (i1_ref.tointeger() / 2);
				
				//ShockOverlay.SetTextColor(r,g,b);
				ShockOverlay.DrawString(showCode, x, y);
			}
		}
	}
	
	function DrawTOverlay()
	{
		logic.DrawTOverlay();
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
j4fRadarOverlayInstance <- j4fIsShock ? J4FShockdarOverlayHandler() : J4FRadarOverlayHandler();
