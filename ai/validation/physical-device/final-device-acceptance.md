# Final Physical Device Acceptance — 2026-10-24

**Status:** USER-REPORTED PASS (full manual acceptance sweep)
**Reported by:** project owner (Human Review)
**Report date:** 2026-10-24
**Code under test:** `9c994c2586f55e3094e365651580eba84a0994d0` (+ comment-only
change in `7bde6456faf0cdc6c4d6313df748791b8ae116d1`, zero logic delta)
**Device model:** NOT PROVIDED
**iOS version:** NOT PROVIDED
**Xcode version used for device build:** NOT PROVIDED
**Evidence artifacts (screenshots / screen recordings / logs):** NOT PROVIDED —
the acceptance exists as the owner's explicit human-review statement. This
document records that statement and its scope; it does not fabricate artifacts.

## Evidence discipline

- Every row below is **USER-REPORTED PASS**: the owner executed the scenario on
  a physical iPhone and reported the full checklist as passed on 2026-10-24.
- No row below is an **AUTOMATED PASS**. Automated evidence for the same code
  remains exactly: Debug Build PASS, Unit 466/466 PASS, ScanEntryUITests 2/2
  PASS (2026-10-23); ScanCameraUITests + ExceptionHandlingUITests were BLOCKED
  by a simulator service failure on 2026-10-23 (re-run status recorded in the
  delivery documents); other UI tests NOT RUN on final code.
- This record **does not** convert any earlier BLOCKED / NOT RUN automated
  result into a pass. Manual acceptance and automated suites are separate
  evidence classes.

## Acceptance sweep — user-reported results (2026-10-24)

| # | Scenario | Result | Scope note |
|---|----------|--------|------------|
| 1 | T01–T20 behavioural sweep (all twenty acceptance scenarios) | USER-REPORTED PASS | Per-scenario detail not individually logged; owner reported the full set as passed |
| 2 | PD-B01 — dark flash returning from Scanner to Card Holder | USER-REPORTED PASS | Core symptom verified earlier 2026-10-23; no regression reported in final sweep |
| 3 | PD-B02 — "+" toolbar item clipping during scan push | USER-REPORTED PASS | Core transition symptom verified earlier 2026-10-23; no regression reported |
| 4 | Capture / retake / cancel | USER-REPORTED PASS | — |
| 5 | PhotosPicker import and cancel | USER-REPORTED PASS | System picker semantics per Apple HIG; cancel returns to scan flow |
| 6 | Card boundary detection + manual crop adjust | USER-REPORTED PASS | — |
| 7 | OCR and structured field extraction | USER-REPORTED PASS | Device OCR quality observations are anecdotal; the quantitative 34-card evaluation remains simulator/harness-based (164/233 = 70.4%) |
| 8 | Manual field editing before save | USER-REPORTED PASS | — |
| 9 | Save → detail view → edit saved card | USER-REPORTED PASS | — |
| 10 | Search, tags, delete | USER-REPORTED PASS | — |
| 11 | Kill app → relaunch → persistence (cards, images, edits, tags, notes) | USER-REPORTED PASS | — |
| 12 | Original-image viewer vs processed image distinction | USER-REPORTED PASS | — |
| 13 | Contacts export + field mapping | USER-REPORTED PASS | Device Contacts were modified by real export (known side effect) |
| 14 | Camera permission denial + recovery | USER-REPORTED PASS | Denied state, settings guidance, and re-grant recovery |
| 15 | Backgrounding / foregrounding, system light/dark appearance, safe-area layout | USER-REPORTED PASS | No layout overlap or appearance regression reported |
| 16 | T01 first-install empty state | USER-REPORTED PASS (scoped) | A rigorous first-install empty-state proof requires a fresh install environment; the owner's report covers the observed empty-state behaviour but the exact install preconditions were not logged |

## Relationship to prior records

- [PD-B01-PD-B02-device-validation.md](PD-B01-PD-B02-device-validation.md)
  remains the historical record of the two transition bugs and their fix
  verification (2026-10-23). This document does not overwrite it; it extends
  the same device evidence to the full acceptance sweep one day later.
- G-11 status impact: with this sweep, physical-device coverage moves from
  "core transition symptoms only" to a full user-reported manual sweep. The
  evidence class stays **USER-REPORTED** (no automated device runner, no
  captured artifacts). This is recorded in the delivery documents as such.

## What this record does NOT claim

- No automated on-device test run exists.
- No screenshot / recording / log artifacts are attached; none were provided.
- Device model, iOS version, and Xcode version for the device build are not
  recorded (NOT PROVIDED).
- Simulator-side automated gaps (27 BLOCKED + 33 NOT RUN as of 2026-10-23) are
  unaffected by this manual acceptance.
