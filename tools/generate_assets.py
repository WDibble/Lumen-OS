#!/usr/bin/env python3
"""
Lumen-OS Lumen Asset Generator
Governed by:
  - craft-philosophy (concentric radii, quiet chrome, luminance elevation)
  - tweakcn-theming (OKLCH dark-mode contrast, semantic color tokens)
  - motion-physics (acoustic decay modeling for tactile sound)
  - trimui-theme-spec (exact geometry contracts, 24-bit RGB bg, 32-bit RGBA UI)
"""

import math
import os
import struct
import wave
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME_DIR = os.path.join(REPO_ROOT, "Themes", "Lumen")
SKIN_DIR = os.path.join(THEME_DIR, "skin")
SOUND_DIR = os.path.join(THEME_DIR, "sound")

os.makedirs(SKIN_DIR, exist_ok=True)
os.makedirs(SOUND_DIR, exist_ok=True)

# ----------------------------------------------------------------------
# 0. FONT HELPER (Robust macOS & bundled fallback loader)
# ----------------------------------------------------------------------
def get_font(size):
    font_candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/SFCompact.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        os.path.join(THEME_DIR, "wqy-microhei.ttf"),
        "/Library/Fonts/Arial Bold.ttf",
    ]
    for fp in font_candidates:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except Exception:
                continue
    return ImageFont.load_default()

# ----------------------------------------------------------------------
# 1. TACTILE AUDIO SYNTHESIS (motion-physics / WWDC fluid interface laws)
# ----------------------------------------------------------------------
def generate_tactile_click():
    wav_path = os.path.join(SOUND_DIR, "click.wav")
    sample_rate = 44100
    duration_s = 0.024  # 24 milliseconds acoustic transient
    f0 = 580.0         # 580 Hz warm tactile fundamental
    tau = 0.0055        # 5.5 ms exponential acoustic decay

    num_samples = int(sample_rate * duration_s)
    attack_samples = int(sample_rate * 0.0015)  # 1.5ms attack ramp
    taper_samples = int(sample_rate * 0.0030)   # 3.0ms Hann taper to zero
    samples = []

    for i in range(num_samples):
        t = i / sample_rate
        if i < attack_samples:
            attack = 0.5 * (1.0 - math.cos(math.pi * i / attack_samples))
        else:
            attack = 1.0

        decay = math.exp(-t / tau)

        if i >= num_samples - taper_samples:
            taper = 0.5 * (1.0 + math.cos(math.pi * (i - (num_samples - taper_samples)) / (taper_samples - 1)))
        else:
            taper = 1.0

        envelope = attack * decay * taper
        signal = 0.82 * math.sin(2.0 * math.pi * f0 * t) + 0.18 * math.sin(2.0 * math.pi * (f0 * 2.0) * t)
        val = signal * envelope
        int_val = int(val * 28000.0)
        int_val = max(-32767, min(32767, int_val))
        samples.append(int_val)

    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(1)       # Mono
        wf.setsampwidth(2)       # 16-bit
        wf.setframerate(sample_rate)
        raw_data = struct.pack(f"<{len(samples)}h", *samples)
        wf.writeframes(raw_data)

    print(f"Synthesized tactile audio click: {wav_path} ({len(samples)} samples, 24ms, zero DC step)")

# ----------------------------------------------------------------------
# 2. HELPER: SUPER-SAMPLED DRAWING (4x supersampling for razor edges)
# ----------------------------------------------------------------------
def create_supersampled(width, height, scale=4):
    sw, sh = width * scale, height * scale
    canvas = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    return canvas, ImageDraw.Draw(canvas), scale

def finalize_supersampled(canvas, target_size):
    return canvas.resize(target_size, Image.Resampling.LANCZOS)

