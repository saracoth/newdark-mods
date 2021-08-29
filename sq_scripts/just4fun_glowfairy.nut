// =============================================================================
// This script goes on the control inventory item.
class J4FFairyController extends SqRootScript
{
	// Given the way the NewDark squirrel documentation is written, feels like
	// everything is slow and expensive. So let's preemptively limit our use of
	// GetData() by giving us a spot to store that info.
	// Object IDs
	playerId = 0;
	fairyId = 0;
	markerId = 0;
	homeId = 0;
	// Link IDs
	homeToMarkerId = 0;
	markerToHomeId = 0;
	// Timer handles
	doubleClickTimer = 0;
	// userparams() data
	maxRange = 100;
	doubleClickTime = 0.5;
	
	// Other variables. Note that we have to track them with GetData/SaveData
	// as well, or we'll lose them when reloading a save game.
	
	// If a positive value, this refers to a concrete object within the game
	// level. If a zero, we've halted movement. If a negative value, we're
	// following the player's gaze.
	// NOTE: Negative integers are acceptable object IDs in some places, but
	// because they refer to archetype definitions within a gamesys rather than
	// actual in-level objects, we don't have to worry about telling the fairy
	// to follow something with a negative ID.
	// TODO: auto-stop if our object vanishes; detect invalid/destroyed objects
	followTarget = 0;
	
	function OnBeginScript()
	{
		if (IsDataSet("playerId"))
		{
			playerId = GetData("playerId");
		}
		
		if (IsDataSet("fairyId"))
		{
			fairyId = GetData("fairyId");
		}
		
		if (IsDataSet("markerId"))
		{
			markerId = GetData("markerId");
		}
		
		if (IsDataSet("homeId"))
		{
			homeId = GetData("homeId");
		}
		
		if (IsDataSet("doubleClickTimer"))
		{
			homeId = GetData("doubleClickTimer");
		}
		
		if (IsDataSet("followTarget"))
		{
			followTarget = GetData("followTarget");
		}
		
		maxRange = userparams().MaxRange;
		doubleClickTime = userparams().DoubleClickTime;
	}
	
	function OnContained()
	{
		// This function is for first-time setup only. We can skip it.
		if (playerId != 0)
			return;
		
		// Get a reference to our containing Avatar, so we can follow their gaze.
		local containerId = message().container;
		if (!Object.InheritsFrom(containerId, "Avatar"))
			return;
		
		SetData("playerId", containerId);
		playerId = containerId;
		
		// Spawn stuff well above the player to avoid their light giving
		// away our position at the start of a mission.
		local farAway = vector(0, 0, 200);
		local zeros = vector(0);
		
		// For all the objects, rather than use Object.Create() directly,
		// we will use BeginCreate() and EndCreate() to allow us to set up
		// any necessary properties before the creation process finishes.
		
		// Create the home marker.
		local home = Object.BeginCreate("TerrPt");
		Object.Teleport(home, farAway, zeros, playerId);
		Object.EndCreate(home);
		
		SetData("homeId", home);
		homeId = home;
		
		// Now we can the second marker.
		local marker = Object.BeginCreate("TerrPt");
		Object.Teleport(marker, farAway, zeros, playerId);
		Object.EndCreate(marker);
		
		SetData("markerId", marker);
		markerId = marker;
		
		// With both markers on the map, we can create a loop between them.
		local homeToMarker = Link.Create("TPath", home, marker);
		local markerToHome = Link.Create("TPath", marker, home);
		// The default data for these kinds of links is 0 speed, no pause,
		// and allow nice curving paths. We need to change the "Speed"
		// property from its default value.
		LinkTools.LinkSetData(homeToMarker, "Speed", 5.0);
		LinkTools.LinkSetData(markerToHome, "Speed", 5.0);
		
		SetData("markerToHomeId", markerToHome);
		markerToHomeId = markerToHome;
		SetData("homeToMarkerId", homeToMarker);
		homeToMarkerId = homeToMarker;
		
		// Now create the fairy and link it to the home marker.
		local fairy = Object.BeginCreate("J4FFairy");
		Object.Teleport(fairy, farAway, zeros, playerId);
		local fairyToHome = Link.Create("TPathInit", fairy, home);
		Object.EndCreate(fairy);
		
		SetData("fairyId", fairy);
		fairyId = fairy;
		
		// Begin controlling fairy motion.
		SetOneShotTimer("J4FFairyMotion", 0.25);
	}
	
