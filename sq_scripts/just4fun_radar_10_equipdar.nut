// This script goes on pingable items, to generate a visible puff in response
// to a ping.
class J4FSpawnEquipPolo extends SqRootScript
{
	function OnJ4FRadarPingStimStimulus()
	{
		// Several example .nut scripts do something similar. This should be
		// slightly more efficient than creating two zero vectors later.
		local zeros = vector(0);
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it, similar to create_obj receptrons.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FRadarPuffEquipPolo");
		// Now we place the new object on top of the radar-detected item.
		Object.Teleport(summon, zeros, zeros, self);
		// Now we're done setting up the new object instance.
		Object.EndCreate(summon);
	}
}