# ----------------------------------------------------------------------
# 3. BACKGROUNDS (1280x720, 24-bit RGB, NO alpha channel, pure obsidian)
# ----------------------------------------------------------------------
def generate_backgrounds():
    w, h = 1280, 720
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    c_top = (9, 13, 20)    # #090D14
    c_bot = (14, 19, 29)   # #0E131D
    for y in range(h):
        ratio = y / (h - 1)
        r = int(c_top[0] + (c_bot[0] - c_top[0]) * ratio)
        g = int(c_top[1] + (c_bot[1] - c_top[1]) * ratio)
        b = int(c_top[2] + (c_bot[2] - c_top[2]) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # Save to both Themes/Lumen/bg.png and Themes/Lumen/skin/bg.png
    root_bg = os.path.join(THEME_DIR, "bg.png")
    skin_bg = os.path.join(SKIN_DIR, "bg.png")
    img.save(root_bg, "PNG", optimize=True)
    img.save(skin_bg, "PNG", optimize=True)
    print(f"Generated 24-bit RGB background: {root_bg} and {skin_bg}")

# ----------------------------------------------------------------------
# 4. NAVIGATION BRANDING (nav-logo.png: 218x40 RGBA)
# ----------------------------------------------------------------------
def generate_nav_logo():
    w, h = 218, 40
    canvas, draw, S = create_supersampled(w, h, scale=4)
    # Electric Cyan pill accent on left
    draw.rounded_rectangle([12 * S, 11 * S, 16 * S, 29 * S], radius=2 * S, fill=(56, 189, 248, 255))
    
    # Titanium white (#F8FAFC) wide-tracked text 'L U M E N'
    font = get_font(15 * S)
    letters = ["L", "U", "M", "E", "N"]
    letter_spacing = 26 * S
    start_x = 36 * S
    y_pos = 20 * S
    for i, char in enumerate(letters):
        draw.text((start_x + i * letter_spacing, y_pos), char, fill=(248, 250, 252, 255), font=font, anchor="mm")

    out = finalize_supersampled(canvas, (w, h))
    logo_path = os.path.join(SKIN_DIR, "nav-logo.png")
    out.save(logo_path, "PNG", optimize=True)
    print(f"Generated brand nav logo: {logo_path}")

# ----------------------------------------------------------------------
# 5. BUTTON TIPS (40x40 circle/pill with clean typography)
# ----------------------------------------------------------------------
def generate_button_tips():
    tips = [
        ("tips-A.png", "A", (239, 68, 68)),        # Red / Ruby accent
        ("tips-B.png", "B", (245, 158, 11)),       # Amber / Yellow accent
        ("tips-X.png", "X", (59, 130, 246)),       # Blue accent
        ("tips-Y.png", "Y", (34, 197, 94)),        # Green accent
        ("tips-MENU.png", "M", (56, 189, 248)),    # Cyan accent
        ("tips-START.png", "ST", (148, 163, 184)), # Muted silver
        ("tips-SELECT.png", "SE", (148, 163, 184)),# Muted silver
        ("tips-L.png", "L", (148, 163, 184)),
        ("tips-R.png", "R", (148, 163, 184)),
        ("tips-L2.png", "L2", (148, 163, 184)),
        ("tips-R2.png", "R2", (148, 163, 184)),
    ]

    for fname, label, accent in tips:
        canvas, draw, S = create_supersampled(40, 40)
        draw.ellipse([2*S, 2*S, 38*S, 38*S], fill=(22, 29, 43, 230), outline=(56, 189, 248, 120), width=1*S)
        draw.ellipse([3*S, 3*S, 37*S, 37*S], outline=(255, 255, 255, 25), width=1*S)
        
        font_size = 19 * S if len(label) == 1 else 11 * S
        font = get_font(font_size)

        y_target = 81.5 if len(label) == 1 else 81.0
        draw.text((20 * S, y_target), label, fill=(248, 250, 252, 255), font=font, anchor="mm")

        out = finalize_supersampled(canvas, (40, 40))
        out.save(os.path.join(SKIN_DIR, fname), "PNG", optimize=True)

        if fname.startswith("tips-"):
            alias = fname.replace("tips-", "button-tips-")
            out.save(os.path.join(SKIN_DIR, alias), "PNG", optimize=True)

    print("Generated modern button badges.")

# ----------------------------------------------------------------------
# 6. BATTERY GAUGES (40x40 modern pill cells)
# ----------------------------------------------------------------------
def generate_battery_gauges():
    levels = [
        ("ic-batery-0%.png", 0, (239, 68, 68)),
        ("ic-batery-25%.png", 25, (245, 158, 11)),
        ("ic-batery-50%.png", 50, (56, 189, 248)),
        ("ic-batery-75%.png", 75, (56, 189, 248)),
        ("ic-batery-100%.png", 100, (34, 197, 94))
    ]

    for fname, pct, fill_color in levels:
        canvas, draw, S = create_supersampled(40, 40)
        bx0, by0, bx1, by1 = 8*S, 13*S, 30*S, 27*S
        radius = 3 * S
        draw.rounded_rectangle([bx0, by0, bx1, by1], radius=radius, outline=(148, 163, 184, 200), width=1*S)
        draw.rounded_rectangle([30*S, 17*S, 32*S, 23*S], radius=1*S, fill=(148, 163, 184, 200))
        
        if pct > 0:
            margin = 2 * S
            max_fill_w = (bx1 - bx0) - (margin * 2)
            cur_fill_w = int(max_fill_w * (pct / 100.0))
            if cur_fill_w > 0:
                fx0 = bx0 + margin
                fy0 = by0 + margin
                fx1 = fx0 + cur_fill_w
                fy1 = by1 - margin
                draw.rounded_rectangle([fx0, fy0, fx1, fy1], radius=1*S, fill=fill_color)

        out = finalize_supersampled(canvas, (40, 40))
        out.save(os.path.join(SKIN_DIR, fname), "PNG", optimize=True)

    canvas, draw, S = create_supersampled(24, 34)
    bolt_pts = [
        (13*S, 4*S),
        (6*S, 18*S),
        (12*S, 18*S),
        (10*S, 30*S),
        (18*S, 14*S),
        (12*S, 14*S),
    ]
    draw.polygon(bolt_pts, fill=(56, 189, 248, 255))
    out = finalize_supersampled(canvas, (24, 34))
    out.save(os.path.join(SKIN_DIR, "ic-charging.png"), "PNG", optimize=True)
    print("Generated modern battery icons.")

# ----------------------------------------------------------------------
# 7. WI-FI & CONNECTIVITY GLYPHS
# ----------------------------------------------------------------------
def generate_wifi_glyphs():
    for i in range(1, 6):
        canvas, draw, S = create_supersampled(40, 40)
        cx, cy = 20 * S, 28 * S
        for arc_idx in range(4):
            r = (arc_idx + 1) * 4 * S
            bbox = [cx - r, cy - r, cx + r, cy + r]
            alpha = 255 if arc_idx < (i - 1) else 60
            color = (56, 189, 248, alpha) if arc_idx < (i - 1) else (148, 163, 184, 60)
            draw.arc(bbox, start=225, end=315, fill=color, width=2*S)
        dot_color = (56, 189, 248, 255) if i > 1 else (148, 163, 184, 60)
        draw.ellipse([cx - 2*S, cy - 2*S, cx + 2*S, cy + 2*S], fill=dot_color)

        out = finalize_supersampled(canvas, (40, 40))
        fname = f"ic-wifi-0{i}.png"
        out.save(os.path.join(SKIN_DIR, fname), "PNG", optimize=True)
        if i == 5:
            out.save(os.path.join(SKIN_DIR, "ic-wifi.png"), "PNG", optimize=True)
            out.save(os.path.join(SKIN_DIR, "wifi-connected.png"), "PNG", optimize=True)
        elif i == 1:
            out.save(os.path.join(SKIN_DIR, "ic-wifi-n.png"), "PNG", optimize=True)

    print("Generated modern Wi-Fi glyphs.")

# ----------------------------------------------------------------------
# 8. SWITCHES & CHECKBOXES
# ----------------------------------------------------------------------
def generate_switches():
    canvas, draw, S = create_supersampled(80, 40)
    draw.rounded_rectangle([4*S, 4*S, 76*S, 36*S], radius=16*S, fill=(2, 132, 199, 255))
    draw.ellipse([46*S, 6*S, 74*S, 34*S], fill=(255, 255, 255, 255))
    out = finalize_supersampled(canvas, (80, 40))
    out.save(os.path.join(SKIN_DIR, "sw-on.png"), "PNG", optimize=True)

    canvas, draw, S = create_supersampled(80, 40)
    draw.rounded_rectangle([4*S, 4*S, 76*S, 36*S], radius=16*S, fill=(30, 41, 59, 255), outline=(51, 65, 85, 255), width=1*S)
    draw.ellipse([6*S, 6*S, 34*S, 34*S], fill=(148, 163, 184, 255))
    out = finalize_supersampled(canvas, (80, 40))
    out.save(os.path.join(SKIN_DIR, "sw-off.png"), "PNG", optimize=True)

    canvas, draw, S = create_supersampled(60, 60)
    draw.rounded_rectangle([10*S, 10*S, 50*S, 50*S], radius=8*S, fill=(56, 189, 248, 255))
    check_pts = [(18*S, 30*S), (26*S, 38*S), (42*S, 20*S)]
    draw.line(check_pts, fill=(13, 17, 23, 255), width=4*S, joint="curve")
    out = finalize_supersampled(canvas, (60, 60))
    out.save(os.path.join(SKIN_DIR, "checkbox-checked.png"), "PNG", optimize=True)

    canvas, draw, S = create_supersampled(60, 60)
    draw.rounded_rectangle([10*S, 10*S, 50*S, 50*S], radius=8*S, fill=(22, 29, 43, 180), outline=(71, 85, 105, 200), width=2*S)
    out = finalize_supersampled(canvas, (60, 60))
    out.save(os.path.join(SKIN_DIR, "checkbox-uncheck.png"), "PNG", optimize=True)
    print("Generated modern switch and checkbox controls.")

# ----------------------------------------------------------------------
# 9. CONCENTRIC SELECTION CARDS, BUTTONS & NAV TABS
# ----------------------------------------------------------------------
def generate_cards_and_selectors():
    # Grid item focused: 305x280
    w, h = 305, 280
    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([4*S, 4*S, (w-4)*S, (h-4)*S], radius=16*S, fill=(30, 38, 56, 230), outline=(56, 189, 248, 240), width=2*S)
    draw.line([(18*S, 6*S), ((w-18)*S, 6*S)], fill=(255, 255, 255, 31), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "grid-item-bg-f.png"), "PNG", optimize=True)

    # Grid item normal: 295x270
    w, h = 295, 270
    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([4*S, 4*S, (w-4)*S, (h-4)*S], radius=14*S, fill=(19, 25, 35, 160), outline=(30, 41, 59, 140), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "grid-item-bg-n.png"), "PNG", optimize=True)

    # Button bg: exactly 300x60 for both normal and focused states
    w, h = 300, 60
    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=10*S, fill=(56, 189, 248, 230), outline=(255, 255, 255, 80), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "btn-bg-f.png"), "PNG", optimize=True)

    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=10*S, fill=(30, 41, 59, 180), outline=(51, 65, 85, 160), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "btn-bg-n.png"), "PNG", optimize=True)

    # Main nav selector tabs
    # Left: 31x70
    canvas, draw, S = create_supersampled(31, 70)
    draw.rounded_rectangle([2*S, 6*S, 40*S, 68*S], radius=12*S, fill=(30, 38, 56, 240), outline=(56, 189, 248, 200), width=1*S)
    out = finalize_supersampled(canvas, (31, 70))
    out.save(os.path.join(SKIN_DIR, "main-nav-sel-left.png"), "PNG", optimize=True)

    # Mid: 4x70
    canvas, draw, S = create_supersampled(4, 70)
    draw.rectangle([0, 6*S, 4*S, 68*S], fill=(30, 38, 56, 240))
    draw.line([(0, 6*S), (4*S, 6*S)], fill=(56, 189, 248, 200), width=1*S)
    draw.line([(0, 68*S), (4*S, 68*S)], fill=(56, 189, 248, 200), width=1*S)
    out = finalize_supersampled(canvas, (4, 70))
    out.save(os.path.join(SKIN_DIR, "main-nav-sel-mid.png"), "PNG", optimize=True)

    # Right: 31x70
    canvas, draw, S = create_supersampled(31, 70)
    draw.rounded_rectangle([-10*S, 6*S, 29*S, 68*S], radius=12*S, fill=(30, 38, 56, 240), outline=(56, 189, 248, 200), width=1*S)
    out = finalize_supersampled(canvas, (31, 70))
    out.save(os.path.join(SKIN_DIR, "main-nav-sel-right.png"), "PNG", optimize=True)

    print("Generated modern concentric cards and navigation selectors.")

