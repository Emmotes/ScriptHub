#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk
class IC_BrivGemFarm_Class
{   
    static FARIDEH_ID := 33
    ; static WARDEN_ID := 36
    ; static BRIV_ID := 58
    ; static MELF_ID := 59
    ; static TATYANA_ID := 97

    TimerFunctions := {}
    TargetStacks := 0
    GemFarmGUID := ""
    StackFailAreasTally := {}
    LastStackSuccessArea := 0
    MaxStackRestartFails := 3
    StackFailAreasThisRunTally := {}
    StackFailRetryAttempt := 0
    DoKeySpam := True
    keyspam := Array()
    LastResetCount := 0
    ThisRunStart := 0
    IsInModronFormation := True
    BossKillAttempt := False
    previousSilverChestCount := 0
    previousGoldChestCount := 0
    DoneLeveling := False
    ClickSpam := "{ClickDmg}"
    LockLevelUp := False
    ; Levelup Addon compatability
    ChampIDs := {}
    UsedWardenUlt := false
    UsedFaridehUlt := false
    SkipNextChestCheck := False
    FaridehInParty := False

    ; Speed Champs
    InitChamps()
    {
        this.ChampIDs := {}
        this.ChampIDs[Briv := "58"] := 58 ; must be in quotes so object is treated as dict and not an array that will modify keys.
        this.ChampIDs[Widdle := 91] := 91
        this.ChampIDs[Ellywick := 83] := 83
        this.ChampIDs[HewMaan := 75] := 75
        this.ChampIDs[Tatyana := 97] := 97
        this.ChampIDs[Melf := 59] := 59
        this.ChampIDs[Dynaheir := 145] := 145
        this.ChampIDs[Diana := 148] := 148
        this.ChampIDs[BBEG := 125] := 125
        this.ChampIDs[Dungeon_Master := 99] := 99
        this.ChampIDs[Imoen := 117] := 117
        this.ChampIDs[Laezel := 128] := 128
        this.ChampIDs[Deekin := 28] := 28
        this.ChampIDs[Virgil := 115] := 115
        this.ChampIDs[Sentry := 52] := 52
        this.ChampIDs[Nahara := 102] := 102
        this.ChampIDs[Dhani := 89] := 89
        this.ChampIDs[Kent := 114] := 114
        this.ChampIDs[Gazrick := 98] := 98
        this.ChampIDs[Alyndra := 79] := 79
        this.ChampIDs[Selise := 81] := 81
        this.ChampIDs[Vi := 95] := 95
        this.ChampIDs[Havilar := 56] := 56
        this.ChampIDs[Shandie := 47] := 47
        this.ChampIDs[Minsc := 7] := 7
        this.ChampIDs[Baldric := 165] := 165 
        this.ChampIDs[Thellora := 139] := 139
    }

    ;=====================================================
    ;Primary Functions for Briv Gem Farm
    ;=====================================================
    ;The primary loop for gem farming using Briv and modron.
    GemFarm()
    {
        errLevel := this.GemFarmPreLoopSetup()
        try
            g_ScriptHubComs.RunTimersOnGemFarmStart()
        if (errLevel < 0)
            return errLevel
        this.InitChamps()            
        this.FormationModron := formationModron := g_SF.Memory.GetActiveModronFormation()
        loop
        {
            g_SharedData.LoopString := "Main Loop"
            CurrentZone := g_SF.Memory.ReadCurrentZone()
            if (CurrentZone == "" AND !g_SF.SafetyCheck() ) ; Check for game closed
                g_SF.ToggleAutoProgress( 1, false, true ) ; Turn on autoprogress after a restart
            if (this.GemFarmShouldSetFormation())
                g_SF.SetFormation(g_BrivUserSettings)
            if (g_SF.Memory.ReadResetting())
                this.ModronResetCheck()
            else
                this.GemFarmDoNonModronActions(CurrentZone)
            if ((g_SF.Memory.ReadResetsCount() > this.LastResetCount OR g_SharedData.TriggerStart) AND PreviousZone := 1) ; first loop or Modron has reset. Set previouszone to 1 (:= is intentional)
                this.LastResetCount := this.GemFarmResetSetup(formationModron, doBasePartySetup := True), CurrentZone := g_SF.Memory.ReadCurrentZone() 
            if (g_SharedData.StackFail != 2)
                g_SharedData.StackFail := Max(this.TestForSteelBonesStackFarming(), g_SharedData.StackFail)
            if (g_SharedData.StackFail == 2 OR g_SharedData.StackFail == 4 OR g_SharedData.StackFail == 6 ) ; OR g_SharedData.StackFail == 3
                g_SharedData.TriggerStart := true
            if (!Mod( g_SF.Memory.ReadCurrentZone(), 5 ) AND Mod( g_SF.Memory.ReadHighestZone(), 5 ) AND !g_SF.Memory.ReadTransitioning())
                g_SF.ToggleAutoProgress( 1, true ) ; Toggle autoprogress to skip boss bag
            if (CurrentZone > PreviousZone ) ; needs to be greater than because offline could get stuck stacking in descending zones.
            {
                PreviousZone := CurrentZone
                this.GemFarmDoZone(formationModron)
                continue
            }
            g_SF.ToggleAutoProgress( 1 )
            if (g_SF.CheckifStuck())
                this.GemFarmDoStuckCleanup()
            Sleep, 20 ; here to keep the script responsive.
        }
    }

    ;=====================================================
    ;Primary Gem Farm loop functions
    ;=====================================================
    ; Records the end of a run for statistics.
    RecordEndRun()
    {
        g_SharedData.LastRunTime := A_TickCount - This.ThisRunStart
        , g_SharedData.TotalRunsCount += 1
        This.ThisRunStart := A_TickCount
    }

    ; setup steps to take to set up gem farm before starting the primary loop. Returns 0 on normal, negative on error.
    GemFarmPreLoopSetup(includeBrivFormation3 := False)
    {
        g_SharedData.TriggerStart := true
        g_SF.Hwnd := WinExist("ahk_exe " . g_UserSettings[ "ExeName"])
        existingProcessID := g_UserSettings[ "ExeName"]
        Process, Exist, %existingProcessID%
        g_SF.PID := ErrorLevel
        ; Process, Priority, % g_SF.PID, High
        Process, Priority, % g_SF.PID, Realtime
        g_SF.Memory.OpenProcessReader()
        if ((g_SF.CurrentAdventure := g_SF.VerifyAdventureLoaded()) < 0)
            return -2
        g_ServerCall.UpdatePlayServer()
        g_SF.PatronID := g_SF.Memory.ReadPatronID()
        g_SF.ResetServerCall()
        this.LastStackSuccessArea := g_BrivUserSettings [ "StackZone" ]
        this.StackFailAreasThisRunTally := {}
        g_SF.GameStartFormation := g_BrivUserSettings[ "BrivJumpBuffer" ] > 0 ? 3 : 1
        g_SaveHelper.Init() ; slow call, loads briv dictionary (3+s)
        if (this.PreFlightCheck(includeBrivFormation3) == -1) ; Did not pass pre flight check.
            return -1
        ;Pre-load formations
        loop, 3
            g_SF.Memory.GetFormationByFavorite(A_Index)
        g_SF.Memory.GetActiveModronFormationSaveSlot()
        this.ThelloraRushZone := g_SF.Memory.GetFavorExponentFor("Corellon") + 1
        g_PreviousZoneStartTime := A_TickCount
        g_SharedData.StackFail := 0
        if (g_SF.Memory.ReadNumAttackingMonstersReached() >= 10 || g_SF.Memory.ReadNumRangedAttackingMonsters())
            g_SF.FallBackFromZone(2000)
        g_SF.SetFormation(g_BrivUserSettings)
        return 0
    }

