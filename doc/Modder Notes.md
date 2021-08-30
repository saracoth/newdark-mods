# Notes to Modders

## Duplication of Code

To keep things simpler, I avoided writing general-purpose functions. For example, each mod has a nearly identical script to give the player an inventory item. I did this to keep the scope of each mod clear, for users and curious modders alike. Absolutely no files are shared between multiple mods.

## Conflict-Free Naming

All scripts, stims, metaproperties, and archetypes have a "J4F" prefix. Using generic names like "SummonStim" could cause issues with other mods. Choosing unique names gives maximum compatibility with other mods and FMs, and it's recommended that you use a similar approach.

## DML Receptron Limitation

This repository was originally created to demonstrate workarounds for a DML file limitation. When CreateArch was first introduced, it was not possible to use those object names in the Agent and Target fields of a receptron. Those fields accept only integer ID numbers, the "Me" keyword, and the "Source" keyword.

In general, this limitation can be completely bypassed through use of squirrel script files. These mods show how to mimic adding and removing metaproperties, spawning objects, and cloning properties from one object to another. The sorts of things an act/react-based mod could do with new archetypes, if only it knew how to reference them.

I hope this helps modders who are not comfortable with squirrel scripts to see how they can be used for simple effects like those. The [original versions](https://github.com/saracoth/newdark-mods/tree/1.0) of these mods stick closer to act/react-based systems, and only use scripts where absolutely necessary. The current versions of these scripts take advantage of scripting wherever it was beneficial. Feel free to take a look at either or both versions of these mods to see how they work.

## Safely Assigning Scripts

It's perfectly safe to assign scripts to brand new archetypes and metaproperties you define yourself, with CreateArch DML commands. For anything else, you run the risk of conflicts with other mods or FMs.

For example, the Garrett archetype in the vanilla game already has a Sanctifier script attached to him, in script #0. Some random fan mission might attach its own special Garrett script as well, in script #1. If your mod also assigns script #1 to Garrett, either the FM or your mod will stop working correctly.

Instead, I recommend creating a new metaproperty, assigning your script to that, then assigning the metaproperty to your target object. An object can have any number of scripts safely assigned to it in this way.

Unfortunately, it's not possible to assign a metaproperty to another metaproperty. I'm not aware of a 100% safe workaround to assign additional scripts to pre-existing metaproperties. In some cases, even this can be worked around. The radar mod uses a "stimulate object" receptron to reflect a stimulus back to its source. This allows us to safely add extra behaviors to the pre-existing IsLoot archetype, by allowing loot to announce their presence to a different script on a different object.