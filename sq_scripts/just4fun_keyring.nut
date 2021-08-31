class J4FKeyringTarget extends SqRootScript
{
	// This happens when the player uses the item directly, as opposed to
	// using a key, lockpick, or other item on it.
	function OnFrobWorldEnd()
	{
		local frobMessage = message();
		
		// We only care when the player is frobbing. We can ignore NPCs and such.
		if (frobMessage.Frobber < 1 || !Object.InheritsFrom(frobMessage.Frobber, "Avatar"))
			return;
		
		// We only care when the frobbed object has a locked status.
		if (!Property.Possessed(self, "Locked"))
			return;
		
		// Has the user enabled automatic locking as well? If not, we don't care.
		// For the auto-lock option, we check that a given metaproperty exists at
		// all, without caring who or what it's assigned to. If it exists, it
		// should have a negative object ID like all other archetypes.
		if (!Property.Get(self, "Locked") && ObjID("J4FAutoLockEnabled") > -1)
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
				// Success! We have the key. Now select or use it and stop
				// looping through inventory items.
				
				// Has the user enabled automatic key usage, or just auto key
				// selection? We check that a given metaproperty exists at all,
				// without caring who or what it's assigned to. If it exists,
				// it should have a negative object ID like all other archetypes.
				if (ObjID("J4FAutoKeyUseEnabled") < 0)
				{
					// This method seems like it'd be ideal, and 99% of the time it
					// will be just fine. However, the door/etc. doesn't receive all
					// the same events and effects it normally would.
					//
					// NOTE: There's also an eKeyUse.kKeyUseCheck option. I bet it
					// would allow us to see whether the key works or not, without
					// actually interacting with the locked object and without us
					// needing to manually check the regions, master bits, etc.
					Key.TryToUseKey(inventoryItemId, self, eKeyUse.kKeyUseDefault);
					
					/*
This is what it looks like to unlock+open a door by using the key normally:
: OSM: SQUIRREL> Debug Door1 264: PlayerToolFrob Key1 187 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: DoorOpening  0 -> Door1 264 [4]
: OSM: SQUIRREL> Debug Door1 264: NowUnlocked  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: TweqComplete  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: DoorOpen  0 -> Door1 264 [4]

This is what it looks like to unlock+open a door with Key.TryToUseKey():
: OSM: SQUIRREL> Debug Door1 264: DoorOpening  0 -> Door1 264 [4]
: OSM: SQUIRREL> Debug Door1 264: NowUnlocked  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: TweqComplete  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: DoorOpen  0 -> Door1 264 [4]

This is what it looks like to lock+close a door by using the key normally:
: OSM: SQUIRREL> Debug Door1 264: PlayerToolFrob Key1 187 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: DoorClosing  0 -> Door1 264 [4]
: OSM: SQUIRREL> Debug Door1 264: NowLocked  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: TweqComplete  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: DoorClose  0 -> Door1 264 [4]

This is what it looks like to lock+close a door with Key.TryToUseKey():
: OSM: SQUIRREL> Debug Door1 264: DoorClosing  0 -> Door1 264 [4]
: OSM: SQUIRREL> Debug Door1 264: NowLocked  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: TweqComplete  0 -> Door1 264 [0]
: OSM: SQUIRREL> Debug Door1 264: DoorClose  0 -> Door1 264 [4]

Note the lack of PlayerToolFrob events.

And that's just the door! The key itself can have its own scripts, and can
even have a Stim that it applies to an object when used as a tool. We can't
realistically simulate any of that ourselves.

So in short, there are all kinds of edge cases we can't cover here. In general,
the auto-use effect will never be 100% safe.
					*/
				}
				else
				{
					// If not already the current item, make it so.
					if (DarkUI.InvItem() != inventoryItemId)
					{
						DarkUI.InvSelect(inventoryItemId);
					}
				}
				
				// Exit the inventory items loop.
				break;
			}
		}
	}
}
