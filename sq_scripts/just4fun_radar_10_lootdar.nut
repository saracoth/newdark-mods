// This script goes on the Marco/Ping puff, to reach to Polo/Pong responses
// from items of interest. We will create a visible puff on those items.
class J4FRadarLootTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		color = "Y";
	}
	
	// Ignore decorative/etc. "loot" we can't pick up.
	function BlessItem()
	{
		return base.BlessItem() && IsPickup();
	}
}
