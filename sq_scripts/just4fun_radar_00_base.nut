// This script goes on the player. When receiving the appropriate stimulus,
// spawn a marco puff on the scripted object. In this case, the player.
class J4FSpawnMarco extends SqRootScript
{
	function OnJ4FRadarStimStimulus()
	{
		// This On<stim>Stimulus function will be called when the player
		// receives that kind of stim.
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it. This is equivalent to
		// the commented-out create_obj receptron in the DML file.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FLootPuffMarco");
		// Here we use that to set the new object's position before we
		// finish creating it.
		Object.Teleport(summon, vector(0, 0, 0), vector(0), self);
		// Now we're done.
		Object.EndCreate(summon);
		
		// NOTE: In practice, the following one-liner worked equally well.
		// Object.Teleport(Object.Create("J4FLootPuffMarco"), vector(0, 0, 0), vector(0), self);
	}
}

// This script goes on the player. When receiving the appropriate stimulus,
// spawn a marco puff on the scripted object. In this case, the loot.
class J4FSpawnPolo extends SqRootScript
{
	function OnJ4FRadarStimStimulus()
	{
		// This On<stim>Stimulus function will be called when the player
		// receives that kind of stim.
		
		// Create a new instance of our puff in the game world,
		// then immediately teleport it. This is equivalent to
		// the commented-out create_obj receptron in the DML file.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate("J4FLootPuffPolo");
		// Here we use that to set the new object's position before we
		// finish creating it.
		Object.Teleport(summon, vector(0, 0, 0), vector(0), self);
		// Now we're done.
		Object.EndCreate(summon);
		
		// NOTE: In practice, the following one-liner worked equally well.
		// Object.Teleport(Object.Create("J4FLootPuffPolo"), vector(0, 0, 0), vector(0), self);
	}
}

// This script will be called on the player when the game starts, giving them the radar item.
class J4FGiveRadarItem extends SqRootScript
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
			
			// Assume they don't have the radar item until we prove otherwise.
			local hasRadarItem = false;
			// It may be possible to use the string directly everywhere we use
			// this variable, but it's probably less efficient than doing the
			// ID lookup once and storing the result. This approach was used
			// in the HolyH2O script sample as well.
			local radarItemId = ObjID("J4FRadarMarcoItem");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the radar item?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FRadarMarcoItem as well, but that's not relevant
				// to this mod.)
				if ( Object.InheritsFrom(LinkDest(link), radarItemId) )
				{
					// The player already has the radar item!
					hasRadarItem = true;
					// So we can stop looking through their inventory.
					break;
				}
			}
			
			// If the player doesn't already have the radar item...
			if (!hasRadarItem)
			{
				// Then create one and give it to them.
				Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(radarItemId));
			}
        }
    }
}
