# SimCamCard

SimCamCard is a Specification-Driven Development (SDD) project that black-box replicates the instructor-defined CamCard 8.63.1 feature slice:

**Business Card Digitization and Contact Management**

The project follows the full SDD loop:

```
Specification → Architecture → Implementation → Test → Difference Analysis → Revision → Regression
```

When implementation conflicts with a frozen specification, the implementation is fixed, not the specification.

## Current stage

- **Phase 1.1 — Accepted (human review), 2026-10-18.**
- Baseline commit: `de58eee81326e6728080a2816ac718520c268366` on branch `week4/structured-recognition`.
- The Week 1 SDD baseline (`spec.md`, `spec/`, `evidence/`, `dataset/`) remains frozen and unchanged.
- Implementation covers the full bounded slice: Card Holder, camera + permission flow, photo-library import, card region detection + perspective correction, OCR, structured field extraction, human verification / correction, save, detail (with original-image viewer and native phone/email/website actions), edit, delete, search, groups/tags, notes, local persistence, and export to system Contacts.
- **Next: Final Delivery Phase 2 (documentation refresh & human review).**
  Formal packaging and extraction verification occur in Phase 3. No new feature increment is planned.

## Bounded scope

Included: Card Holder / list / empty state, scan entry, camera preview + permission flow, photo-library import, card region detection, manual crop / perspective correction, OCR, raw OCR preservation, structured field extraction, manual verification / correction, save, detail view, edit, delete, search, groups/tags, notes, local persistence, export to system Contacts or VCF, and required exception paths.

Excluded: user registration / membership, subscription / payment / VIP, advertising, cloud sync, multi-device sync, team card libraries, CRM/Salesforce sync, enterprise org/permissions, digital business-card design, QR-based exchange, email signatures / virtual backgrounds, AI business intelligence / company analysis, meeting recording / summarization, sales pipeline, enterprise-data enrichment, nearby-contact maps.

Observed-but-excluded CamCard UI does not become an implementation requirement.

## Environment (frozen)

- Xcode **27.0**; Swift compiler/toolchain **6.4**; Swift language mode (`SWIFT_VERSION`) **6.0**
- iOS deployment target **27.0**
- Primary simulator: **iPhone 18 Pro, iOS 27.0**
- Reference App: CamCard / 名片全能王 8.63.1, Simplified Chinese, logged out, free / non-member
- Observation platform: Apple Silicon Mac (M2), macOS 27.0 (CamCard in iPhone/iPad-compatible mode)

See `spec/reference-environment.md` for details and the physical-iPhone verification caveat.

