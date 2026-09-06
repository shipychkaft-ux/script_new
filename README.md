# Nightix — Roblox Client

Nightix is a Roblox Lua client with a Nightix-style ClickGUI.

## GitHub loader

Upload all project files to the same GitHub repository. `MainScript.lua` loads the other files from:

`https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/`

Loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/shipychkaft-ux/script_new/main/MainScript.lua"))()
```

`loadstring.lua` can also be used when `MainScript.lua` is present locally.

## Main fixes in this build

- Speed `Velocity` and `CFrame` modes use real studs/second movement instead of frame-scaled movement.
- Speed survives respawns and restores the player's original WalkSpeed/JumpPower/Animate state when disabled.
- Fixed `ReToggle()` so changing module settings while a module is enabled restarts the module correctly instead of silently leaving it disabled.
- Fixed the ESP `ReToggle` error caused by calling `ReToggle()` on option toggles.
- ESP cleanup/restart and player respawn handling were hardened.
- Atmosphere no longer recreates itself after being disabled.
- Fixed several stale/incorrect connection assignments and invalid comparisons.
- Panic now actually disables active modules.
- Removed the legacy NeverLose config/autosave system from the Nightix window.
- Configs are now manual profiles stored under `Nightix/Configs/<PlaceId>/`.
- Profiles has a config list: click a config to load it, plus **Add**, **Save current**, **Remove**, and **Rename** (pencil) controls.
- Config loading applies options before module states and explicitly disables modules that are off in the selected profile.
- No background config autosave and no automatic config load on startup.
- Render/Utility sound/message lists no longer show the generic **Add** button.
- Watermark uses the Nightix icon and displays `UID: <UserId>`.
- Fixed several smaller runtime/cleanup issues in ESP, UsernameHider, Friends, Fullbright, HighJump and console handling.

## Controls

| Input | Action |
|---|---|
| `RightShift` | Open/close menu |
| `LMB` | Toggle module |
| `RMB` | Open module options |
| Mouse wheel button / `M3B` | Supported as a module bind |

## Files

- `MainScript.lua` — entry point and tab setup
- `GuiLibrary.lua` — compatibility/API layer and manual config storage
- `NightixMenu.lua` — Nightix UI adapter and profile manager
- `NeverLose.lua` — UI implementation
- `Universal.lua` — universal modules
- `espLibrary.lua` — ESP implementation
- `playersHandler.lua` — player handling
- `toolHandler.lua` — tool handling
- `loadstring.lua` — local loader

## Configs

Configs are **not** saved automatically. Use the Profiles tab:

1. Type a name and press **Add** to save the current state as a new config.
2. Click a config in the list to load it.
3. Select a config and press **Save current** to update it.
4. Select a config, enter a new name, then press **Rename** (pencil) to rename it.
5. Select a config and press **Remove** to delete it.

## Credits

- ManaV2ForRoblox — Maanaaaa & Wowzers
- Nightix-style UI implementation in this project
