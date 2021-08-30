# Fairy Light (Thief 1/Gold/2)

A controllable, movable light. Probably as close as Thief gets to a flashlight mod, considering the way the lighting engine works and the limitations related to that.

![Fairy lighting distant sign](doc/img/FairyLight-Gazing.png)

When this mod is installed, a Tinker's Bell item will be added to your inventory in every mission. Using it toggles your light fairy from waiting in place to following your gaze. The fairy will fly through walls to accomplish this, and will move faster when it needs to cross greater distances. NPCs ignore the fairy and can't hear its bell, but everyone benefits from the light it gives off.

The further away the fairy, the bigger its glow! However, due to engine limitations, the radius never grows beyond 30 feet or so. The fairy also prefers to stick to walls, floors, and ceilings. If you stare at a door, the fairy will probably light up the room on the other side rather than the door itself.

You can also "double-click" the Tinker's Bell (use it twice in quick succession) to make the fairy tail someone nearby.

![Fairy following servant through city streets](doc/img/FairyLight-Tailing.png)

This can be any creature, including the player. If they fail to find a close enough creature, the fairy will give up and wait in place. Otherwise, they will tail their target until you use the Tinker's Bell again.

**Required files** (see [installation instructions](doc/Installation and Removal.md)):
* dbmods\just4fun_glowfairy.dml
* sq_scripts\just4fun_glowfairy.nut

*Modder's Notes*: Fairy motion is based on elevators and other moving terrain. Some juggling is required to keep the movement butter smooth, but it's more visually appealing than teleporting a light directly. That would require much more frequent updates, which could affect performance. Using an ObjRaycast() instead of PortalRaycast() could eliminate the "flies through doors" effect, but might reduce performance. As for selecting targets to follow, that uses a combination of the act/react system to find targets within an area, and several layers of scripting to process the results.