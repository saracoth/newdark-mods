# X-Raydar (Thief 1/Gold/2; System Shock 2)

Useful in finding hidden things, or those pesky little coins.

![Rings of various colors and sizes. Three rings encircle loose coins in a fountain.](img/Radar.jpg)

Which items are detected, if any, depends on which of the optional extras you install. If you install none, the radar is pretty useless. Install one or more extras based on the kinds of items you'd like to detect. Installing or removing these extras will require starting a new game, as with installing or removing the mod in general.

Some items work with multiple radar types. For example, loot in a chest will be detected with either the loot radar or the container radar. Likewise, a purse on a belt will be detected both by the loot radar and the pickpocket radar.

## Thief Details

When this mod is installed, a compass-like item will be put in your inventory during every mission. Use this inventory item to show or hide the location of nearby points of interest.

**Required files** (see [installation instructions](Installation%20and%20Removal.md)):
* [dbmods\just4fun_radar_00_base.dml](../dbmods/just4fun_radar_00_base.dml?raw=1)
* [dbmods\miss_all\just4fun_radar_ui.dml](../dbmods/miss_all/just4fun_radar_ui.dml?raw=1) (Unlike the other DML files on this page, this one goes in a miss_all folder inside the dbmods folder.)
* [sq_scripts\just4fun_radar_00_base.nut](../sq_scripts/just4fun_radar_00_base.nut?raw=1)
* [dbmods\just4fun_radar_01_direct_script.dml](../dbmods/just4fun_radar_01_direct_script.dml?raw=1) (Optional, but recommended. Makes some features of device and readable radars more reliable.)
* [dbmods\just4fun_radar_02_thief.dml](../dbmods/just4fun_radar_02_thief.dml?raw=1)
* [j4fRes.crf](../j4fRes.crf)

**Optional loot detection**: Yellow indicators.
* [dbmods\just4fun_radar_10_lootdar.dml](../dbmods/just4fun_radar_10_lootdar.dml?raw=1)

**Optional quest/secret detection**: Pink indicators. This isn't as thorough as other indicators, and only handles *some* objectives to pick up, destroy, or protect a thing. Missions may track objectives through special scripts instead, and this includes the Thief 1 original missions. Thief 2 missions and FMs are more likely to use detectable quest objectives, but this is no guarantee.
* [dbmods\just4fun_radar_10_lootdar.dml](../dbmods/just4fun_radar_10_questdar.dml?raw=1)

**Optional equipment detection (keys, arrows, potions, etc.)**: Green indicators.
* [dbmods\just4fun_radar_10_equipdar.dml](../dbmods/just4fun_radar_10_equipdar.dml?raw=1)
* [dbmods\just4fun_radar_11_T1_equip.dml](../dbmods/just4fun_radar_11_T1_equip.dml?raw=1)
* [dbmods\just4fun_radar_11_T2_equip.dml](../dbmods/just4fun_radar_11_T2_equip.dml?raw=1)

**Optional readable detection (books, scrolls, etc.)**: Blue indicators. Ignores previously read items.
* [dbmods\just4fun_radar_10_bookdar.dml](../dbmods/just4fun_radar_10_bookdar.dml?raw=1)

**Optional creature detection (guards, robots, cameras, etc.)**: Red indicators. Ignores dead and knocked-out creatures. Ignores nonhostile creatures (allies, rats, etc.), depending on which files you install.
* [dbmods\just4fun_radar_10_creaturedar.dml](../dbmods/just4fun_radar_10_creaturedar.dml?raw=1)
* [dbmods\just4fun_radar_11_creature_neutral.dml](../dbmods/just4fun_radar_11_creature_neutral.dml?raw=1) (Extra optional, to display neutral creatures as well as hostiles.)
* [dbmods\just4fun_radar_11_creature_good.dml](../dbmods/just4fun_radar_11_creature_good.dml?raw=1) (Extra optional, to display allied creatures as well as hostiles.)

**Optional device detection (switches, pressure plates, etc.)**: Purple indicators. Ignores devices you've used.
* [dbmods\just4fun_radar_10_devicedar.dml](../dbmods/just4fun_radar_10_devicedar.dml?raw=1)

**Optional container detection (chests, lockboxes, etc.)**: White indicators. Ignores empty containers.
* [dbmods\just4fun_radar_10_containerdar.dml](../dbmods/just4fun_radar_10_containerdar.dml?raw=1)

**Optional pickpocketable detection (purses, quivers, etc.)**: White indicators.
* [dbmods\just4fun_radar_10_pocketdar.dml](../dbmods/just4fun_radar_10_pocketdar.dml?raw=1)

