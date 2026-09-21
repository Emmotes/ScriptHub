; ############################################################
;                    Add tab to the GUI
; ############################################################
GUIFunctions.AddTab("BrivGF Advanced")

; ############################################################
;               Create the Gui of the tab here
; ############################################################
; Select the tab you created above
Gui, ICScriptHub:Tab, BrivGF Advanced

;g_BrivUserSettings[ "IgnoreBrivHaste" ]
;g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
;g_BrivUserSettings[ "BrivJumpBuffer" ]
;g_BrivUserSettings[ "DashWaitBuffer" ]
;g_BrivUserSettings[ "HiddenFarmWindow" ]
;g_BrivUserSettings[ "RestoreLastWindowOnGameOpen" ]
;g_BrivUserSettings[ "WindowXPosition" ]
;g_BrivUserSettings[ "WindowYPosition" ]
;g_BrivUserSettings[ "BrivLevelingThresholdsCount" ] 
;g_BrivUserSettings[ "BrivLevelingThresholds" ]
Class IC_BrivGemFarm_AdvancedSettings_GUI
{
    Init()
    {
        global
        ; Advanced Options Settings Group (Checkboxes only)
        Gui, ICScriptHub:Add, GroupBox, Section x10 y+15 w215 h190 vWindowSettingsGroup, Advanced Settings
        GuiControlGet, ws, ICScriptHub:Pos, WindowSettingsGroup
        Gui, ICScriptHub:Add, Checkbox, vOptionSettingCheck_HiddenFarmWindow xs+10 ys+20, Hide Gem Farm Window
        Gui, ICScriptHub:Add, Checkbox, vOptionSettingCheck_RestoreLastWindowOnGameOpen xs+10 y+5, Restore Last Window On Game Open
        Gui, ICScriptHub:Add, Checkbox, vOptionSettingCheck_IgnoreBrivHaste xs+10 y+5, Predict Stacks
        Gui, ICScriptHub:Add, Checkbox, vOptionSettingCheck_FortOnlyRestart xs+10 y+5, No Stack FORTs
        Gui, ICScriptHub:Add, Checkbox, vOptionSettingCheck_WaitForZoneCompleted xs+10 y+5, Complete Zone Before Stacking

        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_WardenUltThreshold xs+10 y+20 w40, % g_BrivUserSettings[ "WardenUltThreshold" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_WardenUltThreshold x+5 yp hp 0x200, Warden Ult Threshold (0 = off)
        
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_FaridehUltThreshold xs+10 y+5 w40, % g_BrivUserSettings[ "FaridehUltThreshold" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_FaridehUltThreshold x+5 yp hp 0x200, Farideh Ult Threshold (0 = off)

        ; Advanced Settings Group (Edit boxes/Numerical fields only)
        Gui, ICScriptHub:Add, GroupBox, x235 ys w215 h190 vAdvancedSettingsGroup, Advanced Settings
        
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_ForceOfflineRunThreshold x245 ys+20 w50, % g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_ForceOfflineRunThreshold x+5 yp hp 0x200, ForceOfflineRunThreshold

        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_BrivJumpBuffer x245 y+5 w50, % g_BrivUserSettings[ "BrivJumpBuffer" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_BrivJumpBuffer x+5 yp hp 0x200, BrivJumpBuffer

        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_DashWaitBuffer x245 y+5 w50, % g_BrivUserSettings[ "DashWaitBuffer" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_DashWaitBuffer x+5 yp hp 0x200, DashWaitBuffer

        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_WindowXPosition x245 y+5 w50, % g_BrivUserSettings[ "WindowXPosition" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_WindowXPosition x+5 yp hp 0x200, WindowXPosition

        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, vOptionSettingEdit_WindowYPosition x245 y+5 w50, % g_BrivUserSettings[ "WindowYPosition" ]
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vOptionSettingText_WindowYPosition x+5 yp hp 0x200, WindowyPosition

        ; Preferred Briv Jump Zones Group
        preferredY := wsY + 205
        Gui, ICScriptHub:Add, GroupBox, x10 y%preferredY% w440 h235 vPreferredJumpGroup, Preferred Briv Jump Zones
        
        local controlLoc := IC_BrivGemFarm_AdvancedSettings_Functions.BuildModTables(20, preferredY)
        IC_BrivGemFarm_AdvancedSettings_Component.LoadAdvancedSettings()

        GuiControlGet, pos, ICScriptHub:Pos, PreferredJumpGroup
        posY := posY + posH + 15
        if(IsObject(IC_BrivGemFarm_Component))
        {
            Gui, ICScriptHub:Add, Picture, x15 y%posY% h50 w50 gBrivGemFarmAdvancedUpdateStatusAndClick vBrivGemFarmAdvancedSaveButton, %g_SaveButton%
            Gui, ICScriptHub:Add, Text, x+10 y+-33 w250 vBrivGemFarmAdvancedStatusText,
        }
        else
        {
            Gui, ICScriptHub:Add, Text, x10 y+30 w250 vBrivGemFarmAdvancedStatusText, Save settings using main Briv Gem Farm tab.
        }
    }

    LoadBrivLevelingThresholds(thresholds, count)
    {
        GuiControl, ICScriptHub:, OptionSettingEdit_BrivLevelingCount, % count
        Loop, 15
        {
            zone := thresholds[A_Index].zone
            level := thresholds[A_Index].level
            GuiControl, ICScriptHub:, BrivLevelingZone%A_Index%, % zone
            GuiControl, ICScriptHub:, BrivLevelingLevel%A_Index%, % level
        }
        this.UpdateBrivLevelingRows(count)
    }

    UpdateBrivLevelingRows(count)
    {
        GuiControlGet, b, ICScriptHub:Pos, BrivLevelingGroup
        if (!bW)
            return
        
        count := count == "" ? 0 : count
        countX := bX + 10
        countY := bY + 18
        
        ; Bug when using Move in a Tab control
        GuiControl, ICScriptHub:MoveDraw, OptionSettingEdit_BrivLevelingCount, x%countX% y%countY%
        GuiControlGet, bug, ICScriptHub:Pos, OptionSettingEdit_BrivLevelingCount
        offX := bugX - countX
        offY := bugY - countY
        countX -= offX
        countY -= offY
        GuiControl, ICScriptHub:MoveDraw, OptionSettingEdit_BrivLevelingCount, x%countX% y%countY%
        GuiControl, ICScriptHub:MoveDraw, OptionSettingText_BrivLevelingCountText, % "x" (countX + 45) " y" countY

        gridStartY := countY + 28
        maxY := gridStartY

        Loop, 15
        {
            if (A_Index <= count)
            {
                row := Ceil(A_Index / 3)
                col := Mod(A_Index - 1, 3)

                colX := bX + 10 + (col * 142) - offX
                rowY := gridStartY + (row - 1) * 28

                GuiControl, ICScriptHub:MoveDraw, BrivLevelingZone%A_Index%, x%colX% y%rowY%
                GuiControl, ICScriptHub:MoveDraw, BrivLevelingZoneText%A_Index%, % "x" (colX + 42) " y" rowY
                GuiControl, ICScriptHub:MoveDraw, BrivLevelingLevel%A_Index%, % "x" (colX + 75) " y" rowY
                GuiControl, ICScriptHub:MoveDraw, BrivLevelingLevelText%A_Index%, % "x" (colX + 117) " y" rowY                
                GuiControl, ICScriptHub:Show, BrivLevelingZone%A_Index%
                GuiControl, ICScriptHub:Show, BrivLevelingZoneText%A_Index%
                GuiControl, ICScriptHub:Show, BrivLevelingLevel%A_Index%
                GuiControl, ICScriptHub:Show, BrivLevelingLevelText%A_Index%
                
                maxY := rowY + 22
            }
            else
            {
                GuiControl, ICScriptHub:Hide, BrivLevelingZone%A_Index%
                GuiControl, ICScriptHub:Hide, BrivLevelingZoneText%A_Index%
                GuiControl, ICScriptHub:Hide, BrivLevelingLevel%A_Index%
                GuiControl, ICScriptHub:Hide, BrivLevelingLevelText%A_Index%
            }
        }
        
        if (count > 0)
            newH := maxY - (bY - offY) + 10
        else
            newH := countY + 28 - (bY - offY)
            
        GuiControl, ICScriptHub:MoveDraw, BrivLevelingGroup, h%newH%


        verticalDistance := newH - bH
		GUIFunctions.VerticalReposition("BrivGemFarmAdvancedStatusText", verticalDistance)
		GUIFunctions.VerticalReposition("BrivGemFarmAdvancedSaveButton", verticalDistance)
        if (isObject(IC_Advanced_PresetRoutes_Component))
        {
		    GUIFunctions.VerticalReposition("Advanced_PresetRoutes", verticalDistance)
		    GUIFunctions.VerticalReposition("APR_Header", verticalDistance)
		    GUIFunctions.VerticalReposition("APR_Set", verticalDistance)
		    GUIFunctions.VerticalReposition("APR_FeatSwapNote", verticalDistance)
        }
    }
}

IC_BrivGemFarm_AdvancedSettings_GUI.Init()

BrivLevelingThresholds()
{
    global
    thresholds := []
    GuiControlGet, count,, OptionSettingEdit_BrivLevelingCount
    Loop, % count
    {
        GuiControlGet, zone,, BrivLevelingZone%A_Index%
        GuiControlGet, level,, BrivLevelingLevel%A_Index%
        if (zone != "" AND level != "")
            thresholds.Push({"zone": zone, "level": level})
    }
    g_BrivUserSettings[ "BrivLevelingThresholds" ] := thresholds
}

BrivLevelingCount()
{
    global
    if ((value := GUIFunctions.ValidateIntegerInput(1, 15)) != "RETURN")
    {
        g_BrivUserSettings[ "BrivLevelingThresholdsCount" ] := value
        IC_BrivGemFarm_AdvancedSettings_GUI.UpdateBrivLevelingRows(value)
    }
}

BrivGemFarmAdvancedUpdateStatusAndClick()
{
    global BrivGemFarmAdvancedStatusText
    Briv_Save_Clicked()
    GUIFunctions.UpdateStatusTextWithClear(BrivGemFarmAdvancedStatusText, "Saved...", timer := 3000)
}

; ############################################################

IC_BrivGemFarm_AdvancedSettings_Component.AddToolTips()