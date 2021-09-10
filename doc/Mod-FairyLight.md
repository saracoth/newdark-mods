# Fairy Light (Thief 1/Gold/2)

A controllable, movable light. A blend between a lantern and a flashlight. Check out the [YouTube video demonstration](https://youtu.be/w-Nmsh-dpBU) to see it in action.

When this mod is installed, a Tinker's Bell item will be added to your inventory in every mission. Using it toggles your light fairy on and off. By default, the fairy follows your gaze. It will fly through walls to accomplish this, and will move faster when it needs to cross greater distances. NPCs ignore the fairy and can't hear its bell, but its light could reveal you or your stash of bodies, so please use responsibly.

The further away the fairy, the bigger its glow! However, due to engine limitations, the radius never grows beyond 30 feet or so. The fairy also prefers to stick to walls, floors, and ceilings. If you stare at a door, the fairy will probably light up the room on the other side rather than the door itself.

Once the fairy has been summoned, attempting to drop the Tinker's Bell will instead tell the fairy to stop moving. It will continue lighting up the current spot until you use the bell to douse its light. You can also attempt to drop the bell a second time to resume following your gaze.

"Double-click" the Tinker's Bell (use it twice in quick succession) to make the fairy tail someone nearby. This can be any creature, including the player. If they fail to find a close enough creature, the fairy will give up and wait in place. Otherwise, they will tail their target until you use the Tinker's Bell again.

When tailing the player, the fairy will project a larger light radius for your convenience. When tailing any other creature, the fairy will try really, really hard to not give away your position. If you need to, you can always douse the fairy in an emergency.

**Required files** (see [installation instructions](Installation%20and%20Removal.md)):
* [dbmods\just4fun_glowfairy.dml](../dbmods/just4fun_glowfairy.dml?raw=1)
* [sq_scripts\just4fun_glowfairy.nut](../sq_scripts/just4fun_glowfairy.nut?raw=1)

**Optional extras**:
* [dbmods\just4fun_glowfairy_orig_control.dml](../dbmods/just4fun_glowfairy_orig_control.dml?raw=1) (Original control scheme. Dropping the bell douses the fairy. A single ring switches between waiting and gaze following.)

**Keybind item name** ([What's this?](Keybinds.md)): j4ffairycontrolbell

*Modder's Notes*: Fairy motion is based on elevators and other moving terrain. Some juggling is required to keep the movement butter smooth, but it's more visually appealing than teleporting a light directly. That would require much more frequent updates, which could affect performance. Using an ObjRaycast() instead of PortalRaycast() could eliminate the "flies through doors" effect if one so wanted. As for selecting targets to follow, that uses a combination of the act/react system to find targets within an area, and several layers of scripting to process the results.