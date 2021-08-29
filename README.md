# newdark-mods

Collection of example game modifications for NewDark-engine games (Thief 1/Gold, Thief 2, and System Shock 2). These are simple gameplay modifications for demonstration purposes. Only vanilla game assets are used.

The available mods are described after the basic installation instructions.

## Installation

See also the troubleshooting section of this document if mods aren't working after following these instructions.

### Warnings

Currently, all mods are suitable for either Thief game. These mods use features only available in NewDark version 1.27 and higher. If you're not familiar with what that is or how to install it, look into a program called TFix. TFix version 1.27 and higher should install the necessary files for you.

Installing and uninstalling mods like this will probably break existing saves. It's recommended to start a new game after installing or removing any of these mods.

### Simple Method (TFix Installations Only)

In the default TFix setup, the UserMods directory is already included in the list of mod paths.

1. Find your Thief game folder. This could be something like "C:\Games\Thief 2 The Metal Age", or it may be in your "C:\GOG Games" folder somewhere. In any case, you're looking for the folder that has a Thief.exe or a Thief2.exe file.
2. Inside your thief game folder, add a UserMods folder if one doesn't exist yet.
3. Inside the UserMods folder, create a dbmods folder if one doesn't exist yet.
4. Also create a sq_scripts folder.

In total, you should have stuff like this:
* C:\Games\Thief 2 The Metal Age\UserMods
* C:\Games\Thief 2 The Metal Age\UserMods\dbmods
* C:\Games\Thief 2 The Metal Age\UserMods\sq_scripts

You can now download or copy files from this repository into the appropriate folders. Be sure to grab both the dbmods .dml files and the sq_scripts .nut files for a given mod!

### Alternative Method

You can manually edit your cam_mod.ini file to change the mod_path list. Create a directory to hold the mod files from this project and add it to the list.

For example, you could create a "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun" folder and do something like this:

```
mod_path usermods+Mods\Just4Fun
```

If you already have a mod_path in your cam_mod.ini file, you'd add a plus sign and the new folder at the end of the existing list.

Installation now proceeds as with the simple method, but with something like "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun" instead of the usermods folder. For example:
* "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun"
* "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun\dbmods"
* "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun\sq_scripts"

## Uninstalling

### Simple Method

If you used the simple install method, you only need to delete the just4fun*.dml and just4fun*.nut files. Removing mods breaks existing saves just as much as installing them, so be sure to start a new game afterward.

### Alternative Method

1. Delete the entire Just4Fun folder from the Mods folder.
2. Edit your cam_mod.ini file to remove the Mods\Just4Fun folder from the list. Be sure to delete the plus sign as well.

```
; Before uninstalling:
mod_path usermods+Mods\Just4Fun

; After uninstalling:
mod_path usermods
```

## The Mods

Each mod lists the files it requires, and possibly optional files you can include or skip. Be sure to put the dml files in the dbmods directory and the nut files in the sq_scripts directory. Refer to installation instructions for more details.

It is not necessary to install every mod, but you can if you'd like. Feel free to pick and choose any combination of mods you wish.

For curious modders, I'd rank these mods from least complex to most complex, in terms of figuring out the moving pieces and how they work together:
1. Ghost Mode
2. Minion Summoner
3. Radar
4. Fairy Light

### Fairy Light (Thief 1/Gold/2)

A controllable, movable light. Probably as close as Thief gets to a flashlight mod, considering the way the lighting engine works and the limitations related to that.

When this mod is installed, a Tinker's Bell item will be added to your inventory in every mission. Using it toggles your light fairy from waiting in place to following your gaze. The fairy will fly through walls to accomplish this, and will move faster when it needs to cross greater distances. NPCs ignore the fairy and can't hear its bell, but everyone benefits from the light it gives off.

The further away the fairy, the bigger its glow! However, due to engine limitations, the radius never grows beyond 30 feet or so. The fairy also prefers to stick to walls, floors, and ceilings. If you stare at a door, the fairy will probably light up the room on the other side rather than the door itself.

You can also "double-click" the Tinker's Bell (use it twice in quick succession) to make the fairy tail someone nearby. This can be any creature, including the player. If they fail to find a close enough creature, the fairy will give up and wait in place. Otherwise, they will tail their target until you use the Tinker's Bell again.

**Required files**:
* dbmods\just4fun_glowfairy.dml
* sq_scripts\just4fun_glowfairy.nut

