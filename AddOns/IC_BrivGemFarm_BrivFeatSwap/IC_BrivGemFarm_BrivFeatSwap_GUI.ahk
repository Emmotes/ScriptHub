GUIFunctions.AddTab("Briv Feat Swap")

; Add GUI fields to this addon's tab.
Gui, ICScriptHub:Tab, Briv Feat Swap

GUIFunctions.UseThemeTextColor("HeaderTextColor", 700)
Gui, ICScriptHub:Add, Text, Section vBGFBFS_Status, Status:
Gui, ICScriptHub:Add, Text, x+5 w420 vBGFBFS_StatusText, Not Running
GUIFunctions.UseThemeTextColor("WarningTextColor", 700)

Gui, ICScriptHub:Add, Text, xs ys+20 Hidden vBGFBFS_StatusWarning, WARNING: Addon was loaded too late. Stop/start Gem Farm to resume.
GUIFunctions.UseThemeTextColor()

BrivGemFarm_BrivFeatSwap_Target()
{
    global
    if (g_BrivFeatSwap.GetPresetName() != "")
        GUIFunctions.ValidateIntegerInput(%A_GuiControl%, %A_GuiControl%)
    else if ((value := GUIFunctions.ValidateIntegerInput(0, 999)) != "RETURN")
        g_BrivFeatSwap.UpdatePath()
}

BrivGemFarm_BrivFeatSwap_Save()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    GuiControl, ICScriptHub: Disable, BrivGemFarm_BrivFeatSwap_Save
    g_BrivFeatSwap.Save(BrivGemFarm_BrivFeatSwap_TargetQ, BrivGemFarm_BrivFeatSwap_TargetE)
    GuiControl, ICScriptHub: Enable, BrivGemFarm_BrivFeatSwap_Save
}

BGFBFS_Preset()
{
    global
    Gui, ICScriptHub:Submit, NoHide
    local value := % %A_GuiControl%
    g_BrivFeatSwap.LoadPreset(value)
}

; Disable mod50 checkboxes when a preset has been selected.
BGFBFS_Mod50CheckBoxes()
{
    global
    if (g_BrivFeatSwap.GetPresetName() == "")
        g_BrivFeatSwap.UpdatePath()
    else
    {
        local beforeSubmit := % %A_GuiControl%
        GuiControl, ICScriptHub:, %A_GuiControl%, % beforeSubmit
        Gui, ICScriptHub:Submit, NoHide
    }
}

