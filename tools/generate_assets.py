#!/usr/bin/env python3
"""
Lumen-OS Lumen Asset Generator
Governed by:
  - craft-philosophy (concentric radii, quiet chrome, luminance elevation)
  - tweakcn-theming (OKLCH dark-mode contrast, semantic color tokens)
  - motion-physics (acoustic decay modeling for tactile sound)
"""

import math
import os
import struct
import wave
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SKIN_DIR = "/Users/dibble/Documents/GitHub/lumen-os/Themes/Lumen/skin"
SOUND_DIR = "/Users/dibble/Documents/GitHub/lumen-os/Themes/Lumen/sound"
os.makedirs(SKIN_DIR, exist_ok=True)
os.makedirs(SOUND_DIR, exist_ok=True)

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
        # 1.5ms attack envelope
        if i < attack_samples:
            attack = 0.5 * (1.0 - math.cos(math.pi * i / attack_samples))
        else:
            attack = 1.0

        # Natural acoustic exponential decay
        decay = math.exp(-t / tau)

        # Hann end-tapering to guaranteed exact zero (prevents DC step pop)
        if i >= num_samples - taper_samples:
            taper = 0.5 * (1.0 + math.cos(math.pi * (i - (num_samples - taper_samples)) / (taper_samples - 1)))
        else:
            taper = 1.0

        envelope = attack * decay * taper
        signal = 0.82 * math.sin(2.0 * math.pi * f0 * t) + 0.18 * math.sin(2.0 * math.pi * (f0 * 2.0) * t)
        val = signal * envelope
        # 16-bit integer scaling (-32768 to 32767)
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
# 3. BUTTON TIPS (40x40 circle/pill with clean typography)
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
        # Background disk
        draw.ellipse([2*S, 2*S, 38*S, 38*S], fill=(22, 29, 43, 230), outline=(56, 189, 248, 120), width=1*S)
        # Inner highlight ring
        draw.ellipse([3*S, 3*S, 37*S, 37*S], outline=(255, 255, 255, 25), width=1*S)
        
        # Load bold modern font with fallback
        font_path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
        if not os.path.exists(font_path):
            font_path = "/System/Library/Fonts/SFCompact.ttf"
        if not os.path.exists(font_path):
            font_path = "/System/Library/Fonts/Helvetica.ttc"

        font_size = 19 * S if len(label) == 1 else 11 * S
        try:
            font = ImageFont.truetype(font_path, font_size)
        except Exception:
            font = ImageFont.load_default()

        # Center vertically and horizontally using anchor="mm" with optical adjustment
        y_target = 81.5 if len(label) == 1 else 81.0
        draw.text((20 * S, y_target), label, fill=(248, 250, 252, 255), font=font, anchor="mm")

        out = finalize_supersampled(canvas, (40, 40))
        out.save(os.path.join(SKIN_DIR, fname), "PNG", optimize=True)

        # Also save button-tips-* aliases
        if fname.startswith("tips-"):
            alias = fname.replace("tips-", "button-tips-")
            out.save(os.path.join(SKIN_DIR, alias), "PNG", optimize=True)

    print("Generated modern button badges.")