*Modder's Notes*: Fairy motion is based on elevators and other moving terrain. Some juggling is required to keep the movement butter smooth, but it's more visually appealing than teleporting a light directly. That would require much more frequent updates, which could affect performance. Using an ObjRaycast() instead of PortalRaycast() could eliminate the "flies through doors" effect, but might reduce performance. As for selecting targets to follow, that uses a combination of the act/react system to find targets within an area, and several layers of scripting to process the results.

### Ghost Mode (Thief 1/Gold/2)

When this mod is installed, a silent gong will be put in your inventory during every mission. Using this item from your inventory will toggle ghost mode on and off. When in ghost mode, everything should ignore you, the same as they ignore rats and other neutral NPCs. Your footsteps will be muffled and your light gem will darken. You won't be able to fly or walk through walls, but you can walk through NPCs, doors, and most objects.

You also lose the ability to climb ropes and ladders, and can fall through elevator platforms to your death. Have fun with that. Ghost mode includes a low-gravity effect that might help a bit. It works much like slow-fall potions.

This is not perfect invisibility, since NPCs can retroactively notice you after you leave ghost mode. In reality, they always noticed you, but didn't care until you returned to normal mode. Either way, you can't pick the pockets of NPCs that are aware of you, whether hostile or ignoring you.

**Required files**:
* dbmods\just4fun_ghost_mode.dml
* sq_scripts\just4fun_ghost_mode.nut