**Keybind item name** ([What's this?](Keybinds.md)): j4fradarcontrolitem

## System Shock 2 Details

The radar is active by default.

**Required files** (see [installation instructions](Installation%20and%20Removal.md)):
* [dbmods\just4fun_radar_00_base.dml](../dbmods/just4fun_radar_00_base.dml?raw=1)
* [dbmods\miss_all\just4fun_radar_ui.dml](../dbmods/miss_all/just4fun_radar_ui.dml?raw=1) (Unlike the other DML files on this page, this one goes in a miss_all folder inside the dbmods folder.)
* [sq_scripts\just4fun_radar_00_base.nut](../sq_scripts/just4fun_radar_00_base.nut?raw=1)
* [dbmods\just4fun_radar_01_direct_script.dml](../dbmods/just4fun_radar_01_direct_script.dml?raw=1) (Optional, but recommended. Makes some features of device and readable radars more reliable.)
* [dbmods\just4fun_radar_02_shock.dml](../dbmods/just4fun_radar_02_shock.dml?raw=1)
* [j4fRes.crf](../j4fRes.crf)

**Optional cybermodule detection**: Green indicators. Includes some scripted events, which may highlight buttons or empty air until you earn the modules.
* [dbmods\just4fun_radar_20_moduledar.dml](../dbmods/just4fun_radar_20_moduledar.dml?raw=1)

**Optional nanite detection**: Yellow indicators.
* [dbmods\just4fun_radar_20_nanitedar.dml](../dbmods/just4fun_radar_20_nanitedar.dml?raw=1)

**Optional slotless equipment detection**: Yellow indicators. Does not include nanites or cybermodules. Includes installable software, including game cartridges that temporarily take up a space until you install them.
* [dbmods\just4fun_radar_20_equipdar_slotless.dml](../dbmods/just4fun_radar_20_equipdar_slotless.dml?raw=1)

**Optional stackable equipment detection**: Pink indicators. Includes ammo and hypos.
* [dbmods\just4fun_radar_20_equipdar_stacked.dml](../dbmods/just4fun_radar_20_equipdar_stacked.dml?raw=1)

**Optional unstackable equipment detection**: Purple indicators. Includes weapons and armor.
* [dbmods\just4fun_radar_20_equipdar_slotted.dml](../dbmods/just4fun_radar_20_equipdar_slotted.dml?raw=1)

**Optional creature detection**: Red indicators. Ignores dead creatures. Ignores nonhostile creatures (allies, rats, etc.), depending on which files you install.
* [dbmods\just4fun_radar_20_creaturedar.dml](../dbmods/just4fun_radar_20_creaturedar.dml?raw=1)
* [dbmods\just4fun_radar_21_creature_neutral.dml](../dbmods/just4fun_radar_21_creature_neutral.dml?raw=1) (Extra optional, to display neutral creatures as well as hostiles.)
* [dbmods\just4fun_radar_21_creature_good.dml](../dbmods/just4fun_radar_21_creature_good.dml?raw=1) (Extra optional, to display allied creatures as well as hostiles.)

**Optional data detection**: Blue indicators. Includes audio logs. Includes some scripted messages, which may highlight a button or empty air until you trigger the message.
* [dbmods\just4fun_radar_20_readdar.dml](../dbmods/just4fun_radar_20_readdar.dml?raw=1)

**Optional container detection (chests, lockboxes, etc.)**: White indicators. Ignores empty containers.
* [dbmods\just4fun_radar_20_containerdar.dml](../dbmods/just4fun_radar_20_containerdar.dml?raw=1)

**Optional Toggle**:

Toggle controls are possible, but currently a bit of a pain. A future update might add a toggle button to the UI somewhere. In the meanwhile, you could try manually adding a keybind. System Shock 2 instructions are similar to [Thief keybinds](Keybinds.md), but you'll use a summon_obj command instead. Note that these commands only work when your player character has access to their inventory and other controls.

```
bind r+ctrl "summon_obj j4fshockdarcontrolitem"
```

## Modder's Notes

This mod uses the same scripting features someone would use to create new HUD elements. Instead of positioning them on specific parts of the screen, these overlays are created, destroyed, and repositioned to match the location of objects in the game world.

There's a ton of code to handle corner cases, like "don't inherit" objects we cannot safely script directly. In addition to using metaproperties directly where able, the mod also scans every object at mission start to flag items of interest. At least on my machine, none of this processing results in FPS drops. Some processes are capped or staggered over time to help keep it that way.

The [original version](https://github.com/saracoth/newdark-mods/tree/original) of this mod uses as little scripting as possible, instead creating visible particle effects to indicate nearby items of interest.