// This script goes on the equipment of interest.
class J4FRadarContainerTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		color = "B";
	}
	
	// Ignore empty containers.
	function BlessItem()
	{
		// Bless if has at least one item inside.
		// Also require IsPickup() to be sure we can try to open it.
		return base.BlessItem() && (Link.GetOne("Contains", self) > 0) && IsPickup() && IsRendered();
	}
}