*Modder's Notes*: This mod demonstrates adding and removing metaproperties, as well as copying specific properties from one object to another. It's 100% script-based rather than using the act/react system. The [original version](https://github.com/saracoth/newdark-mods/tree/original) of this mod uses as little scripting as possible. As a result, it lacks the slowfall effect.

### Minion Summoner (Thief 1/Gold/2)

When this mod is installed, a golden skull will be put in your inventory during every mission. Use this inventory item to spawn a minion. By default, a tiny shadow minion that will fight for you. They should be able to blow apart zombies and smash most robots to bits.

If you install the just4fun_summoner_modmod.dml in addition to the other files, your minion will be an ordinary fire elemental instead. This file exists mostly for demonstration purposes, to show how a different mod could tweak the creature summoned.

Minions have a time limit. About five seconds for the default shadow minion, and about thirty for the slower fire elemental version. Since minions don't follow the player and can clutter up the level, the limited duration helps keep them from getting in your way or distracting you.

**Required files**:
* dbmods\just4fun_summoner.dml
* sq_scripts\just4fun_summoner.nut

**Optional extras**:
* dbmods\just4fun_summoner_modmod.dml (fire element variant)

*Modder's Notes*: This mod demonstrates creating new objects in the game world. It's 100% script-based rather than using the act/react system. The [original version](https://github.com/saracoth/newdark-mods/tree/original) of this mod uses as little scripting as possible. As a result, it lacks some features, like the duration limit.

### Radar (Thief 1/Gold/2)

When this mod is installed, a compass-like item will be put in your inventory during every mission. Use this inventory item to "ping" nearby items of interest. Can be useful in finding hidden things, or those pesky little coins.

When an item is detected, a particle effect will explode out from it. Lag spikes can happen if there are lots and lots of items detected nearby.

Which items are detected, if any, depends on which of the optional extras you install. If you install none, the radar is pretty useless. Install one or more extras based on the kinds of items you'd like to detect. Installing or removing these extras will require starting a new game, as with installing or removing the mod in general.

**Required files**:
* dbmods\just4fun_radar_00_base.dml
* sq_scripts\just4fun_radar_00_base.nut

**Optional loot detection**:
* dbmods\just4fun_radar_10_lootdar.dml
* sq_scripts\just4fun_radar_10_lootdar.nut

**Optional equipment detection (arrows, potions, keys, etc.)**:
* dbmods\just4fun_radar_10_equipdar.dml
* dbmods\just4fun_radar_11_T1_equip.dml
* dbmods\just4fun_radar_11_T2_equip.dml
* sq_scripts\just4fun_radar_10_equipdar.nut

**Optional device detection (switches, pressure plates, etc.)**:
* dbmods\just4fun_radar_10_devicedar.dml
* sq_scripts\just4fun_radar_10_devicedar.nut

**Optional container detection (chests, lockboxes, etc.)**:
* dbmods\just4fun_radar_10_containerdar.dml
* dbmods\just4fun_radar_11_T1_containers.dml
* dbmods\just4fun_radar_11_T2_containers.dml
* sq_scripts\just4fun_radar_10_containerdar.nut

*Modder's Notes*: This mod demonstrates creating new objects in the game world, positioned on top of arbitrary targets. The [original version](https://github.com/saracoth/newdark-mods/tree/original) of this mod uses as little scripting as possible. As a result, it lacks some features of the current mod.

## Troubleshooting

If the mods don't have any effect, first make sure you're running the latest version of NewDark. These files require version 1.27 or higher. Unless you want to get your hands dirty, I recommend using the latest version of TFix to update your game. It doesn't matter whether you install or skip the optional fixes and enhancements.

Remember also to start a new game. Existing saves will either break or be unaffected.

If the mods still don't work, check your Thief.log or Thief2.log file in the game directory for any errors. You can also use this file to doublecheck what version of the game you're running. For example, NewDark 1.27 has the following log entries:

```
: -----------------------------------------------------------
: App Version: Thief 2 Final 1.27
: --------------------- misc config -------------------------
```

You can also edit your cam.cfg file and make sure dbmod_log is set to 1 by adding this to the bottom of that file.

```
dbmod_log 1
```

Next time you launch the game and start a new mission, you'll also have a dbmod.log file. It may contain errors or warnings about the just4fun .dml files. Even if there aren't errors, you should see that the game loaded the files at all:

```
INFO: found file 'just4fun_radar_00_base.dml' in path 'C:\Games\Thief\usermods\dbmods\', loading... (40200)
```

If you don't see similar lines in dbmod.log, then the game never even tried to load the mod files. Doublecheck your cam_mod.ini file to be sure it includes the necessary directories. Refer to the installation instructions for details.

## Notes to Modders

### Duplication of Code

To keep things simpler, I avoided writing general-purpose functions. For example, each mod has a nearly identical script to give the player an inventory item. I did this to keep the scope of each mod clear, for users and curious modders alike. Absolutely no files are shared between multiple mods.

### Conflict-Free Naming

All scripts, stims, metaproperties, and archetypes have a "J4F" prefix. Using generic names like "SummonStim" could cause issues with other mods. Choosing unique names gives maximum compatibility with other mods and FMs, and it's recommended that you use a similar approach.

### DML Receptron Limitation

This repository was originally created to demonstrate workarounds for a DML file limitation. When CreateArch was first introduced, it was not possible to use those object names in the Agent and Target fields of a receptron. Those fields accept only integer ID numbers, the "Me" keyword, and the "Source" keyword.

In general, this limitation can be completely bypassed through use of squirrel script files. These mods show how to mimic adding and removing metaproperties, spawning objects, and cloning properties from one object to another. The sorts of things an act/react-based mod could do with new archetypes, if only it knew how to reference them.

I hope this helps modders who are not comfortable with squirrel scripts to see how they can be used for simple effects like those. The [original versions](https://github.com/saracoth/newdark-mods/tree/1.0) of these mods stick closer to act/react-based systems, and only use scripts where absolutely necessary. The current versions of these scripts take advantage of scripting wherever it was beneficial. Feel free to take a look at either or both versions of these mods to see how they work.

### Safely Assigning Scripts

It's perfectly safe to assign scripts to brand new archetypes and metaproperties you define yourself, with CreateArch DML commands. For anything else, you run the risk of conflicts with other mods or FMs.

For example, the Garrett archetype in the vanilla game already has a Sanctifier script attached to him, in script #0. Some random fan mission might attach its own special Garrett script as well, in script #1. If your mod also assigns script #1 to Garrett, either the FM or your mod will stop working correctly.

Instead, I recommend creating a new metaproperty, assigning your script to that, then assigning the metaproperty to your target object. An object can have any number of scripts safely assigned to it in this way.

Unfortunately, it's not possible to assign a metaproperty to another metaproperty. I'm not aware of a 100% safe workaround to assign additional scripts to pre-existing metaproperties. In some cases, even this can be worked around. The radar mod uses a "stimulate object" receptron to reflect a stimulus back to its source. This allows us to safely add extra behaviors to the pre-existing IsLoot archetype, by allowing loot to announce their presence to a different script on a different object.

## Licensing

This project is provided under a permissive MIT license, to encourage modification, reuse, and free distribution of these files. You're welcome to repurpose parts of these files for your own work, subject to the minimal requirements of the MIT license itself. You needn't ask for permission to do so, nor wait for a response if you do ask.