	function OnTimer()
	{
		local timerName = message().name;
		switch (timerName)
		{
			case "J4FFairyMotion":
				// We'll need this later, in a few places.
				local fairyPos = Object.Position(fairyId);
				
				// This is where we want the fairy to end up. We'll start by
				// assuming we want it to stay right where it is, until we
				// decide otherwise. This default value is also what takes
				// effect when followTarget == 0 (halt mode).
				local targetPos = fairyPos;
				
				// So what is the fairy actually doing right now?
				if (followTarget < 0)
				{
					//print("Following gaze");
					
					// Following our gaze. We'll set targetPos to a part of the map
					// roughly where the player is looking.
					
					// To figure out what part of the level geometry the player is
					// looking at, we use the PortalRaycast function. It ignores
					// objects and is therefore a little faster.
					//
					// To use it, we can't just pass in a starting point and a
					// direction. Instead, it wants two points in 3D space. This
					// means we have to figure out what the second point is
					// ourselves, based on the direction we're looking and the max
					// distance we want to project the fairy out to.
					//
					// This requires some trigonometry math. I followed along with
					// https://stackoverflow.com/a/1568687 which says:
					// x = cos(pitch) * cos(yaw)
					// y = cos(pitch) * sin(yaw)
					// z = sin(pitch)
					//
					// The pitch is how far up or down the camera is pointing, which
					// is why it's all that matters for the vertical Z axis. The yaw
					// comes from turning left or right.
					//
					// We can't get these values from the player itself, because
					// the avatar object only has yaw. There is no pitch. So instead,
					// we get the current *camera* position and facing.
					local camPos = Camera.GetPosition();
					local camFacing = Camera.GetFacing();
				
					// Now, the squirrel sin() and cos() functions work with radians.
					// However, camFacing is given to us in degrees. So let's convert.
					local camPitch = PI * camFacing.y / 180;
					local camYaw = PI * camFacing.z / 180;
				
					// NOTE: camFacing.x exists, but only comes into play for leaning
					// and similar things we're can ignore. Our pitch is 0 when the
					// view is centered, and increases up to 90 when looking down.
					// When looking up, it wraps backwards to 360 degrees and drops
					// down to as low as 270 for looking directly up. The yaw value
					// gets bigger and bigger as we turn left, until it would hit
					// 360 and wraps back around to 0 instead.
				
					// Now we can convert our pitch and yaw into what's called a
					// directional vector. Instead of representing X, Y, and Z
					// coordinates, it acts as a multiplier. If we multiply its
					// X, Y, and Z values by 100, the result is a 3D coordinate in
					// space that is exactly 100 units away from the 0,0,0 position.
				
					local direction = vector(
						cos(camPitch) * cos(camYaw),
						cos(camPitch) * sin(camYaw),
						sin(-1 * camPitch)
						);
				
					// For our raycasting test, let's pick a point up to MaxRange units
					// away. Or however many units we'd like. The point is, the fairy
					// can't be controlled outside whatever distance we pick here.
					// To get these coordinates, we multiply the directional vector
					// by 100 units, then add that to the camera position. This way,
					// instead of being 100 units away from 0,0,0 we pick a point
					// 100 units away from wherever the camera happens to be.
				
					local testPos = (direction * maxRange) + camPos;
				
					// Assuming PortalRaycast() returns true, targetPos contains our
					// point of impact. Let's re-initialize it to a brand new vector,
					// as a paranoia measure.
					targetPos = vector(0);
				
					if (Engine.PortalRaycast(camPos, testPos, targetPos))
					{
						// The targetPos is touching some piece of level geometry.
						// So if we place the center point of our object right at
						// that spot, it will be partly inside and partly outside
						// the level boundaries.
						//
						// So we'd like to pull the target point back a little closer
						// to the camera. To do that, we first figure out what
						// distance targetPos is from the camera. We'll use the
						// https://gamedev.stackexchange.com/a/92521 approach.
					
						local displacement = targetPos - camPos;
						// Per https://en.wikipedia.org/wiki/Dot_product , the
						// dot product of any vector with itself is a non-negative
						// number. So sqrt() is safe in this context, and will always
						// give us a positive distance value.
						local impactDistance = sqrt(displacement.Dot(displacement));
					
						// If the player is hugging a wall or something, going a few
						// units backwards could target a location behind the camera.
						// So let's cam the shortened distance to non-negative values
						// to prevent that.
						if (impactDistance <= 2)
						{
							// Center on the camera instead of behind it.
							targetPos = camPos;
						}
						else
						{
							// Here's that directional vector again, doing the same
							// job as before but with a smaller distance.
							targetPos = (direction * (impactDistance - 2)) + camPos;
						}
					}
					else
					{
						// Ray tracing said there are no obstacles in our way.
						//
						// I don't see where it's defined what the PortalRaycast()
						// function does to the third parameter when there is no
						// impact. So to be on the safe side, we'll explicitly say
						// the targetPos is max-distance testPos instead.
						targetPos = testPos;
					}
				}
				else if (followTarget > 0)
				{
					//print("Following target");
					
					// Following a specific ingame creature.
					// TODO: implement
				}
				//else
				//{
				//	print("Doing nothing");
				//}
				
				//print(format("Targeting %g / %g / %g", targetPos.x, targetPos.y, targetPos.z));
				
				// Teleport() with only three parameters has no frame-of-reference
				// object. So the targetPos coordinates will be treated as absolute
				// game-world coordinates, instead of coordinates relative to some
				// reference object.
				// We use Object.Facing() to get and preserve the object's current
				// facing, if any.
				Object.Teleport(markerId, targetPos, Object.Facing(markerId));
				Object.Teleport(homeId, targetPos, Object.Facing(homeId));
				
				// Doing some more vector math to get another distance. This time,
				// the distance between the fairy and its target. Refer to the above
				// comments for details on what this math is doing and where it
				// came from.
				local fairyDisplacement = targetPos - fairyPos;
				local fairyDistance = sqrt(fairyDisplacement.Dot(fairyDisplacement));
				// Scale the distance so that we'll cover it in roughly X seconds.
				// The number of seconds is the divisor here, like 0.5 for 0.5 secs.
				// Note, however, that we're updating this speed over and over again
				// throughout its journey. So the actual journey will take more than
				// that time, because we keep slowing it down along the way.
				local fairySpeed = fairyDistance / 0.75;
				// Maintain a minimum speed
				if (fairySpeed < 5.0)
				{
					fairySpeed = 5.0;
				}
				// Enforce a maximum speed to reduce overshooting targets?
				//else if (fairySpeed > 1000.0)
				//{
				//	fairySpeed = 1000.0;
				//}
				
				LinkTools.LinkSetData(homeToMarkerId, "Speed", fairySpeed);
				LinkTools.LinkSetData(markerToHomeId, "Speed", fairySpeed);
				
				// Turning this property off and on again is enough for the engine to
				// recalculate its path. Otherwise, even after we teleport the markers
				// away, the fairy will continue moving towards its last-known location
				// until it reaches its destination.
				//
				// Toggling this also allows it to see the changed speed values above.
				Property.SetSimple(fairyId, "MovingTerrain", false);
				Property.SetSimple(fairyId, "MovingTerrain", true);
				
				// Repeat.
				SetOneShotTimer("J4FFairyMotion", 0.25);
				
				break;
			case "J4FDoubleClick":
				// If this timer goes off, it's because we failed to click a second
				// time. So this is where our single-click functionality goes.
				
				// For starters, forget the whole timer thing. It's gone off and the
				// handle is useless now.
				doubleClickTimer = 0;
				SetData("doubleClickTimer", doubleClickTimer);
				
				// If we're not following the player's gaze, then start doing so.
				if (followTarget >= 0)
				{
					followTarget = -1;
					
					// Update the controller item name for extra clarity.
					Property.SetSimple(self, "GameName", "name_j4f_fairy_controller_gaze: \"Tinker's Bell (Gazing)\"");
				}
				else
				{
					// If we were already following their gaze, we stop moving.
					followTarget = 0;
					
					// Update the controller item name for extra clarity.
					Property.SetSimple(self, "GameName", "name_j4f_fairy_controller_halt: \"Tinker's Bell (Waiting)\"");
				}
				
				// In either case, we want to remember the follow target between
				// saving/loading, so store it.
				SetData("followTarget", followTarget);
				
				break;
		}
	}
	
