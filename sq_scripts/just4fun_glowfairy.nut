// This script goes on the control inventory item.
class J4FFairyController extends SqRootScript
{
	function OnFrobInvEnd()
	{	
		// TODO: who is responsible for creating the NPC and when? How should
		// we keep track of those things in safe way that persists across
		// saving/loading games?
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FFairy");
		// Here we use that to set the new object's position before we
		// finish creating it.
		Object.Teleport(summon, vector(5, 0, 0), vector(0), message().Frobber);
		// Now we're done.
		Object.EndCreate(summon);
	}
}

// This script goes on the player. When the game starts, all necessary objects
// will be created and configured.
class J4FFairySetup extends SqRootScript
{
	// We only need this script to fire once, when the game simulation first starts.
    function OnSim()
	{
        if (message().starting)
		{
			// Assuming this script is attached to the player, "self" refers
			// to that player. Every object with a "Contains" type link is
			// stuff in the player's inventory.
			local playerInventory = Link.GetAll("Contains", self);
			
			// Assume they don't have the control item until we prove otherwise.
			local hasControlItem = false;
			// It may be possible to use the string directly everywhere we use
			// this variable, but it's probably less efficient than doing the
			// ID lookup once and storing the result. This approach was used
			// in the HolyH2O script sample as well.
			local controlItemId = ObjID("J4FFairyControlBell");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the control item?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FFairyControlBell as well, but that's not relevant
				// to this mod at the moment.)
				if ( Object.InheritsFrom(LinkDest(link), controlItemId) )
				{
					// The player already has the control item!
					hasControlItem = true;
					// So we can stop looking through their inventory.
					break;
				}
			}
			
			// If the player doesn't already have the control item...
			if (!hasControlItem)
			{
				// Then create one and give it to them.
				Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(controlItemId));
			}
        }
    }
}
