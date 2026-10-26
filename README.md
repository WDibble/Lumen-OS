# Lumen-OS

The definitive custom operating system distribution and modern user experience for the **TrimUI Smart Pro** (Allwinner A133plus, 1280×720 IPS display). Built with strict adherence to the **Handheld Craft Philosophy**, **Zero-NAND Safety**, and **POSIX Reliability**.

---

## 🌟 Highlights

- **Complete Platform Coverage**: Full support for 112 retro console platforms, high-performance standalone emulators (PPSSPP 1.17.1 Vulkan/GL, Drastic NDS, Mupen64plus, Flycast v2.4), and native applications (`PortMaster`, `FileManager`, `MusicPlayer`, `Terminal`, `SystemTools`, `BIOS Doctor`).
- **Zero NAND Mutation Invariant**: Internal flash partitions (`/dev/mmcblk0p*`, `/dev/mtd*`, `/dev/nand*`, `/mnt/UDISK`) are 100% untouched. All runtimes, configurations, emulators, ROMs, and states live strictly on `/mnt/SDCARD/` and volatile `/tmp/lumen/`.
- **Physical FN Hardware Switch Integration**: Dedicated 50ms debounced hardware daemon toggling Turbo (1608MHz + Cyan stick LED) vs Balanced (816–1608MHz + Sapphire Blue stick LED) with on-screen OSD toasts.
- **Autonomous Low-Battery Auto-Save Sentinel**: 3-tier battery sentinel with proactive warnings at 15% (Amber LED + toast) and 10% (Red flash + critical toast). When battery drops below 4%, the sentinel throttles CPU to 1008MHz to prevent brownout UVLO, sends an emergency `SAVE_STATE` command to RetroArch, flushes I/O buffers, and performs a graceful poweroff.
- **Curated 720p Bezel Overlays & GLSL Shaders**: 215+ pixel-exact overlays with integer scaling cutouts for GB, GBC, GBA, Game Gear, Neo Geo, Arcade, SNES, and Genesis—eliminating black sidebars without geometry distortion.
- **Global In-Game Hotkeys**: Ergonomic combinations for Fast-Forward, Rewind, and Save Slot cycling, plus Undo Load State (<kbd>MENU</kbd> + <kbd>Y</kbd>) protection.
- **Audio DAC Sleep De-Pop Guard**: Mutes audio codecs with a 60ms pre-sleep dwell and 250ms post-wake stabilization delay, completely eliminating harsh pop transients through micro-speakers.
- **Single-Process Global Game Switcher**: Chord (<kbd>SELECT</kbd> + <kbd>MENU</kbd>) to switch between recent games without OOM panics on 1GB RAM.
- **On-Device BIOS & Readiness Auditor**: Built-in checker (`Apps/SystemChecker`, labeled **BIOS Doctor**) with two-tiered existence, byte-size, and case-sensitivity verification across 7 major systems.

---

## 🎮 Global Hotkey Reference

### In-Game (RetroArch Core)

| Hotkey Combination | Action | Description |
| :--- | :--- | :--- |
| <kbd>MENU</kbd> + <kbd>X</kbd> | Quick Menu | Opens RetroArch Quick Menu HUD |
| <kbd>MENU</kbd> + <kbd>START</kbd> | Clean Exit | Saves state and returns to MainUI |
| <kbd>MENU</kbd> + <kbd>A</kbd> | Save State | Saves to current active slot |
| <kbd>MENU</kbd> + <kbd>B</kbd> | Load State | Loads from current active slot |
| <kbd>MENU</kbd> + <kbd>Y</kbd> | Undo Load State | Reverts accidental state load |
| <kbd>MENU</kbd> + <kbd>R1</kbd> | Fast-Forward | Toggles fast-forward (speedrun / JRPG grinding) |
| <kbd>MENU</kbd> + <kbd>L1</kbd> | Rewind | Instant gameplay rollback |
| <kbd>MENU</kbd> + <kbd>D-Pad Right</kbd> | Slot +1 | Cycles to next save slot |
| <kbd>MENU</kbd> + <kbd>D-Pad Left</kbd> | Slot -1 | Cycles to previous save slot |

### Global System Chords (MainUI & Everywhere)

| Hotkey Combination | Action | Description |
| :--- | :--- | :--- |
| <kbd>SELECT</kbd> + <kbd>R2</kbd> | Screenshot | Instant 720p PNG capture to `Screenshots/` |
| <kbd>SELECT</kbd> + <kbd>L2</kbd> | Night Mode | Toggle display color warmth / blue-light filter |
| <kbd>MENU</kbd> + <kbd>VOL +</kbd> / <kbd>-</kbd> | Brightness | Hardware backlight step (+10% / -10%) |
| <kbd>SELECT</kbd> + <kbd>MENU</kbd> | Game Switcher | Launches FastLaunch / Activities selector |
| **FN Switch (Right)** | Turbo Mode | Max 1608MHz CPU, cyan stick LED |
| **FN Switch (Left)** | Balanced Mode | Dynamic ondemand CPU, sapphire blue stick LED |

---

## 📁 Storage Architecture

```
/mnt/SDCARD/
├── Apps/              # Handheld utilities (PortMaster, Terminal, BIOS Doctor, System Tools)
├── Backgrounds/       # System background wallpapers
├── BIOS/              # Console BIOS firmware (PlayStation, Dreamcast, Saturn, Neo Geo)
├── Emus/              # 112 console launcher configurations and dispatchers
├── Icons/             # System icon packs
├── RetroArch/         # 64-bit RetroArch engine, Libretro cores, overlays, and shaders
├── Roms/              # Game ROM libraries organized by console folder (with README guides)
├── Saves/             # Game saves, save states, and RetroAchievements data
├── Screenshots/       # 720p PNG screenshots
├── System/            # Lumen-OS init.d services, binaries, and hardware daemons
├── Themes/            # MainUI UI theme packs (Lumen default)
└── trimui/            # Hardware preload hooks and inputd configuration
```

---

## 🛠️ Developer & Verification Tools

- **Local Handheld Simulator**: Run `python3 tools/run_simulator.py` to test MainUI grid navigation, sound effects, and console launching on desktop at `http://localhost:8765`.
- **System Test Suite**: Run `python3 -m unittest tests/test_system.py` for comprehensive regression testing covering Zero-NAND assertions, argument normalization, and daemons.
- **Distribution Packager**: Run `./tools/package_release.sh` to produce clean release zips.
- **SD Deployer**: Run `./tools/deploy_to_sd.sh /Volumes/TRIMUI` to synchronize system files to an inserted MicroSD card.
