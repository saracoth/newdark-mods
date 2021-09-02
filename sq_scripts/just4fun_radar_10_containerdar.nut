// This script goes on pingable items, to generate a visible puff in response
// to a ping.
class J4FSpawnContainerPolo extends SqRootScript
{
	function OnJ4FRadarPingStimStimulus()
	{
		// This function will fire when a container has been pinged.
		// But let's first check to see if there are any Contains links,
		// meaning the container actually has something in it.
		local anyLink = Link.GetOne("Contains", self);
		
		// Empty.
		if (anyLink <= 0)
			return;
		
		// Otherwise, the container is probably intersting to us and should
		// respond to the ping.
		
		// Several example .nut scripts do something similar. This should be
		// slightly more efficient than creating two zero vectors later.
		local zeros = vector(0);
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it, similar to create_obj receptrons.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FRadarPuffContainerPolo");
		// Now we place the new object on top of the radar-detected item.
		Object.Teleport(summon, zeros, zeros, self);
		// Now we're done setting up the new object instance.
		Object.EndCreate(summon);
	}
}