# Installation

See also [Troubleshooting](Troubleshooting.md) if mods aren't working after following these instructions.

## Warnings

Currently, all mods use features only available in NewDark version 1.27 and higher. If you're not familiar with what that is or how to install it, look into a program called TFix (for Thief) or SS2Tool (for System Shock 2). SS2Tool will also install a mod manager for you.

Installing and uninstalling mods like this will probably break existing saves. It's recommended to start a new game after installing or removing any of these mods.

## Simple Method (TFix Installations)

In the default TFix setup, the UserMods directory is already included in the list of mod paths.

1. Find your Thief game folder. This could be something like "C:\Games\Thief 2 The Metal Age", or it may be in your "C:\GOG Games" folder somewhere. In any case, you're looking for the folder that has a Thief.exe or a Thief2.exe file.
2. Inside your thief game folder, add a UserMods folder if one doesn't exist yet. All CRF files will go here.
3. Inside the UserMods folder, create a dbmods folder if one doesn't exist yet. All DML files will go here.
4. Also create a sq_scripts folder. All NUT files will go here.

In total, you should have stuff like this:
* C:\Games\Thief 2 The Metal Age\UserMods
* C:\Games\Thief 2 The Metal Age\UserMods\dbmods
* C:\Games\Thief 2 The Metal Age\UserMods\sq_scripts

You can now download or copy files from this repository into the appropriate folders. Be sure to grab both the dbmods .dml files and the sq_scripts .nut files for a given mod!

If a mod requires the j4fRes.crf file, that goes directly in the Usermods folder, like "C:\Games\Thief 2 The Metal Age\UserMods\j4fRes.crf"

## Dark Mod Manager Method (DMM)

These mods could be packaged into files compatible with DMM. So far, such packages haven't been created, but it's on the TODO list for a future release version.

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

# Uninstalling

## Simple Method

If you used the simple install method, you only need to delete the just4fun*.dml and just4fun*.nut files. Removing mods breaks existing saves just as much as installing them, so be sure to start a new game afterward.

## Dark Mod Manager Method (DMM)

Use the mod manager to deactivate the mod as normal.

## Alternative Method

1. Delete the entire Just4Fun folder from the Mods folder.
2. Edit your cam_mod.ini file to remove the Mods\Just4Fun folder from the list. Be sure to delete the plus sign as well.

```
; Before uninstalling:
mod_path usermods+Mods\Just4Fun

; After uninstalling:
mod_path usermods
```