# BrivGemFarm_Performance Settings File
## Description:
These are the settings used by the BrivGemFarm_Performance AddOn. They are saved in `BrivGemFarmSettings.json` and can be configured through the main Briv Gem Farm tab, the Advanced Settings tab, or edited directly in the JSON file.

## Settings:

* **LastSettingsUsed**: `<string>` (Default: "Default")  
Stores the name of the last settings profile loaded or saved.

* **Fkeys**: `0` / `1` (Default: `1`)  
When set to 1, the script uses function keys (F1-F12) to level up champions in the active team automatically, eliminating the need for familiars on individual bench slots.

* **StackFailRecovery**: `0` / `1` (Default: `1`)  
Enables forced early restarts to recover when Briv runs out of haste stacks but has sufficient Steelbones stacks in reserve to proceed with a new run.

* **DisableDashWait**: `0` / `1` (Default: `0`)  
When set to 1, completely disables waiting for Shandie's Dash to activate after a stack restart.

* **StackZone**: `<integer>` (Default: `700`)  
The zone number after which the script will begin farming Steelbones stacks for Briv (usually positioned a couple of zones prior to the Modron reset zone).

* **MinStackZone**: `<integer>` (Default: `200`)  
The minimum area zone where Briv is allowed to farm Steelbones stacks (used as a fallback recovery limit).

* **TargetStacks**: `<integer>` (Default: `0`)  
The target number of haste stacks that the script should attempt to farm for the next run.

* **RestartStackTime**: `<integer>` (Default: `12000`)  
The time in milliseconds that the client will remain closed during a stack restart (an offline stack restart is disabled if this is set to 0).

* **BuyChests**: `0` / `1` (Default: `1`)  
Enables automatic purchasing of chests.

* **OpenChests**: `0` / `1` (Default: `1`)  
Enables automatic opening of chests.

* **MinGemCount**: `<integer>` (Default: `0`)  
The minimum gem count to maintain. No chests will be purchased if your gem count falls below this threshold.

* **BuyGoldChestRatio** / **BuySilverChestRatio**: `<decimal>` (Default: `1.0` / `0.0`)  
Determines the proportion of chest purchases allocated to gold vs. silver chests. For example, 0.9 for gold and 0.1 for silver means 90% of spent gems buy gold chests and 10% buy silver chests.

* **MinGoldChestCount** / **MinSilverChestCount**: `<integer>` (Default: `0`)  
The number of gold or silver chests to keep in reserve. The script will open chests only above this quantity.

* **WaitToBuyChests**: `0` / `1` (Default: `1`)  
Known in the GUI as "Only buy/open max chests (250 buy/1000 open)". When set to 1, the script waits to buy or open chests until a full/max request size can be sent to reduce server load.

* **FeatSwapEnabled**: `0` / `1` (Default: `0`)  
Enables automatic feat swapping (such as Briv's Steelbones vs. Haste feats) at the appropriate zones (requires supporting addons).

* **HiddenFarmWindow**: `0` / `1` (Default: `0`)  
Hides the secondary command window launched by the script for farming when set to 1. Only a tray icon will be visible.

* **RestoreLastWindowOnGameOpen**: `0` / `1` (Default: `1`)  
When enabled, the script attempts to return focus to the last active window on your computer immediately after launching the game.

* **IgnoreBrivHaste**: `0` / `1` (Default: `0`)  
Known in the GUI as "Predict Stacks Off? (IgnoreBrivHaste)". When set to 1, ignores Briv's haste stacks when predicting/deciding when to stack, forcing offline stacking once per run.

* **FortOnlyRestart**: `0` / `1` (Default: `0`)  
Known in the GUI as "No Stack FORTs". When running Forced Offline restarts, the game will restart instantly rather than farming stacks while offline.

* **WaitForZoneCompleted**: `0` / `1` (Default: `1`)  
Known in the GUI as "Complete Zone Before Stacking". When checked, the script completes the current zone before starting online stacking.

* **ForceOfflineRunThreshold**: `<integer>` (Default: `0`)  
Activates "hybrid stacking" (HTS). Forces the script to perform an offline stack restart once the number of runs based on "Resets Done" as reported by the current Modron core. An offline stack restart is forced every N runs (0 or 1 = disable).

* **BrivJumpBuffer**: `<integer>` (Default: `0`)  
The number of areas before the Modron reset zone where the script will switch from the 'q' (jump) formation to the 'e' (non-jump) formation to ensure stacks convert properly.

* **DashWaitBuffer**: `<integer>` (Default: `30`)  
The distance from your Modron's reset zone where dashwait will stop being activated.

* **WindowXPosition** / **WindowYPosition**: `<integer>` (Default: `0` / `0`)  
Sets the horizontal and vertical screen coordinates where the gem farm script window appears on your monitor.

* **WardenUltThreshold** / **FaridehUltThreshold**: `<integer>` (Default: `0`)  
Triggers Warden's or Farideh's ultimates while stacking when the number of enemies exceeds the specified threshold (0 = off).

* **PreferredBrivJumpZones**: `<array>`  
An array of 50 binary values representing the zones in a 50-zone cycle where Briv jumps are preferred (`1` allows jumping, `0` disables).

* **BrivLevelingThresholdsCount**: `<integer>` (Default: `5`)  
Specifies the count of custom zone leveling thresholds for Briv.

* **BrivLevelingThresholds**: `<array>`  
Contains the custom zone and level mapping array (e.g. `[{"zone": 1100, "level": 400}, ...]`) for auto-leveling Briv.
