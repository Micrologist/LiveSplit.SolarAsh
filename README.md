## Solar Ash ASL

This script uses the following the values to determine the game's state:

`gameState`  
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

`map`
Tracks the full path name of the currently active map as a (UTF-16) `string`.
A pointer to that string is located at offset `0x428` inside the active map struct.
