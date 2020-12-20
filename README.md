## Summary

This is the core user profile I use on all my different setups (home laptop, nas, android cell phone through termux, work).

It defines all the common shell functions I use. For short scripts, I prefer using shell functions then shell scripts.

It is divided in 2 parts: one set of general purpose functions, one specific to each machine or setup. This repo contains the first one and propose hooks to load the second one. This is particularily useful to separate my environement for work, to my environement for my nas or my android phone.

## Principle

The common functions are spread in multiple small scripts in folder "~/.rc.d". The main entry point is function "rc_source" in script "~/.rc".

Called without argument, the "rc_source" function loads all executable scripts in folder "~/.rc.d" or listed in "~/.rc.list".

Called with an argument, the "rc_source" function loads all scripts in "~/.rc.d" whose name matches partially the argument, whether it is executable or not.

File "~/.rc.list" is useful on filesystems where files cannot be made executable, like Android sdcard.

The user/machine specific extension set of scripts is loaded through scripts ".rc.local" and ".rc.local.end".

## File tree
```
$HOME/
  .rc
  .rc.list
  .rc.end
  .rc.local (optional)
  .rc.local.end (optional)
  .rc.d/
```

## Bootstrapping the environment

The environment is loaded with:
```
source "$HOME/.rc"
```
or
```
. "$HOME/.rc"
```

Consider adding these lines in your "~/.bashrc" or "~/.mkshrc" (or any shell user profile script) to autoload it in all interactive shells.

When ".rc" is loaded, the function "rc_source" (alias "rc") is made available, and the following scripts are loaded in order:
    1. file ".rc.local"
    2. all flagged files in folder ".rc.d/" (see section "autoloaded scripts")
    2. file '.rc.end'
    3. file '.rc.local.end', if it exists.

## Select autoloaded scripts

All executable scripts in folder ".rc.d/" are autoloaded by command "rc_source" (alias "rc"). For filesystems which don't support this flag (ex: android sdcard), an alternate way is to put the autoloaded scripts names in file ".rc.list".

The scripts are loaded in the alphabetical order, numbers first. To ensure the load order, I usually prefix the scripts with a 2 digit number. Ex: 01_bash.sh 

## Load specific scripts manually on-demand

All scripts can be (re)loaded manually using command "rc_source" (alias "rc") anytime. Refer to "rc_source" function usage.

## Function "rc_source" usage

```
Loads the user environment scripts 
Usage: rc_source [-v] [-a] [scriptname]... [folder]...
    -v : verbose mode, shows the loaded scripts names
    -a : load all available scripts, don't look at the execute flag or file .rc.list
    scriptname...: space separated list of partial script names to load.
    folder...: space separated list of folders from which to load scripts.
When no scriptname and no folder is specified, load the '.rc.local' script, then all executable scripts in '.rc.d' or the ones listed in .rc.list, then '.rc.end' and finally '.rc.local.end'
```

## Local user specific extensions (.rc.local and .rc.local.end)

An extension mechanism is available to store user or machine specific scripts separated from this core environement ones.

This extension relies on files ".rc.local" and ".rc.local.end", which are loaded by "rc_source" when they exist. The first one is loaded before any other script, while the second is loaded very last.

With these 2 scripts, the user can build his own set of scripts in folder ".rc.local.d/", similar to ".rc.d/" and loaded from either ".rc.local" or ".rc.local.end" with:
```
rc_source ".rc.local.d/"
```

Note the folder name ".rc.local.d/" is a suggestion only.

When this is done, function "rc_source" can load/reload/autoload all user scripts from the ".rc.local.d/" folder as well as the ones in ".rc.d/"
