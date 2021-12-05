## Solar Ash ASL

This script uses the `GameStatus` property of `ASolarGameMode` as `gameState` to determine whether the game is loading.

The property is located at offset `0x530` inside its class.

gameState is an enum with the following values:
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