# ----------------------------------------------------------------------
# 10. LIST ROWS & PARITY ASSETS (Exact dimensional parity)
# ----------------------------------------------------------------------
def generate_list_rows():
    specs = [
        ("list-item-2line-long-bg", 1260, 110, 14),
        ("list-item-2line-short-bg", 680, 110, 14),
        ("list-item-1line-sort-bg", 840, 90, 12),
        ("bg-list-long", 1260, 90, 12),
        ("list-item-2line-bg", 840, 110, 12),
    ]

    for base_name, w, h, rad in specs:
        # Focused state (-f or -a)
        canvas_f, draw_f, S = create_supersampled(w, h, scale=4)
        draw_f.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=rad*S, fill=(30, 41, 59, 235), outline=(56, 189, 248, 240), width=2*S)
        draw_f.line([( (rad + 4)*S, 5*S ), ( (w - rad - 4)*S, 5*S )], fill=(255, 255, 255, 35), width=1*S)
        out_f = finalize_supersampled(canvas_f, (w, h))

        # Normal state (-n)
        canvas_n, draw_n, S = create_supersampled(w, h, scale=4)
        draw_n.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=rad*S, fill=(19, 25, 35, 160), outline=(51, 65, 85, 120), width=1*S)
        out_n = finalize_supersampled(canvas_n, (w, h))

        if base_name == "bg-list-long":
            out_f.save(os.path.join(SKIN_DIR, "bg-list-long-a.png"), "PNG", optimize=True)
            out_n.save(os.path.join(SKIN_DIR, "bg-list-long-n.png"), "PNG", optimize=True)
        else:
            out_f.save(os.path.join(SKIN_DIR, f"{base_name}-f.png"), "PNG", optimize=True)
            out_n.save(os.path.join(SKIN_DIR, f"{base_name}-n.png"), "PNG", optimize=True)

    print("Generated list row assets with full dimensional parity.")

