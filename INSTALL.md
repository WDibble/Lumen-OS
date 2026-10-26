# Lumen-OS: Installation & Setup Guide

This guide covers installing **Lumen-OS** on the **TrimUI Smart Pro**.

---

## 📋 Requirements

1. **TrimUI Smart Pro Handheld Console** running official TrimUI firmware (hotfix 9 or newer recommended).
2. **MicroSD Card**: High-speed Class 10 / UHS-I / U3 card (64GB to 512GB recommended).
3. **Computer**: macOS, Windows, or Linux with an SD card reader.

---

## 💾 1. MicroSD Card Preparation

For optimal performance and to maximize read/write throughput on the Allwinner A133plus SDIO bus, format your card as follows:

- **Cards $\le 32\text{GB}$**: **FAT32** with **32KB** or **64KB** cluster size.
- **Cards $\ge 64\text{GB}$**: **exFAT** or **FAT32** with **128KB** cluster size.

> [!TIP]
> Use official SD Association **SD Card Formatter** or `guiformat` (Windows) / `Disk Utility` (macOS) / `mkfs.fat -F 32 -s 128` (Linux).

---

## 🚀 2. Fresh Installation

1. Download the latest release archive (`Lumen-OS-v1.0.0.zip`).
2. Extract the archive contents directly to the root of your MicroSD card.
3. Your MicroSD card root directory should contain:
   ```
   Apps/
   Backgrounds/
   BIOS/
   Emus/
   Icons/
   RetroArch/
   Roms/
   System/
   Themes/
   trimui/
   ```
4. Safely eject the card from your computer and insert it into the **TF** slot of your powered-off TrimUI Smart Pro.
5. Power on the console. Lumen-OS will execute its **First-Boot OOBE** setup:
   - Verifies directory scaffolds.
   - Generates persistent Dropbear SSH host keys.
   - Pulses analog LEDs in cyan to signal readiness.

---

## 🕹️ 3. BIOS & ROM Setup

### BIOS Files
Place BIOS files directly in the `/mnt/SDCARD/BIOS/` folder:

| System | Recommended BIOS File(s) | Notes |
| :--- | :--- | :--- |
| **Sony PlayStation** | `scph1001.bin`, `scph5501.bin`, `psxonpsp660.bin` | Required for PS1 accuracy |
| **Sega Dreamcast** | `dc/dc_boot.bin` | Required for Flycast standalone & core |
| **Sega Saturn** | `saturn_bios.bin` | Required for YabaSanshiro / Beetle Saturn |
| **SNK Neo Geo** | `neogeo.zip` | Required for FBNeo and MVS games |
| **Sega CD** | `bios_CD_U.bin`, `bios_CD_E.bin`, `bios_CD_J.bin` | Required for MegaCD / SegaCD |
| **Game Boy Advance**| `gba_bios.bin` | Optional, improves boot intro |
| **Nintendo DS** | `bios7.bin`, `bios9.bin`, `firmware.bin` | Required for Drastic & melonDS |

> [!NOTE]
> Launch **BIOS Doctor** from the Apps tab on your console at any time to verify that your BIOS files are present, properly sized, and case-sensitive.

### ROMs
Place ROM files in their corresponding folders under `/mnt/SDCARD/Roms/` (e.g. `Roms/FC/`, `Roms/SFC/`, `Roms/MD/`, `Roms/PS/`, `Roms/GBA/`, `Roms/NDS/`, `Roms/PSP/`). Each folder contains a `README.txt` file detailing supported file extensions.

---

## 🛡️ 4. Zero-NAND Guarantee

Lumen-OS operates under a strict **Zero-NAND Mutation Invariant**:
- It never touches `/dev/mmcblk0p*`, `/dev/mtd*`, `/dev/nand*`, or internal root partitions.
- It will never alter your internal firmware bootloader.
- Removing the MicroSD card returns the TrimUI Smart Pro to its original stock state instantly.
