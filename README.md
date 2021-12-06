## Solar Ash ASL

This script uses the following the values to determine the game's state:

#### `gameState`  
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

#### `map`  
Tracks the full path name of the currently active map as a (UTF-16) `string`.  
A pointer to that string is located at offset `0x428` inside the active map struct.  
The following map names are of interest:
- `/Game/Maps/TitleNMainMenu` - Main Menu
- `/Game/Maps/Cutscenes/Opening_Master` - Opening Cutscene
- `/Game/Maps/UltraVoid/UltraVoid` - Game World

### Load Removal
The game is considered to be loading whenever the `GameStatus` is neither `ESolarGameModeStatus__Gameplay` nor `ESolarGameModeStatus__Cutscene`.
```c#
isLoading
{
    return current.gameState < 3;
}
```
Since the `ASolarGameMode` class only gets instantiated once you load into a save file, this also pauses the timer in the main menu as a side effect.

### Timer Start
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

### Timer Reset
The timer should reset when the player starts a new save file and loads into the opening cutscene.
```c#
reset
{
    return current.map != old.map && current.map == "/Game/Maps/Cutscenes/Opening_Master";
}
```