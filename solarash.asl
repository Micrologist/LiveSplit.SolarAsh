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

'saveFlagPtr' and 'saveFlagCount' track the state of the `GameFlags` array

For full documentation see:
https://github.com/Micrologist/LiveSplit.SolarAsh/blob/main/README.md
*/

state("Solar-Win64-Shipping")
{
    byte gameState : 0x043E0158, 0x5E0;
    string255 map : 0x0465F710, 0x428, 0x0;
    int saveFlagCount : 0x044A14D8, 0x260, 0x208;
    long saveFlagPtr : 0x044A14D8, 0x260, 0x200;
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

    vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
        if (textSetting == null)
        {
            var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
            var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
            timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));
            textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
            textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
        }
        if (textSetting != null)
            textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
	});

    vars.bossKillFlags = new List<string>(){
        "Vale_Starseed_Remnant",
        "Woods_OldCity_Remnant",
        "Woods_IronRootBasin_Remnant",
        "Shroom_GhostCoppice_Remnant",
        "Beach_AcidLagoon_SwordRemnant",
        "Shroom_Overflow_Remnant"
    };

    settings.Add("splitOnBossKills", true, "Split after killing a boss");
    settings.Add("splitBadEnding", true, "Split on Any% Ending");
    settings.Add("debugTextComponents", false, "[DEBUG] Show values in layout");
}


init
{
    vars.GetFNamePool = (Func<IntPtr>) (() => {	
        var scanner = new SignatureScanner(game, modules.First().BaseAddress, (int)modules.First().ModuleMemorySize);
        var pattern = new SigScanTarget("74 09 48 8D 15 ?? ?? ?? ?? EB 16");
        var gameOffset = scanner.Scan(pattern);
        if (gameOffset == IntPtr.Zero) return IntPtr.Zero;
        int offset = game.ReadValue<int>((IntPtr)gameOffset+0x5);
        return (IntPtr)gameOffset+offset+0x9;
    });

    vars.GetNameFromFName = (Func<IntPtr, string>) ( ptr => {
        long id = game.ReadValue<long>((IntPtr)ptr);
        if(vars.fNameDict.ContainsKey(id))
        {
            return vars.fNameDict[id];
        }
        int key = game.ReadValue<int>((IntPtr)ptr);
        int partial = game.ReadValue<int>((IntPtr)ptr+4);
        int chunkOffset = key >> 16;
        int nameOffset = (ushort)key;
        IntPtr namePoolChunk = memory.ReadValue<IntPtr>((IntPtr)vars.FNamePool + (chunkOffset+2) * 0x8);
        Int16 nameEntry = game.ReadValue<Int16>((IntPtr)namePoolChunk + 2 * nameOffset);
        int nameLength = nameEntry >> 6;
        var result = "";
        if (partial == 0) {
            result = game.ReadString((IntPtr)namePoolChunk + 2 * nameOffset + 2, nameLength);
        } else {
            result = game.ReadString((IntPtr)namePoolChunk + 2 * nameOffset + 2, nameLength)+"_"+partial.ToString();
        }
        vars.fNameDict.Add(id, result);
        return result;
    });

    vars.startOnGainControl = false;
    vars.splitOnLoseControl = false;

    vars.fNameDict = new Dictionary<long,string>();
    vars.FNamePool = vars.GetFNamePool();
    if(vars.FNamePool == IntPtr.Zero)
        throw new Exception("init not ready");

    current.newestSaveFlag = "";
}

update
{
    if(current.saveFlagCount > 0)
    {
        current.newestSaveFlag = vars.GetNameFromFName((IntPtr)current.saveFlagPtr+0x8*(current.saveFlagCount-1));
    }

    if(settings["debugTextComponents"])
    {
        vars.SetTextComponent("Game State", current.gameState.ToString());
        vars.SetTextComponent("Newest Flag", current.newestSaveFlag);
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

split
{
    if(settings["splitOnBossKills"])
    {
        if(current.newestSaveFlag != old.newestSaveFlag && vars.bossKillFlags.Contains(current.newestSaveFlag))
        {
            return true;
        }
    }

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

        if(vars.splitOnLoseControl && current.map == "/Game/Maps/TitleNMainMenu")
            vars.splitOnLoseControl = false;
    }
}

reset
{
    return current.map != old.map && current.map == "/Game/Maps/Cutscenes/Opening_Master";
}