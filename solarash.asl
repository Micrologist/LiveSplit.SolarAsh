/*
'gameState' is the 'GameStatus' property of 'ASolarGameMode'
The property is located at offset '0x530' inside its class.
gameState is an enum with the following values:
	ESolarGameModeStatus__Undefined = 0,
	ESolarGameModeStatus__Loading  = 1,
	ESolarGameModeStatus__Reloading = 2,
	ESolarGameModeStatus__Cutscene = 3,
	ESolarGameModeStatus__Gameplay = 4,
'map' is the full path string name of the currently active map
A pointer to that string is located at offset '0x428' inside the active map struct
*/
state("Solar-Win64-Shipping")
{
    byte gameState : 0x043E0158, 0x5E0;
    string255 map : 0x0465F710, 0x428, 0x0;
}

init
{
    vars.startOnGainControl = false;
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var timingMessage = MessageBox.Show(
            "This game uses RTA w/o Loads as the main timing method.\n"
            + "LiveSplit is currently set to show Real Time (RTA).\n"
            + "Would you like to set the timing method to RTA w/o Loads?",
            "Solar Ash | LiveSplit",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question
        );
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

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

isLoading
{
    return current.gameState < 3;
}

reset
{
    return current.map != old.map && current.map == "/Game/Maps/Cutscenes/Opening_Master";
}