Class IC_BrivGemFarm_BrivFeatSwap_GUI
{
    LeftAlign := 20
    XSection := 10
    YSection := 10
    XSpacing := 10
    YSpacing := 10
    YTitleSpacing := 20
    ToolTipAdded := false

    SetupGroups()
    {
        global
        local xSpacing := this.XSpacing
        local yTitleSpacing := this.YTitleSpacing
        Gui, ICScriptHub:Add, Button, xs y+%yTitleSpacing% vBrivGemFarm_BrivFeatSwap_Save gBrivGemFarm_BrivFeatSwap_Save, Save
        Gui, ICScriptHub:Add, CheckBox, x+18 yp+5 vBGFBFS_Enabled, Enabled
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, Text, Section xs y+%yTitleSpacing% vBGFBFS_PresetText, Presets:
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, DropDownList, x+%xSpacing% yp-3 w100 vBGFBFS_Preset gBGFBFS_Preset
        GUIFunctions.UseThemeTextColor("WarningTextColor", 700)
        Gui, ICScriptHub:Add, Text, x+27 yp w300 R2 vBGFBFS_PresetWarningText
        GUIFunctions.UseThemeTextColor()
        this.SetupSkipSetupGroup()
        this.SetupStacksSetupGroup()
        this.SetupPreferredBrivJumpZonesGroup()
        this.SetupBGFLUGroup()
        this.AddToolTips()
    }

    SetupSkipSetupGroup()
    {
        global
        local leftAlign := this.LeftAlign
        local xSection := this.XSection
        local xSpacing := this.XSpacing
        local ySpacing := this.YSpacing
        local yTitleSpacing := this.YTitleSpacing
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, Section xs vBGFBFS_SkipSetup, Skip setup
        Gui, ICScriptHub:Font, w400
        Gui, ICScriptHub:Add, Text, xs+%xSection% ys+%yTitleSpacing% w125 vBGFBFS_DetectedText, Briv skip:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapReads xs+%xSection% y+%ySpacing% w30, Reads
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapTarget x+15 w30, Target
        GuiControlGet, pos, ICScriptHub:Pos, BrivFeatSwapTarget
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapQText xs+%xSection% y+%ySpacing% w15, Q:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapQValue x+%xSpacing% w20
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, x%posX% y+-16 h19 w33 Limit3 vBrivGemFarm_BrivFeatSwap_TargetQ gBrivGemFarm_BrivFeatSwap_Target, 0
        GUIFunctions.UseThemeTextColor("WarningTextColor")
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapQPartialText x+%xSpacing% h19 w50 0x200
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapWText xs+%xSection% y+%ySpacing% w15, W:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapWValue x+%xSpacing% w20
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapEText xs+%xSection% y+%ySpacing% w15, E:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapEValue x+%xSpacing% w20
        GUIFunctions.UseThemeTextColor("InputBoxTextColor")
        Gui, ICScriptHub:Add, Edit, x%posX% y+-16 h19 w33 Limit3 vBrivGemFarm_BrivFeatSwap_TargetE gBrivGemFarm_BrivFeatSwap_Target, 0
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapsMadeThisRunText xs+%xSection% y+%ySpacing%, SwapsMadeThisRun:
        Gui, ICScriptHub:Add, Text, vBrivFeatSwapsMadeThisRunValue x+%xSpacing% w40
        ; Resize
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_SkipSetup
        GuiControlGet, pos, ICScriptHub:Pos, BrivFeatSwapsMadeThisRunValue
        local newHeight := posY + posH - posGY + this.YSection
        local newWidth := posX + posW - posGX + this.XSection
        GuiControl, ICScriptHub:Move, BGFBFS_SkipSetup, h%newHeight% w%newWidth%
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_SkipSetup
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_Preset
        newWidth := posGX + posGW - posX
        GuiControl, ICScriptHub:Move, BGFBFS_Preset, w%newWidth%
    }

    SetupPreferredBrivJumpZonesGroup()
    {
        global
        local leftAlign := this.LeftAlign
        local xSpacing := this.XSpacing
        local ySpacing := this.YSpacing
        local yTitleSpacing := this.YTitleSpacing
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_SkipSetup
        local nextPos := posGY + posGH + ySpacing
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, Section x%posGX% y%nextPos% vBGFBFS_PreferredBrivJumpZones, Preferred Briv Jump Zones
        Gui, ICScriptHub:Font, w400
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_PreferredBrivJumpZones
        this.BuildModTable(posX + this.XSection, posY)
        ; Resize
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_PreferredBrivJumpZones
        GuiControlGet, pos, ICScriptHub:Pos, BGFBFS_CopyPasteBGFAS_Mod_50_50
        local newHeight := posY + posH - posGY + this.YSection
        local newWidth := posX + posW - posGX + this.XSection
        GuiControl, ICScriptHub:Move, BGFBFS_PreferredBrivJumpZones, h%newHeight% w%newWidth%
    }

    SetupBGFLUGroup()
    {
        global
        local xSpacing := this.XSpacing
        local ySpacing := this.YSpacing
        local yTitleSpacing := this.YTitleSpacing
        Gui, ICScriptHub:Font, w700
        Gui, ICScriptHub:Add, GroupBox, Section xs y+%yTitleSpacing% vBGFBFS_BGFLU, BrivGemFarm LevelUp
        Gui, ICScriptHub:Font, w400
        ; Resize
        GuiControlGet, posG, ICScriptHub:Pos, BGFBFS_BGFLU
        GuiControlGet, posG2, ICScriptHub:Pos, BGFBFS_PreferredBrivJumpZones
        local newHeight := posY + posH - posGY + this.YSection
        GuiControl, ICScriptHub:Move, BGFBFS_BGFLU, h%newHeight% w%posG2W%
        ; Link to LevelUp addon
        Gui, ICScriptHub:Add, Text, Hidden xs+%xSpacing% y+%yTitleSpacing% vBGFBFS_GetLevelUpAddonText, % "Use the "
        GUIFunctions.UseThemeTextColor("SpecialTextColor1")
        local link := "https://github.com/imp444/IC_Addons/tree/main/IC_BrivGemFarm_LevelUp_Extra"
        Gui, ICScriptHub:Add, Link, Hidden x+0 vBGFBFS_GetLevelUpAddonLink hwndBGFBFS_GetLevelUpAddonLink, <a href="%link%">LevelUp</a>
        this.LinkUseDefaultColor(BGFBFS_GetLevelUpAddonLink)
        GUIFunctions.UseThemeTextColor()
        Gui, ICScriptHub:Add, Text, Hidden x+0 vBGFBFS_GetLevelUpAddonText2, % " addon to walk early zones."
    }

    ; https://www.autohotkey.com/boards/viewtopic.php?t=37894
    LinkUseDefaultColor(hLink, Use := True)
    {
       VarSetCapacity(LITEM, 4278, 0)            ; 16 + (MAX_LINKID_TEXT * 2) + (L_MAX_URL_LENGTH * 2)
       NumPut(0x03, LITEM, "UInt")               ; LIF_ITEMINDEX (0x01) | LIF_STATE (0x02)
       NumPut(Use ? 0x10 : 0, LITEM, 8, "UInt")  ; ? LIS_DEFAULTCOLORS : 0
       NumPut(0x10, LITEM, 12, "UInt")           ; LIS_DEFAULTCOLORS
       While DllCall("SendMessage", "Ptr", hLink, "UInt", 0x0702, "Ptr", 0, "Ptr", &LITEM, "UInt") ; LM_SETITEM
          NumPut(A_Index, LITEM, 4, "Int")
;       GuiControl, +Redraw, %hLink%
    }

    ; Builds mod50 checkboxes for PreferredBrivJumpZones.
    BuildModTable(xLoc, yLoc)
    {
        leftAlign := xLoc
        Loop, 50
        {
            if(Mod(A_Index, 10) != 1)
                xLoc += 35
            else
            {
                xLoc := leftAlign
                yLoc += 20
            }
            this.AddControlCheckbox(xLoc, yLoc, A_Index)
        }
    }

    ; Adds a single checkBox for PreferredBrivJumpZones.
    AddControlCheckbox(xLoc, yLoc, loopCount)
    {
        global
        Gui, ICScriptHub:Add, Checkbox, vBGFBFS_CopyPasteBGFAS_Mod_50_%loopCount% Checked x%xLoc% y%yLoc% gBGFBFS_Mod50CheckBoxes, % loopCount
    }

    ; Show tooltips on mouseover.
    AddToolTips()
    {
        GUIFunctions.AddToolTip("BGFBFS_Enabled", "Enable/disable this addon.")
        GUIFunctions.AddToolTip("BGFBFS_PresetText", "Select a preset. Choose the blank option to use custom settings.")
        GUIFunctions.AddToolTip("BGFBFS_Preset", "Select a preset. Choose the blank option to use custom settings.")
        GUIFunctions.AddToolTip("BrivGemFarm_BrivFeatSwap_TargetQ", "Number of areas Briv will skip in Q formation. To simulate walking, enter 0.")
        GUIFunctions.AddToolTip("BrivGemFarm_BrivFeatSwap_TargetE", "Number of areas Briv will skip in E formation. To simulate walking, enter 0.")
    }

    ; Show Briv's slot 4 current item gild/raity/level.
    AddBrivSkipTooltip()
    {
        GuiControlGet, isVisible, ICScriptHub:Visible, BGFBFS_DetectedText
        if (!isVisible)
            return
        loot := IC_BrivGemFarm_Class.BrivFunctions.GetBrivLoot()
        gild := loot.gild
        enchant := loot.enchant
        rarity := loot.rarity
        str := (gild == 1) ? "Shiny " : (gild == 2) ? "Golden " : ""
        str .= (rarity == 1) ? "Common " : (rarity == 2) ? "Uncommon " : (rarity == 3) ? "Rare " : (rarity == 4) ? "Epic " : ""
        str .= enchant != "" ? "level " . (enchant + 1) : ""
        GUIFunctions.AddToolTip("BGFBFS_DetectedText", str)
        this.ToolTipAdded := true
    }
}