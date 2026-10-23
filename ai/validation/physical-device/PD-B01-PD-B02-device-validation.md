# PD-B01 / PD-B02 Physical Device Validation

- **Bug IDs**: PD-B01, PD-B02
- **Validation Date**: 2026-10-23 (user-reported)
- **Git SHA (code fix)**: `9c994c2586f55e3094e365651580eba84a0994d0` — `fix(scan): stabilize scanner transition and appearance (PD-B01 PD-B02)`
- **Device Information**: UNKNOWN (not reported by user; iPhone model / iOS version unconfirmed)
- **Xcode Version**: UNKNOWN (assumed 27.0 per project conventions)

---

## PD-B01 — Scan-to-Holder Dark Flash

### Original Phenomenon
On a real iPhone, after tapping ✕ to dismiss the Scanner (`ScanEntryView`) and return to the Card Holder (`CardHolderView`), the newly-visible Card Holder would flash dark for approximately one frame before snapping back to its normal light appearance.

### Root Cause Confirmed
`ScanEntryView`, `CardCropView`, and `RecognitionView` each applied `.preferredColorScheme(.dark)` — a **window-level** modifier that propagates up to the hosting `UIWindow`. During the `NavigationStack` pop transition, the window's dark preference lingered for one frame after the Scanner disappeared, causing the Card Holder (which has no explicit color scheme) to render dark before the window preference cleared.

### Failed Attempts (Pre-Correction Evidence, Preserved for Audit)
| Attempt | Rationale | Outcome |
|---------|-----------|---------|
| `.preferredColorScheme(.dark)` (original) | Force dark scan UI | **Caused PD-B01** — window-level propagation |
| `.colorScheme(.dark)` (SwiftUI view-local) | View-local scoping, non-deprecated at time | Correct scoping, but SwiftUI 27 marked this modifier Deprecated |
| `.environment(\.colorScheme, .dark)` | Direct environment key injection, view-local, non-deprecated | **Used in final fix** |

### Final Implementation
All three scan subtree views now use `.environment(\.colorScheme, .dark)` instead of `.preferredColorScheme(.dark)`:
- `SimCamCard/View/Scan/ScanEntryView.swift`
- `SimCamCard/View/Scan/CardCropView.swift`
- `SimCamCard/View/Scan/RecognitionView.swift`

### User-Reported Result
| Scope | Result |
|-------|--------|
| **Flash no longer observed on device** | **USER-REPORTED PASS** |
| Unverified scenarios | Background/foreground switch; system dark-mode while scan; PhotosPicker cancel path; crop→recognition→holder pop |

---

## PD-B02 — Trailing "+" Toolbar Item Clipping During Scan Push

### Original Phenomenon
On a real iPhone, when navigating from the Card Holder (with a system navigation bar displaying a trailing "+" `ToolbarItem`) into the Scanner (pushed via `NavigationStack`), the Scanner's navigation bar is entirely hidden (`.toolbar(.hidden, for: .navigationBar)`). During the push transition, the source navigation bar's trailing "+" item has no destination bar to transition into, and gets clipped at the right screen edge — appearing as "half a plus button stuck on the edge" before vanishing.

### Failed Attempts (Pre-Correction Evidence, Preserved for Audit)
| Attempt | Rationale | Outcome |
|---------|-----------|---------|
| `.toolbarBackground(.hidden)` + `.ignoresSafeArea(.container, edges: .top)` | Keep a transparent nav bar so destination exists for cross-bar transition | **FAIL — BLOCKING REGRESSION**: transparent bar injects safe-area inset; the `.ignoresSafeArea(.top)` compensation pushed the custom topBar out of the safe area, overlapping the Dynamic Island and status bar |
| `fullScreenCover(isPresented:)` | Modal presentation independent of NavigationStack bar transitions | **WORKED** — no clipping, correct safe area. But uses vertical sheet animation (from bottom), diverging from CamCard Reference's horizontal push |
| `.navigationDestination(isPresented:)` + conditional `if !isScannerPushed` removal of Button | Horizontal push preserved; remove toolbar item before push so nothing clips | **PARTIAL — residual "+" still observed on device** (source bar animation snapshot likely captured before toolbar rebuild committed) |
| `.navigationDestination(isPresented:)` + stable `ToolbarItem(id:)` + conditional removal | Stable ToolbarItem identity so UIKit Liquid Glass tracks it across transition | **NO MATERIAL IMPROVEMENT** (user-reported) |
| `.navigationDestination(isPresented:)` + stable `ToolbarItem(id:)` + **always-present** Button (final) | Mirror community-reported iOS 26 Liquid Glass workaround: ToolbarItem + Button never conditionally mutated during navigation | **USER-REPORTED PASS (core transition symptom)** |

