// NOTE: this script is mostly isolated from the optional modules, but there
// may be some cases where it's easier to write code here to support them.
// For example, for the IsLoot handling.

const MIN_ALPHA = 32;
const MAX_ALPHA = 100;
// NOTE: This also helps with various limitations. I've seen, for example,
// that in some busy missions, we seem to run out of overlays before we
// can render stuff like loot. This seems irrelevant to how many overlays
// are rendered on screen at the moment, and likely has to do with a max
// number of created overlay handles.
// TODO: configurable?
const MAX_DIST = 150;

// 1 (move) + 2 (script) + 128 (default)
const INTERESTING_FROB_FLAGS = 131;

// This script goes on an inventory item the player can use to turn the
// radar effect on and off.
class J4FRadarToggler extends SqRootScript
{
	function OnFrobInvEnd()
	{
		// TODO: implement, default to off
	}
}

class J4FRadarEchoReceiver extends SqRootScript
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
		// required to enable these effects, because otherwise the POI
		// metaproperty won't exist.
		local lootPointOfInterest = ObjID("J4FRadarLootPOI");
		
		if (
			// The optional loot module is installed.
			lootPointOfInterest < 0
			// And it's a loot item.
			&& Object.InheritsFrom(newPointOfInterest, "IsLoot")
			// But it does not yet have the loot POI metaproperty.
			&& !Object.HasMetaProperty(newPointOfInterest, lootPointOfInterest)
		)
		{
			Object.AddMetaProperty(newPointOfInterest, lootPointOfInterest);
		}
	}
}

// This a subclass of script goes on pingable items, to generate a visible
// puff in response to a ping.
class J4FRadarAbstractTarget extends SqRootScript
{
	// Subclass's constructor() should specify this if desired. No
	// save/load persistence is necessary, because when classes are
	// (re)constructed, they'll set this value again.
	color = "W";
	// Persistence is optional here, because we'll default this to
	// false and rely on timers to review it periodically.
	isBlessed = false;
	
	// Subclasses can override this to define how items can become temporarily
	// interesting or ininteresting. As opposed to a more permanent, one-time veto.
	function BlessItem()
	{
		// If we're contained by a thing (with a reverse "Contains" link),
		// then our object's location is irrelevant. Hide ourselves.
		// NOTE: We pass 0 to the second parameter because we don't know
		// the object ID of our container, or if we're even contained.
		if (Link.GetOne("Contains", 0, self) != 0)
			return false;
		
		return true;
	}
	
	// This is a common need for many points of interest, and implemented
	// here so they can add it to their BlessItem() if desired.
	function IsPickup()
	{
		// This property contains our frob flags, if any. We only
		// care if those flags include interesting options.
		return (Property.Get(self, "FrobInfo", "World Action") & INTERESTING_FROB_FLAGS) > 0;
	}
	
	// NOTE: This is not a truly reliable check for whether a given object
	// can be rendered. Instead, it just checks for certain things that
	// are known to prevent rendering. There are others, like being
	// contained inside a different object, not having a model, or
	// having a model which is effectively empty.
	function IsRendered()
	{
		// We'll assume invisible render statuses are irrelevant.
		if (Property.Possessed(self, "INVISIBLE") && Property.Get(self, "INVISIBLE"))
			return false;
		
		// Likewise ignore things with unusual, undesirable render types.
		// These include type 1 (not at all) and 3 (editor only).
		if (Property.Possessed(self, "RenderType"))
		{
			switch (Property.Get(self, "RenderType"))
			{
				// not-at-all
				case 1:
					// intentional fall-through to next case statement
				// editor-only
				case 3:
					return false;
			}
		}
		
		// I dunno, I guess it's rendered. I suppose we also need things
		// like a model and to not be contained inside something.
		return true;
	}
	
	// This will fire on mission start and on reloading a save.
	function OnBeginScript()
	{
		// Depending on which order objects are set up, things like the
		// overlay marker may not be ready yet. We'll add a slight
		// startup delay before registering our existence with them.
		// We use our item ID to help stagger startup times when there
		// are a lot of items in the level. We could generate a random
		// delay, but that carries a CPU cost of its own.
		SetOneShotTimer("J4FRadarTargetReview", ((self % 900) + 100) / 1000.0);
		
		// We also need to regularly review our blessed status.
	}
	
	function OnTimer()
	{
		if (message().name != "J4FRadarTargetReview")
			return;
		
		local newBlessed = BlessItem();
		
		// If our blessing status changes, add or remove us from the list
		// of targets to review and display.
		if (isBlessed != newBlessed)
		{
			if (newBlessed)
			{
				SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDetected", self, color);
			}
			else
			{
				SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDestroyed", self);
			}
			
			isBlessed = newBlessed;
		}
		
		// Periodically review our blessing status.
		SetOneShotTimer("J4FRadarTargetReview", 0.25);
	}
	
