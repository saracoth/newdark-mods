// This script goes on the summoning object itself. When used from inventory,
// it spawns a minion a short distance in front of the user/player.
class J4FSpawnJustAhead extends SqRootScript
{
	function OnFrobInvEnd()
	{
		// Create a new instance of J4FSummonedSwordGuy in the game world,
		// then immediately teleport it. It will be placed 5 units in front
		// of the player/user/frobber, and will have the same facing and
		// orientation as the player/user/frobber.
		//
		// Rather than hard-code the "J4FSummonedSwordGuy" string, we
		// refer to the userparams(), which come from the summoning
		// item's "Design Notes" property. This allows mods of this mod
		// to change what kind of minion the token spawns.
		
		// Start the creation process. This may be better than using just
		// Object.Create() in some cases.
		local summon = Object.BeginCreate(userparams().J4FMinionType);
		// Here we use that to set the new object's position before we
		// finish creating it.
		Object.Teleport(summon, vector(5, 0, 0), vector(0), message().Frobber);
		// Now we're done.
		Object.EndCreate(summon);
		
		// NOTE: In practice, the following one-liner worked equally well.
		// Object.Teleport(Object.Create(userparams().J4FMinionType), vector(5, 0, 0), vector(0), message().Frobber);
	}
}

// This script goes on the minion to give it a time limit.
class J4FTimedSummon extends SqRootScript
{
	// We only need this script to fire once, when the minion is first spawned.
    function OnCreate()
	{
		// Give it however many seconds to live.
		SetOneShotTimer("J4FSummonExpire", userparams().J4FMinionDuration);
    }
	
	// This will fire for any timer event on the object this script is attached to.
    function OnTimer()
	{
		// So let's make sure it's an event from the timer we actually care about.
        if (message().name == "J4FSummonExpire")
		{
			// The minion's time limit has expired, and it's time to go.
			Object.Destroy(self);
        }
    }
}

// This script goes on the player with the ability to summon stuff.
// They will be given the summoning object when the game starts.
class J4FSummoner extends SqRootScript
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
			
			// Assume they don't have the summon item until we prove otherwise.
			local hasSummonItem = false;
			// It may be possible to use the string directly everywhere we use
			// this variable, but it's probably less efficient than doing the
			// ID lookup once and storing the result. This approach was used
			// in the HolyH2O script sample as well.
			local summonItemId = ObjID("J4FSummoningToken");
			
			// Loop through everything in the player's inventory to find the token.
			foreach (link in playerInventory)
			{
				// Is the inventory item an instance of the summoning token?
				// (InheritsFrom *might* also detect other kinds of items based
				// on the J4FSummoningToken as well, but that's not relevant
				// to this mod at the moment.)
				if ( Object.InheritsFrom(LinkDest(link), summonItemId) )
				{
					// The player already has the summoning item!
					hasSummonItem = true;
					// So we can stop looking through their inventory.
					break;
				}
			}
			
			// If the player doesn't already have the summoning item...
			if (!hasSummonItem)
			{
				// Then create one and give it to them.
				Link.Create(LinkTools.LinkKindNamed("Contains"), self, Object.Create(summonItemId));
			}
        }
    }
}
