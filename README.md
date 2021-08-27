# newdark-mods

Collection of example game modifications for NewDark-engine games (Thief 1/Gold, Thief 2, and System Shock 2). These are simple gameplay modifications for demonstration purposes. Only vanilla game assets are used.

The available mods are described after the basic installation instructions.

## Installation

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

If you used the simple install method, you only need to delete the just4fun*.dml and just4fun*.nut files. If your dbmods or sq_scripts folders are empty, you can delete them as well. Just be sure to keep the UserMods folder itself.

### Alternative Method

1. Delete the entire Just4Fun folder from the Mods folder.
2. Edit your cam_mod.ini file to remove the Mods\Just4Fun folder from the list. Be sure to delete the plus sign as well.

```
; Before uninstalling:
mod_path usermods+Mods\Just4Fun

; After uninstalling:
mod_path usermods
```

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

## The Mods

Each mod lists the files it requires, and possibly optional files you can include or skip. Be sure to put the dml files in the dbmods directory and the nut files in the sq_scripts directory. Refer to installation instructions for more details.

It is not necessary to install every mod, but you can if you'd like. Feel free to pick and choose any combination of mods you wish.

For curious modders, I'd rank these mods from least complex to most complex, in terms of figuring out the moving pieces and how they work together:
1. Minion Summoner
2. Radar
3. Ghost Mode

### Ghost Mode

Required files:
* dbmods\just4fun_ghost_mode.dml
* sq_scripts\just4fun_ghost_mode.nut

This mod demonstrates adding and removing metaproperties, as well as copying specific properties from one object to another. In this case, these are used to create a "ghost mode" effect.

When this mod is installed, a silent gong will be put in your inventory during every mission. Using this item from your inventory will toggle ghost mode on and off. When in ghost mode, everything should ignore you, the same as they ignore rats and other neutral NPCs. Your footsteps will be muffled and your light gem will darken. You won't be able to fly or walk through walls, but you can walk through NPCs, doors, and most objects.

You also lose the ability to climb ropes and ladders, and can fall through elevator platforms to your death. Have fun with that. Ghost mode includes a low-gravity effect that might help a bit. It works much like slow-fall potions.

This is not perfect invisibility, since NPCs can retroactively notice you after you leave ghost mode. In reality, they always noticed you, but didn't care until you returned to normal mode. Either way, you can't pick the pockets of NPCs that are aware of you, whether hostile or ignoring you.

### Minion Summoner

Required files:
* dbmods\just4fun_summoner.dml
* sq_scripts\just4fun_summoner.nut

Optional extras:
* dbmods\just4fun_summoner_modmod.dml (fire element variant)

This mod demonstrates creating new objects in the game world. In this case, a tiny shadow minion that will fight for you. They should be able to blow apart zombies and smash most robots to bits.

If you install the just4fun_summoner_modmod.dml in addition to the other files, your minion will be an ordinary fire elemental instead. This is intended to demonstrate how one mod could alter another mod.

Minions have a time limit. About five seconds for the default shadow minion, and about thirty for the slower fire elemental version. Since minions don't follow the player and can clutter up the level, the limited duration helps keep them from getting in your way or distracting you.

When this mod is installed, a golden skull will be put in your inventory during every mission. Use this inventory item to spawn a minion.

### Radar

Required files:
* dbmods\just4fun_radar_00_base.dml
* sq_scripts\just4fun_radar_00_base.nut

Optional loot detection:
* dbmods\just4fun_radar_10_lootdar.dml
* sq_scripts\just4fun_radar_10_lootdar.nut

Optional equipment detection (arrows, potions, keys, etc.):
* dbmods\just4fun_radar_10_equipdar.dml
* dbmods\just4fun_radar_11_T1_equip.dml
* dbmods\just4fun_radar_11_T2_equip.dml
* sq_scripts\just4fun_radar_10_equipdar.nut

Optional device detection (switches, pressure plates, etc.):
* dbmods\just4fun_radar_10_devicedar.dml
* sq_scripts\just4fun_radar_10_devicedar.nut

Optional container detection (chests, lockboxes, etc.):
* dbmods\just4fun_radar_10_containerdar.dml
* dbmods\just4fun_radar_11_T1_containers.dml
* dbmods\just4fun_radar_11_T2_containers.dml
* sq_scripts\just4fun_radar_10_containerdar.nut

This mod demonstrates creating new objects in the game world. In this case, particle effects to spot nearby loot. Helpful for noticing things hidden just out of sight, or those pesky little coins. The kinds of items which are detected depends on which of the optional extras you include. Install as many as you want, or even all of them. If you don't install at least one of the optional detectors, this mod is pretty well useless.

When this mod is installed, a compass-like item will be put in your inventory during every mission. Use this inventory item to "ping" nearby loot, equipment, or other items. You should see a particle effect explode out from each individual item. Expect lag spikes if there are lots of detectable items nearby.

## Notes to Modders

### Duplication of Code

To keep things simpler, I avoided writing general-purpose functions. For example, each mod has a nearly identical script to give the player an inventory item. I did this to cut down on questions as to what files were needed for what mod. I hope this streamlines installing and removing these mods, since absolutely no files are shared between them.

### Conflict-Free Naming

All scripts, stims, metaproperties, and archetypes have a "J4F" prefix. Using generic names like "SummonStim" could cause issues with other mods. Choosing unique names gives maximum compatibility with other mods and FMs, and I recommend you use a similar approach.

### DML Receptron Limitation

This repository was created to demonstrate how to work around a limitation in the DML file format. When CreateArch was first introduced, it was not possible to use those object names in the Agent and Target fields of a receptron. Those fields accept only integer ID numbers, the "Me" keyword, and the "Source" keyword.

In general, this limitation can be completely bypassed through use of squirrel script files. These mods show how to mimic adding and removing metaproperties, spawning objects, and cloning properties from one object to another.

I hope this helps modders who are not comfortable with squirrel scripts to see how they can be used for simple effects like this. The [original versions](https://github.com/saracoth/newdark-mods/tree/1.0) of these mods stick closer to act/react-based systems, and only use scripts where absolutely necessary. The current versions of these scripts take advantage of scripting to simplify things where possible. Feel free to take a look at either or both versions of these mods to see how they work.

### Safely Assigning Scripts

It's perfectly safe to assign scripts to brand new archetypes and metaproperties you define yourself, with CreateArch DML commands. For anything else, you run the risk of conflicts with other mods or FMs.

For example, the Garrett archetype in the vanilla game already has a Sanctifier script attached to him, in script #0. Some random fan mission might attach its own special Garrett script as well, in script #1. If your mod also assigns script #1 to Garrett, either the FM or your mod will stop working correctly.

Instead, I recommend creating a new metaproperty, assigning your script to that, then assigning the metaproperty to your target object. An object can have any number of scripts safely assigned to it in this way.

Unfortunately, it's not possible to assign a metaproperty to another metaproperty. I'm not aware of a 100% safe workaround to assign additional scripts to pre-existing metaproperties. The loot Radar mod was created to demonstrate and comment on this risk, since it assigns a script to the vanilla IsLoot metaproperty.

## Licensing

This project is provided under a permissive MIT license, to encourage modification, reuse, and free distribution of these files. You're welcome to repurpose parts of these files for your own work, subject to the minimal requirements of the MIT license itself. You needn't ask for permission to do so, nor wait for a response if you do ask.