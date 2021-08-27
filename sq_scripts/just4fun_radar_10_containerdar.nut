// This script goes on the Marco/Ping puff, to reach to Polo/Pong responses
// from items of interest. We will create a visible puff on those items.
class J4FSpawnContainerPolo extends SqRootScript
{
	function OnJ4FR_ContnrStimStimulus()
	{
		// message() for a stimulus includes a source and a sensor property.
		// These are LinkIDs, not ObjIDs. So to get the objects themselves,
		// we need to turn the numeric link ID into an sLink object. Now
		// we can access the .source and .dest properties of the link.
		local link = sLink();
		LinkTools.LinkGet(message().source, link);
		
		// Several example .nut scripts do something similar. This should be
		// slightly more efficient than creating two zero vectors later.
		local zeros = vector(0);
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it, similar to create_obj receptrons.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FRadarPuffContainerPolo");
		// Now we place the new object on top of the radar-detected item
		// that triggered this stim.
		Object.Teleport(summon, zeros, zeros, link.source);
		// Now we're done setting up the new object instance.
		Object.EndCreate(summon);
	}
}