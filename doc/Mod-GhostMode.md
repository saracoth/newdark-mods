# Ghost Mode (Thief 1/Gold/2)

When this mod is installed, a silent gong will be put in your inventory during every mission. Using this item from your inventory will toggle ghost mode on and off. When in ghost mode, everything should ignore you, the same as they ignore rats and other neutral NPCs. Your footsteps will be muffled and your light gem will darken. You won't be able to fly or walk through walls, but you can walk through NPCs, doors, and most objects.

You also lose the ability to climb ropes and ladders, and can fall through elevator platforms to your death. Have fun with that. Ghost mode includes a low-gravity effect that might help a bit. It works much like slow-fall potions.

This is not perfect invisibility, since NPCs can retroactively notice you after you leave ghost mode. In reality, they always noticed you, but didn't care until you returned to normal mode. Either way, you can't pick the pockets of NPCs that are aware of you, whether hostile or ignoring you.

**Required files** (see [installation instructions](doc/Installation and Removal.md)):
* dbmods\just4fun_ghost_mode.dml
* sq_scripts\just4fun_ghost_mode.nut

*Modder's Notes*: This mod demonstrates adding and removing metaproperties, as well as copying specific properties from one object to another. It's 100% script-based rather than using the act/react system. The [original version](https://github.com/saracoth/newdark-mods/tree/original) of this mod uses as little scripting as possible. As a result, it lacks the slowfall effect.