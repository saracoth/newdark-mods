# Keyring (Thief 1/Gold/2)

This mod saves the trouble of scrolling through inventory items looking for keys, gears, etc. How much of the work it does for you depends on which optional extras you install. This should work on almost every "lockable" item, including unconventional ones like the elemental ward stones outside the haunted cathedral.

By default, the mod just selects the appropriate key item for the locked door, container, or other item you're interacting with. This allows you to see what item you need to use before you actually use it. This is the recommended setup, and should work for everyone.

You can optionally enable this feature for *unlocked* items as well (under **Optional extras**). This makes it easy to re-lock items without looking for the appropriate key. However, it can be annoying in practice, and often unnecessary. For the best experience, either avoid this feature or combine it with the auto-using of keys described below.

With the optional auto-use option (under **Optional extras**), instead of *selecting* the appropriate key item, you'll automatically *use* it. You won't get to see what item it was you just used, but you also won't lose track of your currently selected inventory item. This is ever-so-slightly more convenient, but may not be 100% compatible with all FMs.

**Warning**: While the auto-select feature is 100% safe, the auto-use feature is not. It should work perfectly fine in most cases. However, the automatic usage behaves slightly differently than using a key manually. This could break levels or FMs that rely on "when X tool is used on Y object" functionality, because those events never happen.

**Required files** (see [installation instructions](Installation%20and%20Removal.md)):
* [dbmods\just4fun_keyring.dml](../dbmods/just4fun_keyring.dml?raw=1)
* [sq_scripts\just4fun_keyring.nut](../sq_scripts/just4fun_keyring.nut?raw=1)

**Optional extras**:
* [dbmods\just4fun_keyring_autolock.dml](../dbmods/just4fun_keyring_autolock.dml?raw=1) to make it easier to lock stuff, as well as unlock.
* [dbmods\just4fun_keyring_autouse.dml](../dbmods/just4fun_keyring_autouse.dml?raw=1) to automatically *use* the key item, without selecting it or losing track of your current inventory item. See **Warning** above.