    ; Steps to run when a modron reset occurs or the gem farm first starts.
    GemFarmResetSetup(formationModron := "", doBasePartySetup := False)
    {
        static lowestHasteStacks := 9999999
        static firstRun := True
        
        g_SharedData.LoopString := "Reset Setup"
        g_PreviousZoneStartTime := A_TickCount
        g_SF.ToggleAutoProgress( 0, false, true )
        g_SharedData.StackFail := this.CheckForFailedConv()
        this.keyspam := Array()
        g_SF.Memory.ActiveEffectKeyHandler.Refresh()
        ; Don't reset last stack success area if 3 or more runs have failed to stack.
        this.LastStackSuccessArea := this.StackFailAreasTally[g_BrivUserSettings[ "StackZone" ]] < this.MaxStackRestartFails ? g_BrivUserSettings[ "StackZone" ] : this.LastStackSuccessArea
        this.StackFailAreasThisRunTally := {}
        this.StackFailRetryAttempt := 0
        this.DoneLeveling := False
        this.LockLevelUp := False
        g_SF.FormationLevelingLock := False
        g_SF.AlreadyOfflineStackedThisRun := false
        g_SharedData.BossesHitThisRun := 0
        g_SharedData.SwapsMadeThisRun := 0
        g_SharedData.TriggerStart := false
        g_SharedData.LoopString := "Main Loop"
        g_SharedData.LowestHasteStacks := lowestHasteStacks := firstRun ? "" : g_SF.Memory.ReadHasteStacks() 
        firstRun := False
        g_SharedData.PlayServer := StrSplit(StrSplit(g_ServerCall.webroot,".")[1], "/")[3]
        ; Do Chests after Reset
        if (!this.SkipNextChestCheck)
            g_SharedData.LoopString := this.CheckAndDoChests()
        this.SkipNextChestCheck := False
        
        if(doBasePartySetup)
        {
            g_SF.WaitForFirstGoldSetup()
            if g_BrivUserSettings[ "Fkeys" ]
                this.keyspam := g_SF.GetFormationFKeys(formationModron)
            this.DoKeySpam := true
            this.DoPartySetup(formationModron)
        }
        else
            g_SF.WaitForFirstGold()
        g_SharedData.LoopString := "Main Loop"
        if(this.GemFarmShouldSetFormation())
            g_SF.SetFormationForStart()
        return g_SF.Memory.ReadResetsCount()
    }

    GemFarmDoZone(formationModron := "")
    {
        g_SharedData.LoopString := "Main Loop - Do Zone"
        if (!(Mod( g_SF.Memory.ReadCurrentZone(), 5)) AND !(Mod( g_SF.Memory.ReadHighestZone(), 5)))
            this.GemFarmDoTouchedBoss()
        if (this.DoKeySpam AND g_BrivUserSettings[ "Fkeys" ] AND g_SF.AreChampionsUpgraded(formationModron)) 
        { ; leveling completed, remove champs from keyspam.
            g_SF.DirectedInput(hold:=0,release:=1, this.keyspam) ;keysup
            g_SF.DirectedInput(hold:=0,release:=1, this.ClickSpam) ;click key up
            this.DoKeySpam := false
        }
        g_SF.InitZone( this.keyspam )
        g_SF.ToggleAutoProgress( 1 )
    }

    ; If gem farm lands on a boss, do these steps.
    GemFarmDoTouchedBoss()
    {
        g_SharedData.TotalBossesHit++
        g_SharedData.BossesHitThisRun++
    }

    ; Do things that are needed after a game reset from being stuck
    GemFarmDoStuckCleanup()
    {
        this.RecordEndRun()
        g_SharedData.TriggerStart := true
        g_SharedData.StackFail := StackFailStates.FAILED_TO_PROGRESS ; 3
        g_SharedData.StackFailStats.TALLY[g_SharedData.StackFail] += 1
    }

    ; Determins whether to use the default set formation each loop
    GemFarmShouldSetFormation()
    {
        return true
    }

    ; function that can be overridden for extra actions taken if no modron reset is occurring. Currently set to leveling.
    GemFarmDoNonModronActions(currentZone := "")
    {

        static clickBonusAmount := 100
        g_SharedData.LoopString := "Main Loop - Do Actions"
        ; static lastZone := 0
        if(this.DoneLeveling)
            return
        ; this.Memory.ReadHeroUpgradeRequiredLevelByIndex(champID, A_Index - 1) ;bugfix ReadHeroUpgradesSize
        keyspam := g_SF.GetFormationFKeys(g_SF.Memory.GetFormationByFavorite(g_SF.Memory.ReadMostRecentFormationFavorite()))
        if(keyspam.Length() > 0)
            this.DoBasicLeveling(keyspam)
        else
            this.DoneLeveling := True
        g_SF.DirectedInput(,,currKeySpam*)
        if(g_SF.Memory.ReadClickLevel() <= (g_SF.Memory.ReadcurrentZone() + clickBonusAmount))
            g_SF.DirectedInput(,,this.ClickSpam)
    }

    DoBasicLeveling(keyspam := "")
    {
        currKeySpam := []
        for k,hotkeyVal in keyspam
        {
            ; extract fkey number, check champ in seat of number, check if it can afford to upgrade - if yes add to spam
            seatID := SubStr(hotkeyVal, 3, -1)
            champID := g_SF.Memory.ReadSelectedChampIDBySeat(seatID)
            if(!this.LockLevelUp)
                g_SF.DirectedInput(,,hotkeyVal)
            if(!g_SF.Memory.ReadBoughtLastUpgradeBySeat(seatID))
                if(this.CanAffordUpgrade(champID))
                    if(!g_SF.Memory.DoesChampHavePurchasedWithoutUpgraded(champID))
                        currKeySpam.Push(hotkeyVal) ; increment index but add index from before increment
        }
        this.LockLevelUp := True
        if(currKeyspam.Length() > 0)
        {
            g_SF.DirectedInput(,,currKeySpam*)
            if(g_SF.ReadClickLevel() <= (g_SF.ReadcurrentZone() + clickBonusAmount))
                g_SF.DirectedInput(,,this.ClickSpam)
            Sleep, %sleepTime%
        }
    }

