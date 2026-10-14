# FPV drones — radio, simulator, build path

Started 2026-10-11. Personal context and goals live in the private
`~/ai-memory/projects/fpv.md`; this file is the technical runbook.

## Status (2026-10-13)

TX15 arrived. EdgeTX **3.0.0** (RadioMaster build), stick **Mode 2**, internal
ELRS **3.5.5 FCC, on the 900 MHz band** as shipped ("FCC915"). Before a first
real quad: switch the band to 2.4 GHz and decide LBT (EU-legal, reflash with
ExpressLRS Configurator) vs FCC — receivers must match. Irrelevant for the sim.
Storage is built in (504 MB, no SD card); config backed up to `config/edgetx/tx15/`.

## Gear

| Item | Notes |
|---|---|
| RadioMaster **TX15** (ELRS, Mode 2) | EdgeTX firmware; internal ExpressLRS module on an **LR1121** chip — 2.4 GHz *or* 900 MHz, one at a time. Use **2.4 GHz** (what most receivers use). |
| 2× RadioMaster 18650 3200 mAh | Not included with the radio; charged inside it over USB-C. |

## Plan

1. **Now → winter:** radio + simulator, Acro from day one, 20–30 min a day.
2. **When comfortable in the sim (~Dec/Jan):** goggles + a prebuilt **BNF ELRS
   tiny whoop** for indoors. Pick the **video system first** — goggles lock it in.
   Leaning **analog** (open, cheap, repairable, widely used).
3. **Spring:** build a 5" quad (soldering, Betaflight — Joshua Bardwell's
   build series), EU operator registration + online test before outdoor flights.

## The TX15 on a Mac (do this when it arrives)

Plugging it in over USB-C offers three modes:

- **USB storage** — the radio's SD card mounts as a drive.
- **USB joystick (HID)** — for simulators.
- **Serial/flash** — for firmware tools.

**Day-one checklist** (Claude can drive this):

1. Charge the 18650s in the radio; power on, finish the setup wizard.
2. **Back up the whole SD card** before changing anything (see *Backups*).
3. Check the ExpressLRS firmware **domain**: **LBT** (EU-legal, lower power,
   listen-before-talk) or **FCC**. Radio and every receiver must run the same
   one or they won't bind. Shown in the ELRS Lua script / ExpressLRS
   Configurator.
4. Update EdgeTX if behind (**EdgeTX Buddy**, a WebUSB page — Chrome/Brave) and
   the ELRS module (**ExpressLRS Configurator**, macOS app).
5. Create a **sim model** and a **quad model** (templates below).
6. In Liftoff: choose the TX15 as joystick, calibrate, map arm/beeper.

### Tools (all run on macOS)

| Tool | What for |
|---|---|
| EdgeTX Companion | Edit/back up models and settings on the computer; simulator for testing setups |
| EdgeTX Buddy (web) | Flash EdgeTX firmware, prepare SD-card content (sounds, scripts) |
| ExpressLRS Configurator | ELRS firmware for radio module and receivers; LBT/FCC choice |
| ELRS Lua script (on radio) | Link settings from the radio: power, packet rate, bind |
| Betaflight TX Lua (on radio) | Tune the quad (rates, PIDs, VTX channel/power) without a laptop |

### Customization worth doing

- **Switches:** arm on a 2-position switch with a prearm/safety condition,
  beeper (find a crashed quad), flight mode, turtle mode (flip over after a crash).
- **Timers + voice:** a flight timer started by arming, voice callouts for
  battery voltage and link quality (RSSI/LQ) from telemetry.
- **Telemetry screen / widgets:** voltage, current, LQ, GPS (later).
- **Rates:** gentle rates while learning, a second rate profile for later.

"Helping you fly" is limited to the above. Self-levelling (**Angle mode**) is a
Betaflight setting on the quad, not the radio. Learn **Acro** in the sim — it's
what freestyle and cinematic flying is.

### Backups (into this repo)

Plan: `config/edgetx/tx15/` holds the radio's `MODELS/` (YAML model files),
`RADIO/radio.yml`, and our custom `SCRIPTS/`. **Never commit the ELRS binding
phrase or UID** — it is effectively a password for the link; strip it from the
copied YAML (or keep that file out of the repo) — this repo is public. The full
raw SD-card image goes to a private location (`~/backups/edgetx/`), not Git.

## Simulators (macOS / Apple Silicon)

| Sim | Where | Use |
|---|---|---|
| **Liftoff** | Steam | Start here. Freestyle/cinematic maps, good physics, native on Apple Silicon. |
| **Uncrashed** | Steam (has a Mac version) | Very realistic freestyle; add later. |
| **VelociDrone** | velocidrone.com (not on Steam), Mac version available | Racing standard; only if racing. |

**Lag:** game mode (see `HOME_SERVER_REFERENCE.md` → *Game mode*) pauses the
busy homelab containers automatically while Liftoff runs and resumes them 20 min
after it closes.

Setup: radio in **USB Joystick (HID)** mode → in the sim pick the TX15,
calibrate all axes, map an aux switch to arm/reset. Practice ladder: hover and
gentle laps → orbits around an object → proximity lines → dives. Expect
10–20 hours before Acro clicks.

## Rules (EU / Lithuania) — before any outdoor flight

- EU **open category**: operator registration + online test; FPV needs a
  **visual observer**.
- FPV gear has **no geofencing** — check airspace yourself: Oro navigacija
  (ans.lt) airspace info, airports, border zones, military areas. Lithuania has
  had drone incidents and air-raid alerts; take it seriously.
- ELRS **LBT** firmware is the EU-compliant domain; FCC exceeds EU limits.

## Shopping

Prefer Lithuanian/EU shops: 1dronas.lt, rcshop.lt; EU: Rotorama, Flyingfolk,
FPV-Multicopter. Non-EU orders under €150 incur a €3 per item-category customs
duty (since July 2026). **Buy LiPo batteries from EU shops.**

## Open items

- [x] ~~TX15 arrives → backup~~ — 2026-10-13, `config/edgetx/tx15/` + raw copy in `~/backups/edgetx/`.
- [ ] Quad model (Multirotor wizard) + arm/beeper switches; Liftoff set up.
- [x] ~~Confirm LBT/FCC~~ — FCC (900 MHz as shipped). Reflash to LBT + switch to 2.4 GHz before the first quad.
- [ ] Choose the video system + goggles, then a matching BNF ELRS whoop.
- [ ] EU operator registration + test before outdoor flying (spring).