# ----------------------------------------------------------------------
# 11. MENUS & DIALOGS (Full MainUI asset suite)
# ----------------------------------------------------------------------
def generate_menus_and_dialogs():
    # 1. bg-menu-01.png through bg-menu-09.png
    heights = [64, 124, 184, 244, 304, 364, 424, 484, 544]
    for idx, h in enumerate(heights, 1):
        w = 604
        canvas, draw, S = create_supersampled(w, h, scale=4)
        draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=14*S, fill=(15, 20, 30, 245), outline=(71, 85, 105, 140), width=int(1.5*S))
        draw.line([(18*S, 5*S), ((w-18)*S, 5*S)], fill=(255, 255, 255, 35), width=1*S)
        out = finalize_supersampled(canvas, (w, h))
        out.save(os.path.join(SKIN_DIR, f"bg-menu-{idx:02d}.png"), "PNG", optimize=True)

    # 2. menu-list-sel.png: 560 x 60
    w, h = 560, 60
    canvas, draw, S = create_supersampled(w, h, scale=4)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=10*S, fill=(32, 45, 66, 240), outline=(56, 189, 248, 240), width=2*S)
    draw.line([(14*S, 5*S), ((w-14)*S, 5*S)], fill=(255, 255, 255, 35), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "menu-list-sel.png"), "PNG", optimize=True)

    # 3. bg-menu-item.png: 560 x 60
    canvas, draw, S = create_supersampled(w, h, scale=4)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=10*S, fill=(19, 25, 35, 160), outline=(51, 65, 85, 120), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "bg-menu-item.png"), "PNG", optimize=True)

    # 4. pop-bg.png: 904 x 544
    w, h = 904, 544
    canvas, draw, S = create_supersampled(w, h, scale=4)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=16*S, fill=(15, 20, 30, 245), outline=(71, 85, 105, 140), width=int(1.5*S))
    draw.line([(20*S, 5*S), ((w-20)*S, 5*S)], fill=(255, 255, 255, 35), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "pop-bg.png"), "PNG", optimize=True)

    # 5. bg-setting-textfield.png: 500 x 60
    w, h = 500, 60
    canvas, draw, S = create_supersampled(w, h, scale=4)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=10*S, fill=(9, 13, 20, 235), outline=(51, 65, 85, 180), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "bg-setting-textfield.png"), "PNG", optimize=True)

    # 6. preview.png: 640 x 360 preview card
    w, h = 640, 360
    canvas = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(canvas)
    c_top = (9, 13, 20)
    c_bot = (14, 19, 29)
    for y in range(h):
        ratio = y / (h - 1)
        r = int(c_top[0] + (c_bot[0] - c_top[0]) * ratio)
        g = int(c_top[1] + (c_bot[1] - c_top[1]) * ratio)
        b = int(c_top[2] + (c_bot[2] - c_top[2]) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    draw.rectangle([(0, 0), (w, 35)], fill=(13, 17, 23))
    draw.line([(0, 35), (w, 35)], fill=(51, 65, 85))
    draw.rounded_rectangle([(16, 12), (18, 24)], radius=1, fill=(56, 189, 248))

    font_mini = get_font(12)
    draw.text((26, 18), "L U M E N", fill=(248, 250, 252), font=font_mini, anchor="lm")

    draw.rounded_rectangle([(30, 60), (280, 310)], radius=8, fill=(30, 41, 59), outline=(56, 189, 248), width=2)
    draw.line([(40, 62), (270, 62)], fill=(255, 255, 255), width=1)
    draw.text((155, 180), "LUMEN OS", fill=(248, 250, 252), font=get_font(16), anchor="mm")
    draw.text((155, 210), "720p Obsidian Experience", fill=(148, 163, 184), font=get_font(10), anchor="mm")

    for i in range(3):
        ly = 70 + i * 75
        fill_col = (30, 41, 59) if i == 0 else (19, 25, 35)
        border_col = (56, 189, 248) if i == 0 else (51, 65, 85)
        draw.rounded_rectangle([(310, ly), (610, ly + 55)], radius=6, fill=fill_col, outline=border_col, width=1 if i > 0 else 2)
        draw.text((330, ly + 28), f"Console Platform {i+1}", fill=(248, 250, 252) if i == 0 else (148, 163, 184), font=get_font(11), anchor="lm")

    canvas.save(os.path.join(THEME_DIR, "preview.png"), "PNG", optimize=True)
    print("Generated menus, popups, textfields, and preview card.")

# ----------------------------------------------------------------------
# MAIN EXECUTION
# ----------------------------------------------------------------------
if __name__ == "__main__":
    print("=== Generating Full Lumen Design Assets ===")
    generate_tactile_click()
    generate_backgrounds()
    generate_nav_logo()
    generate_button_tips()
    generate_battery_gauges()
    generate_wifi_glyphs()
    generate_switches()
    generate_cards_and_selectors()
    generate_list_rows()
    generate_menus_and_dialogs()
    print("=== All Lumen design assets generated successfully! ===")