### Final Implementation
`SimCamCard/View/CardHolder/CardHolderView.swift`:

```swift
// State
@State private var isScannerPushed = false

// Toolbar — stable ToolbarItem identity, Button always present
ToolbarItem(id: "card-holder-scan-entry", placement: .topBarTrailing) {
    Button {
        isScannerPushed = true
    } label: {
        Image(systemName: "plus")
    }
    .accessibilityLabel("扫描")
    .accessibilityIdentifier("scan-entry")
}

// Presentation — standard horizontal NavigationStack push
.navigationDestination(isPresented: $isScannerPushed) {
    ScanEntryView(cardRepository: cardRepository, imageStore: imageStore)
}
```

### ScanEntryView Layout (Preserved — No Further Modification)
```swift
.environment(\.colorScheme, .dark)       // PD-B01, view-local (not window-level)
.toolbar(.hidden, for: .navigationBar)  // System bar still hidden; custom topBar provides chrome
```
Explicitly **not** reintroduced: `.toolbarBackground(.hidden)`, `.toolbarColorScheme(.dark)`, `.ignoresSafeArea(.container, edges: .top)`.

### User-Reported Result
| Scope | Result |
|-------|--------|
| **Core "+" clipping during horizontal push** | **USER-REPORTED PASS** ("实机测试基本通过") |
| Unverified scenarios | PhotosPicker import/cancel while Scanner is pushed; capture→crop→recognition→save→holder reload; rapid tap sequences; system dark/light mode during push |

---

## Automated Test Evidence

| Suite | Result | Run Date | Notes |
|-------|--------|----------|-------|
| Debug Build | **PASS** | 2026-10-23 | Zero compile errors, zero deprecation warnings |
| Unit Suite | **466/466 PASS** (37 suites, 7.5 s) | 2026-10-23 | Matches Phase 1.1 historical baseline |
| `ScanEntryUITests` (2 tests) | **2/2 PASS** (28.5 s) | 2026-10-23 | Includes `testEnterScannerShowsStaticShell` (tap scan-entry → scan-entry-view appears) and `testCloseReturnsToCardHolderWithStateUnchanged` (tap scan-close → scan-entry-view disappears, holder nav bar visible) |
| `ScanCameraUITests` (24 tests) | **BLOCKED — 0 executed** | 2026-10-23 | `DTServiceHubClient failed to bless service hub` — simulator service infrastructure failure; runner timed out after 600 s with 0 tests executed |
| `ExceptionHandlingUITests` (3 tests) | **BLOCKED — 0 executed** | 2026-10-23 | Same `DTServiceHubClient` failure as above |
| Other UI tests (33 tests) | **NOT RUN** | — | Not selected in this round's targeted runs |
| Full UI Suite (62 tests) | **NOT RERUN this round** | — | This round's actual execution: 2 PASS + 27 BLOCKED (0 executed) + 33 NOT RUN. Historical 62/62 PASS (Phase 1.1, pre-bugfix code) is recorded separately and must not be presented as this round's result |

Root-cause framing note: the causal explanations above (window-level `.preferredColorScheme` propagation; Liquid Glass trailing-item transition mis-tracking) are **reasonable judgments supported by code-level analysis and user device observations** — they have NOT been proven via UIKit internal transition instrumentation. No such instrumentation exists in this repository.

## Remaining Risks and Unverified Scope