    CanAffordUpgrade(champID)
    {
        if (champID < 1)
            return false
        seat := g_SF.Memory.ReadChampSeatByID(champID)
        cost := g_SF.Memory.ReadLevelUpCostBySeat(seat)
        gold := g_SF.Memory.ReadGoldString()
        compareIntCost := g_SF.ConvertNumberStringToInt(cost)
        compareIntGold := g_SF.ConvertNumberStringToInt(gold)
        return compareIntCost < compareIntGold
    }

    ;=====================================================
    ;Functions for Briv Stack farming, mostly for gem runs
    ;=====================================================
    ;Various checks to determine when to stack SteelBones should be stacked or failed to stack.
    TestForSteelBonesStackFarming()
    {
        CurrentZone := g_SF.Memory.ReadCurrentZone()
        ; Don't test while modron resetting.
        if (CurrentZone < 0 OR CurrentZone >= g_SF.ModronResetZone)
            return
        ; TODO Add test for if boss zone stacking is necessary.
        if (!Mod( g_SF.Memory.ReadCurrentZone(), 5)) ;land on boss zone = do not stack here.
            return 0
        stacks := this.GetNumStacksFarmed()
        targetStacks := g_BrivUserSettings[ "TargetStacks" ]
        
        stackfail := 0
        forcedResetReason := ""
        ; passed stack zone, start stack farm. Normal operation.
        if (stacks < targetStacks AND CurrentZone > g_BrivUserSettings[ "StackZone" ])
        {
            ; normal-success / adjusted-success behavior. Use settings zone or adjusted zone if good zone has been found. (Resets to StackZone for 3 runs before sticking)
            if (this.LastStackSuccessArea == CurrentZone ) 
                this.StackFarm()
            ; abnormal stacking - Normal zone failed, current zone is later and has 0 or "" failures on this zone. Try it.
            else if (!this.StackFailAreasTally[CurrentZone] ) 
                this.StackFarm()
            ; only stack farm if this zone hasn't been tried this run yet and still below max tries. 
            else if (this.LastStackSuccessArea == 0 AND !this.StackFailAreasThisRunTally[CurrentZone] AND this.StackFailAreasTally[CurrentZone] < this.MaxStackRestartFails)
                this.StackFarm()
            ; Safety - One more jump will be over modron reset and stacking has not been done.
            else if (CurrentZone > g_SF.Memory.GetModronResetArea() - (ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount() + 1))
                this.StackFarm()
            return 0
        }
        if ("" == (hasteStacks := g_SF.Memory.ReadHasteStacks())) ; can't read haste, skip next steps
            return stackFail
        ; stack briv between min zone and stack zone if briv is out of jumps (if stack fail recovery is on)
        if (hasteStacks < 50 AND stacks < targetStacks AND CurrentZone >= g_BrivUserSettings[ "MinStackZone" ] AND g_BrivUserSettings[ "StackFailRecovery" ] AND CurrentZone <= g_BrivUserSettings[ "StackZone" ] )
        {
            ; only use current zone if there's been no/non-excess issues with it.
            if (!this.StackFailAreasThisRunTally[CurrentZone] AND (!this.StackFailAreasTally[CurrentZone] OR this.StackFailAreasTally[CurrentZone] < this.MaxStackRestartFails))
            {
                stackFail := StackFailStates.FAILED_TO_REACH_STACK_ZONE ; 1
                g_SharedData.StackFailStats.TALLY[stackfail] += 1
                this.StackFarm()
                return stackfail
            }
            return 0
        }
        ; Briv ran out of jumps but has enough stacks for a new adventure, restart adventure. With protections from repeating too early or resetting within 5 zones of a reset.
        if (hasteStacks < 50 AND stacks >= targetStacks AND g_SF.Memory.ReadHighestZone() > 10 AND (g_SF.Memory.GetModronResetArea() - g_SF.Memory.ReadHighestZone() > 5 ))
        {
            this.RecordEndRun()
            stackFail := StackFailStates.FAILED_TO_REACH_STACK_ZONE_HARD ; 4
            g_SharedData.StackFailStats.TALLY[stackfail] += 1
            forcedResetReason := "Briv ran out of jumps but has stacks for next. [@" . g_SF.Memory.ReadHighestZone() . "]"
            g_SF.RestartAdventure(forcedResetReason)
        }         
        return stackfail
    }

    ; Determines if offline stacking is expected with current settings and conditions.
    ShouldOfflineStack()
    {
        runsMax := g_BrivUserSettings[ "ForceOfflineRunThreshold" ]
        ; hybrid stacking not used. Use default test for offline stacking. 
        if (runsMax <= 1)
            return ( g_BrivUserSettings [ "RestartStackTime" ] > 0 )
        ; hybrid and already offline stacked
        if (this.DelayStackTest())
            return False
        ; hybrid stacking by number of runs.
        ; Note: Uses reset count value so can stack restart early the first time.
        if (runsMax > 1)
        {
            memRead := g_SF.Memory.ReadResetsCount()
            if (memRead > 0 AND Mod( memRead, runsMax ) == 0)
                return True
        }
        ; hybrid stacking enabled but conditions for offline stacking not met
        return False
    }

    ; Determines if offline stacking is expected with current settings and conditions. Returns true if needs delay, false if needs stacking.
    DelayStackTest()
    {
        if (g_SF.AlreadyOfflineStackedThisRun)
            return True
        return False
    }

    ;thanks meviin for coming up with this solution
    ;Gets total of SteelBonesStacks + Haste Stacks
    GetNumStacksFarmed()
    {
        ;; OLD CODE In case of needed revert 
        ; if (this.ShouldOfflineStack())
        ; {
        ;     currentStacks := g_BrivUserSettings[ "IgnoreBrivHaste" ] ? g_SF.Memory.ReadSBStacks() : ( (g_SF.Memory.ReadHasteStacks() + 0) + (g_SF.Memory.ReadSBStacks() + 0) )
        ;     return currentStacks
        ; } 
        ; if (this.ShouldOfflineStack())
        ;     this.StackRestart()
        ;;
        if (IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())
        {
            sbStacks := g_SF.Memory.ReadSBStacks()
            hasteStacksAfterReset := IC_BrivGemFarm_Class.BrivFunctions.PredictStacks(False,False,True)
            stacksAfterReset := g_SF.BrivHasThunderStep() ? sbStacks * 1.2 + hasteStacksAfterReset: sbStacks + hasteStacksAfterReset
            return stacksAfterReset
        }
        else
            return g_SF.Memory.ReadSBStacks() + 48
            ; If restart stacking is disabled, we'll stack to basically the exact
            ; threshold.  That means that doing a single jump would cause you to
            ; lose stacks to fall below the threshold, which would mean StackNormal
            ; would happen after every jump.
            ; Thus, we use a static 48 instead of using the actual haste stacks
            ; with the assumption that we'll be at minimum stacks after a reset.
    }
    
