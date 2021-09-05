// This script goes on the equipment of interest.
class J4FRadarContainerTarget extends J4FRadarAbstractTarget
{
	constructor()
	{
		color = "B";
	}
	
	// Ignore empty containers.
	function BlessItem(itemToBless)
	{
		// Bless if has at least one item inside.
		return Link.GetOne("Contains", itemToBless) > 0;
	}
}