| Risk | Severity | Mitigation Status |
|------|----------|------------------|
| ScanCamera/ExceptionHandling UITests not re-executed after PD-B02 | MEDIUM | Simulator service `DTServiceHubClient` failure; will rerun when infrastructure stabilises |
| Capture→Crop→Recognition→Save→Holder reload path untested on device | MEDIUM | No reported regressions from user, but save path was not explicitly verified with the new presentation |
| PD-B01 not re-verified after PD-B02 final fix | LOW | PD-B02 does not touch color-scheme modifiers; window-level propagation fix preserved |
| iOS 27 Liquid Glass toolbar behavior still not comprehensively understood | LOW | Final ToolbarItem structure (stable id + always-present Button) mirrors community-reported pattern; accept as best-practice workaround without theoretical guarantee |
| Full historical UI 62/62 baseline not confirmed on post-fix code | LOW | Changes are navigation-layer, not view-model or business-logic; Unit Suite zero regressions |

## Code Diff Scope (Bugfix Commit Preview)

Files intended for a single Bugfix commit (project.pbxproj intentionally excluded):

| File | Lines | Purpose |
|------|-------|---------|
| `SimCamCard/View/CardHolder/CardHolderView.swift` | +33/-5 | PD-B02 scanner entry: state-driven `navigationDestination`, stable ToolbarItem id |
| `SimCamCard/View/Scan/ScanEntryView.swift` | +16/-3 | PD-B01 `.preferredColorScheme(.dark)` → `.environment(\.colorScheme, .dark)` |
| `SimCamCard/View/Scan/CardCropView.swift` | +1/-1 | PD-B01 same |
| `SimCamCard/View/Scan/RecognitionView.swift` | +1/-1 | PD-B01 same |

Affected T/P/G items (evaluative, not asserted):
- **T02 Enter Scanner**: behavior unchanged (enter/exit still works); fidelity shift (vertical sheet → horizontal push → final stable-id push)
- **T04/T05 Scan Flow**: no impact (presentation changes do not affect scan/crop/recognise internals)
- **P04 Reference Fidelity**: horizontal push restored (matches CamCard Reference animation direction)
- **PD-B01**: new tracking ID for this specific scan flash regression
- **PD-B02**: new tracking ID for this specific toolbar clipping regression
- **G-11 (physical device verification gap)**: partially reduced — device tested on 2026-10-23; retain UNVERIFIED for unexecuted scenarios

## Intentional Exclusions from Bugfix Commit

| Item | Reason |
|------|--------|
| `SimCamCard.xcodeproj/project.pbxproj` | DEVELOPMENT_TEAM = `9MX9UVFPJK` is an Xcode auto-injected local signing configuration; should not be hard-coded into shared repository |
| `ai/delivery/final-course-report.md` | Phase 2A-2 deliverable — to be updated with post-commit SHA then committed separately |
| `ai/delivery/final-traceability-matrix.md` | Phase 2A-2 deliverable — same |
| `ai/delivery/spec-change-ledger.md` | Phase 2A-2 deliverable — same |
| `ai/validation/physical-device/PD-B01-PD-B02-device-validation.md` | This very document — to be committed with the Bugfix commit or immediately after; commit SHA will be filled in |

## SDD Follow-up Plan (Not Executed — Awaiting Human Decision)

| Document | Planned Update | Priority |
|----------|----------------|----------|
| `final-traceability-matrix.md` | Add PD-B01 / PD-B02 evidence rows; update T02 fidelity column | HIGH |
| `final-course-report.md` | Record failure attempts, final implementation choice, user-device findings | HIGH |
| `G-11` (traceability matrix) | Move from "no physical iPhone" → "partial physical coverage" with explicit scenario list | MEDIUM |
| `P04` fidelity | Re-evaluate if horizontal push restoration restores PASS status (do not retroactively modify historical PASS lines — add current-state columns) | MEDIUM |
| `ai/changes.md` | Append new PD-B01/PD-B02 section under existing W4I12 body — **DO NOT** overwrite historical paragraphs | MEDIUM |

---

*This document captures the known evidence as of 2026-10-23. It does not assert scenarios that were not explicitly tested on device. The code fix was committed as `9c994c2` (see header).*
