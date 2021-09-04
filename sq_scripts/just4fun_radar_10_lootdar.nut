// This script goes on the Marco/Ping puff, to reach to Polo/Pong responses
// from items of interest. We will create a visible puff on those items.
class J4FSpawnLootPolo extends J4FSpawnAbstractPolo
{
	constructor()
	{
		puffName = "J4FRadarPuffLootPolo";
	}
	
	// TODO: bless only non-zero loot value? to ignore loot used as decoration
	
	// Because we're targeting things with the IsLoot metaproperty, we can't
	// assign scripts as safely and easily as other radar types. As a result,
	// we can only have the IsLoot items throw the ping to a different object
	// with this script. The loot item iself is the source of the ping stim!
	function GetPingedItem()
	{
		// message() for a stimulus includes a source and a sensor property.
		// These are LinkIDs, not ObjIDs. So to get the objects themselves,
		// we need to turn the numeric link ID into an sLink object. Now
		// we can access the .source and .dest properties of the link.
		// TODO:
		//return sLink(message().source).source;
		// TODO: testing
		return self;
	}
	
	// Given the weird setup of stims and such, this script needs to respond
	// to a nonstandard stim.
	function OnJ4FR_LootStimStimulus()
	{
		base.OnJ4FRadarPingStimStimulus();
	}
	
	// And it can ignore the standard one.
	function OnJ4FRadarPingStimStimulus()
	{
		// TODO: testing
		base.OnJ4FRadarPingStimStimulus();
		// TODO: testing
		//return;
	}
}
