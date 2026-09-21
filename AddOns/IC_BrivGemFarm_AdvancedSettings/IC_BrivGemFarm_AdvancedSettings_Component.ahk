class IC_BrivGemFarm_AdvancedSettings_Component
{
    ;Saves Advanced Settings associated with BrivGemFarm
    SaveAdvancedSettings() {
        global
        Gui, ICScriptHub:Submit, NoHide
        g_BrivUserSettings[ "HiddenFarmWindow" ] := OptionSettingCheck_HiddenFarmWindow
        g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ] := OptionSettingCheck_RestoreLastWindowOnGameOpen
        g_BrivUserSettings[ "ForceOfflineRunThreshold" ] := OptionSettingEdit_ForceOfflineRunThreshold
        g_BrivUserSettings[ "BrivJumpBuffer" ] := OptionSettingEdit_BrivJumpBuffer
        g_BrivUserSettings[ "DashWaitBuffer" ] := OptionSettingEdit_DashWaitBuffer
        g_BrivUserSettings[ "WindowXPosition" ] := OptionSettingEdit_WindowXPosition
        g_BrivUserSettings[ "WindowYPosition" ] := OptionSettingEdit_WindowYPosition
        g_BrivUserSettings[ "IgnoreBrivHaste" ] := OptionSettingCheck_IgnoreBrivHaste
        g_BrivUserSettings[ "FortOnlyRestart" ] := OptionSettingCheck_FortOnlyRestart
        g_BrivUserSettings[ "WaitForZoneCompleted" ] := OptionSettingCheck_WaitForZoneCompleted
        g_BrivUserSettings[ "WardenUltThreshold" ] := OptionSettingEdit_WardenUltThreshold
        g_BrivUserSettings[ "FaridehUltThreshold" ] := OptionSettingEdit_FaridehUltThreshold
        IC_BrivGemFarm_AdvancedSettings_Functions.UpdateJumpSettings()
        g_SF.WriteObjectToJSON( A_LineFile . "\..\..\IC_BrivGemFarm_Performance\BrivGemFarmSettings.json" , g_BrivUserSettings )
        try ; avoid thrown errors when comobject is not available.
        {
            local SharedRunData := ComObjActive(g_BrivFarm.GemFarmGUID)
            SharedRunData.ReloadSettings("RefreshSettingsView")
        }
        return
    }

    LoadAdvancedSettings() {
        global
        if(g_BrivUserSettings)
        {
            GuiControl, ICScriptHub:, OptionSettingCheck_HiddenFarmWindow, % g_BrivUserSettings[ "HiddenFarmWindow" ]
            GuiControl, ICScriptHub:, OptionSettingCheck_RestoreLastWindowOnGameOpen, % g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ]
            GuiControl, ICScriptHub:, OptionSettingCheck_IgnoreBrivHaste, % g_BrivUserSettings[ "IgnoreBrivHaste" ]
            GuiControl, ICScriptHub:, OptionSettingCheck_FortOnlyRestart, % g_BrivUserSettings[ "FortOnlyRestart" ]
            GuiControl, ICScriptHub:, OptionSettingCheck_WaitForZoneCompleted, % g_BrivUserSettings[ "WaitForZoneCompleted" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_ForceOfflineRunThreshold, % g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_BrivJumpBuffer, % g_BrivUserSettings[ "BrivJumpBuffer" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_DashWaitBuffer, % g_BrivUserSettings[ "DashWaitBuffer" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_WindowXPosition, % g_BrivUserSettings[ "WindowXPosition" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_WindowYPosition, % g_BrivUserSettings[ "WindowYPosition" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_WardenUltThreshold, % g_BrivUserSettings[ "WardenUltThreshold" ]
            GuiControl, ICScriptHub:, OptionSettingEdit_FaridehUltThreshold, % g_BrivUserSettings[ "FaridehUltThreshold" ]
            IC_BrivGemFarm_AdvancedSettings_Functions.LoadPreferredBrivJumpSettings()
        }
        Gui, ICScriptHub:Submit, NoHide
        return
    }

    AddToolTips() {
        GUIFunctions.AddToolTip( "OptionSettingCheck_HiddenFarmWindow", "Disable the visibility of the second script window")
        GUIFunctions.AddToolTip( "OptionSettingCheck_RestoreLastWindowOnGameOpen", "Whether the script will try to switch focus back to the last active window immediately when the game opens")
        GUIFunctions.AddToolTip( "OptionSettingCheck_IgnoreBrivHaste", "Smart Briv Stack Calculations. Turn off to ignore haste stacks when deciding to stack. Will force stacking once every run.")
        GUIFunctions.AddToolTip( "OptionSettingCheck_FortOnlyRestart", "When running Forced Offline restarts IC will restart instantly rather than farming stacks while offline")
        GUIFunctions.AddToolTip( "OptionSettingCheck_WaitForZoneCompleted", "Complete the zone before online stacking")
        GUIFunctions.AddToolTip( "OptionSettingText_WardenUltThreshold", "Use Warden's ult while stacking when the number of enemies is greater than the threshold")
        GUIFunctions.AddToolTip( "OptionSettingText_FaridehUltThreshold", "Use Farideh's ult while stacking when the number of enemies is greater than the threshold")
        GUIFunctions.AddToolTip( "OptionSettingText_ForceOfflineRunThreshold", "Stack offline once in every N runs as reported by Resets done of current core (0 or 1 = disable)")
        GUIFunctions.AddToolTip( "OptionSettingText_BrivJumpBuffer", "How many areas before a modron reset zone that switching to e formation over q formation is desired.")
        GUIFunctions.AddToolTip( "OptionSettingText_DashWaitBuffer", "The distance from your modron's reset zone where dashwait will stop being activated.")
        GUIFunctions.AddToolTip( "OptionSettingText_WindowXPosition", "Where the gem farm script will appear horizontally across your screen")
        GUIFunctions.AddToolTip( "OptionSettingText_WindowYPosition", "Where the gem farm script will appear vertically on your screen")            
    }
}