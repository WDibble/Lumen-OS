---
name: handheld-ui-primitives
description: Architecture and contract specifications for TrimUI Smart Pro handheld navigation primitives. Governs D-Pad focus state machines, two-pane master-detail views, D-Pad steppers, breadcrumb status bars, contextual hardware hint bars, and full-screen launch dispatchers. Use when authoring, modifying, or auditing handheld interface components.
---

# Handheld UI Primitives: TrimUI Smart Pro Architecture

This skill defines the canonical layout, state machine, and navigation contracts for the TrimUI Smart Pro custom OS (Lumen). All interfaces on the 1280×720 display are constructed from these foundational primitives.

---

## 🏛️ Handheld Primitive Hierarchy

```
Screen (1280×720 IPS)
├── Top Status Bar (Height: 48px)
│   ├── Brand Mark & Hardware Chip ("L U M E N", "TRIMUI PRO")
│   ├── Breadcrumb Hierarchy ("› CONSOLES", "› GBA")
│   └── System Telemetry (Wi-Fi, Battery %, Real-time Tabular Clock)
│
├── Main Viewport Area (Height: 624px)
│   ├── Primitive 1: Top-Level Carousel (Tab Bar + Horizontal Card Pitch)
│   ├── Primitive 2: Two-Pane Master-Detail Stage (Console 3D Hero + ROM List)
│   ├── Primitive 3: Handheld Settings View (Category Hero + D-Pad Steppers)
│   └── Primitive 4: Fullscreen Dispatcher (launch.sh Execution Overlay)
│
└── Bottom Hardware Hint Bar (Height: 48px)
    ├── Contextual Action Badges ([A] LAUNCH, [B] BACK, [X] OPTIONS)
    └── Position Telemetry ("1 / 14" Tabular Numeral Counter)
```

---

## 🕹️ Primitive Specifications

### 1. Two-Pane Master-Detail Stage (Game List View)
Replaces floating web dialogs with an integrated handheld split view:
- **Left Stage (Width: 440px)**:
  - Concentric 3D hardware console render resting on a subtle radial pedestal glow.
  - Heading 1: Console title (24px, 700 weight, -0.01em tracking).
  - Subtitle: Manufacturer and release year (14px, monospace).
  - Badge: Installed game count chip (`6 TITLES INSTALLED`).
- **Right Scroll Pane (Width: 800px)**:
  - Scrollable column of 2-line list items (`height: 76px`, gap: 10px).
  - Matches TrimUI's authentic `list-item-2line-bg-*.png` geometry.
  - Focused item translates right (+8px), activates 2px accent border (`#38BDF8`), and reveals the `[A] LAUNCH` badge.
  - Always scrolls the focused item into view (`scrollIntoView({ block: "nearest" })`).

### 2. Handheld D-Pad Stepper (`◄ Value ►`)
Replaces mouse-drag sliders and dropdown menus:
- **Interaction Contract**:
  - D-Pad <kbd>↑</kbd> <kbd>↓</kbd> changes row focus.
  - D-Pad <kbd>←</kbd> <kbd>→</kbd> decrements / increments discrete options.
  - Instant acoustic click feedback on each step.
  - Real-time side-effect execution (e.g. Backlight PWM immediately updates screen filter, Theme Accent immediately updates UI highlights).
- **Visual Styling**:
  - Arrow indicators (`◄`, `►`) highlight in cyan when row is focused.
  - Stepper value rendered inside an elevated pill (`#1E283D`) with `font-variant-numeric: tabular-nums` to eliminate text jitter.

### 3. Contextual Hardware Action Hints
- Located at the bottom 48px of the screen.
- Driven by authentic 40×40 circular button badge icons (`tips-A.png`, `tips-B.png`, `tips-X.png`, `tips-MENU.png`).
- Dynamically updates labels depending on the active view:
  - **Carousel**: `[A] OPEN` | `[B] BACK` | `[Q/E] TABS` | `[MENU] SYSTEM`
  - **Game List**: `[A] LAUNCH` | `[B] CONSOLES` | `[X] FAVORITE` | `[MENU] MENU`
  - **Settings**: `[A] SELECT` | `[◄►] ADJUST` | `[B] BACK` | `[X] DEFAULT`

### 4. Fullscreen Hardware Launch Dispatcher
When the user presses <kbd>A</kbd> on a game or app:
- Smoothly fades in a black fullscreen execution overlay (1280×720).
- Displays the POSIX execution path:
  `[System/scripts/launch.sh] Dispatching /mnt/SDCARD/Roms/GBA/Zelda.gba...`
  `[next-hw] Setting CPU governor to performance (1608 MHz)...`
- Pressing <kbd>B</kbd> or <kbd>Esc</kbd> returns immediately to the launcher.
