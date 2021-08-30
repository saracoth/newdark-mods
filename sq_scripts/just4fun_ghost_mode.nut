// This script adds or removes the ghost mode metaproperty. When adding it,
// we also change the player's gravity in a similar fashion as a slow-fall
// potion.
class J4FGhostModeToggle extends SqRootScript
{
	function OnFrobInvEnd()
	{
		// Grab some stuff for very minor efficiency boost.
		local ghostMetaproperty = ObjID("J4FGhostMode");
		local frobber = message().Frobber;
		
		// NOTE: Because this script is attached to the toggle item
		// itself, "self" refers to that item. The frobber is the player
		// who used this item. So this one function can alter both
		// the player and the toggle item in one go.
		
		// Is the player already in ghost mode?
		if (Object.HasMetaProperty(frobber, ghostMetaproperty))
		{
			// Change the toggle item name so it's clearer what will happen when we use it next.
			Property.SetSimple(self, "GameName", "name_j4f_ghost_toggle_on: \"Ghost On\"");
			
			// Back to normal, by means of removing the metaproperty.
			// If we somehow ended up with multiple copies, remove them all.
			// This is pure paranoia / defensive coding, vs just calling
			// RemoveMetaProperty once without the loop.
			while (Object.HasMetaProperty(frobber, ghostMetaproperty))
			{
				Object.RemoveMetaProperty(frobber, ghostMetaproperty);
			}
			
			// Back to normal gravity. It may be possible the player's gravity
			// should go back to some other weird value, but standard slow-fall
			// potions also assume 100% gravity when they expire. In any case,
			// this ghost mode mod allows players to break levels in all kinds
			// of ways already.
			Physics.SetGravity(frobber, 1.0);
			
			// For some reason, setting physics collision types with a
			// metaproperty seems to have no effect. So we're managing that
			// by hand instead.
			Property.CopyFrom(frobber, "CollisionType", "Garrett");
			// Same for the Fungus property.
			Property.SetSimple(frobber, "Fungus", false);
		}
		else
		{
			// Change the toggle item name so it's clearer what will happen when we use it next.
			Property.SetSimple(self, "GameName", "name_j4f_ghost_toggle_off: \"Ghost Off\"");
			
			// Add the ghost mode metaproperty.
			Object.AddMetaProperty(frobber, ghostMetaproperty);
			
			// Halve gravity.
			Physics.SetGravity(frobber, 0.5);
			
			// Halve the current falling velocity, if already falling.
			local velocity = vector(0);
			// This function does not return a value, but instead changes the velocity variable we pass in.
			Physics.GetVelocity(frobber, velocity);
			// Negative Z-axis velocity means we're moving down (falling).
			if (velocity.z < 0)
			{
				velocity.z /= 2;
				Physics.SetVelocity(frobber, velocity);
			}
			
			// For some reason, setting physics collision types with a
			// metaproperty seems to have no effect. So we're managing that
			// by hand instead.
			Property.CopyFrom(frobber, "CollisionType", ghostMetaproperty);
			// Same for the Fungus property.
			Property.SetSimple(frobber, "Fungus", true);
		}
	}
}

// This script will be called on the player when the game starts, giving them the toggle item.
class J4FGhostToggleGiver extends SqRootScript
{
	// We only need this script to fire once, when the game simulation first starts.
    function OnSim()
	{
        if (message().starting)
		{
			// Assuming this script is attached to a player, "self" refers
			// to that player. Every object with a "Contains" type link is
			// stuff in the player's inventory.
			local playerInventory = Link.GetAll("Contains", self);
			
			// Assume they don't have the toggle item until we prove otherwise.
			local hasToggleItem = false;
			// It may be possible to use the string directly everywhere we use
			// this variable, but it's probably less efficient than doing the
			// ID lookup once and storing the result. This approach was used
			// in the HolyH2O script sample as well.
			local toggleItemId = ObjID("J4FGhostToggler");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the toggle item?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FGhostToggler as well, but that's not relevant
				// to this mod.)
				if ( Object.InheritsFrom(LinkDest(link), toggleItemId) )
				{
					// The player already has the toggle item!
					hasToggleItem = true;
					// So we can stop looking through their inventory.
					break;
				}
			}
			
			// If the player doesn't already have the toggle item...
			if (!hasToggleItem)
			{
				// Then create one and give it to them.
				Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(toggleItemId));
			}
        }
    }
}
