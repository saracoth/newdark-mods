# Troubleshooting

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

If you don't see similar lines in dbmod.log, then the game never even tried to load the mod files. Doublecheck your cam_mod.ini file to be sure it includes the necessary directories. Refer to the [installation instructions](doc/Installation and Removal.md) for details.