	function OnFrobInvEnd()
	{
		// We can't necessarily take immediate action, because we need to detect
		// whether this is a click or a double click (frob or double frob).
		
		if (doubleClickTimer == 0)
		{
			// No timer exists, so this is our first (and possibly only) click.
			// We have to either wait for a second click, or for the window of
			// opportunity to expire.
			doubleClickTimer = SetOneShotTimer("J4FDoubleClick", doubleClickTime);
			SetData("doubleClickTimer", doubleClickTimer);
			return;
		}
		
		// If we made it this far, it's because there's already a timer going.
		// So we've clicked a second time before it ran out. Now we want to
		// stop that timer before it goes off, or else we'll process both
		// the single- and double-click functionality.
		
		KillTimer(doubleClickTimer);
		doubleClickTimer = 0;
		SetData("doubleClickTimer", doubleClickTimer);
		
		// NOTE: The single-click functionality is in the OnTimer message
		// insetad. Everything below this point is for double-clicking.
		
		// TODO: find the nearest valid target and follow them
		print("Fairy controller double clicked");
	}
}

// This script goes on the player. When the game starts, all necessary objects
// will be created and configured.
class J4FFairySetup extends SqRootScript
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
			
			// Assume they don't have the control item until we prove otherwise.
			local hasControlItem = false;
			// It may be possible to use the string directly everywhere we use
			// this variable, but it's probably less efficient than doing the
			// ID lookup once and storing the result. This approach was used
			// in the HolyH2O script sample as well.
			local controlItemId = ObjID("J4FFairyControlBell");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the control item?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FFairyControlBell as well, but that's not relevant
				// to this mod at the moment.)
				if ( Object.InheritsFrom(LinkDest(link), controlItemId) )
				{
					// The player already has the control item!
					hasControlItem = true;
					// So we can stop looking through their inventory.
					break;
				}
			}
			
			// If the player doesn't already have the control item...
			if (!hasControlItem)
			{
				// Then create one and give it to them.
				Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(controlItemId));
			}
        }
    }
}
