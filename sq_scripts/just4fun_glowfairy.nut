// =============================================================================
// This script goes on the control inventory item.
class J4FFairyController extends SqRootScript
{
	// Given the way the NewDark squirrel documentation is written, feels like
	// everything is slow and expensive. So let's preemptively limit our use of
	// GetData() by giving us a spot to store that info.
	playerId = 0;
	fairyId = 0;
	maxRange = 100;
	
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
		
		maxRange = userparams().MaxRange;
	}
	
	/*
What events can we expect to see? From what I can tell, we get these on creation:
: OSM: SQUIRREL> Fairy controller: BeginScript
: OSM: SQUIRREL> Fairy controller: Create
: OSM: SQUIRREL> Fairy controller: Contained

Contained seems ideal to me, since we can get a reference to the avatar we're
contained by. However, if we associate any setup or behavior with this, we'll
want to be wary of anything that takes us out of the inventory or puts us back.
For example, there was a demo that allowed a player to swap between two
characters, and I think it did it through a combination of teleporting and also
shifting inventory around.

And these on game load:
: OSM: SQUIRREL> Fairy controller: Sim
: OSM: SQUIRREL> Fairy controller: EndScript
: Loaded script module "miss01.osm" [FileModDate=1999-Sep-28]
: OSM: SQUIRREL> Fairy controller: EndScript
: OSM: SQUIRREL> Fairy controller: BeginScript

Is the second EndScript happening after the load or before? Judging by the fact
it happens twice at all, and the second one seems to come after mission files
have been loaded again, I'm tempted to assume it happens after the reload.

In any case, BeginScript might be handy after a reload, provided we keep track
of whether we've ever had Create or Contained fire off.

	function OnMessage()
	{
		print(format("Fairy controller: %s", message().message));
	}
	*/
	
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
		
		// TODO: who is responsible for creating the NPC and when? How should
		// we keep track of those things in safe way that persists across
		// saving/loading games?
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FFairy");
		// Here we use that to set the new object's position before we
		// finish creating it.
		Object.Teleport(summon, vector(5, 0, 0), vector(0), playerId);
		// Now we're done.
		Object.EndCreate(summon);
		
		SetData("fairyId", summon);
		fairyId = summon;
		
		// Begin following gaze.
		SetOneShotTimer("J4FFairyGaze", 0.25);
	}
	
	function OnTimer()
	{
		local timerName = message().name;
		switch (timerName)
		{
			case "J4FFairyGaze":
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
				
				local targetPos = (direction * maxRange) + camPos;
				
				// Assuming PortalRaycast() returns true, this contains our
				// point of impact.
				local gazeTarget = vector(0);
				
				if (Engine.PortalRaycast(camPos, targetPos, gazeTarget))
				{
					// The gazeTarget is touching some piece of level geometry.
					// So if we place the center point of our object right at
					// that spot, it will be partly inside and partly outside
					// the level boundaries.
					//
					// So we'd like to pull the target point back a little closer
					// to the camera. To do that, we first figure out what
					// distance gazeTarget is from the camera. We'll use the
					// https://gamedev.stackexchange.com/a/92521 approach.
					
					local displacement = gazeTarget - camPos;
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
						gazeTarget = camPos;
					}
					else
					{
						// Here's that directional vector again, doing the same
						// job as before but with a smaller distance.
						gazeTarget = (direction * (impactDistance - 2)) + camPos;
					}
				}
				else
				{
					// Ray tracing said there are no obstacles in our way.
					//
					// I don't see where it's defined what the PortalRaycast()
					// function does to the third parameter when there is no
					// impact. So to be on the safe side, we'll explicitly say
					// the gazeTarget is max-distance targetPos instead.
					gazeTarget = targetPos;
				}
				
				// Teleport() with only three parameters has no frame-of-reference
				// object. So the gazeTarget coordinates will be treated as absolute
				// game-world coordinates, instead of coordinates relative to some
				// reference object.
				// We use Object.Facing() to get and preserve the fairy's current
				// facing, if any.
				Object.Teleport(fairyId, gazeTarget, Object.Facing(fairyId));
				
				// Repeat.
				SetOneShotTimer("J4FFairyGaze", 0.25);
				
				break;
		}
	}
	
	function OnFrobInvEnd()
	{
		print("Fairy controller frobbed");
		// TODO: teleport or toggle between modes
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
