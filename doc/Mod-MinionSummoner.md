# Minion Summoner (Thief 1/Gold/2)

When this mod is installed, a golden skull will be put in your inventory during every mission. Use this inventory item to spawn a minion. By default, a tiny shadow minion that will fight for you. They should be able to blow apart zombies and smash most robots to bits.

If you install the just4fun_summoner_modmod.dml in addition to the other files, your minion will be an ordinary fire elemental instead. This file exists mostly for demonstration purposes, to show how a different mod could tweak the creature summoned.

Minions have a time limit. About five seconds for the default shadow minion, and about thirty for the slower fire elemental version. Since minions don't follow the player and can clutter up the level, the limited duration helps keep them from getting in your way or distracting you.

**Required files** (see [installation instructions](Installation%20and%20Removal.md)):
* [dbmods\just4fun_summoner.dml](../dbmods/just4fun_summoner.dml?raw=1)
* [sq_scripts\just4fun_summoner.nut](../sq_scripts/just4fun_summoner.nut?raw=1)

**Optional extras**:
* [dbmods\just4fun_summoner_modmod.dml](../dbmods/just4fun_summoner_modmod.dml?raw=1) (fire element variant)

**Keybind item name** ([What's this?](Keybinds.md)): j4fsummoningtoken

*Modder's Notes*: This mod demonstrates creating new objects in the game world. It's 100% script-based rather than using the act/react system. The [original version](https://github.com/saracoth/newdark-mods/tree/original) of this mod uses as little scripting as possible. As a result, it lacks some features, like the duration limit.