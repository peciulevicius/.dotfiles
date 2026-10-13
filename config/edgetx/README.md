# EdgeTX radio configs

`tx15/` — RadioMaster TX15 (EdgeTX 3.0.0 RadioMaster build, internal ELRS
module 3.5.5, FCC firmware on the 900 MHz band as shipped). Copied from the
radio's built-in storage (504 MB, appears as a drive in USB Storage mode).

- `RADIO/radio.yml` — radio-wide settings. Stick mode 2 is `stickMode: 1`
  (EdgeTX counts from 0).
- `MODELS/*.yml` — one file per model (`model1.yml` = the factory "AERO" model).
- `edgetx.sdcard.version` — the SD-content version these files match.

Not here: firmware, sounds, images, widgets and stock scripts — all
re-downloadable; the full raw copy of the radio's storage is in
`~/backups/edgetx/` (private). The **ELRS binding phrase** lives in the radio
module, not in these files — never add it (this repo is public).

**Back up again** after changing models: radio → USB → *USB Storage*, then in
Finder copy `RADIO/` and `MODELS/` here (the terminal needs *Removable Volumes*
access for `cp`). **Restore:** copy them back onto the radio's drive.
Runbook: `docs/guides/FPV.md`.
