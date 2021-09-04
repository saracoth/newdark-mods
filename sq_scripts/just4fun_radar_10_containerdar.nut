// This script goes on pingable items, to generate a visible puff in response
// to a ping.
class J4FSpawnContainerPolo extends J4FSpawnAbstractPolo
{
	constructor()
	{
		puffName = "J4FRadarPuffContainerPolo";
	}
	
	// Ignore empty containers.
	function BlessItem(itemToBless)
	{
		// Bless if has at least one item inside.
		return Link.GetOne("Contains", itemToBless) > 0;
	}
}
