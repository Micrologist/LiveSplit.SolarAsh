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

isLoading
{
    return current.gameState < 3;
}