    ; Assumes current jump value, does not account for featswapping.
    StacksRequiredForMissingThelloraJumps()
    {
        maxRushArea := ActiveEffectKeySharedFunctions.Thellora.ThelloraPlateausOfUnicornRunHandler.ReadMaxRushArea()
        currentRushStacks := g_SF.ThelloraRushTest()
        ; Party has not progressed to the next zone yet but Briv stacks were consumed.
        if (maxRushArea - currentRushStacks > 0)
            distance += (maxRushArea - currentRushStacks)       
        skipAmount := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipAmount()
        skipChance := ActiveEffectKeySharedFunctions.Briv.BrivUnnaturalHasteHandler.ReadSkipChance()
        jumps := Ceil(distance / ((skipAmount * (1-skipChance)) + ((skipAmount+1) * skipChance)))
        consume := g_SF.IsBrivMetalborn() ? -.032 : -.04  ;Default := 4%, SteelBorn := 3.2%
        stacks := Ceil(this.GetNumStacksFarmed() / (1+consume)**jumps) - this.GetNumStacksFarmed()
    }

    ; Stops progress and switches to appropriate party to prepare for stacking Briv's SteelBones.
    StackFarmSetup()
    {
        g_SharedData.LoopString := "Switching to stack farm formation."
        if (!this.BossKillAttempt AND !g_SF.KillCurrentBoss() ) ; Previously/Alternatively FallBackFromBossZone()
            this.BossKillAttempt := True, g_SF.FallBackFromBossZone() ; Boss kill Timeout
        stackFormation := g_SF.Memory.GetFormationByFavorite(2)
        sTimer := new SH_SharedTimers()
        while(g_SF.Memory.ReadClickLevel() < g_SF.Memory.ReadCurrentZone() and !sTimer.isTimeUp(3000))
            g_SF.DirectedInput(,,this.ClickSpam )
        this.LockLevelUp := False ; Allow leveling starting at 0 again for stacking champions.
        this.DoBasicLeveling(g_SF.GetFormationFKeys(stackFormation))
        inputValues := "{w}" ; Stack farm formation hotkey
        g_SF.DirectedInput(,, inputValues )
        g_SF.WaitForTransition( inputValues )
        g_SF.ToggleAutoProgress( 0 , false, true )
        StartTime := A_TickCount
        ElapsedTime := 0
        counter := 0
        sleepTime := 60
        g_SharedData.LoopString := "Setting stack farm formation."
        isFormation2 := g_SF.Memory.ReadMostRecentFormationFavorite() == 2 AND IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun
        if (!isFormation2)
            if(g_SF.IsCurrentFormationLazy(stackFormation))
                isFormation2 := True
        while (!isFormation2 AND ElapsedTime < 5000 )
        {
            ElapsedTime := A_TickCount - StartTime
            if (ElapsedTime > (sleepTime * counter++))
                g_SF.DirectedInput(,,inputValues)
            ; Can't formation switch when under attack.
            isFormation2 := g_SF.Memory.ReadMostRecentFormationFavorite() == 2 AND IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun
            if (!isFormation2)
                if(g_SF.IsCurrentFormationLazy(stackFormation))
                    isFormation2 := True
            if (ElapsedTime > 1000 AND !isFormation2 && g_SF.Memory.ReadNumAttackingMonstersReached() > 10 || g_SF.Memory.ReadNumRangedAttackingMonsters())
                 ; not W formation or briv is benched
                if (g_SF.Memory.ReadChampBenchedByID(ActiveEffectKeySharedFunctions.Briv.HeroID) OR !(g_SF.Memory.ReadMostRecentFormationFavorite() == 2))
                    g_SF.FallBackFromZone()
        }
        return
    }

