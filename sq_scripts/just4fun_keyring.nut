class J4FKeyringTarget extends SqRootScript
{
	// This happens when the player uses the item directly, as opposed to
	// using a key, lockpick, or other item on it.
	function OnFrobWorldBegin()
	{
		local frobMessage = message();
		
		// We only care when the player is frobbing. We can ignore NPCs and such.
		if (frobMessage.Frobber < 1 || !Object.InheritsFrom(frobMessage.Frobber, "Avatar"))
			return;
		
		// We only care when the frobbed object is currently locked.
		if (!Property.Possessed(self, "Locked") || !Property.Get(self, "Locked"))
			return;
		
		// Okay, the player has used a locked door. Do they have a key?
		// More important than that, does a key exist, period? Check to see
		// if the frobbed object cares about keys.
		if (!Property.Possessed(self, "KeyDst"))
			return;
		
		// Great, the frobbed object accepts keys, if we have one. Do we?
		// First, figure out the accepted region(s). While DromEd and the DML
		// files specify these as bit strings, like 1101 for 13, in scripting
		// we have access to these as actual integers. That makes it easy to
		// do a "bitwise and" to see if there's any overlap in regions between
		// lock and key.
		local wantRegion = Property.Get(self, "KeyDst", "RegionMask");
		
		// Turns out the locked item doesn't accept any regions at all, so
		// no keys will ever work for it.
		if (wantRegion == 0)
			return;
		
		// Great, so a key can be accepted. Which one, specifically?
		local wantKey = Property.Get(self, "KeyDst", "LockID");
		
		// All that's left is to see if the player has anything that'll work.
		// We already know the frobber is an Avatar, so we'll assume it's a
		// player. Their inventory is anything contained by them, per links.
		local playerInventory = Link.GetAll("Contains", frobMessage.Frobber);
		
		// Search through the player's inventory, so they don't have to.
		foreach (link in playerInventory)
		{
			// Are you the keymaster?
			local inventoryItemId = LinkDest(link);
			
			// If it doesn't have key data, we don't care.
			if (!Property.Possessed(inventoryItemId, "KeySrc"))
				continue;
			
			// Does this key work for us?
			if (
				(Property.Get(inventoryItemId, "KeySrc", "RegionMask") & wantRegion) != 0
				&& (
					Property.Get(inventoryItemId, "KeySrc", "LockID") == wantKey
					|| Property.Get(inventoryItemId, "KeySrc", "MasterBit")
				)
			)
			{
				// Success! We have the key. Now select it and stop
				// looping through inventory items.
				if (DarkUI.InvItem() != inventoryItemId)
				{
					DarkUI.InvSelect(inventoryItemId);
				}
				
				// Exit the inventory items loop.
				break;
			}
		}
	}
}
