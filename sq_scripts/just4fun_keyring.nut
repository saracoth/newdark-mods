class J4FKeyringTarget extends SqRootScript
{
	// This happens when the player uses the item directly, as opposed to
	// using a key, lockpick, or other item on it.
	// NOTE: Using DarkUI.InvSelect() during OnFrobWorldBegin() can have
	// side effects in some cases. In Thief 1/Gold, rather than just selecting
	// the item, you begin to use the tool. For keys and key-like items, this
	// just focuses them on the world, but doesn't seem to apply them. For
	// lockpicks, it can begin the picking events, but in a weird way that
	// can, for example, cause the lock to continually play picking sounds
	// even after it's been opened. So we use OnFrobWorldEnd() instead.
	function OnFrobWorldEnd()
	{
		local frobMessage = message();
		
		// We only care when the player is frobbing. We can ignore NPCs and such.
		if (frobMessage.Frobber < 1 || !Object.InheritsFrom(frobMessage.Frobber, "Avatar"))
			return;
		
		// We only care when the frobbed object is currently locked.
		if (!Property.Possessed(self, "Locked") || !Property.Get(self, "Locked"))
			return;
		
		// Okay, the player has used a locked door. Do they have a key or pick?
		// More important than that, does the locked object even accept keys or
		// picks in the first place?
		
		// Accepting keys requires a KeyDst property, but also a non-zero region
		// mask. A region mask of 0 means no key will work.
		local wantsKeyRegion = Property.Possessed(self, "KeyDst") ? Property.Get(self, "KeyDst", "RegionMask") : 0;
		
		// If picks are accepted at all, which one(s) do we currently accept?
		local wantsPicks = 0;
		if (Property.Possessed(self, "PickCfg"))
		{
			switch (Property.Get(self, "PickState", "CurTumbler/State"))
			{
				case 0:
					wantsPicks = Property.Get(self, "PickCfg", "LockBits 1");
					break;
				case 1:
					wantsPicks = Property.Get(self, "PickCfg", "LockBits 2");
					break;
				case 2:
					wantsPicks = Property.Get(self, "PickCfg", "LockBits 3");
					break;
			}
		}
		
		// NOTE: There's also such a thing as the AdvPickStateCfg, but that
		// allows for much more sophisticated logic, and finding a correct
		// sequence of picking is beyond the scope of this mod. It would
		// essentially require pathfinding from the current pick state to
		// an unlocked state. Plus, any FMs using this feature likely intend
		// for selecting the correct pick to be a challenge, but this mod is
		// intended to deal with the annoyance of picking the obviously
		// correct item instead.
		// TODO: Based on the above comments, be wary of "Reset On Fail"
		// flags and disable pick auto-select for them as well?
		
		// If the locked item wants neither picks nor keys, nothing we can do.
		if (wantsPicks == 0 && wantsKeyRegion == 0)
			return;
		
		// All that's left is to see if the player has anything that'll work.
		// We already know the frobber is an Avatar, so we'll assume it's a
		// player. Their inventory is anything contained by them, per links.
		local playerInventory = Link.GetAll("Contains", frobMessage.Frobber);
		local foundItem = 0;
		
		// Search through the player's inventory, so they don't have to.
		foreach (link in playerInventory)
		{
			// Are you the keymaster?
			local inventoryItemId = LinkDest(link);
			
			// If we find a usable key, we can accept it right away.
			if (
				// We want keys.
				wantsKeyRegion != 0
				// We're looking at a key.
				&& Property.Possessed(inventoryItemId, "KeySrc")
				// The key is for our region.
				&& Key.TryToUseKey(inventoryItemId, self, eKeyUse.kKeyUseCheck)
			)
			{
				foundItem = inventoryItemId;
				// Stop looping through inventory items.
				break;
			}
			
			// If we find a usable lockpick, let's make a note of it, but keep looking.
			// We might find a key later, which would be even more betterer.
			if (
				// We want picks.
				wantsPicks != 0
				// We're looking at a pick.
				&& Property.Possessed(inventoryItemId, "PickSrc")
				// NOTE: CheckPick totally does not work as advertised. The third parameter
				// is ignored, and the return value is not a boolean. In fact, it
				// returns 0 for no match and 1 for a match, but it can also return a
				// value of 4 for things like not having certain properties set yet.
				// In fact, I've seen locks begin in such a state, before the player
				// attempts to pick them. In these circumstances, all picks will return
				// a "truthy" value of 4, even though some of those picks wouldn't work!
				// So PickLock.CheckPick() is only reliable after the player has begun to
				// pick the lock, or a level designer explicitly added a PickState property.
				//&& PickLock.CheckPick(inventoryItemId, self, wantsPickState)
				// And the pick matches!
				&& (Property.Get(inventoryItemId, "PickSrc") & wantsPicks) != 0
			)
			{
				foundItem = inventoryItemId;
			}
		}
		
		if (foundItem > 0)
		{
			// Success! We have a key or pick. Now select it.
			if (DarkUI.InvItem() != foundItem)
			{
				DarkUI.InvSelect(foundItem);
			}
		}
	}
}
