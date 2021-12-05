/*
This script tracks the 'GameStatus' property of 'ASolarGameMode' as 'gameState'.
The property is located at offset '0x530' inside its class.
gameState is an enum with the following values:
	ESolarGameModeStatus__Undefined = 0,
	ESolarGameModeStatus__Loading  = 1,
	ESolarGameModeStatus__Reloading = 2,
	ESolarGameModeStatus__Cutscene = 3,
	ESolarGameModeStatus__Gameplay = 4,
*/
state("Solar-Win64-Shipping")
{
    byte gameState : 0x043E0158, 0x5E0;
    string255 map : 0x0465F710, 0x428, 0x0;
}

init
{
    current.level = "";
    current.loading = false;
    vars.startOnGainControl = false;
}

update
{
    current.loading = current.gameState < 3;

    if(!String.IsNullOrEmpty(current.map))
    {
        current.level = current.map;
    }

    if(current.level != old.level)
    {
        print("Level transition: "+old.level+" -> "+current.level);
    }
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
    if(current.level == "/Game/Maps/UltraVoid/UltraVoid" && old.level == "/Game/Maps/Cutscenes/Opening_Master")
    {
        vars.startOnGainControl = true;
    }

    if(vars.startOnGainControl && current.gameState == 4)
    {
        vars.startOnGainControl = false;
        return true;
    }
}

isLoading
{
    return current.loading;
}