    ;Starts stacking SteelBones based on settings (Restart or Normal).
    StackFarm()
    {
        if (this.ShouldOfflineStack())
            if(g_BrivUserSettings[ "FortOnlyRestart" ])
                this.StackRestartFORTOnly()
            else
                this.StackRestart()
        else if (this.StackNormal() == 0)
            return
        ;SetFormation needs to occur before dashwait in case game erroneously placed party on boss zone after stack restart
        g_SF.SetFormation(g_BrivUserSettings)
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1 )
        this.BossKillAttempt := False
    }

    /*  StackRestart - Stack Briv's SteelBones by switching to his formation and restarting the game.
                       Attempts to buy are open chests while game is closed.

    Parameters:

    Returns:
    */
    ; Stack Briv's SteelBones by switching to his formation and restarting the game.
    StackRestart()
    {
        g_SF.AlreadyOfflineStackedThisRun := True
        retryAttempt := 0
        maxRetries := 2
        if (this.LastStackSuccessArea == 0)
            maxRetries := 1
        targetStacks := g_BrivUserSettings[ "TargetStacks" ] + 0
        stacksFarmed := lastStacks := this.GetNumStacksFarmed()
        while ( stacksFarmed < targetStacks AND retryAttempt <= maxRetries )
        {
            this.StackFailRetryAttempt++ ; per run
            retryAttempt++               ; pre stackfarm call
            this.StackFarmSetup()
            g_SF.CurrentZone := g_SF.Memory.ReadCurrentZone() ; record current zone before saving for bad progression checks
            modronResetZone := g_SF.Memory.GetModronResetArea()
            if (modronResetZone != "" AND g_SF.CurrentZone > modronResetZone)
            {
                g_SharedData.LoopString := "Attempted to offline stack after modron reset - verify settings"
                break
            }
            g_SF.CloseIC( "StackRestart" . (this.StackFailRetryAttempt > 1 ? (" - Warning: Retry #" . this.StackFailRetryAttempt - 1 . ". Check Stack Settings."): "") )
            g_SharedData.LoopString := "Stack Sleep: "
            StartTime := A_TickCount
            ElapsedTime := 0
            while ( ElapsedTime < g_BrivUserSettings[ "RestartStackTime" ] )
            {
                g_SharedData.LoopString := "Stack Sleep: " . g_BrivUserSettings[ "RestartStackTime" ] - ElapsedTime
                Sleep, 124
                ElapsedTime := A_TickCount - StartTime
            }
            g_SF.SafetyCheck(stackRestart := True)
            stacksFarmed := this.GetNumStacksFarmed()
            this.SkipNextChestCheck := True
            ;check if save reverted back to below stacking conditions
            if (g_SF.Memory.ReadCurrentZone() < g_BrivUserSettings[ "MinStackZone" ])
            {
                g_SharedData.LoopString := "Stack Sleep: Bad Save? Z-Loaded < Min stack zone"
                Break
            }
            g_SharedData.PreviousStacksFromOffline := stacksFarmed - lastStacks
            lastStacks := stacksFarmed
        }
        ; 5/19/2026 - incremental stack restart gain removed.
        if (retryAttempt == 1)
            this.StackFailAreasTally[g_SF.CurrentZone] := 0
        this.LastStackSuccessArea := g_SF.CurrentZone
        g_PreviousZoneStartTime := A_TickCount
        this.StackRestartRecover()
    }

    StackRestartFORTOnly()
    {
        g_SF.AlreadyOfflineStackedThisRun := True
        g_SharedData.LoopString := "FORT Restart"
        g_SF.ToggleAutoProgress(0)
        g_PreviousZoneStartTime := A_TickCount ; reset zone start time after stacking
        if(g_SharedData.TotalRunsCount > 0)
            g_SF.CloseIC( "FORT Restart" )
        g_SF.SafetyCheck(stackRestart := True)
        this.StackRestartRecover()
        ; SetFormation effectively called here after returning from this function by way of Stack continuing StackFarm()
    }

    StackRestartRecover()
    {
        if (g_SF.Memory.ReadNumAttackingMonstersReached() > 10 || g_SF.Memory.ReadNumRangedAttackingMonsters())
            g_SF.FallBackFromZone() ; don't get stuck getting attacked.
        if (g_SF.UnBenchBrivConditions(g_BrivUserSettings))
            g_SF.DirectedInput(,, "{q}")
        else if (g_SF.BenchBrivConditions(g_BrivUserSettings))
            g_SF.DirectedInput(,, "{e}")
        IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun := True
    }

    /*  StackNormal - Stack Briv's SteelBones by switching to his formation and waiting for stacks to build.

    Parameters:
    maxOnlineStackTime -  Maximum time in ms script will spend stacking. Default is 5 minutes.

    Returns:
    */
    ; Stack Briv's SteelBones by switching to his formation.
    StackNormal(maxOnlineStackTime := 300000, targetStacks := 0)
    {
        ; TODO:: Update target stacks if Thellora doesn't have enough stacks for the next run.
        stacksStart := stacksFarmed := this.GetNumStacksFarmed() ; TODO: Previous behavior of GNSF() was would offline stack if ShouldOfflineStack says yes  
        stacksToFarm := targetStacks ? targetStacks : g_BrivUserSettings[ "TargetStacks" ]
        ; first checks should short circuit last check if failed.
        if (this.ShouldAvoidRestack(stacks, stacksToFarm)) {
            g_SharedData.LoopString .= " - Rejected. Already Stacked"
            return 0
        }
        g_SF.ToggleAutoProgress( 0, false, true )
        ; Complete the current zone
        if ( g_BrivUserSettings[ "WaitForZoneCompleted" ] )
            g_SF.WaitForZoneCompleted()
        this.StackFarmSetup(setUIString := True)
        g_SharedData.LoopString := "Stack Normal"

        ; Stacking
        ; Incremental Briv Leveling vars
        StartTime := A_TickCount
        ElapsedTime := 0
        this.LockLevelUp := False ; Allow leveling starting at 0 again for stacking champions.
        amountToLevelBriv := this.StackNormalGetMoreBrivLeveling()
        levelBrivSomeMore := amountToLevelBriv > 340
        SBStacksStart := g_SF.Memory.ReadSBStacks()
        if (!IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())  ; Haste stacks are taken into account
            stacksToFarm := stacksToFarm - stacksStart
        stackFormation := this.GetFKeysForFormations(g_SF.Memory.GetFormationByFavorite(2))
        defaultLevelingFormation := this.GetFKeysForFormations(g_SF.Memory.GetFormationByFavorite(1))
        levelingOptions := {}
        ; add leveling keys not in stack formation - to level formation champs without leveling stacking team.
        for k,v in defaultLevelingFormation
        {
            foundKey := false
            for key,value in stackFormation
                if (v == value)
                    foundKey := True
            if (!foundKey)
                levelingOptions[k] := v
        }
        
        this.FaridehInParty := IC_BrivGemFarm_Class.FARIDEH_ID == g_SF.Memory.ReadSelectedChampIDBySeat(g_SF.Memory.ReadChampSeatByID(IC_BrivGemFarm_Class.FARIDEH_ID))
        while ( stacksFarmed < stacksToFarm AND ElapsedTime < maxOnlineStackTime )
        {
            if (g_SF.Memory.ReadCurrentZone() < 1)
                return g_SharedData.LoopString := "Stacking interrupted due to game closed or reset"
            if (!IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive())
                g_SharedData.LoopString := "Stacking: " . (stacksStart + stacksFarmed ) . "/" . stacksToFarm
            else
                g_SharedData.LoopString := "Stacking: " . stacksFarmed . "/" . stacksToFarm
            g_SF.FallBackFromBossZone()
            this.StackNormalExtraLevelingTasks(levelingOptions, stackFormation)
            if (IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun AND g_SF.Memory.ReadMostRecentFormationFavorite() != 2) ; not in formation 2 still
                this.StackFarmSetup()
            else if (!this.IsCurrentFormationLazy(this.Memory.GetFormationByFavorite(2)))
                this.StackFarmSetup()
            else if ((!IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()) and SBStacksFarmed < (stacksToFarm / 10) and ElapsedTime > 10000 ) ; not gaining stacks 
                this.StackFarmSetup()
            if (!IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()) 
                stacksFarmed := g_SF.Memory.ReadSBStacks() - SBStacksStart
            else
                stacksFarmed := this.GetNumStacksFarmed() ; TODO: Previous behavior of GNSF() was would offline stack if ShouldOfflineStack says yes
            Sleep, 30
            ElapsedTime := A_TickCount - StartTime
        }
        this.UsedWardenUlt := False
        this.UsedFaridehUlt := False
        if ( ElapsedTime >= maxOnlineStackTime)
        {
            this.RecordEndRun()
            this.RestartAdventure( "Online stacking took too long (> " . (maxOnlineStackTime / 1000) . "s) - z[" . g_SF.Memory.ReadCurrentZone() . "].")
            this.SafetyCheck()
            g_PreviousZoneStartTime := A_TickCount
            return ""
        }
        g_PreviousZoneStartTime := A_TickCount
        this.LockLevelUp := False ; Allow leveling starting at 0 again after stacking since DoBasicLeveling locks it after stack formation is leveled.
        ; Go back to zone minus 1 if failed to complete the current zone
        if (g_SF.Memory.ReadQuestRemaining() > 0)
            g_SF.FallBackFromZone()
        g_SF.ToggleAutoProgress( 1, false, true )
        ; StackFarm won't be able to switch back to Q/E from W if the formation on the field isn't the exact
        ; formation saved in the second favorite formationslot.
        g_SF.SetFormation(g_BrivUserSettings)
        g_SharedData.LoopString := "Online stacking done"
        return ""
    }

    ; Test if Briv needs extra leveling based on zones reached.
    StackNormalGetMoreBrivLeveling()
    {
        currentZone:= g_SF.Memory.ReadCurrentZone()
        amountToLevelBriv := 0
        thresholds := g_BrivUserSettings[ "BrivLevelingThresholds" ]
        if (IsObject(thresholds))
        {
            ; Loop backwards from highest zone threshold
            Loop, % thresholds.Length()
            {
                i := thresholds.Length() - A_Index + 1
                if (currentZone >= thresholds[i].zone)
                {
                    amountToLevelBriv := thresholds[i].level
                    break
                }
            }
        }
        if (amountToLevelBriv == 0)
            amountToLevelBriv := this.BGFLU_GetTargetLevel(ActiveEffectKeySharedFunctions.Briv.HeroID, minOrMax := "Max") ; LevelUp adds this function
        return amountToLevelBriv ? amountToLevelBriv : 0
    }

    ; Get Fkeys or Formaton depending on in LevelUp addon is being used.
    GetFKeysForFormations(formation)
    {
        if (!( IsObject(IC_BrivGemFarm_LevelUp_Component) || IsObject(IC_BrivGemFarm_LevelUp_Class) )) ; No Levelup Addon
            return g_SF.GetFormationFKeys( formation )
        return formation
        
    }

    ; Determines which leveling to method is used based on if levelup addon is being used.
    StackNormalExtraLevelingTasks( levelingOptions, stackFormation )
    {
        if (!( IsObject(IC_BrivGemFarm_LevelUp_Component) || IsObject(IC_BrivGemFarm_LevelUp_Class) )) ; No Levelup Addon
        {
            this.DoBasicLeveling( stackFormation )
            this.DoLeveling( levelingOptions ) ; Level non-stacking champs and clickers while stacking.
        }
        else
            this.LevelUpAddonAvailableExtraLevelingTasks( levelingOptions, stackFormation )
        this.UseUlts()
    }

    ; LevelUp addon style leveling should be used.
    LevelUpAddonAvailableExtraLevelingTasks( levelingOptions, stackFormation )
    {
        ; StackNormalExtraLevelingTasks pre-tests this
        ; if (!( IsObject(IC_BrivGemFarm_LevelUp_Component) || IsObject(IC_BrivGemFarm_LevelUp_Class) )) ; No Levelup Addon
        ;     return
        if (this.FaridehInParty)
            this.BGFLU_LevelUpChamp(IC_BrivGemFarm_Class.FARIDEH_ID, this.BGFLU_GetTargetLevel(IC_BrivGemFarm_Class.FARIDEH_ID), true) ; special redundant level Farideh x25
        if (!IC_BrivGemFarm_Class.BrivFunctions.PredictStacksActive()) 
        {
            this.BGFLU_DoPartySetupMax(stackFormation)
            this.BGFLU_DoPartySetupMax(levelingOptions)
            this.BGFLU_LevelUpChamp(ActiveEffectKeySharedFunctions.Briv.HeroID, amountToLevelBriv)
        }
        if (levelBrivSomeMore)
            this.BGFLU_LevelUpChamp(ActiveEffectKeySharedFunctions.Briv.HeroID, amountToLevelBriv)
    }

    ; Use Warden/Farideh ults if conditons met.
    UseUlts()
    {
        ; Warden ultimate
        if (!this.UsedWardenUlt && g_BrivUserSettings[ "WardenUltThreshold" ] > 0)
            this.UsedWardenUlt := g_SF.UseChampUltIfEnemyThresholdMet(WARDEN_ID := 36, g_BrivUserSettings[ "WardenUltThreshold" ])
        
        ; Farideh ultimate
        if (!this.UsedFaridehUlt && g_BrivUserSettings[ "FaridehUltThreshold" ] > 0)
            this.UsedFaridehUlt := g_SF.UseChampUltIfEnemyThresholdMet(FARIDEH_ID := 33, g_BrivUserSettings[ "FaridehUltThreshold" ])
    }

    ; Presses leveling keys including click leveling.
    DoLeveling( spam := "" )
    {
        ; two passes on leveling heroes before clickers.
        this.DirectedInput(hold := True, release := True, spam*)
        this.DirectedInput(hold := True, release := True, spam*) 
        if(g_UserSettings[ "NoCtrlKeypress" ])
            this.DirectedInput(,,this.ClickSpam)
        else { ; ctrl level clickers
            this.DirectedInput(,release := 0, ["{RCtrl}",this.ClickSpam]*) ;keysdown
            this.DirectedInput(hold := 0,, [this.ClickSpam,"{RCtrl}"]*) ;keysup
        }
    }

    ResetToPreviousLoopString(returnVal := "")
    {
        g_SharedData.LoopString := this.previousLootString
        return returnVal
    }

    SetPreviousLoopString(returnVal := "")
    {
        this.previousLootString := g_SharedData.LoopString
        return returnVal
    }

    StripEmptySlotsFrom(formation := "")
    {
        strippedFormation := {}
        for k, heroID in formation
        {
            if (heroID > 0)
                strippedFormation.Push(heroID)
        }
        return strippedFormation
    }

    ; avoids attempts to stack again after stacking has been completed and level not reset yet.
    ShouldAvoidRestack(stacks, targetStacks)
    {
        if ( stacks >= targetStacks )
            return 1
        if (g_SF.Memory.ReadCurrentZone() == 1) ; likely modron has reset
            return 1
        if (g_SF.Memory.ReadCurrentZone() < g_BrivUserSettings[ "MinStackZone" ]) ; don't stack below min stack zone
            return 1
        return 0
    }

    /* ;A function that checks if farmed SB stacks from previous run failed to convert to haste.
       ;If so, the script will manually end the adventure to attempt to convert the stacks, close IC, use a servercall to restart the adventure, and restart IC.
    */
    CheckForFailedConv()
    {
        CurrentZone := g_SF.Memory.ReadCurrentZone()
        targetStacks := g_BrivUserSettings[ "TargetStacks" ]
        variationLeeway := 10
        ; Zone 10 gives plenty leeway for fast starts that skip level 1 while being low enough to not have received briv stacks
        ; needed to ensure DoPartySetup
        if (!g_BrivUserSettings[ "StackFailRecovery" ] OR CurrentZone > 10)
        {
            return 0
        }
        stacks := g_SF.Memory.ReadHasteStacks() + g_SF.Memory.ReadSBStacks()
        ; stacks not converted to haste properly. Buffer allows for automatic calc variations and possible early jump before calculation done.
        if ((g_SF.Memory.ReadHasteStacks() + variationLeeway) < targetStacks AND stacks >= targetStacks)
        {
            g_SharedData.StackFailStats.TALLY[StackFailStates.FAILED_TO_CONVERT_STACKS] += 1
            g_SF.RestartAdventure( "Failed Conversion" )
            g_SF.SafetyCheck()
            return StackFailStates.FAILED_TO_CONVERT_STACKS ; 2
        }
        ; all stacks were lost on reset. Stack leeway given for automatic calc variations. 
        if ((g_SF.Memory.ReadHasteStacks() + variationLeeway) < targetStacks AND g_SF.Memory.ReadSBStacks() <= variationLeeway)
        {
            g_SharedData.StackFailStats.TALLY[StackFailStates.FAILED_TO_KEEP_STACKS] += 1
            return StackFailStates.FAILED_TO_KEEP_STACKS ; 5
        }
        return 0
    }

    ;===========================================================
    ;Helper functions for Briv Gem Farm
    ;===========================================================
    /*  DoPartySetup - When gem farm is started or an adventure is reloaded, this is called to set up the primary party.
                       Levels Shandie and Briv, waits for Shandie Dash to start, completes the quests of the zone and then go time.

        Parameters:

        Returns:
    */
    DoPartySetup(formationModron)
    {
        g_SharedData.LoopString := "Leveling champions"
        formationFavorite1 := g_SF.Memory.GetFormationByFavorite( 1 )
        isShandieInFormation := g_SF.IsChampInFormation( ActiveEffectKeySharedFunctions.Shandie.HeroID, formationFavorite1 )
        g_SF.LevelChampByID( ActiveEffectKeySharedFunctions.Briv.HeroID, 170, 7000, "{q}") ; level briv
        if (isShandieInFormation)
            g_SF.LevelChampByID( ActiveEffectKeySharedFunctions.Shandie.HeroID,, 230, 7000, "{q}") ; level shandie
        isHavilarInFormation := g_SF.IsChampInFormation( ActiveEffectKeySharedFunctions.Havilar.HeroID, formationFavorite1 )
        if (isHavilarInFormation)
            g_SF.LevelChampByID( ActiveEffectKeySharedFunctions.Havilar.HeroID, 15, 7000, "{q}") ; level havi
        g_SF.ModronResetZone := g_SF.Memory.GetModronResetArea() ; once per zone in case user changes it mid run.
        if (g_SF.ShouldRushWait())
            g_SF.DoRushWait()
        if (g_SF.ShouldDashWait())
            g_SF.DoDashWait( Max(g_SF.ModronResetZone - g_BrivUserSettings[ "DashWaitBuffer" ], 0) )
        g_SF.ToggleAutoProgress( 1, false, false )
    }

    DoZ1Setup()
    {
        this.SetFormationForStart()
    }

    ;Waits for modron to reset. Closes IC if it fails.
    ModronResetCheck()
    {
        global g_ScriptHubComs
        g_SharedData.LoopString := "Modron Reset Check"
        modronResetTimeout := 75000
        if (!g_SF.WaitForModronReset(modronResetTimeout))
            g_SF.CheckifStuck(True)
        else
        {
            try ; set off any timers in SH that need to run on a reset.
            {
                ; e.g. buy/open chests
                g_ScriptHubComs.RunTimersOnModronResetEnd()
            }
        }

        g_PreviousZoneStartTime := A_TickCount ; modron reset - prev zone now 1 and new run starting.
        if (g_SharedData.ScriptStartTime == "" OR g_SharedData.ScriptStartTime <= 0) ; ignore first run - will almost always be incomplete run. start on 2nd.
            g_SharedData.ScriptStartTime := this.ThisRunStart := g_PreviousZoneStartTime
        else
            g_SharedData.LastRunTime := g_PreviousZoneStartTime - This.ThisRunStart
            , g_SharedData.TotalRunsCount += 1
        This.ThisRunStart := g_PreviousZoneStartTime
        IC_BrivGemFarm_Class.BrivFunctions.HasSwappedFavoritesThisRun := False
        this.IsInModronFormation := g_SharedData.TriggerStart := True
    }

    ; Test that favorite exists
    TestFormationSlotByFavorite(favorite := "", txtCheck := "")
    {
        if (!favorite)
            return ""
        testFunc := ObjBindMethod(g_SF.Memory, "GetSavedFormationSlotByFavorite", favorite)
        errMsg := "Please confirm a formation is saved in formation favorite slot " . favorite . ". " . txtCheck
        formationSlot := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := -1, shouldBeEqual := False)
        if (formationSlot == -1)
            return -1
        return formationSlot
    }

    ; Test that formation has champions
    TestFormationFavorite( formationSlot := "", favorite := "", txtCheck := "")
    {
        if (!formationSlot)
            return ""
        team := {1:"Speed", 2:"Stack Farm", 3:"Speed No Briv"}
        testFunc := ObjBindMethod(g_SF.Memory, "GetFormationSaveBySlot", formationSlot, 0) ; don't ignore empty
        errMsg := "Please confirm your " . team[favorite] . " team is saved in formation favorite slot " . favorite . ". " . txtCheck
        formation := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := 0, shouldBeEqual := False, testSize := True)
        if (formation == -1)
            return -1
        return formation
    }

    ; Test that formation has champions
    TestChampInFormation( champID := "", formation := "", includeChampion := True, favorite := 1, txtCheck := "")
    {
        if (!champID)
            return ""
        team := {1:"Speed", 2:"Stack Farm", 3:"Speed No Briv"}
        testFunc := ObjBindMethod(g_SF, "IsChampInFavoriteFormation", champID, favorite ) ; don't ignore empty
        foundChampName := g_SF.Memory.ReadChampNameByID(champID)
        
        errMsg := "Please confirm " . foundChampName . stateText . (includeChampion ? " is" : " is NOT") .  " saved in formation favorite slot " . favorite . ". " . txtCheck
        formation := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := True, shouldBeEqual := includeChampion)
        if (formation == -1)
            return -1
        return formation
    }
    
    ; Test Modron Reset Automation is enabled
    TestModronResetAutomationEnabled()
    {
        testFunc := ObjBindMethod(g_SF.Memory, "ReadModronAutoReset")        
        errMsg := "Please confirm that Modron Reset Automation is enabled."
        modronAutomationStatus := g_SF.RetryTestOnError(errMsg, testFunc, expectedVal := True, shouldBeEqual := True)
        return modronAutomationStatus
    }

    ; Run tests to check if favorite formations are saved, they have champions, and that the expected champion is/isn't included.
    RunChampionInFormationTests(champion, favorite, includeChampion, txtCheck)
    {
        formationSlot := this.TestFormationSlotByFavorite( favorite , txtcheck)
        if (formationSlot == -1)
            return -1 
        formation := this.TestFormationFavorite(formationSlot, favorite, txtcheck)
        if (formation == -1)
            return -1
        isChampInFormation := this.TestChampInFormation(champion, formation, includeChampion, favorite, txtcheck)
        if (isChampInFormation == -1)
            return -1
    }

    FamiliarFormationsFieldCheck()
    {
        if ((ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 1, True)))
            MsgBox, %ErrorMsg%
        while (ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 2, False))
        {
            MsgBox, 5,, %ErrorMsg%
            IfMsgBox, Retry
            {
                g_SF.OpenProcessReader()
                ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 2, False)
            }
            IfMsgBox, Cancel
            {
                MsgBox, Canceling Run
                return -1
            }
        }
        if (ErrorMsg := g_SF.FormationFamiliarCheckByFavorite(favorite := 3, True))
            MsgBox, %ErrorMsg%
        return 0
    }

    StackSettingsCheck()
    {
        if g_BrivUserSettings[ "TargetStacks" ] < 50
        {
            errMsg := "Your target haste stacks settings are incompatible with BrivGemFarm. Please set a value that would cause Briv to farm for stacks (More than 50). Now ending Gem Farm."
            MsgBox, % ErrMsg
            return -1
        }
        return 0
    }

    ; Tests to make sure Gem Farm is properly set up before attempting to run.
    PreFlightCheck(includeBrivFormation3 := False)
    {
        memoryVersion := g_SF.Memory.GameManager.GetVersion()
        ; Test Favorite Exists
        txtCheck := "`n`nOther potential solutions:"
        txtCheck .= "`n`n1. Be sure Imports are up to date. Current imports are for: v" . g_SF.Memory.GetImportsVersion()
        txtCheck .= "`n`n2. Check the correct memory file is being used. Current version: " . memoryVersion
        txtcheck .= "`n`n3. If IC is running with admin privileges, then the script will also require admin privileges."
        if (_MemoryManager.is64bit)
            txtcheck .= "`n4. Check AHK is 64-bit. (Currently " . (A_PtrSize = 4 ? 32 : 64) . "-bit)"
        if (this.StackSettingsCheck() < 0)
            return -1
        if (this.TestQFormation(txtCheck) < 0 OR this.TestWFormation(txtCheck) < 0 OR this.TestEFormation(txtCheck) < 0)
            return -1
        if (this.TestModronResetAutomationEnabled() == -1)
            return -1
        if(this.FamiliarFormationsFieldCheck() < 0)
            return -1
        return 0
    }

    TestQFormation(txtCheck := "")
    {
        formationQ := g_SF.FindChampIDinSavedFavorite( ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 1, includeChampion := True )
        if (formationQ == -1 AND this.RunChampionInFormationTests(ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 1, includeChampion := True, txtCheck) == -1)
            return -1
        return 0
    }

    TestWFormation(txtCheck := "")
    {
        formationW := g_SF.FindChampIDinSavedFavorite( ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 2, includeChampion := True  )
        if (formationW == -1 AND this.RunChampionInFormationTests(ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 2, includeChampion := True, txtCheck) == -1)
            return -1
        return 0
    }

    TestEFormation(txtCheck := "")
    {
        formationE := g_SF.FindChampIDinSavedFavorite( ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 3, includeChampion := False )
        if (formationE == -1 AND this.RunChampionInFormationTests(ActiveEffectKeySharedFunctions.Briv.HeroID, favorite := 3, includeChampion := False, txtCheck) == -1)
            return -1
        return 0
    }

    ;=====================================================
    ;Functions for direct server calls between runs
    ;=====================================================
   
    CheckAndDoChests()
    {
        memorySilvers := g_SF.Memory.ReadChestCountByID(1)
        memoryGolds := g_SF.Memory.ReadChestCountByID(2)
        ; Prevent opening non-existent chests by checking if the count is the same as last time.
        ; - Chest counts only update in-game when opening via calls if some are dropped or bought.
        ; - So if the count didn't change between calls - the count can't be trusted. Assume 0.
        numSilverChests := memorySilvers
        if (this.previousSilverChestCount == numSilverChests)
            numSilverChests := 0
        numGoldChests := memoryGolds
        if (this.previousGoldChestCount == numGoldChests)
            numGoldChests := 0
            
        this.previousSilverChestCount := memorySilvers
        this.previousGoldChestCount := memoryGolds
        
        return g_BrivGemFarm.DoChests(numSilverChests, numGoldChests, g_SF.Memory.ReadGems())
    }
    
    ; Sends calls for buying or opening chests and tracks chest metrics.
    DoChests(numSilverChests := "", numGoldChests := "", gems:= "")
    {
        return this.DoChestsSetup(numSilverChests, numGoldChests, gems)
    }

    DoChestsSetup(numSilverChests := "", numGoldChests := "", gems:= "")
    {
        loopString := ""
        ElapsedTime := 0
        startingPurchasedSilverChests := g_SharedData.PurchasedSilverChests
        startingPurchasedGoldChests := g_SharedData.PurchasedGoldChests
        startingOpenedGoldChests := g_SharedData.OpenedGoldChests
        startingOpenedSilverChests := g_SharedData.OpenedSilverChests

        try
        {
            call := "DoChests"
            scriptLocation := A_LineFile . "\..\IC_BrivGemFarm_ServerCalls.ahk"
            Run, %A_AhkPath% "%scriptLocation%" "%call%" "%numSilverChests%" "%numGoldChests%" "%gems%"
        }
        catch
        {
            loopString .= "Failed to run chest buy/open script"
        }
        
        ; after chests buy/open
        currentLoopString := this.GetChestDifferenceString(startingPurchasedSilverChests, startingPurchasedGoldChests, startingOpenedGoldChests, startingOpenedSilverChests)
        loopString := currentLoopString == "" ? loopString : currentLoopString
        return loopString
    }

    ; Builds a string that shows how many chests have been opened/bought above the values passed into this function.
    GetChestDifferenceString(lastPurchasedSilverChests, lastPurchasedGoldChests, lastOpenedGoldChests, lastOpenedSilverChests )
    {
        boughtSilver := g_SharedData.PurchasedSilverChests - lastPurchasedSilverChests 
        boughtGold := g_SharedData.PurchasedGoldChests - lastPurchasedGoldChests
        openedSilver := g_SharedData.OpenedSilverChests - lastOpenedSilverChests
        openedGold := g_SharedData.OpenedGoldChests - lastOpenedGoldChests
        buyString := (boughtSilver > 0 OR boughtGold > 0) ? "Buy: (" . boughtSilver . "s, " . boughtGold . "g)" : ""
        openString := (openedSilver > 0 OR openedGold > 0) ? "Open: (" . openedSilver . "s, " . openedGold . "g)" : ""
        separator := ((boughtSilver > 0 OR boughtGold > 0) AND (openedSilver > 0 OR openedGold > 0)) ? ", " : ""
        returnString := buyString . separator . openString
        return ((returnString != "") ? "Chests - " . returnString : "")
    }
    
    #include *i %A_LineFile%\..\IC_BrivGemFarm_Chests_Deprecated.ahk
    #include %A_LineFile%\..\IC_BrivGemFarm_Briv.ahk
}

#include %A_LineFile%\..\IC_BrivGemFarm_Coms.ahk