# Solar Ash ASL

- [Tracked Values](#tracked-values)
- [Load Removal](#load-removal)
- [Timer Start](#timer-start)
- [Auto Splitting](#auto-splitting)
- [Timer Reset](#timer-reset)

## Tracked Values

This script uses the following the values to determine the game's state:

### `gameState`  
Tracks the `enum GameStatus` property of `ASolarGameMode` as `byte`.  
The property is located at offset `0x530` inside its class.  
The enum can have the following values:  
```c++
enum class Solar_ESolarGameModeStatus : uint8_t
{
	ESolarGameModeStatus__Undefined = 0,
	ESolarGameModeStatus__Loading  = 1,
	ESolarGameModeStatus__Reloading = 2,
	ESolarGameModeStatus__Cutscene = 3,
	ESolarGameModeStatus__Gameplay = 4,
	ESolarGameModeStatus__ESolarGameModeStatus_MAX = 5,
};
```  

### `map`  
Tracks the full path name of the currently active map as a (UTF-16) `string`.  
A pointer to that string is located at offset `0x428` inside the active map struct.  
The following map names are of interest:
- `/Game/Maps/TitleNMainMenu` - Main Menu
- `/Game/Maps/Cutscenes/Opening_Master` - Opening Cutscene
- `/Game/Maps/UltraVoid/UltraVoid` - Game World

### `newestSaveFlag`
In order to track game progression we read from `TArray<struct FName> SaveFlags`, located at offset `0x38` in `struct FSolarSaveData WorkingSaveData`.  
(`WorkingSaveData` is found at offset `0x1C8` in `class USolarInstance`)


`TArray`s consist of a pointer to the start of the Array, as well as an `int` for the number items stored in the array.  
We track the pointer as `saveFlagPtr` and the amount of items as `saveFlagCount`.


In order to save resources we don't actually parse the whole array but only look at the last (and newest) item of the array.


Since the array contains `FName`s we need to lookup the actual string representation of each `FName` in the `FNamePool` using the function `vars.GetNameFromFName`. (Thanks to LongerWarrior for this function)  

The resulting string gets stored as `newestSaveFlag`.

## Load Removal
The game is considered to be loading whenever the `GameStatus` is neither `ESolarGameModeStatus__Gameplay` nor `ESolarGameModeStatus__Cutscene`.
```c#
isLoading
{
    return current.gameState < 3;
}
```
Since the `ASolarGameMode` class only gets instantiated once you load into a save file, this also pauses the timer in the main menu as a side effect.

## Timer Start
The timer should start once you first gain control of your character after starting a new save file. This coincides with a change of `GameStatus` from `ESolarGameModeStatus__Cutscene` to `ESolarGameModeStatus__Gameplay`.  
If the game is currently showing the opening cutscene, we set the script up to start the timer the next time the player gains control.
```c#
start
{
    if(current.map == "/Game/Maps/Cutscenes/Opening_Master")
    {
        vars.startOnGainControl = true;
    }

    if(vars.startOnGainControl && old.gameState == 3 && current.gameState == 4)
    {
        vars.startOnGainControl = false;
        return true;
    }
}
```

## Auto Splitting
The script currently supports to types of split conditions.

### Boss Kills
If the `splitOnBossKills` option is enabled, everytime the `newestSaveFlag` changes, we check to see if the new saveFlag is contained in List of Boss Kill flags (`vars.bossKillFlags`).  
If it is, we trigger a split.
```c#
if(settings["splitOnBossKills"])
{
    if(current.newestSaveFlag != old.newestSaveFlag && vars.bossKillFlags.Contains(current.newestSaveFlag))
    {
        return true;
    }
}
```

### Any% / Bad Ending
Once the player loads back into the landing site during the bad ending, the save flags are essentially wiped, and a `DISABLE_SAVING` flag is triggered.  
When another flag gets added to the SaveFlags array, we set the script up to split the next time the player loses control (`gameState` switches from `Gameplay` to `Cutscene`).
```c#
if(settings["splitBadEnding"])
{
    if(current.newestSaveFlag != old.newestSaveFlag && old.newestSaveFlag == "DISABLE_SAVING" && current.saveFlagCount == 2)
    {
        vars.splitOnLoseControl = true;
    }

    if(vars.splitOnLoseControl && current.gameState == 3 && old.gameState == 4)
    {
        vars.splitOnLoseControl = false;
        return true;
    }
}
```


## Timer Reset
The timer should reset when the player starts a new save file and loads into the opening cutscene.
```c#
reset
{
    return current.map != old.map && current.map == "/Game/Maps/Cutscenes/Opening_Master";
}
```