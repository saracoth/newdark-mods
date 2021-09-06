// This script goes on the equipment of interest.
class J4FRadarDeviceTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		color = "P";
	}
	
	// Ignore invisible devices, which are sometimes used by
	// mission authors to trigger scripted events. Note that
	// we don't check IsPickup(), because that would prevent
	// pressure plates from being indicated.
	function BlessItem()
	{
		return base.BlessItem() && IsRendered();
	}
}
