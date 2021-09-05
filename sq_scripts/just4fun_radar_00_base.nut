/*
TODO: What remains to make this branch feature complete?
* Figure out new detection method. Maybe we ditch the radar item and stims,
	or maybe the radar item just turns the HUD on and off.
-		Requires a new way of safely flagging loot items.
			By process of elimination, we will detect nearby IsLoot by
			having the player avatar repeatedly emit a radius stim. IsLoot
			will respond to that by stimulating the source, in essence
			reflecting our stim back at us. A ping and respond model just the
			same as the current radar mod.
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
		local displayBitmapName = message().data2;
		local displayBitmapPath = message().data3;
		
		// TODO:
		local displayBitmapName = "BUBB00";
		local displayBitmapPath = "bitmap\\txt\\";
		
		// TODO: jury-rig
		if (!(detectedId in j4fRadarOverlayInstance.displayTargets))
		{
			// TODO: figure out these key/value pairs :/
			j4fRadarOverlayInstance.displayTargets[detectedId] <- displayBitmapPath + displayBitmapName;
		}
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
	displayTexture = "";
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
	// TODO: implement resizeNeeded if needed, or else remove that logic
	resizeNeeded = false;
	useBitmapSize = 0;
	displayTargets = {};
	// This is a table whose keys are strings, indicating the appearance
	// of the overlay. For example, a specific bitmap path. The keys are
	// arrays of overlay handles created with DarkOverlay.CreateTOverlayItem()
	// or DarkOverlay.CreateTOverlayItemFromBitmap()
	// TODO: do we need to manually clean this up ourselves on Teardown/etc.?
	overlayPool = {};
	// Contains 
	// See comments in DrawHUD() for an explanation of why we need to feed
	// data into DrawTOverlay like this.
	toDrawThisFrame = [];
	
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
	
	function DrawHUD()
	{
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
		
		foreach (targetId, displayTexture in displayTargets)
		{
			// TODO: Item IDs can and will be reused, so we have to be careful about that.
			//	For example, I saw temporary SFX temporarily receive the radar highlight.
			//	When using the minion summoner, some minions had the highlight as well.
			// TODO: check whether the targetId needs to be ignored/removed
			// eg, item picked up, etc.
			
			// Well, WorldToScreen looked promising, but it appears to just pick a corner
			// of the object. If we want something more...centered, we'll have to use
			// GetObjectScreenBounds instead.
			//local targetPos = Object.Position(targetId);
			//if (!DarkOverlay.WorldToScreen(targetPos, x1_ref, y1_ref))
			//	continue;
			
			// This sets the x/y pairs to the left, top, right, and bottom edges of the
			// object. Or it returns false if the object is completely offscreen.
			if (!DarkOverlay.GetObjectScreenBounds(targetId, x1_ref, y1_ref, x2_ref, y2_ref))
				continue;
			
			// For debugging purposes, we can also draw directly in the HUD this frame.
			// This will draw the bounding box we just retrieved.
			///*
			DarkOverlay.DrawLine(x1_ref.tointeger(), y1_ref.tointeger(), x1_ref.tointeger(), y2_ref.tointeger());
			DarkOverlay.DrawLine(x1_ref.tointeger(), y2_ref.tointeger(), x2_ref.tointeger(), y2_ref.tointeger());
			DarkOverlay.DrawLine(x2_ref.tointeger(), y2_ref.tointeger(), x2_ref.tointeger(), y1_ref.tointeger());
			DarkOverlay.DrawLine(x2_ref.tointeger(), y1_ref.tointeger(), x1_ref.tointeger(), y1_ref.tointeger());
			//*/
			
			// TODO: I guess we should do all the other checking as well, including
			// whether to remove the item ID, whether to ignore it because it's not
			// currently visible or in range, etc.
			
			local metadataForOverlay = J4FRadarPointOfInterest();
			// Pick a point in the center of the object bounds.
			metadataForOverlay.x = (x1_ref.tointeger() + x2_ref.tointeger()) / 2;
			metadataForOverlay.y = (y1_ref.tointeger() + y2_ref.tointeger()) / 2;
			metadataForOverlay.displayTexture = displayTexture;
			toDrawThisFrame.append(metadataForOverlay);
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
	
	function DeleteOverlays()
	{
		foreach (key,overlays in overlayPool)
		{
			// Since the order doesn't matter, may as well loop through
			// backwards. This is marginally more efficient, since we only
			// have to grab the array length once, and we reference fewer
			// variable values and more constant/literal values.
			for (local i = overlays.len(); --i > -1; )
			{
				DarkOverlay.DestroyTOverlayItem(overlays[i]);
			}
		}
	}
	
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
	function DrawTOverlay()
	{
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
		local poolUsed = {};
		
		// Different screen resolutions (and canvas sizes) are suited
		// to different image sizes. If this changes, we should replace
		// the previous overlays with new ones of an appropriate size.
		// To do this, we just discard what we have, and let the logic
		// below create new ones if needed.
		if (resizeNeeded)
		{
			resizeNeeded = false;
			
			// Let's aim for 5% of the screen height. We have images
			// available in multiples of: 8, 16, 24, 32, etc. up to 64.
			// To get 5%, we divide by 20. From there, we want to round
			// so that 13-20 are 16, 21-28 is 24, etc. Ignoring the
			// round to 0 possibility for a moment, this scale starts
			// at 5-12 becoming 8. Subtracting 5, that scale becomes
			// 0-7, 8-15, etc. That allows us to divide by 8, floor()
			// the result, add 1, then multiply by 8 again. Or to make
			// things a little simpler, instead of subtracting 5, we
			// can add 3. That saves the "add 1" step above.
			// We then cap to a min of 8 and max of 64.
			local newBitmapSize = floor(((canvasHeight / 20) + 3) / 8).tointeger() * 8;
			if (newBitmapSize < 8)
			{
				newBitmapSize = 8;
			}
			else if (newBitmapSize > 64)
			{
				newBitmapSize = 64;
			}
			
			// Check to see if it's actually any different. Not every
			// resizeNeeded will yield different target bitmap size.
			if (newBitmapSize != useBitmapSize)
			{
				// Remember the value for future use.
				useBitmapSize = newBitmapSize;
				
				// And clear all existing overlays, if any.
				DeleteOverlays();
			}
		}
		
		// Added to x/y coordinate to place the center of the bitmap on
		// those coordinates, instead of the top-left corner.
		local overlayOffset = 0 - (useBitmapSize / 2);
		
		// Since draw order doesn't matter, may as well loop through
		// backwards. This is marginally more efficient, since we only
		// have to grab the array length once, and we reference fewer
		// variable values and more constant/literal values.
		for (local i = toDrawThisFrame.len(); --i > -1; )
		{
			local drawMetadata = toDrawThisFrame[i];
			local displayTexture = drawMetadata.displayTexture;
			local x = drawMetadata.x;
			local y = drawMetadata.y;
			
			// We need to find or create an overlay to use for this item.
			// Start by getting the array of overlays for this type. Create
			// it if needed.
			local overlayArray;
			local usedInPool = 0;
			if (displayTexture in overlayPool)
			{
				// The array exists, so grab it.
				overlayArray = overlayPool[displayTexture];
				
				// But is this the first time we've grabbed it this frame?
				// If not, we need to load the appropriate usedInPool value.
				if (displayTexture in poolUsed)
				{
					usedInPool = poolUsed[displayTexture];
				}
				// Otherwise, we defaulted usedInPool to 0 earlier.
			}
			else
			{
				// First time we've ever seen this one. Create a new,
				// empty array to work with.
				overlayArray = [];
				// And remember it for future use.
				overlayPool[displayTexture] <- overlayArray;
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
				
				DarkOverlay.UpdateTOverlayPosition(currentOverlay, x - overlayOffset, y - overlayOffset);
				
				// NOTE: The engine remembers the contents of the overlay,
				// so we don't need to re-draw them. We only need to tell
				// it to draw the overlay itself later.
			}
			else
			{
				// We need to create a new overlay. This requires some initial
				// setup.
				// TODO: huh...do we need to get a new bitmap handle for each
				// overlay, or can we use one for all? Also, when should we
				// call DarkOverlay.FlushBitmap()?
				// TODO: so, parameters are not what I expected...review displayTexture keys :(
				local newBitmap = DarkOverlay.GetBitmap("RadarW" + useBitmapSize, "j4fres\\");
				/*
				// TODO: uh, we actually need to know this always, not just on creation :/
				// maybe we need to create classes to track our overlay details; if not,
				// we'll need more tables to store info like this, which seems silly
				local overlayWidth, overlayHeight;
				if (DarkOverlay.GetBitmapSize(newBitmap, x1_ref, y1_ref))
				{
					overlayWidth = x1_ref.tointeger();
					overlayHeight = y1_ref.tointeger();
				}
				else
				{
					// TODO: better error handling
					overlayWidth = 64;
					overlayHeight = 64;
				}
				*/
				
				currentOverlay = DarkOverlay.CreateTOverlayItemFromBitmap(x - overlayOffset, y - overlayOffset, 127, newBitmap, true);
				overlayArray.append(currentOverlay);
				
				// Because we used CreateTOverlayItemFromBitmap(), the
				// contents of the overlay are taken care of for us.
				// Otherwise, we'd want to do something like this:
				/*
				if (DarkOverlay.BeginTOverlayUpdate(currentOverlay))
				{
					// Do whatever drawing operations we need here.
					
					// Tell the engine we're done drawing the overlay contents.
					DarkOverlay.EndTOverlayUpdate();
				}
				*/
			}
			
			// Regardless of how we got here, we're using another overlay of
			// this type and need to make note of that.
			poolUsed[displayTexture] <- usedInPool + 1;
			
			// And whether or not we drew the contents of the overlay earlier,
			// we need to instruct it to draw the overlay itself this frame.
			DarkOverlay.DrawTOverlayItem(currentOverlay);
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
