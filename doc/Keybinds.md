# Keybinds for Mod Items

I'm not aware of a way to add mod items to the controller configuration screen. However, if you want to assign a shortcut to mod-related inventory item anyway, you can edit your keybind files.

These instructions assume you've already launched the game at least once and set up all your other controls.

1. The game allows you to save your current key bindings and give them a name. I recommend you do this, so those settings can be loaded if you have issues later.
2. If the game is open, close it.
3. Find the user.bnd file in your game's installation directory. See below for examples.
4. Open this file in a text editor, like Notepad.
5. Change an existing key binding or add a new one. The "inv_select" bindings select or equip an inventory item or weapon.
6. Save the user.bnd file.

At this point, you may want to save your keybinds again. Perhaps to a different slot and name, rather than overwriting your previously saved bindings.

Here's an example change:

```
; Original keybinding
bind f9 "inv_select compass2"
; Added a new keybinding below that
bind f9+alt "inv_select j4fradarcontrolitem"
```

All bindings are in a similar style. 

These are some example user.bnd file locations. Yours may vary depending on your use of GOG, Steam, or other options:
* C:\Games\Thief\user.bnd
* C:\Games\Thief 2 The Metal Age\user.bnd
