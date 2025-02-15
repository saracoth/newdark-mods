# Installation

See also [Troubleshooting](Troubleshooting.md) if mods aren't working after following these instructions.

## Warnings

Installing and uninstalling mods like this will probably break existing saves. It's recommended to start a new game after installing or removing any of these mods.

Currently, all mods use features only available in Thief version 1.27 and higher, or System Shock 2 version 2.48 and higher. Unless you're comfortable with manually setting up NewDark and editing configuration files, I recommend using TFix (for Thief 1/Gold), T2Fix (for Thief2), or SS2Tool (for System Shock 2) to update your game. If you have the option to install the DMM Dark Mod Manager, I recommend you do so.

## Dark Mod Manager Method (DMM)

Some mods include prepackaged files for use with the DMM Dark Mod Manager. These can be installed like any other standard mod. Refer to the [DMM Homepage](https://pshjt.github.io/dmm/) for instructions or other details.

:bulb: I recommend using [TFix](https://www.ttlg.com/forums/showthread.php?t=134733) or [TFix2](https://www.ttlg.com/forums/showthread.php?t=149669) for the [easiest modding experience](https://www.ttlg.com/forums/showthread.php?t=152783). They include the Dark Engine Mod Manager.

Short version:
1. Click the "Install mod archive(s)" button.
2. Browse to wherever you downloaded the mod package.
3. Open it.
4. Select the new mod in the list.
5. Activate it.
6. Click "Apply changes" or "Launch game"

Unless otherwise stated, the priority of the mods in this github repo doesn't matter. They should work even with a low priority.

## Manual Installation Method

:warning: Do **not** use this method if you have Dark Engine Mod Manager installed. If you have a dmm.exe program in your game directory, I recommend installing mods through DMM instead. If you don't have DMM, consider installing it individually or as part of a fresh [TFix](https://www.ttlg.com/forums/showthread.php?t=134733)/[TFix2](https://www.ttlg.com/forums/showthread.php?t=149669) installation in place of your current Thief/Thief 2 install.

1. Create a ```Mods``` folder in your game directory, like "C:\Games\Thief 2 The Metal Age\Mods"
2. Create a ```Just4Fun``` folder inside that, like "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun"
3. Create a ```dbmods``` folder inside that, like "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun\dbmods"
4. Do the same for a ```sq_scripts``` folder, like "C:\Games\Thief 2 The Metal Age\Mods\Just4Fun\sq_scripts"
5. Edit your ```cam_mod.ini``` file (for example, "C:\Games\Thief 2 The Metal Age\cam_mod.ini")

The ```cam_mod.ini``` has a mod_path property. Yours might be missing, or they might all be commented out with a semicolon at the beginning of the line.

If you already have a mod_path, add a plus sign and the new mod folder, like this:

```
mod_path usermods+Mods\Just4Fun
```

If you have no mod_path, or they're all commented out, just copy/paste the above example to the bottom of your ```cam_mod.ini``` file and save it.

Now you can download the individual mod files to the sq_scripts and/or dbmods folder. See the individual mod pages for a list of files to use in manual installation.

# Uninstalling

## Dark Mod Manager Method (DMM)

Use the Dark Mod Manager to deactivate the mod as normal. Refer to the [DMM Homepage](https://pshjt.github.io/dmm/) for additional details if needed.

## Manual Installation Method

1. Delete the entire Just4Fun folder from the Mods folder.
2. Edit your cam_mod.ini file to remove the Mods\Just4Fun folder from the list. Be sure to delete the plus sign as well.

```
; Before uninstalling:
mod_path usermods+Mods\Just4Fun

; After uninstalling:
mod_path usermods
```