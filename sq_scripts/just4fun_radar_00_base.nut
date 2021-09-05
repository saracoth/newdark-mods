/*
TODO: What remains to make this branch feature complete?
* Figure out new detection method. Maybe we ditch the radar item and stims,
	or maybe the radar item just turns the HUD on and off.
-		Requires a new way of safely flagging loot items.
?			Links only come into play when objects are dynamically spawned
			or when creating objects in DromEd. Even if we added an attachment
			link (ParticleAttachement, DetailAttachement, PhysAttach) to
			something via DML, that will not affect anything that already
			exists in the level. This is fine. After all, this allows
			individual instances of objects to have different links if
			the level designer wishes. However, it does also mean that we
			can't use links to attach a new kind of object to all the loot
			that exists in every level :(
?			We could go full crazy and add a metaproperty to *Object* (or
			at least Physical). However, while we can remove metaproperties
			from objects, I see no way to remove scripts from objects, even
			after removing the metaproperty that put the script there in the
			first place. This is an insanely messy approach.
?			I think I've had radius stims affect the object itself before.
			Giving IsLoot a tiny, one-time radius stim it responds to could
			be the safest approach with the smallest footprint. However,
			that will only work if DML allows Agent/Target properties to
			add a metaproperty by name. Otherwise, we're back to a catch 22
			where we need to attach a script to the IsLoot item, so that we
			can attach our actually desired script to it. We can't stimulate
			specific objects either, because, again, we don't know their
			object IDs.
-		Requires a way to ignore non-physical items. Anything that our
		radius stim wouldn't have affected in the first place. Ideally,
		we do this after performance testing, for sake of worst-case
		testing.
-		Requires figuring out how we want to detect newly-added items. For
		example, if a script spawns an item of interest after the level start.
* Figure out how to remove (and/or hide) items later on. For example, to
	remove an indicator after an item is picked up, or a container after
	it gets emptied.
-		Is it worth doing all those checks on every frame? If not, how
		can we have the scripts on the individual items track this info,
		but give the overlay access to it? Do we need to push those status
		changes to the overlay, or can the overlay easily pull them? I
		assume we'll have to push them.
* Serialize/deserialize data so that savegames reload correctly.
-		Requires implementing a serialize/deserialize, unless squirrel
		turns out to have some native methods for this.
-		Requires figuring out when to SetData() or not. If we do so after
		each individual message identifying a target of interest, then
		we'll serialize that data hundreds of times, to an increasingly
		larger string, which seems a little wasteful. But premature
		optimization is the root of all evil, so maybe hold off on this.
* Switch from HUD object squares to semitransparent overlays with bitmaps.
-		Requires first picking a test image that works for both games
		(like bitmap/txt/BUBB00.pcx or something), then picking better
		images for each game and/or object type.
-		Requires reworking overlay hander code to create, destroy, and
		reposition overlays as appropriate.
* Make the overlay effect prettier. For example, cycling between alpha
	values in a sine wave fashion.
* Once done with performance and other testing, define a distance limit.
	First implement the distance checking, and then implement hiding
	based on distance, for worst-case performance cost testing.
-		Use Object.RenderedThisFrame() to uncap or increase range limit?
*/

// TODO: testing
class J4FScriptRemovalTest extends SqRootScript
{
	function OnBeginScript()
	{
		// Spreading all objects out across a couple of seconds,
		// without spending CPU time generating random numbers for
		// random delays.
		SetOneShotTimer("J4FRadarInitDelay", self / 1000.0);
	}
	
	function OnTimer()
	{
		if (message().name != "J4FRadarInitDelay")
			return;
		
		print("I'm alive!");
		
		if (!Object.HasMetaProperty(self, "IsLoot"))
		{
			print("You killed me!");
			Object.RemoveMetaProperty(self, "J4FAllTheThings");
		}
		
		// TODO: jury-rig
		//SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDetected", self);
	}
	
	function OnEndScript()
	{
		print("I'm dead!");
	}
}

// This script goes on the summoning object itself. When used from inventory,
// it spawns a "marco" ping a short at the player's location.
class J4FSpawnMarco extends SqRootScript
{
	function OnFrobInvEnd()
	{
		// Several example .nut scripts do something similar. This should be
		// slightly more efficient than creating two zero vectors later.
		local zeros = vector(0);
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FRadarPuffMarco");
		// Here we use that to set the new object's position before we
		// finish creating it.
		Object.Teleport(summon, zeros, zeros, message().Frobber);
		// Now we're done.
		Object.EndCreate(summon);
		
		// NOTE: In practice, the following one-liner worked equally well.
		// Object.Teleport(Object.Create("J4FRadarPuffMarco"), vector(0), vector(0), message().Frobber);
	}
}

// This a subclass of script goes on pingable items, to generate a visible
// puff in response to a ping.
class J4FSpawnAbstractPolo extends SqRootScript
{
	// Subclass's constructor() should specify this.
	// TODO: confirm save/load friendly
	puffName = null;
	
	// Subclasses can override this to ignore items that accepted the
	// stimulus, but can turn out to be uninteresting after all.
	function BlessItem(itemToBless)
	{
		return true;
	}
	
	// Subclasses can override this behavior if needed, such as when
	// the item cannot be pinged or scripted directly.
	function GetPingedItem()
	{
		return self;
	}
	
