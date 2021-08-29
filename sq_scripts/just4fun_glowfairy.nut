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
	followerSearchTimer = 0;
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
	followTarget = 0;
	
	// If true, we've replaced the followerSearchTimer with one that will
	// hopefully trigger sooner.
	fastFollowerTimer = false;
	
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
			doubleClickTimer = GetData("doubleClickTimer");
		}
		
		if (IsDataSet("followTarget"))
		{
			followTarget = GetData("followTarget");
		}
		
		if (IsDataSet("followerSearchTimer"))
		{
			followerSearchTimer = GetData("followerSearchTimer");
		}
		
		if (IsDataSet("fastFollowerTimer"))
		{
			fastFollowerTimer = GetData("fastFollowerTimer");
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
		homeId = Object.BeginCreate("TerrPt");
		Object.Teleport(homeId, farAway, zeros, playerId);
		Object.EndCreate(homeId);
		SetData("homeId", homeId);
		
		// Now we can the second marker.
		markerId = Object.BeginCreate("TerrPt");
		Object.Teleport(markerId, farAway, zeros, playerId);
		Object.EndCreate(markerId);
		SetData("markerId", markerId);
		
		// With both markers on the map, we can create a loop between them.
		local homeToMarker = Link.Create("TPath", homeId, markerId);
		local markerToHome = Link.Create("TPath", markerId, homeId);
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
		fairyId = Object.BeginCreate("J4FFairy");
		Object.Teleport(fairyId, farAway, zeros, playerId);
		local fairyToHome = Link.Create("TPathInit", fairyId, homeId);
		Object.EndCreate(fairyId);
		SetData("fairyId", fairyId);
		
		// Give the fairy a reference to us.
		SendMessage(fairyId, "ControllerHello", self);
		
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
					// Following a specific ingame creature.
					// TODO: adjust position to fly above them?
					// TODO: detect deleted, invalid, and dead targets; halt
					
					targetPos = Object.Position(followTarget);
				}
				
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
			case "J4FFollowerFinalize":
				// If this timer goes off, that means we're done searching for
				// follow candidates. Either we've found one or we haven't.
				
				// For starters, forget the whole timer thing. It's gone off and the
				// handle is useless now.
				followerSearchTimer = 0;
				SetData("followerSearchTimer", followerSearchTimer);
				
				// Force 0 for fairy stim values.
				Property.SetSimple(fairyId, "arSrcScale", 0.0);
				
				// We've already picked our best target, if any. What did we find?
				
				// Let the player know what we're doing.
				if (followTarget == playerId)
				{
					// Fairy decided the player was their best match.
					Property.SetSimple(self, "GameName", "name_j4f_fairy_controller_lonely: \"Tinker's Bell (Loves You)\"");
				}
				else if (followTarget > 0)
				{
					// Fairy decided to stick around some other creature.
					Property.SetSimple(self, "GameName", "name_j4f_fairy_controller_lonely: \"Tinker's Bell (Following)\"");
				}
				else
				{
					// Fairy was put into halt mode for the search, and there it will stay.
					Property.SetSimple(self, "GameName", "name_j4f_fairy_controller_lonely: \"Tinker's Bell (Lonely)\"");
				}
				
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
		// instead. Everything below this point is for double-clicking.
		
		// Finding a target to follow is a multi-step, asynchronous process.
		// We can't get a list of nearby suitable targets ourselves, and must
		// instead rely on the Act/React system's radius stimulations to do
		// it for us. However, we can't trigger a radius stim either. Instead,
		// the fairy must be constantly bursting its check in a radius. So
		// we normally "disable" it by setting the fairy's arSrcScale to 0.
		// That multiplies all incoming and outgoing stims by 0. This doesn't
		// stop the radius effect, but it means that creatures/etc. will
		// receive a 0 and should ignore it.
		
		// So, step 1 in this follower candidate finding process:
		// Allow normal fairy stim values.
		
		// Now, because this is an asychronous process, that means other stuff
		// can happen while we're waiting for the final results. That can
		// include the player double clicking us a second time. So before we
		// do anything, check whether the fairy is already "on."
		
		if (followerSearchTimer != 0)
		{
			// Fairy is already sending stimuli to nearby creatures. Just wait.
			return;
		}
		
		// Otherwise, we need to kick off the process.
		// Allow normal fairy stim values.
		Property.SetSimple(fairyId, "arSrcScale", 1.0);
		
		// Let the player know what we're doing.
		Property.SetSimple(self, "GameName", "name_j4f_fairy_controller_search: \"Tinker's Bell (Searching)\"");
		
		// Now we wait. But what does waiting mean, exactly? For starters, the
		// fairy is pulsing its search once per X seconds. So we have to wait at
		// least that long to be sure no creatures were in the area.
		followerSearchTimer = SetOneShotTimer("J4FFollowerFinalize", 0.6);
		SetData("followerSearchTimer", followerSearchTimer);
		
		//In practice, we might not have to wait as long, so we could end up
		// replacing this timer with a (hopefully) shorter one once at least
		// one candidate responds.
		fastFollowerTimer = false;
		SetData("fastFollowerTimer", fastFollowerTimer);
		
		// While we wait, maybe we should stop moving around.
		followTarget = 0;
		SetData("followTarget", followTarget);
	}
	
	function OnFollowCandidate()
	{
		// The fairy passed the candidate's object ID number in the data.
		local candidateId = message().data;
		
		// If we haven't created a fast timer yet, do so now. This allows
		// faster responses on average, since when there's a candidate in
		// range we only have to wait for the next fairy radius stim. If
		// not, we have to wait out the full second to be sure there weren't
		// any creatures in range. That's because we can't know, when the
		// user has double-clicked the controller, how long we'll have to
		// wait for the next time. On average, the fairy will be only 0.5s
		// away from the next burst, not 1s.
		if (!fastFollowerTimer)
		{
			if (followerSearchTimer != 0)
			{
				KillTimer(followerSearchTimer);
			}
			
			// Instead of waiting the full 1.1 seconds, we'll wait an additional 10ms
			followerSearchTimer = SetOneShotTimer("J4FFollowerFinalize", 0.01);
			SetData("followerSearchTimer", followerSearchTimer);
			
			// Don't need to keep creating timers. One replacement is enough.
			fastFollowerTimer = true;
			SetData("fastFollowerTimer", fastFollowerTimer);
		}
		
		// If this is our first candidate, accept them.
		if (followTarget < 1)
		{
			followTarget = candidateId;
			return;
		}
		
		// Otherwise, figure out which of the two is closer to the fairy.
		// Refer to comments in other code for how we're using the dot
		// product to figure out distances.
		local fairyPos = Object.Position(fairyId);
		
		local currentDisplacement = Object.Position(followTarget) - fairyPos;
		local currentDistance = sqrt(currentDisplacement.Dot(currentDisplacement));
		
		local candidateDisplacement = Object.Position(candidateId) - fairyPos;
		local candidateDistance = sqrt(candidateDisplacement.Dot(candidateDisplacement));
		
		// If the new candidate is closer, they win.
		if (candidateDistance < currentDistance)
		{
			followTarget = candidateId;
		}
	}
}

class J4FFairyIntermediary extends SqRootScript
{
	// Given the way the NewDark squirrel documentation is written, feels like
	// everything is slow and expensive. So let's preemptively limit our use of
	// GetData() by giving us a spot to store that info.
	// Object IDs
	myControllerId = 0;
	
	function OnBeginScript()
	{
		if (IsDataSet("myControllerId"))
		{
			myControllerId = GetData("myControllerId");
		}
	}
	
	function OnControllerHello()
	{
		// Our controller has finished creating us, and we can keep track of them
		// for future reference.
		myControllerId = message().data;
		SetData("myControllerId", myControllerId);
	}
	
	function OnJ4FFryFllwStimStimulus()
	{
		// We only care about positive values here.
		if (message().intensity <= 0)
			return;
		
		// message() for a stimulus includes a source and a sensor property.
		// These are LinkIDs, not ObjIDs. So to get the objects themselves,
		// we need to turn the numeric link ID into an sLink object. Now
		// we can access the .source and .dest properties of the link.
		local link = sLink();
		LinkTools.LinkGet(message().source, link);
		
		// Pass the potential target on to my controller.
		SendMessage(myControllerId, "FollowCandidate", link.source);
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