> **Toolchain re-measured, recorded explicitly (Phase 2A-1, 2026-10-19).** The frozen
> reference environment records Xcode **27.0**. The local verification toolchain was
> re-measured for this phase as **Xcode 27.1 (build 27A9275)**, with the same Swift
> compiler/toolchain **6.4** (Apple Swift 6.4) and the same `SWIFT_VERSION = 6.0`
> (`SimCamCard.xcodeproj/project.pbxproj`). Per `spec/reference-environment.md`
> ("later changes must be recorded explicitly rather than silently replacing the
> baseline"), the frozen value above is retained unchanged; only this minor Xcode
> update is recorded here.

## Repository structure

```
SimCamCard/
├── assignment/              # immutable instructor source — do not modify
├── spec.md                  # top-level SDD specification (frozen)
├── spec/                    # derived SDD baseline: environment, inventories, data model, tests (frozen)
├── evidence/                # immutable black-box observation evidence + manifest (frozen)
├── dataset/                 # frozen 34-card dataset + Ground Truth + T20 exception fixture (frozen)
├── ai/                      # AI collaboration rules, change log, delivery audits, evaluation artifacts
│   ├── changes.md           # increment-by-increment AI/human collaboration log
│   ├── final-acceptance.md  # T01–T20 behavioral acceptance
│   ├── final-reference-audit.md  # P01–P11 Reference-fidelity audit
│   ├── delivery/            # course-compliance-matrix, final-gap-list, delivery-package-plan
│   └── evaluation/real-vision-34/  # real Vision OCR evaluation over the 34 frozen cards
├── tools/                   # host-side evaluation assembler
├── SimCamCard.xcodeproj     # Xcode project
├── SimCamCard/              # SwiftUI app source (see below)
├── SimCamCardTests/         # unit tests (Swift Testing)
└── SimCamCardUITests/       # UI tests (XCTest / XCUITest)
```

Application source (`SimCamCard/`) is organized by concern:

```
App/          composition root (dependency injection)
Model/        Domain model (Foundation only — no SwiftUI/UIKit)
Repository/   repository protocols + in-memory/file implementations
Persistence/  JSON file storage schema
Imaging/      image-asset store abstraction
Camera/       AVCapture session + capture controller (actor)  (+ Debug fakes)
Detection/    card region detector (Vision)
Crop/         crop / perspective geometry + processor
OCR/          Vision OCR processor
Recognition/  deterministic field extractor
Edit/         business-card edit draft
Export/       system Contacts exporter           (+ Debug fake exporter)
Search/       deterministic search matcher
View/         SwiftUI views (CardHolder, Scan, CardDetail, Group, Search, Debug)
ViewModel/    @MainActor @Observable view models
```

## Build and run

```bash
# Open in Xcode
open SimCamCard.xcodeproj

# Debug build (simulator)
xcodebuild build -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -configuration Debug

# Release build (simulator)
xcodebuild build -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -configuration Release
```

Run from Xcode on the **iPhone 18 Pro / iOS 27.0** simulator. Camera and native system surfaces (phone / mail / browser / Contacts) behave as simulator surrogates; no physical iPhone exists in this environment.

## Tests

Tests are run **serially** (`-parallel-testing-enabled NO`); never run two `xcodebuild` processes at once.

```bash
# Full unit suite (Swift Testing) — deterministic
xcodebuild test -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardTests -parallel-testing-enabled NO

# Full UI suite (XCTest / XCUITest) — includes the 2 real Contacts integration
# tests (System01 / System02) inside the 62-count total. System01/System02
# write to the simulator Contacts address book (stateful; repeated runs can
# duplicate test contacts). Their simulator side effects are unavoidable;
# you cannot meaningfully exclude them and keep the same total.
xcodebuild test -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardUITests -parallel-testing-enabled NO
```

### Real Vision evaluation (opt-in, env-gated)

The 34-card real-Vision OCR evaluation is a **non-deterministic** harness and is disabled unless the runner environment sets the gate variable, so it never pollutes the deterministic unit baseline. It runs the 34 frozen PNGs through the real production pipeline (Vision rectangle detection → Core Image perspective correction → Swift-native Vision OCR → deterministic extractor) and emits a payload consumed by a host-side assembler.

```bash
TEST_RUNNER_REAL_VISION_EVAL=1 xcodebuild test \
  -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardTests/RealVision34EvaluationTests \
  -parallel-testing-enabled NO

# Re-assemble the human-readable reports from the freshly emitted payload.
# ⚠️ Before running, confirm the Swift test log contains the harness summary
#    line `[real-vision-34] cards=34 comparisonRows=306` (printed by
#    RealVision34EvaluationTests.swift at the very end of the test,
#    immediately before the EVAL-JSON marker). This is the harness' own
#    output — NOT the assembler's (which prints `cards=34 rows=306` after it
#    already ran, see below). If the test short-circuited (e.g. Vision
#    crashed or a single card failed), the payload may be short or malformed
#    — do NOT assemble; fix the harness issue first.
# ⚠️ This script **directly writes** (no dry-run flag) into
#    `ai/evaluation/real-vision-34/`, overwriting `raw-ocr.jsonl`,
#    `structured-results.jsonl`, `comparison.csv`, `summary.md`,
#    and `environment.md`. Back up or copy the directory first if the
#    currently archived results still matter.
python3 tools/assemble_real_vision34.py
```

### Before/after (area-gate) report reconstruction

The full Phase 1.1 summary includes §9 per-card before/after deltas against
the pre-gate baseline payload. To reconstruct that section (e.g. after
re-running the gated harness or switching machines), **explicitly pass the
pre-gate payload** — the assembler will not infer it on its own:

```bash
python3 tools/assemble_real_vision34.py \
  --before ai/evaluation/real-vision-34/_eval-payload-pre-gate-baseline.json
```

Both the before and after payloads must share the same GT and normalization
(they do by design — the baseline was produced by temporarily reverting the
area gate, then fully restoring it before the gated run). Running with a
stale or incompatible `--before` payload silently produces meaningless §9
numbers.

Real-Vision integration is additionally exercised anchor-style over dataset cards 001–004; none of this is a character-level OCR accuracy claim.

### Known side effects

- The **2 real Contacts integration tests** (`System01` / `System02`) write to the simulator's Contacts address book. They are stateful; repeated runs can create duplicate exported test contacts. They are run separately from the deterministic UI count.
- DEBUG-only fixtures/hooks alter app behavior only under explicit launch arguments; they are compiled out of Release (see below).

## Verified baseline (last full run — Phase 1.1, 2026-10-18)

These figures are the **historical** Phase 1.1 verification result at `de58eee`; they were not re-run as part of later documentation edits.

- Unit: **466 / 466 PASS** (Swift Testing, serial)
- UI: **62 / 62 PASS** — full UI regression, including the 2 real Contacts integration tests (`System01` / `System02`)
- Debug build: PASS · Release build: PASS
- DEBUG hook isolation: **16 / 16 ABSENT** in the Release binary; **16 / 16 PRESENT** in the Debug `.debug.dylib`

Hook isolation is audited with `strings -a` against the Release **main binary** and the Debug **`SimCamCard.debug.dylib`** (under `ENABLE_DEBUG_DYLIB`, Debug code lives in the dylib, not the main executable).

## Behavioral PASS vs Reference fidelity PARTIAL

These are two **separate** axes and must not be conflated:

- **Behavioral acceptance (T01–T20): 20 / 20 PASS** — every deterministic scenario required by the assignment works (`ai/final-acceptance.md`).
- **Reference fidelity (P01–P11): PARTIAL** — behavior passes, but some application-owned *surface* details deliberately differ from the CamCard screenshots (SwiftUI idiom, platform-imposed system UI, frozen-Domain constraints, or explicitly excluded features). Each difference is classified in `ai/final-reference-audit.md`.

PARTIAL never means a required behavior failed; it is an honest, classified surface gap.

## Probabilistic OCR results (real Vision, 34 frozen cards)

- Field-level (not character-level) accuracy on **present** Ground-Truth fields: **164 / 233 = 70.4%** (pre-gate baseline 46.8%).
- GT-absent cells use four mutually exclusive buckets (identical definition before/after): strict canonical absence **68 → 64**, alternate-language exact **3 → 7**, alternate-language partial **2 → 2**, genuine fabrication **0 → 0**. Canonical absence and genuine fabrication are both cross-run comparable; partial overlaps are never counted as exact.
- **In the current 34-card frozen dataset and its 73 GT-absent evaluation cells, no genuine fabrication occurred** — GT-absent fields were never filled with unsupported values that lack any GT alternate-language overlap. This is a measured fact for this specific dataset and evaluation run, not a universal correctness guarantee that would hold for an arbitrary input.
- CamCard-vs-SimCamCard recognition comparison covers only the cards actually observed (card-001/002/003 + card-004 minimal + 1 non-card); **card-005–034 are NOT OBSERVED** and carry no CamCard accuracy figure.

## Evaluation data and delivery documents

- Real Vision evaluation: `ai/evaluation/real-vision-34/` — `summary.md`, `environment.md`, `comparison.csv`, `raw-ocr.jsonl`, `structured-results.jsonl`, plus before/after payloads.
- Course compliance: `ai/delivery/course-compliance-matrix.md`.
- Open gaps: `ai/delivery/final-gap-list.md`.
- Packaging plan: `ai/delivery/delivery-package-plan.md`.
- Behavioral acceptance: `ai/final-acceptance.md`.
- Reference fidelity audit: `ai/final-reference-audit.md`.
- AI collaboration log: `ai/changes.md`.

## Source of truth

- `assignment/` is the immutable instructor source.
- `spec.md` and `spec/` are the derived SDD baseline (frozen).
- `evidence/` is immutable black-box observation.
- `dataset/` is the frozen test data.

## AI collaboration rule

The assignment forbids one-prompt generation of the entire application. AI is used incrementally:

1. Provide only the relevant specification/test context.
2. Define the exact component to modify.
3. State interfaces/architecture that must not change.
4. Require unit/UI tests.
5. Run the full relevant regression suite after changes.
6. Record what the AI changed and what a human verified.

See `ai/README.md` and `ai/changes.md`.
