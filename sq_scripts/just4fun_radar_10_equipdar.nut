// This script goes on the equipment of interest.
class J4FRadarEquipTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		color = "G";
	}
	
	// Ignore decorative/etc. equipment we can't pick up.
	function BlessItem()
	{
		return base.BlessItem() && IsPickup();
	}
}
