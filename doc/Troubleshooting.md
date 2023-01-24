# Troubleshooting

If the mods don't have any effect, first make sure you're running the latest version of NewDark. These mods require Thief v1.27 or higher, or System Shock 2 v2.48 or higher.

Unless you want to get your hands dirty, I recommend using the latest version of TFix (for Thief 1/Gold), T2Fix (for Thief2), or SS2Tool (for System Shock 2) to update your game. If you have the option to install the DMM Dark Mod Manager, I recommend you do so.

Remember also to start a new game. Existing saves will either break or be unaffected.

If the mods still don't work, check your `Thief.log`, `Thief2.log`, `SS2.log`, or similar file in the game directory for any errors.

You can also use this file to doublecheck what version of the game you're running. Thief (1, Gold, and 2) should be version 1.27 or higher, like:

```
: -----------------------------------------------------------
: App Version: Thief 2 Final 1.27
: --------------------- misc config -------------------------
```

System Shock 2 should be version 2.48 or higher, like:

```
: -----------------------------------------------------------
: App Version: System Shock 2 Patch Final 2.48
: --------------------- misc config -------------------------
```

All NewDark games (Thief-like and Shock-like) should include the squirrel script module as part of their standard install. Version 1.0.2.0 or higher, like:

```
: Loaded script module "squirrel.osm" [FileVer=1.0.2.0 ; ProductVer=1.0.2.0 ; FileModDate=2018-Oct-30]
```

If there are no obvious problems in those log files, you can also enable a `dbmod.log` file. Edit your `cam.cfg` file and make sure dbmod_log is set to 1 by adding this to the bottom of that file.

```
dbmod_log 1
```

Next time you launch the game and start a new mission, you'll also have a `dbmod.log` file. It may contain errors or warnings about the just4fun .dml files. If there aren't errors, there should be evidence that the files were loaded:

```
INFO: found file 'just4fun_radar_00_base.dml' in path 'C:\Games\Thief\usermods\dbmods\', loading... (40200)
```

If you don't see similar lines in dbmod.log, then the game never even tried to load the mod files. Doublecheck your cam_mod.ini file to be sure it includes the necessary directories. If using DarkModManager, make sure that the mods have an Activated status. Refer to the [installation instructions](Installation%20and%20Removal.md) for details.