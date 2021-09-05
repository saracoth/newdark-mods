# Installation

See also [Troubleshooting](Troubleshooting.md) if mods aren't working after following these instructions.

## Warnings

Currently, all mods are suitable for either Thief game. These mods use features only available in NewDark version 1.27 and higher. If you're not familiar with what that is or how to install it, look into a program called TFix. TFix version 1.27 and higher should install the necessary files for you.

Installing and uninstalling mods like this will probably break existing saves. It's recommended to start a new game after installing or removing any of these mods.

## Simple Method (TFix Installations Only)

In the default TFix setup, the UserMods directory is already included in the list of mod paths.

1. Find your Thief game folder. This could be something like "C:\Games\Thief 2 The Metal Age", or it may be in your "C:\GOG Games" folder somewhere. In any case, you're looking for the folder that has a Thief.exe or a Thief2.exe file.
2. Inside your thief game folder, add a UserMods folder if one doesn't exist yet.
3. Inside the UserMods folder, create a dbmods folder if one doesn't exist yet.
4. Also create a sq_scripts folder.
5. Some mods also require a j4fRes folder.

In total, you should have stuff like this:
* C:\Games\Thief 2 The Metal Age\UserMods
* C:\Games\Thief 2 The Metal Age\UserMods\dbmods
* C:\Games\Thief 2 The Metal Age\UserMods\sq_scripts
* And maybe also "C:\Games\Thief 2 The Metal Age\UserMods\j4fRes" for some mods

You can now download or copy files from this repository into the appropriate folders. Be sure to grab both the dbmods .dml files and the sq_scripts .nut files for a given mod!

## Alternative Method

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
* "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun\j4fRes" (for mods that require a j4fRes folder)

# Uninstalling

## Simple Method

If you used the simple install method, you only need to delete the just4fun*.dml and just4fun*.nut files. Removing mods breaks existing saves just as much as installing them, so be sure to start a new game afterward.

## Alternative Method

1. Delete the entire Just4Fun folder from the Mods folder.
2. Edit your cam_mod.ini file to remove the Mods\Just4Fun folder from the list. Be sure to delete the plus sign as well.

```
; Before uninstalling:
mod_path usermods+Mods\Just4Fun

; After uninstalling:
mod_path usermods
```