# Lumen-OS System Architecture & Hardware Contract

This document outlines the reverse-engineered hardware control interfaces and system architecture of the TrimUI Smart Pro (Allwinner A133plus SoC), alongside the engineering plan for the rebuilt **Lumen-OS** operating system.

---

## 1. Hardware Control Matrix (Sysfs & Debugfs)

The TrimUI Smart Pro runs Linux kernel 4.9/5.4 with hardware nodes mapped into sysfs and debugfs:

| Subsystem | Node / Path | Values / Format | Description |
| :--- | :--- | :--- | :--- |
| **RGB Stick LEDs** | `/sys/class/led_anim/effect_rgb_hex_lr` | Hex string (e.g., `0000FF`) | Set left & right analog stick halo colors |
| **LED Master Switch** | `/sys/class/led_anim/effect_enable` | `0` or `1` | Enable/disable stick illumination |
| **LED Brightness** | `/sys/class/led_anim/max_scale` | `0`–`255` | Master LED intensity (set to `0` during sleep) |
| **LED Framebuffer** | `/sys/class/led_anim/frame_hex` | Raw hex stream | Per-LED addressing for the 24 RGB elements |
| **FN DIP Switch** | `/usr/trimui/bin/trimui_scened` | Script arg `1` / `0` | Dispatches `/usr/trimui/scene/<active_scene>.sh` |
| **LCD Backlight** | `/sys/kernel/debug/dispdbg` | Debugfs commands | Panel blanking and backlight cut on sleep |
| **Display Warmth** | `/sys/class/disp/disp/attr/color_temperature` | Integer | White balance / night mode warmth shift |
| **CPU Governor** | `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` | `ondemand`, `performance` | Dynamic frequency governor |
| **CPU Frequencies** | `/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq` | `408000` to `2000000` (Hz) | 408 MHz up to 2.0 GHz across 8 steps |
| **CPU Core Hotplug** | `/sys/devices/system/cpu/cpu[0-3]/online` | `0` or `1` | Dynamically disable cores for battery saving |
| **Vibration Motor** | `/sys/class/gpio/gpio227/value` | `0` or `1` | Haptic rumble motor |
| **Audio (ALSA)** | `hw:0` (Allwinner Audio Codec) | `tinymix`, `amixer` | Headphone detection, master digital volume |
| **Input Events** | `/dev/input/event3` | Linux input `evdev` | D-pad, face buttons, shoulder triggers, shortcuts |

---

## 2. Boot & Startup Pipeline

The stock TrimUI boot sequence launches `/usr/trimui/bin/runtrimui.sh`, which delegates execution to the SD card:

1. **`trimui/app/preload.sh`**:
   - Intercepts boot.
   - Evaluates "Resume at Boot" session file (`cmd_to_run.sh`).
   - Checks if the user is holding the `MENU` button during power-on to cancel resume.
   - If resuming, launches the game session directly and bypasses the main menu.
2. **`System/init.d/` (Legacy `System/starts/`)**:
   - System daemon startup (Dropbear SSH, SFTPGo, WiFi connectivity).
   - Hotkey listener initialization (`thd` Triggerhappy daemon on `/dev/input/event3`).
   - LED animation daemon (`smartledd`).
3. **`MainUI` (Frontend Launcher)**:
   - Reads system themes from `/mnt/SDCARD/Themes/`.
   - Reads emulator categories from `/mnt/SDCARD/Emus/`.
   - Reads user apps from `/mnt/SDCARD/Apps/`.

---

## 3. Rebuild Architecture Goals

- **Zero Rootfs Mutation**: Replace ad-hoc file copies to internal flash with non-destructive runtime overlays and clean mount points.
- **Unified Hardware Daemon**: Consolidate scattered shell scripts (`smartledd`, `cpufreq.sh`, `nightmode.sh`, `lcd_off.sh`) into a single structured daemon.
- **Modern Design Language**: Build a 1280×720 UI theme (`Lumen`) with clean typography, high-contrast dark palette, standardized iconography, and fluid navigation.
- **Clean POSIX Dispatcher**: Consolidate repetitive per-emulator launch scripts into a single unified runner supporting per-game JSON configs.
