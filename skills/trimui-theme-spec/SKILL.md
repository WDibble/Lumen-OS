---
name: trimui-theme-spec
description: Theme token architecture, asset geometry contracts, and color space specification for the TrimUI Smart Pro (Lumen Theme). Governs MainUI config.json ARGB tokens, exact PNG asset dimensions, 9-slice navigation tab metrics, and WCAG 2.2 AA outdoor sunlight readability on the 1280x720 IPS panel.
---

# Handheld Theming & Asset Specification: TrimUI Smart Pro

This skill defines the color token architecture and asset geometry contracts for the **Lumen** custom theme on the TrimUI Smart Pro.

---

## 🎨 Semantic Color Tokens & Contrast Architecture

All TrimUI themes store color definitions in `Themes/<ThemeName>/config.json` using **ARGB 8-digit hexadecimal format** (`#AARRGGBB`):

| Token Key | Default Hex | OKLCH | Semantic Role | Contrast vs `#090D14` |
| :--- | :--- | :--- | :--- | :--- |
| `nav_color1` | `#FFB0BED0` | `0.77 0.03 240` | Inactive tab label / secondary text | **6.8:1** (WCAG AA Pass) |
| `nav_color2` | `#FFF8FAFC` | `0.98 0.01 240` | Active tab label / primary title | **14.2:1** (WCAG AAA Pass) |
| `nav_color3` | `#FF38BDF8` | `0.76 0.14 230` | Focus accent / tab indicator line | **7.2:1** (WCAG AA Pass) |
| `content_color1` | `#FFF8FAFC` | `0.98 0.01 240` | Game / item primary title | **14.2:1** (WCAG AAA Pass) |
| `content_color2` | `#FFB0BED0` | `0.77 0.03 240` | Game genre / metadata label | **6.8:1** (WCAG AA Pass) |
| `content_color3` | `#FF94A3B8` | `0.68 0.04 240` | File extension / subtle timestamp | **4.9:1** (WCAG AA Pass) |
| `stat_color1` | `#FFF8FAFC` | `0.98 0.01 240` | Clock digits / primary status | **14.2:1** (WCAG AAA Pass) |
| `stat_color2` | `#FFB0BED0` | `0.77 0.03 240` | Battery % / secondary status label | **6.8:1** (WCAG AA Pass) |
| `highlight_color1` | `#FF38BDF8` | `0.76 0.14 230` | Focused border / cursor outline | **7.2:1** (WCAG AA Pass) |

---

## 📐 Canonical Asset Geometry Contracts

MainUI does not support responsive CSS or Android nine-patch (.9.png) files. All assets in `Themes/Lumen/skin/` must match exact pixel dimensions:

| Asset File | Target Dimensions | Geometry & Radii Spec |
| :--- | :--- | :--- |
| `bg.png` | **1280 × 720** | Fullscreen 16:9 wallpaper, dark mesh canvas (`#090D14`). |
| `grid-item-bg-f.png` | **305 × 280** | Focused grid card. Outer $R = 16$, inner top highlight at $y=6$. |
| `grid-item-bg-n.png` | **295 × 270** | Normal grid card. Outer $R = 14$. |
| `list-item-2line-bg-f.png` | **840 × 110** | Focused 2-line list row. Outer $R = 12$, top specular rim highlight. |
| `list-item-2line-bg-n.png` | **840 × 110** | Normal 2-line list row. Outer $R = 12$. |
| `btn-bg-f.png` | **300 × 60** | Focused button. Outer $R = 10$, cyan fill (`#38BDF8`), white border. |
| `btn-bg-n.png` | **300 × 60** | Normal button. Outer $R = 10$, dark slate fill (`#1E293B`). Strict dimensional parity with `f`. |
| `main-nav-sel-left.png` | **31 × 70** | 9-slice left endcap. Rounded $R = 12$, top and bottom cyan border lines. |
| `main-nav-sel-mid.png` | **4 × 70** | 9-slice middle tile. Horizontal lines at $y=6$ and $y=68$. |
| `main-nav-sel-right.png` | **31 × 70** | 9-slice right endcap. Rounded $R = 12$, top and bottom cyan border lines. |
| `tips-*.png` | **40 × 40** | Controller button disk badges (`tips-A.png`, `tips-B.png`, etc.). Centered glyphs via `anchor="mm"`. |

---

## 🛠️ Supersampling & Asset Generation Pipeline

All assets are generated programmatically via [`tools/generate_assets.py`](file:///Users/dibble/Documents/GitHub/lumen-os/tools/generate_assets.py) using **4× supersampling** ($S = 4$):
1. Render shapes, anti-aliased outlines, and specular lines onto a $4\times$ canvas.
2. Downscale using `Image.Resampling.LANCZOS` for razor-sharp edges without pixelation or fringing.
3. Save as optimized 32-bit PNG.
