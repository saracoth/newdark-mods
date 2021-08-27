// This script adds or removes the ghost mode metaproperty and related effects.
// It's used to work around some receptron limitations in DML files.
class J4FGhostPlayerController extends SqRootScript
{
	function OnJ4FGhostModeStimStimulus()
	{
		// Used for debugging purposes. These messages show up in the THIEF.LOG
		// or THIEF2.LOG files.
		//print(format("Player stimulated %g!", message().intensity));
		
		// NOTE: The self keyword/variable refers to the player the script is
		// attached to. It's similar to the "Me" keyword in the receptrons we're
		// emulating. We also have access to a message().source and
		// message().sensor value if we need them.
		
		if (message().intensity < 2.0)
		{
			// Smaller stim values means entering ghost mode.
			
			// Add the ghost mode metaproperty. This is emulating an add_metaprop
			// receptron effect.
			Object.AddMetaProperty(self, "J4FGhostMode");
			
			// Copy the collision type metaproperty from the metaproperty. This
			// emulates an add_prop receptron effect.
			Property.CopyFrom(self, "CollisionType", "J4FGhostMode")
			
			// Same for the fungus flag.
			Property.CopyFrom(self, "Fungus", "J4FGhostMode")
		}
		else
		{
			// Larger stim values means leaving ghost mode.
			
			// Remove the ghost mode metaproperty. This is emulating a rem_metaprop
			// receptron effect.
			Object.RemoveMetaProperty(self, "J4FGhostMode");
			
			// NOTE: We currently do this with plain old receptrons and don't need
			// the script. See the DML file for details. If DML files supported
			// names in Agent and Target keywords, we could eliminate the entire
			// J4FGhostPlayerController script and use receptrons for all of this.
			// Property.CopyFrom(self, "CollisionType", "Garrett");
			
			// Same for the fungus flag.
			// Property.CopyFrom(self, "Fungus", "Garrett")
		}
	}
}

// This script changes the ghost toggler item itself, which changes names and
// behaviors back-and-forth each time it's used. This script is used to work
// around some receptron limitations in DML files.
class J4FGhostTogglerController extends SqRootScript
{
	function OnJ4FGhostModeStimStimulus()
	{
		// Used for debugging purposes. These messages show up in the THIEF.LOG
		// or THIEF2.LOG files.
		//print(format("Toggler stimulated %g!", message().intensity));
		
		// Similar to the J4FGhostPlayerController, self refers to the object
		// the script is attached to. In this case, the toggler item.
		
		if (message().intensity < 4.0)
		{
			// Small stims mean the player is entering ghost mode. Next time the
			// item is used, we want it to take the player out of ghost mode.
			
			// Copy the name property. This emulates an add_prop receptron.
			Property.CopyFrom(self, "GameName", "J4FGhostTogglerOff");
			// Granted, we could skip directly to the intended end result and do
			// this instead:
			//Property.SetSimple(self, "GameName", "name_j4f_ghost_toggle_off: \"Ghost Off\"");
			
			// Also copy the Act/React: Source Scale property.
			Property.CopyFrom(self, "arSrcScale", "J4FGhostTogglerOff");
		}
		else
		{
			print("Toggler negative!");
			// Larger stims mean the player is leaving ghost mode. Next time the
			// item is used, we want it to put the player into ghost mode.
			
			// Copy the name property. This emulates an add_prop receptron.
			Property.CopyFrom(self, "GameName", "J4FGhostTogglerOn");
			// Granted, we could skip directly to the intended end result and do
			// this instead:
			//Property.SetSimple(self, "GameName", "name_j4f_ghost_toggle_on: \"Ghost On\"");
			
			// Also copy the Act/React: Source Scale property.
			Property.CopyFrom(self, "arSrcScale", "J4FGhostTogglerOn");
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
