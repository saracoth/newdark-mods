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
		// First, figure out the accepted region(s). These are available to us
		// as bit strings, like 1101 for 8+4+1=13. Squirrel can do bitwise
		// operators, but only if we convert this into an actual integer type.
		// At that point, we have to go through the effort of enumerating
		// through the characters of each string ourselves. So let's skip the
		// bitwise operators, with the hopes we can exit the looping early in
		// many cases.
		//
		// To prepare for this, we need to have some frame of reference. We'll
		// create an array of enabled bits indices for the locked object. Then,
		// when looping through regions on key items, we only need to check
		// those specific indexes. Continuing the above example, given a key
		// set to region 11, we only need to check the rightmost bit.
		local checkBits = array(0);
		local wantRegion = Property.Get(self, "KeyDst", "RegionMask");
		
		// TODO:
		print(format("Want region is %s", typeof wantRegion));
		
		// TODO:
		print(format("Want region %s", wantRegion));
		
		// Loop backwards, so we only need to check the len() property once,
		// and because it doesn't really matter which direction we work in.
		// Also doing the modification of i in the same place we check its
		// value, decrementing it before the check. This construct can
		// be more efficient overall by reducing total number of operations.
		// Some compilers and interpreters do stuff like this under the
		// hood as well.
        for (local i = wantRegion.len(); --i > -1; ) {
			// ASCII character 49 is the number 1
			if (wantRegion[i] == 49)
			{
				// It's worth checking this region when looping through keys.
				checkBits.push(i);
			}
        }
		
		// TODO:
		print(format("Valid region count %i", checkBits.len()));
		
		// Turns out the locked item doesn't accept any regions at all, so
		// no keys will ever work for it.
		if (checkBits.len() < 1)
			return;
		
		// Great, so a key can be accepted. Which one, specifically?
		local wantKey = Property.Get(self, "KeyDst", "LockID");
		
		// All that's left is to see if the player has anything that'll work.
		// We already know the frobber is an Avatar, so we'll assume it's a
		// player. Their inventory is anything contained by them, per links.
		local playerInventory = Link.GetAll("Contains", self);
		
		// TODO:
		print("Starting inventory loop");
		
		// Search through the player's inventory, so they don't have to.
		foreach (link in playerInventory)
		{
			// Are you the keymaster?
			local inventoryItemId = LinkDest(link);
			
			// If it doesn't have key data, we don't care.
			if (!Property.Possessed(inventoryItemId, "KeySrc"))
				continue;
			
			// We have some kind of key here. Check whether it's the master
			// key, or else the exact kind of key we want.
			if (Property.Get(inventoryItemId, "KeyDst", "LockID") != wantKey && !Property.Get(inventoryItemId, "KeyDst", "MasterBit"))
				continue;
			
			// Almost everything checks out. All that's left is to verify
			// whether there's any overlap in regions.
			local hasRegion = Property.Get(inventoryItemId, "KeyDst", "RegionMask");
			local hasRegionLength = hasRegion.len();
			
			local regionMatch = false;
			foreach (checkBit in checkBits)
			{
				// Again, ASCII character 49 is the number 1
				if (checkBit < hasRegionLength && hasRegion[checkBit] == 49)
				{
					regionMatch = true;
					// Found a match. We're done here.
					break;
				}
			}
			
			if (regionMatch)
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