# ----------------------------------------------------------------------
# 4. BATTERY GAUGES (40x40 modern pill cells)
# ----------------------------------------------------------------------
def generate_battery_gauges():
    levels = [
        ("ic-batery-0%.png", 0, (239, 68, 68)),    # Critical red
        ("ic-batery-25%.png", 25, (245, 158, 11)), # Warning amber
        ("ic-batery-50%.png", 50, (56, 189, 248)), # Cyan normal
        ("ic-batery-75%.png", 75, (56, 189, 248)),
        ("ic-batery-100%.png", 100, (34, 197, 94)) # Full emerald
    ]

    for fname, pct, fill_color in levels:
        canvas, draw, S = create_supersampled(40, 40)
        # Battery outer casing (x: 8 to 30, y: 14 to 26)
        bx0, by0, bx1, by1 = 8*S, 13*S, 30*S, 27*S
        radius = 3 * S
        draw.rounded_rectangle([bx0, by0, bx1, by1], radius=radius, outline=(148, 163, 184, 200), width=1*S)
        # Terminal nub
        draw.rounded_rectangle([30*S, 17*S, 32*S, 23*S], radius=1*S, fill=(148, 163, 184, 200))
        
        # Interior fill
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

    # Charging indicator
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
# 5. WI-FI & CONNECTIVITY GLYPHS
# ----------------------------------------------------------------------
def generate_wifi_glyphs():
    for i in range(1, 6):
        canvas, draw, S = create_supersampled(40, 40)
        cx, cy = 20 * S, 28 * S
        # Draw arcs
        for arc_idx in range(4):
            r = (arc_idx + 1) * 4 * S
            bbox = [cx - r, cy - r, cx + r, cy + r]
            alpha = 255 if arc_idx < (i - 1) else 60
            color = (56, 189, 248, alpha) if arc_idx < (i - 1) else (148, 163, 184, 60)
            draw.arc(bbox, start=225, end=315, fill=color, width=2*S)
        # Center dot
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
# 6. SWITCHES & CHECKBOXES (craft-philosophy: tactile rounded toggles)
# ----------------------------------------------------------------------
def generate_switches():
    # sw-on.png: 80x40 active pill
    canvas, draw, S = create_supersampled(80, 40)
    # Track: Cyan filled (#0284C7)
    draw.rounded_rectangle([4*S, 4*S, 76*S, 36*S], radius=16*S, fill=(2, 132, 199, 255))
    # Thumb: White sphere on right
    draw.ellipse([46*S, 6*S, 74*S, 34*S], fill=(255, 255, 255, 255))
    out = finalize_supersampled(canvas, (80, 40))
    out.save(os.path.join(SKIN_DIR, "sw-on.png"), "PNG", optimize=True)

    # sw-off.png: 80x40 inactive pill
    canvas, draw, S = create_supersampled(80, 40)
    # Track: Dark slate (#1E293B)
    draw.rounded_rectangle([4*S, 4*S, 76*S, 36*S], radius=16*S, fill=(30, 41, 59, 255), outline=(51, 65, 85, 255), width=1*S)
    # Thumb: Muted silver on left
    draw.ellipse([6*S, 6*S, 34*S, 34*S], fill=(148, 163, 184, 255))
    out = finalize_supersampled(canvas, (80, 40))
    out.save(os.path.join(SKIN_DIR, "sw-off.png"), "PNG", optimize=True)

    # Checkboxes: 60x60
    # checked
    canvas, draw, S = create_supersampled(60, 60)
    draw.rounded_rectangle([10*S, 10*S, 50*S, 50*S], radius=8*S, fill=(56, 189, 248, 255))
    check_pts = [(18*S, 30*S), (26*S, 38*S), (42*S, 20*S)]
    draw.line(check_pts, fill=(13, 17, 23, 255), width=4*S, joint="curve")
    out = finalize_supersampled(canvas, (60, 60))
    out.save(os.path.join(SKIN_DIR, "checkbox-checked.png"), "PNG", optimize=True)

    # unchecked
    canvas, draw, S = create_supersampled(60, 60)
    draw.rounded_rectangle([10*S, 10*S, 50*S, 50*S], radius=8*S, fill=(22, 29, 43, 180), outline=(71, 85, 105, 200), width=2*S)
    out = finalize_supersampled(canvas, (60, 60))
    out.save(os.path.join(SKIN_DIR, "checkbox-uncheck.png"), "PNG", optimize=True)
    print("Generated modern switch and checkbox controls.")


# ----------------------------------------------------------------------
# 7. CONCENTRIC SELECTION CARDS & BUTTONS (craft-philosophy)
# ----------------------------------------------------------------------
def generate_cards_and_selectors():
    # Grid item focused: 305x280
    w, h = 305, 280
    canvas, draw, S = create_supersampled(w, h)
    # Concentric radius: R_outer = 16
    draw.rounded_rectangle([4*S, 4*S, (w-4)*S, (h-4)*S], radius=16*S, fill=(30, 38, 56, 230), outline=(56, 189, 248, 240), width=2*S)
    # Physical directional top specular rim (inset 0 1px 0 rgba(255, 255, 255, 0.12))
    draw.line([(18*S, 6*S), ((w-18)*S, 6*S)], fill=(255, 255, 255, 31), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "grid-item-bg-f.png"), "PNG", optimize=True)

    # Grid item normal: 295x270
    w, h = 295, 270
    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([4*S, 4*S, (w-4)*S, (h-4)*S], radius=14*S, fill=(19, 25, 35, 160), outline=(30, 41, 59, 140), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "grid-item-bg-n.png"), "PNG", optimize=True)

    # List items: 840x110
    w, h = 840, 110
    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([4*S, 4*S, (w-4)*S, (h-4)*S], radius=12*S, fill=(30, 38, 56, 230), outline=(56, 189, 248, 230), width=2*S)
    # Physical directional top specular rim
    draw.line([(16*S, 6*S), ((w-16)*S, 6*S)], fill=(255, 255, 255, 31), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "list-item-2line-bg-f.png"), "PNG", optimize=True)

    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([4*S, 4*S, (w-4)*S, (h-4)*S], radius=12*S, fill=(19, 25, 35, 120), outline=(30, 41, 59, 100), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "list-item-2line-bg-n.png"), "PNG", optimize=True)

    # Button bg: exactly 300x60 for both normal and focused states
    w, h = 300, 60
    canvas, draw, S = create_supersampled(w, h)
    draw.rounded_rectangle([2*S, 2*S, (w-2)*S, (h-2)*S], radius=10*S, fill=(56, 189, 248, 230), outline=(255, 255, 255, 80), width=1*S)
    out = finalize_supersampled(canvas, (w, h))
    out.save(os.path.join(SKIN_DIR, "btn-bg-f.png"), "PNG", optimize=True)

    w, h = 300, 60
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


if __name__ == "__main__":
    print("=== Generating Lumen Design Assets ===")
    generate_tactile_click()
    generate_button_tips()
    generate_battery_gauges()
    generate_wifi_glyphs()
    generate_switches()
    generate_cards_and_selectors()
    print("=== All Lumen design assets generated successfully! ===")