	// Because item IDs can be reused, we need to be sure a destroyed
	// item is removed from the list. Otherwise, we could treat some
	// random arrow or blood splatter as a point of interest.
	function OnDestroy()
	{
		SendMessage(ObjID("J4FRadarUiInterfacer"), "J4FRadarDestroyed", self);
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
	
	// Rather than have radar points of interest communicate directly
	// with the overlay instance, we'll have them communicate with us.
	function OnJ4FRadarDetected()
	{
		// We sent the point-of-interest item object ID in "data"
		local detectedId = message().data;
		
		// If the POI item is not already in the list, put it there.
		if (!(detectedId in j4fRadarOverlayInstance.displayTargets))
		{
			// We sent the radar color indicator in "data2"
			j4fRadarOverlayInstance.displayTargets[detectedId] <- message().data2;
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
}

// According to https://developer.electricimp.com/resources/efficientsquirrel it
// should be better to have classes rather than generic tables, if we're going
// to have two or more instances of them. At least, it's more memory efficient.
// Not sure what's more CPU efficient, but we're probably splitting hairs there.
class J4FRadarPointOfInterest
{
	x = 0;
	y = 0;
	displayColor = "W";
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
	resizeNeeded = false;
	useBitmapSize = 0;
	displayTargets = {};
	// This is a table whose keys are strings, indicating the color of the
	// overlay. For example, "W" for white, "Y" for yellow, etc. The keys are
	// arrays of overlay handles created with DarkOverlay.CreateTOverlayItem()
	// or DarkOverlay.CreateTOverlayItemFromBitmap()
	overlayPool = {};
	// Contains a list of points of interest to render on the current frame.
	// See comments in DrawHUD() for an explanation of why we need to feed
	// data into DrawTOverlay like this.
	toDrawThisFrame = [];
	// Used for alpha/opacity/transparency cycling effect.
	currentWaveStep = 0;
	
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
	// mid-game, this function will fire again, and we can resize our overlays.
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
		
		// I'm unclear how squirrel handles modifying an object while
		// enumerating through it. Given that some programming languages
		// consider this a problem and either error out or behave
		// unpredictably, we'll keep track of removed items here and
		// then do the actual removing later.
		local removeIds = [];
		
		// We'll use this for distance checking.
		local cameraPos = Camera.GetPosition();
		
		foreach (targetId, displayColor in displayTargets)
		{
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
			if (!Object.RenderedThisFrame(targetId) && (Object.Position(targetId) - cameraPos).Length() > MAX_DIST)
				continue;
			
			local metadataForOverlay = J4FRadarPointOfInterest();
			// Pick a point in the center of the object bounds.
			metadataForOverlay.x = (x1_ref.tointeger() + x2_ref.tointeger()) / 2;
			metadataForOverlay.y = (y1_ref.tointeger() + y2_ref.tointeger()) / 2;
			metadataForOverlay.displayColor = displayColor;
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
	
	// In some circumstances, we want to gracefully destroy all
	// overlay objects.
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
	// ignored. However, I also noticed some radar indicators flickering
	// on and off as I moved my camera a little. These were near the
	// center of the screen, so the most likely explanation is there is
	// some kind of hard limit. Either there's a time limit to how long
	// our DrawTOverlay can take, or there's a limit to how many overlays
	// can be drawn on the screen, or there's a limit to how many
	// overlays can be defined at all. In any case, this is probably a
	// net win, since it can only help maintain performance when faced
	// with large numbers of radar points of interest.
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
			
			// TODO: I don't like losing the sense of scale/distance.
			// can we choose from a variety of sizes? if we do, how
			// does that change our tracking? I guess instead of
			// color, the keys will have to be full filenames
			
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
			// tl;dr This math picks a multiple of 8 nearest 5% of the
			// screen height.
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
		
		// Subtracted from x/y coordinate to place the center of the
		// bitmap on those coordinates, instead of the top-left corner.
		local overlayOffset = (useBitmapSize / 2);
		
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
		for (local i = toDrawThisFrame.len(); --i > -1; )
		{
			local drawMetadata = toDrawThisFrame[i];
			local displayColor = drawMetadata.displayColor;
			local x = drawMetadata.x;
			local y = drawMetadata.y;
			
			// We need to find or create an overlay to use for this item.
			// Start by getting the array of overlays for this type. Create
			// it if needed.
			local overlayArray;
			local usedInPool = 0;
			if (displayColor in overlayPool)
			{
				// The array exists, so grab it.
				overlayArray = overlayPool[displayColor];
				
				// But is this the first time we've grabbed it this frame?
				// If not, we need to load the appropriate usedInPool value.
				if (displayColor in poolUsed)
				{
					usedInPool = poolUsed[displayColor];
				}
				// Otherwise, we defaulted usedInPool to 0 earlier.
			}
			else
			{
				// First time we've ever seen this one. Create a new,
				// empty array to work with.
				overlayArray = [];
				// And remember it for future use.
				overlayPool[displayColor] <- overlayArray;
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
				DarkOverlay.UpdateTOverlayPosition(currentOverlay, x - overlayOffset, y - overlayOffset);
				// And update its transparency.
				DarkOverlay.UpdateTOverlayAlpha(currentOverlay, currentAlpha);
				
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
				// TODO: fallback if we can detect our bitmaps aren't installed?
				local newBitmap = DarkOverlay.GetBitmap("Radar" + displayColor + useBitmapSize, "j4fres\\");
				
				currentOverlay = DarkOverlay.CreateTOverlayItemFromBitmap(x - overlayOffset, y - overlayOffset, currentAlpha, newBitmap, true);
				overlayArray.append(currentOverlay);
				
				// TODO: we'll get errors for bitmaps of non-power-of-2 sizes.
				// in these cases, we should create an overlay item manually
				// and draw the bitmap in its center
				
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
			poolUsed[displayColor] <- usedInPool + 1;
			
			// And whether or not we drew the contents of the overlay earlier,
			// we need to instruct it to draw the overlay itself this frame.
			DarkOverlay.DrawTOverlayItem(currentOverlay);
		}
		
		// TODO: compare to overlayPool to poolUsed (remember that we may
		// have no poolUsed record for completely unused pool arrays) and
		// destroy unneeded stuff
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
