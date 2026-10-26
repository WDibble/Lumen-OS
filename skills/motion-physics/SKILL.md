---
name: motion-physics
description: Handheld motion physics, frame pacing, and acoustic synchronization specification for TrimUI Smart Pro. Governs 60Hz IPS panel timing, zero-reflow compositor transitions, D-Pad carousel kinetics, analog stick LED pulse curves, and sub-frame acoustic click alignment.
---

# Handheld Motion Physics: TrimUI Smart Pro Specification

This skill codifies physical, fluid motion tailored for embedded Linux handheld consoles. The TrimUI Smart Pro features an Allwinner A133plus SoC with a Mali-G31 GPU driving a 1280×720 IPS panel at a locked 60Hz refresh rate ($16.66\text{ms}$ per frame).

The core law: **Handheld gaming interfaces must respond instantaneously to D-Pad rising edges, animate strictly on the GPU compositor without triggering layout reflow, and synchronize visual motion with acoustic clicks.**

---

## 🏎️ Handheld Motion Invariants

### 1. Compositor-Only Transitions (Zero CPU Layout Reflow)
On resource-constrained embedded SoCs, animating dimension properties (`width`, `height`, `padding`, `border-width`) forces full CPU layout recalculation, dropping frames below 60fps.
- **Rule**: Animate **only** compositor-backed properties: `transform` and `opacity`.
- Pre-allocate borders as transparent (`border: 2px solid transparent`) so selection only animates `border-color`.
- Focus scaling must use transform: `transform: scale(0.92)` ➔ `transform: scale(1.0)` with `will-change: transform`.

### 2. Carousel Translation Kinetic Equation
The top-level console carousel uses fixed-pitch translation anchored dead-center:
- Card width: $W = 300\text{px}$
- Gap: $G = 32\text{px}$
- Pitch: $P = W + G = 332\text{px}$
- Center anchor offset: $X_{\text{start}} = 490\text{px}$
- Active index offset:
  $$\text{translateX} = -(i \times 332)\text{px}$$
- Transition curve: `cubic-bezier(0.16, 1, 0.3, 1)` over $250\text{ms}$. Fast entry with smooth deceleration to a complete resting stop.

### 3. Sub-Frame Acoustic Click Synchronization
A button press on a handheld controller must immediately produce acoustic feedback.
- Audio click is triggered on the **rising edge** of the button press, simultaneous with the visual transition.
- Never debounce or delay the audio trigger.
- Audio transient: 24ms, 580Hz fundamental, tapered smoothly to zero amplitude to eliminate DAC speaker pops.

### 4. Analog Stick RGB LED Breathing Physics
The LED rings surrounding the analog sticks are driven via `/sys/class/led_anim/`:
- **Breathing Mode**: Smooth sinusoidal duty cycle modulation:
  $$I(t) = I_{\text{min}} + (I_{\text{max}} - I_{\text{min}}) \times \frac{1 + \sin(2\pi \cdot f \cdot t)}{2}$$
  Where $f = 0.5\text{Hz}$ (2-second respiratory cycle), $I_{\text{min}} = 20\%$, $I_{\text{max}} = 100\%$.
- **FN Switch Override**: When the physical FN slide switch is toggled, LED sysfs registers yield immediately ($\le 5\text{ms}$) to the target state without transitional lag.
