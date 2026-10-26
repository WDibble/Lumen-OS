#!/usr/bin/env python3
"""
Lumen-OS Automated Test Harness
Executes integrity, syntax, schema, and hardware mock tests.
"""

import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import wave

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class TestLumenNext(unittest.TestCase):

    def test_01_shell_script_syntax(self):
        """Verify all shell scripts have valid POSIX syntax (sh -n)."""
        scripts = glob.glob(f"{REPO_ROOT}/**/*.sh", recursive=True)
        # Also include next-hw which has no extension
        scripts.append(f"{REPO_ROOT}/System/bin/next-hw")

        self.assertGreater(len(scripts), 0, "No shell scripts found to test!")
        for script in scripts:
            res = subprocess.run(["sh", "-n", script], capture_output=True, text=True)
            self.assertEqual(
                res.returncode, 0,
                f"Syntax error in {os.path.relpath(script, REPO_ROOT)}:\n{res.stderr}"
            )

    def test_02_posix_line_endings(self):
        """Verify all scripts and configs use strictly Unix LF (zero CRLF)."""
        extensions = [".sh", ".json", ".md", ".py"]
        all_files = []
        for ext in extensions:
            all_files.extend(glob.glob(f"{REPO_ROOT}/**/*{ext}", recursive=True))
        all_files.append(f"{REPO_ROOT}/System/bin/next-hw")

        for fpath in all_files:
            if ".git" in fpath:
                continue
            with open(fpath, "rb") as f:
                content = f.read()
                self.assertNotIn(
                    b"\r\n", content,
                    f"CRLF carriage return found in {os.path.relpath(fpath, REPO_ROOT)}"
                )

    def test_03_json_schemas(self):
        """Validate JSON syntax and required properties across all configs."""
        # 1. System/etc/config.json
        sys_cfg_path = f"{REPO_ROOT}/System/etc/config.json"
        self.assertTrue(os.path.isfile(sys_cfg_path))
        with open(sys_cfg_path) as f:
            sys_cfg = json.load(f)
            self.assertIn("theme", sys_cfg)
            self.assertIn("led", sys_cfg)
            self.assertIn("cpu", sys_cfg)

        # 2. Themes/Lumen/config.json
        theme_cfg_path = f"{REPO_ROOT}/Themes/Lumen/config.json"
        self.assertTrue(os.path.isfile(theme_cfg_path))
        with open(theme_cfg_path) as f:
            theme_cfg = json.load(f)
            self.assertEqual(theme_cfg.get("name"), "Lumen")
            self.assertIn("fontsize", theme_cfg)
            self.assertIn("fontcolor", theme_cfg)
            self.assertIn("nav_font1", theme_cfg["fontsize"])
            self.assertIn("nav_color2", theme_cfg["fontcolor"])
            self.assertEqual(theme_cfg["fontcolor"]["nav_color1"], "#FFB0BED0")
            self.assertEqual(theme_cfg["fontcolor"]["content_color2"], "#FFB0BED0")
            self.assertEqual(theme_cfg["fontcolor"]["stat_color2"], "#FFB0BED0")
            self.assertEqual(theme_cfg["fontcolor"]["content_color3"], "#FFCBD5E1")

        # 3. Emus/*/config.json
        emu_cfgs = glob.glob(f"{REPO_ROOT}/Emus/*/config.json")
        self.assertGreaterEqual(len(emu_cfgs), 20, "Expected at least 20 console configurations!")
        for ecfg_path in emu_cfgs:
            rel = os.path.relpath(ecfg_path, REPO_ROOT)
            with open(ecfg_path) as f:
                ecfg = json.load(f)
                self.assertIn("label", ecfg, f"Missing 'label' in {rel}")
                self.assertIn("icon", ecfg, f"Missing 'icon' in {rel}")
                self.assertIn("launch", ecfg, f"Missing 'launch' in {rel}")
                self.assertIn("rompath", ecfg, f"Missing 'rompath' in {rel}")
                self.assertIn("extlist", ecfg, f"Missing 'extlist' in {rel}")

    def test_04_theme_assets_integrity(self):
        """Verify presence, non-emptiness, and audio spec for Lumen theme."""
        theme_dir = f"{REPO_ROOT}/Themes/Lumen"
        required_files = [
            f"{theme_dir}/bg.png",
            f"{theme_dir}/shutdown.png",
            f"{theme_dir}/preview.png",
            f"{theme_dir}/skin/bg.png",
            f"{theme_dir}/skin/grid-item-bg-f.png",
            f"{theme_dir}/skin/grid-item-bg-n.png",
            f"{theme_dir}/skin/list-item-2line-bg-f.png",
            f"{theme_dir}/skin/tips-A.png",
            f"{theme_dir}/skin/tips-MENU.png",
            f"{theme_dir}/skin/sw-on.png",
            f"{theme_dir}/skin/sw-off.png",
            f"{theme_dir}/skin/ic-batery-100%.png",
            f"{theme_dir}/skin/ic-charging.png",
            f"{theme_dir}/sound/click.wav"
        ]

        for req in required_files:
            rel = os.path.relpath(req, REPO_ROOT)
            self.assertTrue(os.path.isfile(req), f"Missing required theme asset: {rel}")
            self.assertGreater(os.path.getsize(req), 0, f"Theme asset is empty (0 bytes): {rel}")

        # Check audio spec: < 100ms duration, 16-bit PCM
        wav_path = f"{theme_dir}/sound/click.wav"
        with wave.open(wav_path, "rb") as wf:
            channels = wf.getnchannels()
            sample_width = wf.getsampwidth()
            framerate = wf.getframerate()
            frames = wf.getnframes()
            duration_ms = (frames / float(framerate)) * 1000.0

            self.assertEqual(channels, 1, "Audio click must be Mono")
            self.assertEqual(sample_width, 2, "Audio click must be 16-bit PCM")
            self.assertEqual(framerate, 44100, "Audio click must be 44.1 kHz")
            self.assertLessEqual(duration_ms, 100.0, f"Click duration too long: {duration_ms}ms")

    def test_05_hardware_tool_dry_run(self):
        """Mock Linux sysfs/debugfs and test next-hw execution & frequency ordering."""
        temp_dir = tempfile.mkdtemp()
        try:
            mock_led = os.path.join(temp_dir, "sys/class/led_anim")
            mock_cpu = os.path.join(temp_dir, "sys/devices/system/cpu/cpu0/cpufreq")
            mock_disp = os.path.join(temp_dir, "sys/kernel/debug/dispdbg")
            os.makedirs(mock_led, exist_ok=True)
            os.makedirs(mock_cpu, exist_ok=True)
            os.makedirs(mock_disp, exist_ok=True)

            # Initialize mock files
            for fname in ["effect_enable", "effect_rgb_hex_lr", "max_scale", "effect_cycles_lr", "effect_duration_lr"]:
                with open(os.path.join(mock_led, fname), "w") as f:
                    f.write("0\n")
            for fname in ["scaling_governor", "scaling_min_freq", "scaling_max_freq"]:
                with open(os.path.join(mock_cpu, fname), "w") as f:
                    f.write("ondemand\n" if "gov" in fname else "816000\n")
            for fname in ["name", "command", "param", "start"]:
                with open(os.path.join(mock_disp, fname), "w") as f:
                    f.write("\n")

            # Create a patched next-hw that points to mock_sysfs
            hw_script = f"{REPO_ROOT}/System/bin/next-hw"
            with open(hw_script) as f:
                content = f.read()

            patched = content.replace(
                'LED_SYSFS="/sys/class/led_anim"', f'LED_SYSFS="{mock_led}"'
            ).replace(
                'CPU_SYSFS="/sys/devices/system/cpu"', f'CPU_SYSFS="{os.path.join(temp_dir, "sys/devices/system/cpu")}"'
            ).replace(
                'DISP_SYSFS="/sys/kernel/debug/dispdbg"', f'DISP_SYSFS="{mock_disp}"'
            )

            test_hw = os.path.join(temp_dir, "next-hw-test")
            with open(test_hw, "w") as f:
                f.write(patched)
            os.chmod(test_hw, 0o755)

            # 1. Test LED command
            res = subprocess.run([test_hw, "led", "--hex", "00FF88", "--brightness", "90"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"next-hw led failed: {res.stderr}")
            with open(os.path.join(mock_led, "effect_rgb_hex_lr")) as f:
                self.assertEqual(f.read().strip(), "00FF88")

            # 2. Test CPU profile transitions
            res = subprocess.run([test_hw, "cpu", "--profile", "powersave"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"next-hw cpu powersave failed: {res.stderr}")
            with open(os.path.join(mock_cpu, "scaling_min_freq")) as f:
                min_f = int(f.read().strip())
            with open(os.path.join(mock_cpu, "scaling_max_freq")) as f:
                max_f = int(f.read().strip())
            self.assertLessEqual(min_f, max_f, f"Invariant violated: min_freq {min_f} > max_freq {max_f}")

            # Transition to performance
            res = subprocess.run([test_hw, "cpu", "--profile", "performance"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"next-hw cpu performance failed: {res.stderr}")
            with open(os.path.join(mock_cpu, "scaling_min_freq")) as f:
                min_f = int(f.read().strip())
            with open(os.path.join(mock_cpu, "scaling_max_freq")) as f:
                max_f = int(f.read().strip())
            self.assertLessEqual(min_f, max_f, f"Invariant violated in performance: min_freq {min_f} > max_freq {max_f}")

            # 3. Test Display blanking
            res = subprocess.run([test_hw, "display", "--blank", "1"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"next-hw display blank failed: {res.stderr}")
            with open(os.path.join(mock_disp, "command")) as f:
                self.assertEqual(f.read().strip(), "blank")

            # 4. Test Power sleep & wake cycle
            res = subprocess.run([test_hw, "power", "sleep"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"next-hw power sleep failed: {res.stderr}")
            res = subprocess.run([test_hw, "power", "wake"], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"next-hw power wake failed: {res.stderr}")

        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    def test_06_launch_dispatcher_flow(self):
        """Test universal launch.sh error handling and signal cleanup."""
        launch_script = f"{REPO_ROOT}/System/scripts/launch.sh"
        # Test missing ROM handling
        res = subprocess.run([launch_script, "/nonexistent/test.gba"], capture_output=True, text=True)
        self.assertNotEqual(res.returncode, 0, "launch.sh should fail when ROM does not exist")

        # Test dry run with a dummy ROM file and mock executable
        temp_dir = tempfile.mkdtemp()
        try:
            mock_rom = os.path.join(temp_dir, "test.gba")
            with open(mock_rom, "w") as f:
                f.write("MOCK_ROM_DATA")

            mock_runner = os.path.join(temp_dir, "mock_runner.sh")
            with open(mock_runner, "w") as f:
                f.write("#!/bin/sh\necho 'MOCK_EMU_RUNNING'\nexit 0\n")
            os.chmod(mock_runner, 0o755)

            res = subprocess.run([launch_script, mock_rom, mock_runner], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"launch.sh dry-run failed:\n{res.stderr}")

            # Check that log was created
            log_file = "/tmp/lumen/log/launch.log"
            self.assertTrue(os.path.isfile(log_file), "launch.log was not created!")
            with open(log_file) as f:
                log_content = f.read()
                self.assertIn("Launching ROM", log_content)
                self.assertIn("Post-game teardown initiated", log_content)
                self.assertIn("Session Ended", log_content)

        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    def test_07_theme_dimensions_parity(self):
        """Assert Lumen button background assets have exact dimension parity (300x60)."""
        from PIL import Image
        skin_dir = f"{REPO_ROOT}/Themes/Lumen/skin"
        btn_n = os.path.join(skin_dir, "btn-bg-n.png")
        btn_f = os.path.join(skin_dir, "btn-bg-f.png")

        self.assertTrue(os.path.isfile(btn_n), "Missing btn-bg-n.png")
        self.assertTrue(os.path.isfile(btn_f), "Missing btn-bg-f.png")

        with Image.open(btn_n) as img_n:
            self.assertEqual(img_n.size, (300, 60), f"btn-bg-n.png size is {img_n.size}, expected (300, 60)")
        with Image.open(btn_f) as img_f:
            self.assertEqual(img_f.size, (300, 60), f"btn-bg-f.png size is {img_f.size}, expected (300, 60)")

        mid_nav = os.path.join(skin_dir, "main-nav-sel-mid.png")
        self.assertTrue(os.path.isfile(mid_nav), "Missing main-nav-sel-mid.png")
        with Image.open(mid_nav) as img_mid:
            self.assertEqual(img_mid.size, (4, 70), f"main-nav-sel-mid.png size is {img_mid.size}, expected (4, 70)")

    def test_08_retroarch_configuration(self):
        """Verify RetroArch configuration enforces 720p, absolute paths, and safe hotkeys."""
        ra_cfg_path = f"{REPO_ROOT}/RetroArch/retroarch.cfg"
        self.assertTrue(os.path.isfile(ra_cfg_path), "Missing RetroArch/retroarch.cfg")

        with open(ra_cfg_path) as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith("#")]

        cfg_dict = {}
        for line in lines:
            if "=" in line:
                k, v = line.split("=", 1)
                cfg_dict[k.strip()] = v.strip().strip('"')

        self.assertEqual(cfg_dict.get("video_fullscreen_x"), "1280")
        self.assertEqual(cfg_dict.get("video_fullscreen_y"), "720")
        self.assertEqual(cfg_dict.get("video_vsync"), "true")
        self.assertEqual(cfg_dict.get("video_scale_integer"), "true")
        self.assertEqual(cfg_dict.get("savefile_directory"), "/mnt/SDCARD/RetroArch/.retroarch/saves")
        self.assertEqual(cfg_dict.get("savestate_directory"), "/mnt/SDCARD/RetroArch/.retroarch/states")
        self.assertEqual(cfg_dict.get("system_directory"), "/mnt/SDCARD/BIOS")
        # Ensure R1 (button 5) is NOT used as hotkey enable modifier
        self.assertNotEqual(cfg_dict.get("input_enable_hotkey_btn"), "5")

    def test_09_standalone_emulators_integrity(self):
        """Verify presence of standalone binaries for PSP, NDS, N64, and DC."""
        self.assertTrue(os.path.isfile(f"{REPO_ROOT}/Emus/PSP/PPSSPP_1.17.1/PPSSPPSDL_gl"))
        self.assertTrue(os.path.isfile(f"{REPO_ROOT}/Emus/PSP/PPSSPP_1.17.1/PPSSPPSDL_vulkan"))
        self.assertTrue(os.path.isfile(f"{REPO_ROOT}/Emus/NDS/drastic/drastic_2.5.2.2"))
        self.assertTrue(os.path.isfile(f"{REPO_ROOT}/Emus/N64/mupen64plus/mupen64plus"))
        self.assertTrue(os.path.isfile(f"{REPO_ROOT}/Emus/DC/flycast_v2.4/flycast"))

    def test_10_zram_initialization(self):
        """Verify S02_zram.sh syntax and 384MB size allocation."""
        zram_script = f"{REPO_ROOT}/System/init.d/S02_zram.sh"
        self.assertTrue(os.path.isfile(zram_script))
        with open(zram_script) as f:
            content = f.read()
            self.assertIn("402653184", content, "Expected 384MB (402653184 bytes) disksize")
            self.assertIn("/dev/zram0", content)

    def test_11_core_routing(self):
        """Verify launch.sh properly identifies .so core targets without fallback."""
        launch_script = f"{REPO_ROOT}/System/scripts/launch.sh"
        temp_dir = tempfile.mkdtemp()
        try:
            mock_rom = os.path.join(temp_dir, "game.nds")
            with open(mock_rom, "w") as f:
                f.write("MOCK_NDS_DATA")

            # Dry run with melonds_libretro.so as parameter
            res = subprocess.run([launch_script, mock_rom, "melonds_libretro.so"], capture_output=True, text=True)
            log_file = "/tmp/lumen/log/launch.log"
            with open(log_file) as f:
                log_content = f.read()
                self.assertIn("melonds_libretro.so", log_content)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    def test_12_hotkey_daemon_and_shortcuts(self):
        """Verify triggerhappy configuration, shortcuts mapping, and supervisor script."""
        shortcuts_conf = f"{REPO_ROOT}/System/etc/shortcuts.conf"
        thd_bin = f"{REPO_ROOT}/System/bin/thd"
        s15_script = f"{REPO_ROOT}/System/init.d/S15_hotkeys.sh"
        screenshot_sh = f"{REPO_ROOT}/System/bin/screenshot.sh"

        self.assertTrue(os.path.isfile(shortcuts_conf), "Missing System/etc/shortcuts.conf")
        self.assertTrue(os.path.isfile(thd_bin), "Missing System/bin/thd")
        self.assertTrue(os.access(thd_bin, os.X_OK), "System/bin/thd is not executable")
        self.assertTrue(os.path.isfile(s15_script), "Missing System/init.d/S15_hotkeys.sh")
        self.assertTrue(os.access(s15_script, os.X_OK), "S15_hotkeys.sh is not executable")
        self.assertTrue(os.path.isfile(screenshot_sh), "Missing System/bin/screenshot.sh")
        self.assertTrue(os.access(screenshot_sh, os.X_OK), "screenshot.sh is not executable")

        with open(shortcuts_conf) as f:
            content = f.read()
            self.assertIn("BTN_START+BTN_SELECT", content)
            self.assertIn("screenshot.sh", content)
            self.assertIn("next-hw", content)

    def test_13_input_daemon_integrity(self):
        """Verify trimui_inputd override, polling rate, and config.json input schema."""
        inputd = f"{REPO_ROOT}/trimui/app/trimui_inputd"
        tsp_inputd = f"{REPO_ROOT}/System/resources/tsp_inputd"
        rate_cfg = f"{REPO_ROOT}/trimui/app/inputd_polling_rate.cfg"
        cfg_path = f"{REPO_ROOT}/System/etc/config.json"

        self.assertTrue(os.path.isfile(inputd), "Missing trimui/app/trimui_inputd")
        self.assertTrue(os.access(inputd, os.X_OK), "trimui_inputd is not executable")
        self.assertTrue(os.path.isfile(tsp_inputd), "Missing System/resources/tsp_inputd")
        self.assertTrue(os.access(tsp_inputd, os.X_OK), "tsp_inputd is not executable")
        self.assertTrue(os.path.isfile(rate_cfg), "Missing trimui/app/inputd_polling_rate.cfg")

        with open(cfg_path) as f:
            cfg = json.load(f)
            self.assertIn("input", cfg)
            self.assertIn("swap_ab", cfg["input"])
            self.assertIn("polling_rate_hz", cfg["input"])

    def test_14_network_services_and_samba_sandboxing(self):
        """Verify Dropbear, Samba sandboxing, Avahi configuration, and S20_network.sh."""
        dropbear_bin = f"{REPO_ROOT}/System/bin/dropbear"
        smbd_bin = f"{REPO_ROOT}/System/bin/smbd"
        smb_conf = f"{REPO_ROOT}/System/etc/samba/smb.conf"
        avahi_conf = f"{REPO_ROOT}/System/etc/avahi/avahi-daemon.conf"
        s20_script = f"{REPO_ROOT}/System/init.d/S20_network.sh"

        self.assertTrue(os.path.isfile(dropbear_bin), "Missing System/bin/dropbear")
        self.assertTrue(os.access(dropbear_bin, os.X_OK), "dropbear is not executable")
        self.assertTrue(os.path.isfile(smbd_bin), "Missing System/bin/smbd")
        self.assertTrue(os.access(smbd_bin, os.X_OK), "smbd is not executable")
        self.assertTrue(os.path.isfile(smb_conf), "Missing System/etc/samba/smb.conf")
        self.assertTrue(os.path.isfile(avahi_conf), "Missing System/etc/avahi/avahi-daemon.conf")
        self.assertTrue(os.path.isfile(s20_script), "Missing System/init.d/S20_network.sh")
        self.assertTrue(os.access(s20_script, os.X_OK), "S20_network.sh is not executable")

        # Verify airtight Samba sandboxing
        with open(smb_conf) as f:
            smb_text = f.read()
            self.assertNotIn("path = / \n", smb_text, "Dangerous: rootfs / must never be exposed in Samba!")
            self.assertNotIn("path = /\n", smb_text)
            self.assertIn("path = /mnt/SDCARD", smb_text)
            self.assertIn("/tmp/lumen/samba", smb_text)
            self.assertIn("max smbd processes = 2", smb_text)

        # Verify Avahi D-Bus disabled for stock Tina Linux
        with open(avahi_conf) as f:
            avahi_text = f.read()
            self.assertIn("enable-dbus=no", avahi_text)

    def test_15_portmaster_environment_and_launcher(self):
        """Verify PortMaster binary presence, executable bits, ex_config contract, and fb recovery."""
        pm_dir = f"{REPO_ROOT}/Apps/PortMaster"
        pm_control = f"{pm_dir}/PortMaster"
        pm_launch = f"{pm_dir}/launch.sh"
        ex_config = f"{REPO_ROOT}/System/etc/ex_config"

        self.assertTrue(os.path.isfile(pm_launch), "Missing Apps/PortMaster/launch.sh")
        self.assertTrue(os.access(pm_launch, os.X_OK), "Apps/PortMaster/launch.sh is not executable")
        self.assertTrue(os.path.isfile(ex_config), "Missing System/etc/ex_config")

        # Key PortMaster binaries
        for binary in ["pugwash", "harbourmaster", "gptokeyb2"]:
            bpath = f"{pm_control}/{binary}"
            self.assertTrue(os.path.isfile(bpath), f"Missing PortMaster binary: {binary}")
            self.assertTrue(os.access(bpath, os.X_OK), f"Binary {binary} is not executable")

        # Zero NAND contract in ex_config
        with open(ex_config) as f:
            ex_text = f.read()
            self.assertIn('HOME="/mnt/SDCARD/.home"', ex_text)
            self.assertIn('PYTHONDONTWRITEBYTECODE=1', ex_text)
            self.assertIn('/tmp/lumen/pycache', ex_text)

        # Allwinner double-buffered virtual framebuffer height (1440) restoration check
        with open(pm_launch) as f:
            launch_text = f.read()
            self.assertIn("fbset -g 1280 720 1280 1440 32", launch_text)
            self.assertIn("echo 0 > /sys/class/graphics/fb0/blank", launch_text)

    def test_16_native_apps_configs_and_executables(self):
        """Verify all native apps have valid config.json and executable entrypoints."""
        app_cfgs = glob.glob(f"{REPO_ROOT}/Apps/*/config.json")
        self.assertGreaterEqual(len(app_cfgs), 8, f"Expected at least 8 apps, found {len(app_cfgs)}")

        for acfg_path in app_cfgs:
            app_dir = os.path.dirname(acfg_path)
            rel = os.path.relpath(acfg_path, REPO_ROOT)
            with open(acfg_path) as f:
                acfg = json.load(f)
                self.assertIn("label", acfg, f"Missing 'label' in {rel}")
                self.assertIn("icon", acfg, f"Missing 'icon' in {rel}")
                self.assertIn("launch", acfg, f"Missing 'launch' in {rel}")

                # Ensure launcher file exists
                launcher_path = os.path.join(app_dir, acfg["launch"])
                self.assertTrue(
                    os.path.isfile(launcher_path),
                    f"Configured launcher does not exist: {launcher_path}"
                )

        # Verify DinguxCommander
        dc_bin = f"{REPO_ROOT}/Apps/FileManager/DinguxCommander"
        self.assertTrue(os.path.isfile(dc_bin), "Missing DinguxCommander binary")
        self.assertTrue(os.access(dc_bin, os.X_OK), "DinguxCommander is not executable")

        # Verify Activities binary
        act_bin = f"{REPO_ROOT}/System/bin/activities"
        self.assertTrue(os.path.isfile(act_bin), "Missing System/bin/activities")
        self.assertTrue(os.access(act_bin, os.X_OK), "System/bin/activities is not executable")

    def test_17_extended_console_parity_and_schemas(self):
        """Verify full 112 system parity, config schemas, valid icon PNGs, and matching Roms folders."""
        emu_dirs = [d for d in glob.glob(f"{REPO_ROOT}/Emus/*") if os.path.isdir(d)]
        self.assertEqual(len(emu_dirs), 112, f"Expected exactly 112 console platforms, found {len(emu_dirs)}")

        required_keys = {"label", "icon", "launch", "rompath", "imgpath", "extlist", "launchlist"}
        png_magic = b"\x89PNG\r\n\x1a\n"

        for edir in emu_dirs:
            emu_name = os.path.basename(edir)
            cfg_path = os.path.join(edir, "config.json")
            self.assertTrue(os.path.isfile(cfg_path), f"Missing config.json in {edir}")
            with open(cfg_path) as f:
                cfg = json.load(f)
                missing = required_keys - set(cfg.keys())
                self.assertEqual(len(missing), 0, f"{emu_name} missing required config keys: {missing}")
                self.assertIsInstance(cfg["launchlist"], list)

            # Icon integrity check
            icon_path = os.path.join(edir, "icon.png")
            self.assertTrue(os.path.isfile(icon_path), f"Missing icon.png in {edir}")
            self.assertGreater(os.path.getsize(icon_path), 0, f"Empty icon.png in {edir}")
            with open(icon_path, "rb") as f:
                header = f.read(8)
                self.assertEqual(header, png_magic, f"Invalid PNG magic in {icon_path}")

            # Matching Roms directory check
            rom_dir = os.path.join(REPO_ROOT, "Roms", emu_name)
            self.assertTrue(os.path.isdir(rom_dir), f"Missing Roms folder for {emu_name}: {rom_dir}")

    def test_18_libretro_core_parity_and_elf_integrity(self):
        """Extract all referenced Libretro cores and verify ELF binary presence and integrity."""
        cores_found = set()
        for launch_file in glob.glob(f"{REPO_ROOT}/Emus/*/launch.sh"):
            with open(launch_file, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                import re
                matches = re.findall(r'([a-zA-Z0-9_\-]+_libretro\.so)', content)
                for m in matches:
                    cores_found.add(m)

        self.assertGreater(len(cores_found), 30, f"Expected at least 30 distinct cores referenced, found {len(cores_found)}")
        cores_dir = f"{REPO_ROOT}/RetroArch/.retroarch/cores"
        elf_magic = b"\x7fELF"

        for core_name in cores_found:
            core_path = os.path.join(cores_dir, core_name)
            self.assertTrue(os.path.isfile(core_path), f"Referenced core missing: {core_name}")
            self.assertGreater(os.path.getsize(core_path), 0, f"Core is zero bytes: {core_name}")
            with open(core_path, "rb") as f:
                header = f.read(4)
                self.assertEqual(header, elf_magic, f"Core is not an ELF binary: {core_name}")

    def test_19_launch_dispatcher_argument_normalization(self):
        """Verify System/scripts/launch.sh normalizes both standard and Options launchlist argument orders."""
        launch_script = f"{REPO_ROOT}/System/scripts/launch.sh"
        temp_dir = tempfile.mkdtemp()
        log_file = "/tmp/lumen/log/launch.log"
        try:
            mock_rom = os.path.join(temp_dir, "test_game.zip")
            with open(mock_rom, "w") as f:
                f.write("MOCK_GAME_DATA")

            # Invocations to test
            # Case 1: Normal MainUI order: launch.sh <ROM> <TARGET>
            subprocess.run([launch_script, mock_rom, "fbneo_libretro.so"], capture_output=True, text=True)
            with open(log_file) as f:
                log_1 = f.read()
                self.assertIn(f"ROM={mock_rom}", log_1)
                self.assertIn("Target=fbneo_libretro.so", log_1)

            # Case 2: Inverted Options launchlist order: launch.sh <TARGET> <ROM>
            subprocess.run([launch_script, "fbneo_libretro.so", mock_rom], capture_output=True, text=True)
            with open(log_file) as f:
                log_2 = f.read()
                self.assertIn(f"ROM={mock_rom}", log_2)
                self.assertIn("Target=fbneo_libretro.so", log_2)
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    def test_20_zero_nand_mutation_and_bootlogo_safety(self):
        """Verify strict Zero NAND compliance and non-destructive boot splash configuration."""
        banned_patterns = [
            b"/dev/mtd",
            b"/dev/nand",
            b"nandwrite",
            b"flash_erase",
            b"mount -o remount,rw /",
            b"/dev/mmcblk0p1"
        ]
        all_scripts = glob.glob(f"{REPO_ROOT}/Emus/**/*.sh", recursive=True)
        all_scripts.extend(glob.glob(f"{REPO_ROOT}/Apps/**/*.sh", recursive=True))
        all_scripts.extend(glob.glob(f"{REPO_ROOT}/System/**/*.sh", recursive=True))

        for script in all_scripts:
            with open(script, "rb") as f:
                data = f.read()
                for pattern in banned_patterns:
                    self.assertNotIn(
                        pattern, data,
                        f"Zero NAND violation in {os.path.relpath(script, REPO_ROOT)}: contains {pattern.decode()}"
                    )

        # Specifically verify _BootLogo
        bootlogo_launch = f"{REPO_ROOT}/Emus/_BootLogo/launch.sh"
        self.assertTrue(os.path.isfile(bootlogo_launch))
        with open(bootlogo_launch, "r", encoding="utf-8") as f:
            boot_text = f.read()
            self.assertIn("/mnt/SDCARD/System/res/boot.bmp", boot_text)
            self.assertNotIn("/dev/mmcblk0p1", boot_text)

    def test_21_advanced_handheld_features_integrity(self):
        """Verify the 6 advanced handheld features: FN daemon, Sentinel, USB Storage, Syncthing, Switcher, DAC De-pop."""
        # 1. Audio DAC Sleep De-Pop Guard
        sleep_guard = f"{REPO_ROOT}/System/bin/sleep_guard.sh"
        self.assertTrue(os.path.isfile(sleep_guard), "Missing sleep_guard.sh")
        self.assertTrue(os.access(sleep_guard, os.X_OK), "sleep_guard.sh is not executable")
        with open(sleep_guard) as f:
            text = f.read()
            self.assertIn("amixer", text)
            self.assertIn("250000", text)  # 250ms settling dwell

        # 2. Autonomous Low-Battery & Auto-Save Sentinel
        sentinel_bin = f"{REPO_ROOT}/System/bin/battery_sentinel.sh"
        sentinel_init = f"{REPO_ROOT}/System/init.d/S22_battery.sh"
        self.assertTrue(os.path.isfile(sentinel_bin), "Missing battery_sentinel.sh")
        self.assertTrue(os.access(sentinel_bin, os.X_OK), "battery_sentinel.sh is not executable")
        self.assertTrue(os.path.isfile(sentinel_init), "Missing S22_battery.sh")
        self.assertTrue(os.access(sentinel_init, os.X_OK), "S22_battery.sh is not executable")
        with open(sentinel_bin) as f:
            text = f.read()
            self.assertIn("SAVE_STATE", text)
            self.assertIn("poweroff", text)

        # 3. Physical FN Switch Hardware Daemon
        fndaemon_init = f"{REPO_ROOT}/System/init.d/S16_fndaemon.sh"
        self.assertTrue(os.path.isfile(fndaemon_init), "Missing S16_fndaemon.sh")
        self.assertTrue(os.access(fndaemon_init, os.X_OK), "S16_fndaemon.sh is not executable")
        with open(fndaemon_init) as f:
            text = f.read()
            self.assertIn("EV_SW", text)
            self.assertIn("SW_TABLET_MODE", text)

        # 4. USB Mass Storage App
        usb_app_cfg = f"{REPO_ROOT}/Apps/USBStorage/config.json"
        usb_app_launch = f"{REPO_ROOT}/Apps/USBStorage/launch.sh"
        self.assertTrue(os.path.isfile(usb_app_cfg), "Missing Apps/USBStorage/config.json")
        self.assertTrue(os.path.isfile(usb_app_launch), "Missing Apps/USBStorage/launch.sh")
        self.assertTrue(os.access(usb_app_launch, os.X_OK), "Apps/USBStorage/launch.sh is not executable")

        # 5. Headless Syncthing Service
        syncthing_bin = f"{REPO_ROOT}/System/bin/syncthing"
        syncthing_init = f"{REPO_ROOT}/System/init.d/S25_syncthing.sh"
        self.assertTrue(os.path.isfile(syncthing_bin), "Missing System/bin/syncthing")
        self.assertTrue(os.access(syncthing_bin, os.X_OK), "System/bin/syncthing is not executable")
        self.assertTrue(os.path.isfile(syncthing_init), "Missing S25_syncthing.sh")
        self.assertTrue(os.access(syncthing_init, os.X_OK), "S25_syncthing.sh is not executable")
        with open(syncthing_bin, "rb") as f:
            header = f.read(4)
            self.assertEqual(header, b"\x7fELF", "Syncthing is not an ELF binary")
        with open(syncthing_init) as f:
            text = f.read()
            self.assertIn("GOMEMLIMIT=48MiB", text)

        # 6. Global Game Switcher Shortcut & Launch Hooks
        shortcuts_conf = f"{REPO_ROOT}/System/etc/shortcuts.conf"
        launch_script = f"{REPO_ROOT}/System/scripts/launch.sh"
        with open(shortcuts_conf) as f:
            text = f.read()
            self.assertIn("BTN_SELECT+BTN_MODE", text)
        with open(launch_script) as f:
            text = f.read()
            self.assertIn("pkill -STOP syncthing", text)
            self.assertIn("pkill -CONT syncthing", text)

    def test_22_curated_bezels_and_shaders(self):
        """Verify 720p curated bezels and lightweight PowerVR GLSL shader presets."""
        overlay_dir = f"{REPO_ROOT}/RetroArch/.retroarch/overlay"
        shader_dir = f"{REPO_ROOT}/RetroArch/.retroarch/shaders/shaders_glsl"

        self.assertTrue(os.path.isdir(overlay_dir), "Missing RetroArch overlay directory")
        overlays = glob.glob(f"{overlay_dir}/*_max-ratio.png")
        self.assertGreaterEqual(len(overlays), 30, f"Expected at least 30 max-ratio overlays, found {len(overlays)}")

        self.assertTrue(os.path.isdir(shader_dir), "Missing RetroArch shaders_glsl directory")
        self.assertTrue(os.path.isdir(f"{shader_dir}/crt-lcd 720p"), "Missing crt-lcd 720p shaders")
        self.assertTrue(os.path.isdir(f"{shader_dir}/handheld"), "Missing handheld shaders")
        self.assertTrue(os.path.isdir(f"{shader_dir}/sharp-shimmerless"), "Missing sharp-shimmerless shaders")

    def test_23_in_game_hotkeys_and_retroachievements(self):
        """Verify Fast-Forward, Save Slot cycling, and RetroAchievements configuration in retroarch.cfg."""
        ra_cfg = f"{REPO_ROOT}/RetroArch/retroarch.cfg"
        sys_cfg = f"{REPO_ROOT}/System/etc/config.json"

        with open(ra_cfg) as f:
            text = f.read()
            self.assertIn("input_toggle_fast_forward_btn", text)
            self.assertIn("input_state_slot_increase_btn", text)
            self.assertIn("input_state_slot_decrease_btn", text)
            self.assertIn("cheevos_enable", text)
            self.assertIn("cheevos_leaderboards_enable", text)

        with open(sys_cfg) as f:
            cfg = json.load(f)
            self.assertIn("retroachievements", cfg)
            self.assertIn("enabled", cfg["retroachievements"])
            self.assertIn("hardcore_mode", cfg["retroachievements"])

    def test_24_search_app_and_led_modes(self):
        """Verify Apps/Search utility integrity and next-hw LED modes."""
        search_cfg = f"{REPO_ROOT}/Apps/Search/config.json"
        search_launch = f"{REPO_ROOT}/Apps/Search/launch.sh"
        next_hw = f"{REPO_ROOT}/System/bin/next-hw"

        self.assertTrue(os.path.isfile(search_cfg), "Missing Apps/Search/config.json")
        self.assertTrue(os.path.isfile(search_launch), "Missing Apps/Search/launch.sh")
        self.assertTrue(os.access(search_launch, os.X_OK), "Search launcher is not executable")

        with open(search_launch) as f:
            text = f.read()
            self.assertIn("selector", text)
            self.assertIn("Recent Games", text)

        with open(next_hw) as f:
            text = f.read()
            self.assertIn("--mode", text)
            self.assertIn("battery", text)

    def test_25_zero_nand_static_assertion(self):
        """Assert zero occurrences of raw block devices (/dev/mmcblk0) or partition formatting."""
        forbidden_patterns = ["/dev/mmcblk0", "mkfs.vfat /dev/", "fdisk /dev/"]
        for root, _, files in os.walk(REPO_ROOT):
            if any(p in root for p in [".git", "dist", "tests"]):
                continue
            for fname in files:
                if fname.endswith(".sh"):
                    fpath = os.path.join(root, fname)
                    with open(fpath, "r", errors="ignore") as f:
                        content = f.read()
                        for pattern in forbidden_patterns:
                            self.assertNotIn(
                                pattern,
                                content,
                                f"Zero-NAND violation in {fpath}: found '{pattern}'"
                            )

    def test_26_terminal_and_systemtools_parity(self):
        """Verify Apps/Terminal, SystemTools, BootLogo, and OTA-update parity and traps."""
        term_launch = f"{REPO_ROOT}/Apps/Terminal/launch.sh"
        systools_launch = f"{REPO_ROOT}/Apps/SystemTools/launch.sh"
        ota_launch = f"{REPO_ROOT}/Apps/OTA-update/launch.sh"

        self.assertTrue(os.path.isfile(term_launch) and os.access(term_launch, os.X_OK))
        self.assertTrue(os.path.isfile(systools_launch) and os.access(systools_launch, os.X_OK))
        self.assertTrue(os.path.isfile(ota_launch) and os.access(ota_launch, os.X_OK))

        with open(term_launch) as f:
            t = f.read()
            self.assertIn("fbset -g 1280 720 1280 1440 32", t)
            self.assertIn("SIGCONT", t)

    def test_27_first_boot_oobe(self):
        """Verify First-Boot OOBE script fast-path and directory guarantees."""
        oobe_script = f"{REPO_ROOT}/System/init.d/S00_oobe.sh"
        first_boot = f"{REPO_ROOT}/System/starts/01_first_boot.sh"

        self.assertTrue(os.path.isfile(oobe_script) and os.access(oobe_script, os.X_OK))
        self.assertTrue(os.path.isfile(first_boot) and os.access(first_boot, os.X_OK))

        with open(oobe_script) as f:
            t = f.read()
            # Fast-path check at start
            self.assertIn('[ -f "/mnt/SDCARD/.lumen_initialized" ] && exit 0', t)
            self.assertIn("mkdir -p", t)
            self.assertIn("dropbearkey", t)

    def test_28_system_checker_audit(self):
        """Verify Apps/SystemChecker configuration, launcher, and auditor binary."""
        checker_cfg = f"{REPO_ROOT}/Apps/SystemChecker/config.json"
        checker_launch = f"{REPO_ROOT}/Apps/SystemChecker/launch.sh"
        checker_bin = f"{REPO_ROOT}/Apps/SystemChecker/bin/syschecker"

        self.assertTrue(os.path.isfile(checker_cfg))
        self.assertTrue(os.path.isfile(checker_launch) and os.access(checker_launch, os.X_OK))
        self.assertTrue(os.path.isfile(checker_bin) and os.access(checker_bin, os.X_OK))

        # Run syschecker in a temporary directory
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create dummy PS1 bios with correct size (524288)
            with open(os.path.join(tmpdir, "scph1001.bin"), "wb") as f:
                f.write(b"\0" * 524288)
            
            res = subprocess.run([checker_bin, tmpdir], stdout=subprocess.PIPE, text=True)
            self.assertEqual(res.returncode, 0)
            self.assertIn("Sony PlayStation :: scph1001.bin (OK, 524288B)", res.stdout)
            self.assertIn("Sega Saturn :: saturn_bios.bin (MISSING)", res.stdout)

    def test_29_packaging_and_deployment_tools(self):
        """Verify release packager and SD deployment scripts."""
        packager = f"{REPO_ROOT}/tools/package_release.sh"
        deployer = f"{REPO_ROOT}/tools/deploy_to_sd.sh"

        self.assertTrue(os.path.isfile(packager) and os.access(packager, os.X_OK))
        self.assertTrue(os.path.isfile(deployer) and os.access(deployer, os.X_OK))

        with open(packager) as f:
            t = f.read()
            self.assertIn("COPYFILE_DISABLE=1", t)
            self.assertIn("shasum", t)

    def test_30_safe_bootlogo(self):
        """Verify BootLogo targets SD card userspace res/boot.bmp with zero MTD writes."""
        bootlogo_launch = f"{REPO_ROOT}/Apps/BootLogo/launch.sh"
        emu_bootlogo = f"{REPO_ROOT}/Emus/_BootLogo/launch.sh"

        self.assertTrue(os.path.isfile(bootlogo_launch) and os.access(bootlogo_launch, os.X_OK))
        self.assertTrue(os.path.isfile(emu_bootlogo) and os.access(emu_bootlogo, os.X_OK))

        with open(emu_bootlogo) as f:
            t = f.read()
            self.assertIn("/mnt/SDCARD/System/res/boot.bmp", t)
            self.assertNotIn("/dev/mmcblk0p1", t)

    def test_31_multidevice_hardware_detection(self):
        """Verify dynamic hardware model and resolution detection for all TrimUI devices."""
        hw_bin = f"{REPO_ROOT}/System/bin/next-hw"
        self.assertTrue(os.path.isfile(hw_bin) and os.access(hw_bin, os.X_OK))

        profiles = {
            "tsp": ("TrimUI Smart Pro", "1280 720", 0, 1),
            "tsp-s": ("TrimUI Smart Pro S", "1280 720", 1, 1),
            "brick": ("TrimUI Brick", "1024 768", 0, 0),
            "smart": ("TrimUI Smart", "320 240", 0, 0),
        }

        with tempfile.TemporaryDirectory() as tmpdir:
            for model, (name, res, has_fan, has_rings) in profiles.items():
                env = os.environ.copy()
                env["LUMEN_DEVICE_OVERRIDE"] = model
                env["STATE_DIR"] = os.path.join(tmpdir, model)
                os.makedirs(env["STATE_DIR"], exist_ok=True)

                # Check --get-model
                res_model = subprocess.run([hw_bin, "detect", "--get-model"], env=env, capture_output=True, text=True)
                self.assertEqual(res_model.returncode, 0)
                self.assertEqual(res_model.stdout.strip(), model)

                # Check --get-res
                res_res = subprocess.run([hw_bin, "detect", "--get-res"], env=env, capture_output=True, text=True)
                self.assertEqual(res_res.returncode, 0)
                self.assertEqual(res_res.stdout.strip(), res)

                # Check hardware.env values
                res_dump = subprocess.run([hw_bin, "detect", "--dump"], env=env, capture_output=True, text=True)
                self.assertEqual(res_dump.returncode, 0)
                self.assertIn(f"DEVICE_MODEL={model}", res_dump.stdout)
                self.assertIn(f'DEVICE_NAME="{name}"', res_dump.stdout)
                self.assertIn(f"HAS_FAN={has_fan}", res_dump.stdout)
                self.assertIn(f"HAS_RINGS={has_rings}", res_dump.stdout)

    def test_32_multidevice_fan_control(self):
        """Verify active fan management on fan-equipped devices and clean no-op on passive devices."""
        hw_bin = f"{REPO_ROOT}/System/bin/next-hw"
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Passive device behavior (e.g. tsp or brick)
            env_passive = os.environ.copy()
            env_passive["LUMEN_DEVICE_OVERRIDE"] = "tsp"
            env_passive["STATE_DIR"] = os.path.join(tmpdir, "passive_state")
            os.makedirs(env_passive["STATE_DIR"], exist_ok=True)

            res = subprocess.run([hw_bin, "fan", "--get-fan"], env=env_passive, capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            self.assertIn("PROFILE=passive PWM=0", res.stdout)

            # Profile changes on passive device return 0 gracefully
            res_quiet = subprocess.run([hw_bin, "fan", "--profile", "quiet"], env=env_passive, capture_output=True, text=True)
            self.assertEqual(res_quiet.returncode, 0)

            # 2. Active cooling device behavior (tsp-s)
            env_active = os.environ.copy()
            env_active["LUMEN_DEVICE_OVERRIDE"] = "tsp-s"
            env_active["STATE_DIR"] = os.path.join(tmpdir, "active_state")
            os.makedirs(env_active["STATE_DIR"], exist_ok=True)

            # Test quiet profile (sets PWM 64)
            subprocess.run([hw_bin, "fan", "--profile", "quiet"], env=env_active, check=True)
            res_fan = subprocess.run([hw_bin, "fan", "--get-fan"], env=env_active, capture_output=True, text=True)
            self.assertIn("PROFILE=quiet", res_fan.stdout)
            self.assertIn("PWM=64", res_fan.stdout)

            # Test balanced profile (sets PWM 128)
            subprocess.run([hw_bin, "fan", "--profile", "balanced"], env=env_active, check=True)
            res_fan = subprocess.run([hw_bin, "fan", "--get-fan"], env=env_active, capture_output=True, text=True)
            self.assertIn("PROFILE=balanced", res_fan.stdout)
            self.assertIn("PWM=128", res_fan.stdout)

            # Test performance profile (sets PWM 200)
            subprocess.run([hw_bin, "fan", "--profile", "performance"], env=env_active, check=True)
            res_fan = subprocess.run([hw_bin, "fan", "--get-fan"], env=env_active, capture_output=True, text=True)
            self.assertIn("PROFILE=performance", res_fan.stdout)
            self.assertIn("PWM=200", res_fan.stdout)

            # Test max profile (sets PWM 255)
            subprocess.run([hw_bin, "fan", "--profile", "max"], env=env_active, check=True)
            res_fan = subprocess.run([hw_bin, "fan", "--get-fan"], env=env_active, capture_output=True, text=True)
            self.assertIn("PROFILE=max", res_fan.stdout)
            self.assertIn("PWM=255", res_fan.stdout)

            # Test manual PWM set
            subprocess.run([hw_bin, "fan", "--set", "180"], env=env_active, check=True)
            res_fan = subprocess.run([hw_bin, "fan", "--get-fan"], env=env_active, capture_output=True, text=True)
            self.assertIn("PWM=180", res_fan.stdout)

    def test_33_multidevice_led_routing(self):
        """Verify polymorphic LED routing for stick rings (TSP/TSP-S) vs ambient bar (Brick)."""
        hw_bin = f"{REPO_ROOT}/System/bin/next-hw"
        with tempfile.TemporaryDirectory() as tmpdir:
            mock_sysfs = os.path.join(tmpdir, "sys/class/led_anim")
            os.makedirs(mock_sysfs, exist_ok=True)

            # Create mock sysfs files for TSP (stick rings)
            for f in ["effect_enable", "effect_rgb_hex_lr", "max_scale_lr"]:
                with open(os.path.join(mock_sysfs, f), "w") as fp:
                    fp.write("0\n")

            with open(hw_bin) as f:
                content = f.read()

            patched = content.replace(
                'LED_SYSFS="/sys/class/led_anim"', f'LED_SYSFS="{mock_sysfs}"'
            )
            test_hw = os.path.join(tmpdir, "next-hw-led")
            with open(test_hw, "w") as f:
                f.write(patched)
            os.chmod(test_hw, 0o755)

            env = os.environ.copy()
            env["STATE_DIR"] = os.path.join(tmpdir, "state")
            os.makedirs(env["STATE_DIR"], exist_ok=True)

            # Test TSP routing
            env["LUMEN_DEVICE_OVERRIDE"] = "tsp"
            subprocess.run([test_hw, "led", "--hex", "003366", "--brightness", "80"], env=env, check=True)
            with open(os.path.join(mock_sysfs, "effect_rgb_hex_lr")) as fp:
                self.assertEqual(fp.read().strip(), "003366")
            with open(os.path.join(mock_sysfs, "max_scale_lr")) as fp:
                # 80 * 60 / 100 = 48
                self.assertEqual(fp.read().strip(), "48")

            # Remove ring node, create Brick ambient bar node
            os.remove(os.path.join(mock_sysfs, "effect_rgb_hex_lr"))
            with open(os.path.join(mock_sysfs, "effect_rgb_hex_m"), "w") as fp:
                fp.write("0\n")
            with open(os.path.join(mock_sysfs, "max_scale_f1f2"), "w") as fp:
                fp.write("0\n")

            # Test Brick routing
            env["LUMEN_DEVICE_OVERRIDE"] = "brick"
            subprocess.run([test_hw, "led", "--hex", "FF5500", "--brightness", "50"], env=env, check=True)
            with open(os.path.join(mock_sysfs, "effect_rgb_hex_m")) as fp:
                self.assertEqual(fp.read().strip(), "FF5500")
            with open(os.path.join(mock_sysfs, "max_scale_f1f2")) as fp:
                # 50 * 60 / 100 = 30
                self.assertEqual(fp.read().strip(), "30")

    def test_34_fandaemon_lifecycle(self):
        """Verify active cooling daemon syntax, Schmitt trigger curve, and passive exit."""
        daemon_script = f"{REPO_ROOT}/System/init.d/S17_fandaemon.sh"
        hwdetect_script = f"{REPO_ROOT}/System/init.d/S01_hwdetect.sh"

        self.assertTrue(os.path.isfile(daemon_script) and os.access(daemon_script, os.X_OK))
        self.assertTrue(os.path.isfile(hwdetect_script) and os.access(hwdetect_script, os.X_OK))

        # Check POSIX sh syntax
        res = subprocess.run(["sh", "-n", daemon_script], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Syntax error in S17_fandaemon.sh: {res.stderr}")

        res = subprocess.run(["sh", "-n", hwdetect_script], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Syntax error in S01_hwdetect.sh: {res.stderr}")

        with open(daemon_script) as f:
            t = f.read()
            self.assertIn("HAS_FAN", t)
            self.assertIn("TARGET_PWM", t)
            self.assertIn("quiet", t)
            self.assertIn("performance", t)
            self.assertIn("max", t)
            # Schmitt trigger / hysteresis dwell check
            self.assertIn("ELAPSED=$(( NOW - LAST_DOWN_TIME ))", t)
            # Emergency ceiling override (>75C -> 255)
            self.assertIn("255", t)

if __name__ == "__main__":
    unittest.main()