	// TODO: performance testing by registering all possible items
	//	loot is trickier, but what can we do, right?
	function OnBeginScript()
	{
		if (GetPingedItem() != self)
			return;
		if (!BlessItem(self))
			return;
		
		//SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDetected", self);
		SetOneShotTimer("J4FNoticeMeSempai", 0.1);
	}
	
	// TODO: jury-rig
	function OnTimer()
	{
		if (message().name != "J4FNoticeMeSempai")
			return;
		
		// TODO: jury-rig
		SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDetected", self);
		
		// TODO: jury-rig
		//if (!(detectedId in j4fRadarOverlayInstance.displayTargets))
//		{
//			j4fRadarOverlayInstance.displayTargets[detectedId] <- displayWhat;
//		}
	}
	
	function OnJ4FRadarPingStimStimulus()
	{
		// What is the pinged item of interest?
		local pingedItem = GetPingedItem();
		
		// Is it really interesting enough to point out to the player?
		if (!BlessItem(pingedItem))
			return;
		
		// TODO:
		SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDetected", pingedItem);
		
		// Several example .nut scripts do something similar. This should be
		// slightly more efficient than creating two zero vectors later.
		local zeros = vector(0);
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it, similar to create_obj receptrons.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate(puffName);
		// Now we place the new object on top of the radar-detected item.
		Object.Teleport(summon, zeros, zeros, pingedItem);
		// Now we're done setting up the new object instance.
		Object.EndCreate(summon);
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
			local radarItemId = ObjID("J4FRadarMarcoItem");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the radar item?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FRadarMarcoItem as well, but that's not relevant
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

// TODO: save/load testing
// This script goes on the marker we add to every mission. It sets up and
// tears down the overlay handler. We also use it to pass along messages
// to the overlay handler, including persisted data with SetData()/GetData()
class J4FRadarUi extends SqRootScript
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
	}

	function OnEndScript()
	{
		// Given that we have multiple things to do when tearing down
		// the handler, all that code was moved to the destructor, which
		// we can call by hand.
		destructor();
	}
	
	// TODO: doc
	function OnJ4FRadarDetected()
	{
		local detectedId = message().data;
		// TODO:
		//local displayWhat = message().data2;
		// TODO:
		local displayWhat = "";
		
		// TODO:
		//print(format("Detected %s %i with %s", Object.GetName(Object.Archetype(detectedId)), detectedId, displayWhat));
		
		// TODO: jury-rig
		if (!(detectedId in j4fRadarOverlayInstance.displayTargets))
		{
			j4fRadarOverlayInstance.displayTargets[detectedId] <- displayWhat;
		}
	}
}

// TODO: document class and its contents
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
	resizeNeeded = false;
	displayTargets = {};
	
	function Teardown()
	{
		displayTargets = {};
	}
	
	function Setup()
	{
		displayTargets = {};
	}
	
	// OnUIEnterMode implements an IDarkOverlayHandler method.
	// This is the best spot to figure out our canvas size, which is related to
	// but different than the user's resolution settings. If they change res
	// mid-game, this function will fire again, and we can reposition things.
	function OnUIEnterMode()
	{
		Engine.GetCanvasSize(x1_ref, y1_ref);
		
		local newCanvasWidth = x1_ref.tointeger();
		local newCanvasHeight = y1_ref.tointeger();
		
		if (newCanvasWidth != canvasWidth)
		{
			canvasWidth = newCanvasWidth;
			resizeNeeded = true;
		}
		
		if (newCanvasHeight != canvasHeight)
		{
			canvasHeight = newCanvasHeight;
			resizeNeeded = true;
		}
	}
	
	// TODO: just testing
	function DrawHUD()
	{
		// TODO:
		DarkOverlay.DrawString("Hello", 10, 10);
		
		// I'm unclear how squirrel handles modifying an object while
		// enumerating through it. Given that some programming languages
		// consider this a problem and either error out or behave
		// unpredictably, we'll keep track of removed items here and
		// then do the actual removing later.
		local removeIds = [];
		
		foreach (targetId, displayTexture in displayTargets)
		{
			// TODO: Item IDs can and will be reused, so we have to be careful about that.
			//	For example, I saw temporary SFX temporarily receive the radar highlight.
			//	When using the minion summoner, some minions had the highlight as well.
			// TODO: check whether the targetId needs to be ignored/removed
			// eg, item picked up, etc.
			
			//local targetPos = Object.Position(targetId);
			
			//DarkOverlay.WorldToScreen(targetPos, x, y);
			if (!DarkOverlay.GetObjectScreenBounds(targetId, x1_ref, y1_ref, x2_ref, y2_ref))
				continue;
			
			local x1 = x1_ref.tointeger();
			local y1 = y1_ref.tointeger();
			local x2 = x2_ref.tointeger();
			local y2 = y2_ref.tointeger();
			
			DarkOverlay.DrawLine(x1, y1, x1, y2);
			DarkOverlay.DrawLine(x1, y2, x2, y2);
			DarkOverlay.DrawLine(x2, y2, x2, y1);
			DarkOverlay.DrawLine(x2, y1, x1, y1);
		}
		
		// TODO: process removeIds
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
