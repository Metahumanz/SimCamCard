# Final Course Report — SimCamCard

**Course project:** Mobile Application Development — 100% Black-Box Replication of a
CamCard Feature Slice Using SDD + TRAE.

**Deliverable:** Business Card Digitization and Contact Management (bounded slice of
CamCard / 名片全能王 8.63.1).

**Repository:** `Metahumanz/SimCamCard`, branch `week4/structured-recognition`.
**Baseline commit of record:** `de58eee` (Phase 1.1, 2026-10-18); documentation-audit
commit `bdac7b0` (Phase 2A-1, 2026-10-19).

**Reference environment (frozen, Week 1):** CamCard 8.63.1, Simplified Chinese,
logged out, free / non-member; observed on an Apple Silicon Mac (M2), macOS 27.0
(CamCard in iPhone/iPad-compatible mode). Toolchain baseline Xcode 27.0, Swift
toolchain 6.4, `SWIFT_VERSION = 6.0`, iOS deployment target 27.0, primary simulator
iPhone 18 Pro / iOS 27.0.

**Document role.** This is the reader-facing course report. Detailed traceability
(per-requirement eleven-field rows, per-test grading, G-item status) lives in the
companion [final-traceability-matrix.md](./final-traceability-matrix.md); the change
history lives in [spec-change-ledger.md](./spec-change-ledger.md). Those documents are
the maintained source of record and are cited here by section rather than duplicated.

**No test was re-run to produce this report.** Every number below is quoted from the
named repository record with its date, environment and commit; historical figures are
presented as historical, never as freshly measured.

---

## 1. Project Overview

### 1.1 Assignment goal

The assignment asks the student to treat CamCard as a **black box** and to complete a
full engineering loop — *Product Behavior → Specification → Architecture →
Implementation → Test → Difference Analysis → Revision → Regression* — using TRAE as
the primary AI-assisted development environment. It explicitly forbids "one-prompt
generation" of the whole application (assignment §16) and defines "100% replication"
as equivalence of **observable behavior within the instructor-defined functional
scope, reference version, device environment and test cases** — not source-code or
algorithm reproduction (assignment §4).

### 1.2 What was actually replicated

Only one complete, bounded, testable slice is required, and only that slice was built:

> Enter Card Holder → Capture / Import → Detect and Correct Card Region → OCR →
> Structured Field Extraction → Manual Correction → Save → View Details →
> Search / Manage → Reopen → Export Contact.

The delivered workflow therefore covers: Card Holder list and empty state; scan entry;
camera preview with a permission flow; photo-library import; card-region detection;
manual crop and perspective correction; Vision OCR with raw-text preservation; a
deterministic structured field extractor; human verification and correction; save;
detail page (including tapping phone / email / website and viewing the original card
image); edit; delete; search; groups/tags; notes; local persistence; and export to
system Contacts. All items listed in assignment §15 are explicitly out of scope
(see §9).

This is a **bounded black-box replication of a defined feature slice**, not a
replication of every CamCard feature.

### 1.3 Technology stack and engineering constraints

| Aspect | Value |
|---|---|
| UI framework | SwiftUI (NavigationStack), MVVM with the Observation framework |
| View-model isolation | `@MainActor` + `@Observable` (UI-facing view models) |
| Language / toolchain | Swift 6.4 toolchain, Swift language mode 6; recorded Xcode 27.0 (measured 27.1 build 27A9275 — recorded explicitly in [README.md](../../README.md)) |
| Target | iOS 27.0 / iPhone 18 Pro Simulator (`5B32D815-5F37-4EE0-825C-85DE864E0B02`) |
| Unit tests | Swift Testing |
| UI tests | XCTest / XCUITest |
| Execution policy | Serial only — `-parallel-testing-enabled NO`; never two `xcodebuild` runs at once |
| Domain model | Foundation only (no SwiftUI/UIKit import) |

**Engineering constraints carried through the project** (stated because they shaped
every later decision):

- `assignment/`, `spec.md`, `spec/`, `evidence/`, `dataset/` are **frozen**; when
  implementation conflicts with a frozen specification, the *implementation* is fixed,
  not the specification.
- Repository access is injected behind an abstraction; a view model never binds a
  concrete persistence implementation.
- Camera and other system dependencies are reached through \*\*protocolised seams\*\*, so
  tests can substitute deterministic doubles.
- DEBUG-only fixtures/hooks change behavior only under explicit launch arguments and
  are compiled out of Release.
- AI output is never assumed correct: every AI change required tests and human
  review before acceptance.

---

## 2. Specification-Driven Development Process

### 2.1 The loop actually followed

The project ran the full loop, with a **human acceptance gate** closing each phase:

```
Black-Box Observation → Specification → Architecture → Incremental Implementation
   → Testing → Difference Analysis → Revision → Regression → Human Acceptance
```

The work is recorded increment by increment in [ai/changes.md](../changes.md)
(6,302 lines, 40+ increment-level `Accepted` markers). Phases:

| Phase | Window | Outcome | Commit |
|---|---|---|---|
| Week 1 — observation + specification freeze | to 2026-09-29 | `spec.md`, `spec/`, `evidence/`, `dataset/` frozen | `46f6ebe`, calibrated `b5dcf4d` |
| Weeks 2–4 — incremental implementation | 2026-09 → 2026-10-05 | Feature slice implemented; W4I12 gate | `5ec0803` |
| Phase 1 — behavioral acceptance | 2026-10-09 | T01–T20 = 20/20 behavioral PASS, Human Accepted | `f5533b3` |
| Phase 1.1 — fixes (B-01 / B-02 / G-01) | 2026-10-18 | Detail-page actions, original-image viewer, detector area gate | `de58eee` |
| Phase 2A — documentation traceability | 2026-10-19 | Compliance matrix, gap list, change ledger, this report set | `bdac7b0` |
| Phase 2A-2 — physical-device bugfixes | 2026-10-23/24 | PD-B01 dark-flash fix + PD-B02 scan-entry toolbar fix; user-reported device validation | `9c994c2` (code) + `a12492e` (validation record) |

Git and human review are structural, not incidental: each increment ended without a
commit until a human `Accepted` the record, and AI was never allowed to commit, merge
or tag on its own.

### 2.2 Specification process — direct Markdown SDD, not an OpenSpec CLI workflow

This project maintained its specification **directly**: a hand-written `spec.md` plus
`spec/` artifacts (reference environment, page inventory, state inventory, data model,
T01–T20 reference tests), tracked and versioned by Git, with a contemporaneous change
log and test evidence. It did **not** use an OpenSpec CLI workflow: no OpenSpec
*Proposal*, *Delta Spec* or *archive* operation ever existed, and none is claimed.

Change control was exercised through the
[spec-change-ledger.md](./spec-change-ledger.md) (SCL-01 … SCL-13), which separates
**"fixing code to match a frozen spec"** (not a specification change) from **editing
the specification itself**. Across the whole project there was exactly **one** true
functional-requirement specification-content edit — **SCL-01**, inside the Week 1
closeout, before the freeze was final. All later SCL entries are either calibration
of non-normative wording (e.g. SCL-10 actor-reentrancy wording), evaluation
corrections (SCL-03 repository-ordering un-freeze traceability, SCL-09 dataset
image-ID permutation), or implementation records.

### 2.3 What preserved the specification's integrity

- **Append, do not rewrite.** Historical records kept their original dates, baseline
  commits, blockers and test counts; later changes were marked as later. The Phase
  1.1 notes were appended to `ai/changes.md`, never substituted for the earlier text.
- **Record provenance.** Each ledger entry is tagged *contemporaneous* or
  *retrospective*, so that a decision made at the time is not confused with a
  conclusion reconstructed afterwards from the repository.
- **Phase-level acceptance is phase-level.** "Accepted — 2026-10-09" and
  "Accepted — 2026-10-18" are cited as *phase* scopes; they are never presented as
  individual per-requirement approvals, because no such per-test human decision exists
  in the repository.

---

## 3. System Architecture and Implementation

The application source (`SimCamCard/`) is organised by concern. The map below is the
actual layout (see [README.md](../../README.md) and the source tree):

| Layer | Directory | Representative types | Why this layer exists |
|---|---|---|---|
| Composition root | `App/` | `SimCamCardApp` | Single place where repositories, image store and contact exporter are constructed and injected — dependency injection kept out of view models |
| Domain model | `Model/` | `BusinessCard`, `PhoneNumber`, `CardRegion` | Foundation-only, UI-framework-free; image fields are `String` reference tokens, not `UIImage` |
| Repository | `Repository/` | repository protocols + in-memory + file implementations | View models depend on the protocol, never on a concrete store |
| Persistence | `Persistence/` | JSON snapshot schema (`schemaVersion 1`) | Stable on-disk encoding, decoupled from the domain shape |
| Imaging | `Imaging/` | image-asset store protocol + actor implementation | One owner of image bytes; domain keeps only references |
| Camera | `Camera/` | `actor CameraSessionController` (+ dedicated serial execution context; Debug fakes) | AVFoundation lifecycle is expensive/blocking and must not run on the main actor |
| Detection | `Detection/` | `CardRegionDetector` (Vision rectangles) | Isolates Vision from the crop/geometry logic |
| Crop | `Crop/` | `CardRegionGeometry` (`minimumDetectedArea`), `CardCropProcessor` | Deterministic geometry + Core Image correction behind one seam |
| OCR | `OCR/` | `CardOCRProcessor` (Swift-native `RecognizeTextRequest`) | Vision types stay behind the actor boundary; raw text preserved verbatim |
| Recognition | `Recognition/` | `CardFieldExtractor`, `RecognitionDraft`, `SaveState`, `BusinessCardMaterializer` | Deterministic parser and pure state/materialisation, no guessing |
| Edit | `Edit/` | `BusinessCardEditDraft` | Editing a *saved* card is a separate state machine from first-time recognition |
| Export | `Export/` | `SystemContactExporter` (`CNContactStore`/`CNSaveRequest`) (+ Debug fake) | Real system Contacts behind a protocol; denial/failure branches testable |
| Search | `Search/` | deterministic matcher | Case-insensitive contains + digit-normalised phone; presentation-only |
| View | `View/` | CardHolder, Scan, Crop, CardDetail, Group, Search, Debug views | Pure presentation; stable accessibility identifiers for UI tests |
| ViewModel | `ViewModel/` | `CardHolderViewModel`, `ScanViewModel` (`@MainActor @Observable`) | The single owner of UI state (one state, one owner) |

Navigation composition (final, post-PD-B02): the root is a `NavigationStack`
hosting the Card Holder; detail / search / groups push via `AppRoute` values.
The Scanner is entered through a **state-driven
`.navigationDestination(isPresented:)`** from a toolbar Button whose
`ToolbarItem` carries the stable identity `card-holder-scan-entry` — a standard
horizontal push. The scan subtree applies a view-local dark appearance
(`.environment(\.colorScheme, .dark)`), not a window-level one (§4.4).

### 3.1 Why these boundaries — isolating system dependencies and test side effects

- **Dependency injection at the composition root.** `SimCamCardApp` builds the
  disk-backed `FileBusinessCardRepository`, `FileCardGroupRepository` and
  `FileImageAssetStore` and injects them. This lets the same view-model code run
  against deterministic in-memory doubles in tests without any branch inside the
  view model.
- **Concurrency safety by construction.** The camera controller and the contact
  exporter are Swift `actor`s. `AVCaptureSession` creation/configuration/start/stop run
  on a **dedicated serial execution context**, never on the main actor, so camera
  startup cannot block the UI. Video-frame processing uses its own serial queue, and
  image decode / perspective correction uses a dedicated actor — keeping Swift 6
  strict concurrency honest without `@unchecked Sendable`.
- **Protocolised system seams.** Camera permission, OCR, Vision detection and system
  Contacts are each reached through a seam, so the permission-denied, load-failure and
  export-denial paths can be driven deterministically. Crucially, the *real* system
  integration path is still exercised where it can be (e.g. the two real Contacts
  integration tests, see §4).
- **One owner per state family.** Recognition state (`inactive` / `processing` /
  `structuredResultAvailable` / …), save state (`idle` / `saving` / `saveSucceeded`)
  and card-region state are separate, explicitly owned state families — so a
  "save succeeded" can never masquerade as "recognition succeeded".
- **DEBUG hooks are Release-absent.** Test fixtures and capture hooks exist only under
  Debug and are audited out of the Release binary (§4.3).

---

## 4. Deterministic Functional Verification

Deterministic functions (UI, navigation, state transitions, persistence, editing,
deletion, search, tags, export — assignment §5.1) require **100% of the Reference Test
Suite to pass**. All figures in this section are **historical records**, not re-runs.

### 4.1 T01–T20 behavioral acceptance

- **20 / 20 behavioral PASS** — baseline `5ec0803` (2026-10-05); **Human Accepted —
  2026-10-09 (phase-level)**, `f5533b3`; carried through Phase 1.1 (`de58eee`,
  Accepted 2026-10-18). Source: [final-acceptance.md](../final-acceptance.md).
- Full per-test eleven-field rows and the three-dimension grading (traceability /
  verification coverage / reference fidelity) are in
  [final-traceability-matrix.md](./final-traceability-matrix.md) §5 and §10.

### 4.2 Gate figures on record

| Gate | Commit / date | Unit | UI | DEBUG-hook isolation | Builds |
|---|---|---|---|---|---|
| W4I12 | `5ec0803`, 2026-10-05 | 431 / 431 | 55 / 55 deterministic (+2 real Contacts run separately) | 13 / 13 | Debug + Release PASS |
| Phase 1.1 | `de58eee`, 2026-10-18 | 466 / 466 | **62 / 62 full UI regression, including 2 real Contacts integration tests (System01 / System02)** | 16 / 16 ABSENT (Release) / 16 / 16 PRESENT (Debug `.debug.dylib`) | Debug + Release PASS |
| Phase 2A-2 (post-bugfix) | `9c994c2`, 2026-10-23 | 466 / 466 | **2 / 2 PASS (ScanEntryUITests) + 27 BLOCKED (0 executed, simulator service failure) + 33 NOT RUN** — not a full-suite re-run | not re-audited (no DEBUG-hook change) | Debug PASS |

The 62 UI functions are 60 deterministic tests plus the 2 real Contacts integration
tests. The Phase 1.1 62/62 row is the **pre-bugfix historical baseline**; the
Phase 2A-2 row records what was actually executed on the final code. Hook isolation is audited with `strings -a` against the Release **main binary**
and the Debug **`SimCamCard.debug.dylib`** (under `ENABLE_DEBUG_DYLIB`, Debug code
lives in the dylib, not the main executable).

### 4.3 Correct handling of the nuanced items

- **T03 — camera permission.** Camera allow / deny / restricted map to defined states,
  denial is stable and never crashes, and the system dialog is not replicated. The
  three camera-permission UI tests are **DEBUG-fixture-driven** — the permission state
  is injected through the camera seam, and the denial screenshot
  (`2026-10-07-w4i12-camera-denied.png`) is labelled "(fixture)" in
  [final-acceptance.md](../final-acceptance.md). A real human tapping Allow/Deny in the
  **native** dialog was therefore **not independently exercised**. This limitation
  belongs to T03 itself and is **not** borrowed from any photo-library item.
- **T05 — photo-library import.** Import / cancel / load-failure outcomes are driven by
  DEBUG fixtures through the real `PhotosPicker` integration seam; a real user-initiated
  **cancel gesture inside the system PhotosPicker UI** was never exercised →
  **G-03**.
- **G-02 — photo-library authorization / platform semantics (separate item).** The
  assignment's §T03 "additional detailed checks" historically listing *photo library
  allowed / denied* is tracked as its **own item G-02**, distinct from T03 camera
  permission and from T05 import mechanics. Under iOS 27 the modern `PhotosPicker` runs
  out-of-process and requests no library authorization, so a "denied" state does not
  exist in the same sense; this is treated as a **platform-semantics** matter pending a
  ruling, **not** as an already-passed permission-denial test.
- **T07 — raw OCR text preservation.** The preservation *contract* is verified
  (verbatim top-1 lines, persisted `rawOCRText`, intermediates consumable for
  analysis). The CamCard **raw-text screen was never observed**, so the reference-side
  surface is `NOT OBSERVED` — a fidelity/observability gap, not a behavior failure.
- **T18 — persistence.** Cards, edited fields, groups/tags, notes and both the original
  and processed images survive a full terminate → relaunch cycle (file repositories,
  `schemaVersion 1`; namespaced UI-test storage). Simulator-scoped; physical-device
  persistence **NOT TESTED** (G-11).
- **T19 — Contacts export.** The real `CNContactStore.execute(CNSaveRequest)` path was
  exercised on the simulator (targeted `System01` / `System02` gates, run separately),
  with a real Contacts.app field check of name / company / title / phone / email /
  address. The fake permission/failure scripts plus unit tests cover all denial and
  failure branches. Known side effect: the two real tests mutate the simulator address
  book.
- **T20 — exception paths.** Two non-interchangeable layers: a deterministic DEBUG
  empty/no-card fixture drives state mapping and the save guard; a frozen real non-card
  PNG is run through the real production pipeline (→ `wasDetected = false`, 0 canonical
  fields). GT-synthetic regression is a **separate** parser layer.

---

### 4.4 Post-baseline physical-device bugfixes (PD-B01 / PD-B02, 2026-10-23/24)

After Phase 2A-2 documentation, two defects were found **on a physical iPhone**
(the simulator suites had not surfaced them) and fixed in commit `9c994c2`, with
the device-validation record committed as `a12492e`
([PD-B01-PD-B02-device-validation.md](../validation/physical-device/PD-B01-PD-B02-device-validation.md)).
Both are implementation fixes against the frozen specification — no spec change.

- **PD-B01 — dark flash returning from the Scanner.** The scan views used
  `.preferredColorScheme(.dark)`, a window-level modifier whose preference
  lingered during the NavigationStack pop, flashing the Card Holder dark for one
  frame. Fix: view-local `.environment(\.colorScheme, .dark)` on the three scan
  views. **User-reported PASS** for the core symptom; other device scenarios
  remain NOT TESTED.
- **PD-B02 — "+" toolbar item clipped during the scan push.** The destination
  scan page hides its navigation bar, so the source bar's trailing item had no
  transition target. Failed attempts — a transparent bar with
  `.ignoresSafeArea` (a blocking safe-area regression on device), a
  `fullScreenCover` (removed the clip but changed the entry animation to a
  vertical sheet), conditional removal of the Button (residual clip persisted) —
  are recorded in the validation document. Final fix: state-driven
  `.navigationDestination(isPresented:)` with a stable ToolbarItem identity and
  an always-present Button, keeping the horizontal push. **User-reported PASS**
  for the core transition symptom.

Root causes above are code-level judgements supported by user observation —
**not** proven by UIKit-internal transition instrumentation (none exists in this
repository). Automated evidence on the final code is bounded: Debug Build PASS,
Unit 466/466 PASS, ScanEntryUITests 2/2 PASS; ScanCamera (24) and
ExceptionHandling (3) BLOCKED with 0 executed (simulator service failure); 33
other UI tests NOT RUN (§4.2).

## 5. Black-Box Reference and UI Fidelity

### 5.1 Reference observation

CamCard 8.63.1 was observed purely by normal use. The frozen observation evidence is
**40 reference screenshots** in [evidence/screenshots/](../../evidence/screenshots/)
with [evidence/image-manifest.md](../../evidence/image-manifest.md), captured on an
Apple Silicon Mac (M2) in iPhone/iPad-compatible mode. This is a **separate evidence
class** from SimCamCard's own simulator evidence and is not claimed to be
simulator-based.

### 5.2 P01–P11 dual-axis audit

Fidelity is graded on an axis **independent** of behavior; a behavior PASS never covers
a fidelity PARTIAL (source: [final-reference-audit.md](../final-reference-audit.md),
baseline `5ec0803`):

- **Behavioral Acceptance: 11 / 11 PASS.**
- **Reference Fidelity: P04 PASS; the other 10 pages PARTIAL.**
- Open real-blockers: **0**. No PARTIAL was silently flipped to PASS.

Each on-record SimCamCard verification screenshot lives under
[ai/validation/](../validation/) (55 PNGs, plus 4 dataset-integrity contact sheets).
The per-page dual-axis table is in
[final-traceability-matrix.md](./final-traceability-matrix.md) §6.

### 5.3 What the PARTIAL differences are — and what they are not

The classified differences fall into a small number of categories:

- **Platform-imposed system surfaces** — e.g. the iOS system Contacts UI has no
  account/destination selector; the system PhotosPicker surface is not
  App-controlled (P03, P11 diff-2/5).
- **Frozen-domain constraints** — e.g. the frozen Domain has no email/address *kind*,
  so both map to a generic label rather than fabricating a "work" label (P11 diff-3);
  the domain cannot represent CamCard's inline "capture card" summary row (P10).
- **Bounded / excluded scope** — CamCard's 综合/企业 segmented search surfaces are
  excluded by assignment §15 (P08).
- **Deferred cosmetic detail** — row chrome, success illustration, header/star/
  action-bar styling, etc. (P01, P06, P07, P09).

Therefore the delivered UI is **not** a claim of pixel-level 100% identity on every
page. It is behavioral equivalence on the required flows, with every surface difference
explicitly classified. Notably, T13-detail actions once classed as cosmetic
(tap phone / email / website, view original image) were **reclassified by the course
requirement** and implemented as **B-01 / B-02** (§8), and are marked FIXED.

### 5.4 UI Golden Test

- A **manual** visual comparison has been performed (40 REF vs 55 SimCamCard
  screenshots, P01–P11).
- There is **no automated image pixel/snapshot ("golden") assertion** in the repository
  (0; the strings matching "snapshot" are JSON persistence snapshots, not image
  goldens).
- Whether the instructor requires the **automated** form is **not stated** in the
  assignment text and remains a **pending human ruling** (**G-05**). The absence of an
  automated snapshot is not the absence of any golden/UI-comparison evidence.

### 5.5 Reference scope limitation

Real CamCard recognition was observed only for cards A/B/C (= card-001/002/003),
card-004 (minimal-behavior) and 1 non-card. **card-005–034 are `NOT OBSERVED`** —
no CamCard accuracy figure exists for the 34-card dataset beyond those, and none is
invented (**G-04**).

---

## 6. Probabilistic OCR Evaluation and Error Analysis

Probabilistic functions (assignment §5.2) are evaluated against the instructor-provided
fixed dataset with Ground Truth; the assignment requires the original AI output, the
structured results and a Ground-Truth comparison with error-cause analysis, all
preserved for review.

### 6.1 Test set and pipeline

- **Dataset:** 34 frozen business-card PNGs with 34 Ground-Truth records
  ([dataset/](../../dataset/)), fitting the assignment §14 recommendation of
  ~30–50 cards with Ground Truth. A separate T20 non-card fixture is counted
  separately.
- **Real pipeline evaluated:** `CapturedPhoto → CardCropProcessor.prepare` (Vision
  rectangle detection, area-gated) `→ perspectiveCorrect` (Core Image)
  `→ CardOCRProcessor.recognize` (Swift-native `RecognizeTextRequest`, `.accurate`,
  auto-language, correction off) `→ CardFieldExtractor.extract` (deterministic parser).
- **Harness:** env-gated `TEST_RUNNER_REAL_VISION_EVAL=1`; skipped in the deterministic
  unit baseline, so the probabilistic run never pollutes the 466-test deterministic
  result. Artifacts: [ai/evaluation/real-vision-34/](../evaluation/real-vision-34/)
  (`summary.md`, `environment.md`, `comparison.csv`, `raw-ocr.jsonl`,
  `structured-results.jsonl`, before/after payloads).

### 6.2 OCR vs field parsing — kept separate

The raw Vision output and the deterministic field parser are measured as different
layers: 316 raw OCR lines, 0 zero-line cards, 0 pipeline errors (after run); extractor
conditional accuracy on ground-truth-anchored raw text is 164/219 (74.9%).

### 6.3 Headline result

- **Present-field match rate: 164 / 233 = 70.4%** (after the G-01 gate).
- **Pre-gate baseline: 109 / 233 = 46.8%** (same harness / GT / normalization).

Per-field after-run (present denominator): name 28/34 (82.4%), company 15/20 (75.0%),
jobTitle 28/33 (84.8%), address 11/31 (35.5%), mobile 19/32 (59.4%), office 8/23
(34.8%), fax 2/4 (50.0%), email 29/31 (93.5%), website 24/25 (96.0%).

> **70.4% is a *present-field match rate*** — matches over cells where Ground Truth is
> non-null — using `compact`/`digits` normalization. **It is not a character-level OCR
> accuracy figure**, and it is **not** a direct CamCard-vs-SimCamCard comparison.
> No character-level metric is claimed anywhere.

### 6.4 Error-cause attribution

The 69 non-matching present cells split as **4 detector/crop · 10 OCR recognition ·
55 extractor**. The dominant cause is the deterministic field parser attaching a value
to the wrong field or missing a present field — not Vision failing to read text. A
second, diagnostic-only full-image OCR pass (never scored) exists precisely to separate
detector/crop causes from OCR-recognition causes.

### 6.5 No fabricated fields

GT-absent cells (73) use four **mutually exclusive** buckets, with the identical
definition applied before and after:

| Bucket | Before | After |
|---|---|---|
| strict canonical absence correctness | 68 | **64** |
| alternate-language exact match | 3 | **7** |
| alternate-language partial match (marked PARTIAL, never counted as exact) | 2 | **2** |
| genuine fabrication | 0 | **0** |

**Genuine fabrication is 0 in this dataset and this evaluation run** — GT-absent fields
were never filled with values lacking any Ground-Truth alternate-language overlap. This
is a measured fact for this specific frozen dataset, not a universal correctness
guarantee. Partial overlaps such as `BioSystems` / `Stonepine BioSystems` are always
marked PARTIAL.

### 6.6 G-01 fix, before and after

G-01 was a detector defect: Vision rectangle detection locked onto a small decorative
quad in the top-left of some cards, auto-accepting a crop that contained no text. The
fix was an **area gate** (`CardRegionGeometry.minimumDetectedArea = 0.05`, SCL-11,
`de58eee`) applied only in the auto-accept branch of `CardCropProcessor.prepare()` —
correctly-cropped cards sit at 0.47–0.93 while mis-locked ones were 0.007–0.024, a
>10× separation. After the gate: detection accepted 33→19, fallback 1→15, zero-OCR-line
cards 14→0, pipeline errors 2→0, present-field match 109→164.

### 6.7 Evaluation timeline (three dates, honestly recorded)

- **Measurement / generation date: 2026-10-15** (`summary.md` header
  "Generated: 2026-10-15"; `environment.md` run date `2026-10-15T04:45:25Z`).
- **Repository / revision date: 2026-10-18** (`de58eee`; the directory does not exist
  at `5ec0803` or `f5533b3`).
- **Phase 1.1 Accepted date: 2026-10-18** (same commit; phase-level).

Two payload files are stored side by side (`_eval-payload.json` after-gate;
`_eval-payload-pre-gate-baseline.json` pre-gate); `environment.md` states the pre-gate
baseline was produced by temporarily reverting and restoring the gate. **The number of
actual runs and the config-switch timing are not separately logged and are not
inferred.**

### 6.8 Recorded capability limits

- Real numerals left unlabelled are honestly typed `.other` when no label is present:
  the evaluation reports **30** `kind_misclassification` events (unlabeled → `.other`),
  reported as-is.
- Low address (35.5%) and office-phone (34.8%) match rates reflect genuine label
  ambiguity in the real dataset, not a hidden success claim.
- Two pinned GT-parser exceptions remain documented (card-019 マネージャー, card-030
  "UX Researcher"); typed-layer regression is 34/34 with 0 false positives.

---

## 7. AI Capability Boundaries and Human-in-the-loop

### 7.1 The five assignment §8 boundaries — case by case

Assignment §8 requires examining five situations. They are **not** uniformly evidenced;
the honest result is **3 directly evidenced + 2 PARTIAL** (full per-case table with test
functions, fixtures, results, evidence paths and "cannot prove" notes is in
[final-traceability-matrix.md](./final-traceability-matrix.md) §4.1).

| §8 case | Verdict | What was actually shown | Boundary of the evidence |
|---|---|---|---|
| Field ambiguity (e.g. `Apple` → company? product? address?) | **PARTIAL** | Labelled fixtures classify deterministically; **unlabelled values are never guessed** (honest `.other`) | The assignment's literal example tokens are not used as card fixtures; evidence is *analogous*, not the assignment's own wording |
| Name ↔ company confusion (e.g. `Jordan Lee` / `Lee Consulting`) | **PARTIAL** | Name and company land in separate fields; native-language side kept, Latin counterpart left `unclassified` — no cross-assignment | No dedicated **same-token** ambiguity fixture exists; risk is reduced by label logic, not proven against a deliberately ambiguous pair |
| Multiple phones (mobile / office / fax) | **PASS** | GT multi-phone regression **23/23**; UI fixture shows Mobile/Office/Fax rows simultaneously; bare `1[3-9]`→mobile, other bare→`.other` | Does not claim unlabelled real-world numbers are always typed correctly (30 `kind_misclassification` recorded) |
| Mixed Chinese / English | **PASS** | Bilingual name/company kept on the native side, Latin counterpart retained in unclassified text; real Vision smoke over bilingual/English frozen cards | Not a per-language accuracy claim; no character-level bilingual metric |
| Missing fields must not be fabricated | **PASS** | Absent website stays `nil`; email domain never promoted to a website; empty OCR → all-empty result without error; UI omits the absent row; real eval **0 genuine fabrication** across 73 GT-absent cells | Proves absence-handling for the tested fields, not an exhaustive enumeration of every conceivable fabricated field |

The governing principle — *"a reasonable guess may itself be a software error"*
(assignment §8) — is implemented as: fields that cannot be reliably determined stay
`nil`, and unlabelled numbers are typed `.other` rather than guessed.

### 7.2 Human-in-the-loop

AI output is never saved directly. The workflow is AI recognition → structured fields →
user verification → manual correction → confirmation → save (assignment §9), and the
implementation provides: manual crop adjustment and confirmation; per-field
verification and correction in an editing draft that preserves the original recognition
(`RecognitionDraft.source`); handling of empty fields, multiple phones/emails, OCR
spelling errors and cancellation of modifications; and a save guard that refuses to
save a card with no usable fields. Corrections replace extracted values while the
original recognition remains immutable.

---

## 8. AI-assisted Development and Human Review

The collaboration record is [ai/changes.md](../changes.md). The six cases below are
representative of where AI output was wrong, how it was located, how human review
decided, how it was fixed and how it was regressed.

### 8.1 Specification constraint vs implementation (required image references)

In the first increment the AI made `originalImageReference` /
`processedImageReference` **optional** to avoid depending on the camera pipeline —
which violated the frozen `spec/data-model.md` **Required** invariant. Human review
required non-optional `String` references; the model, fixtures and tests were updated
and regression-tested. (Source: [ai/changes.md](../changes.md#L206-L247); SCL-02,
`6fa0910`.) This is the canonical case of the project rule: *fix the implementation,
not the specification*.

### 8.2 Camera-session concurrency architecture

The AI initially placed the camera-session lifecycle on `MainActor`, conflicting with
Apple's guidance that `startRunning()`/`stopRunning()` are blocking. Review moved
`CameraSessionController` to an **actor with a dedicated serial execution context**,
and a second review caught the AI mis-reporting an initial start failure as `.preview`
— corrected to `CameraSessionError.startFailed` with an `async throws` start and a
deterministic failure test. (Sources: [ai/changes.md](../changes.md#L1263-L1305),
[#L1308-L1362](../changes.md#L1308-L1362); SCL-04, SCL-05.)

### 8.3 Dataset image-ID permutation, losslessly corrected

A dataset-integrity audit found **eight** card PNGs assigned to incorrect card IDs (a
closed permutation in the 005–014 range): the image *bytes* were correct, only the
path↔content mapping was scrambled. The AI's first instinct to "fix" the dataset by
moving files was rejected in favour of a **lossless permutation** through a temporary
directory — avoiding the `mv`-overwrite data-loss risk of naive chained moves. After
correction the **SHA-256 multiset is identical**, and contact sheets were regenerated
and human-verified. (Source:
[dataset/revisions/2026-10-02-image-id-permutation.md](../../dataset/revisions/2026-10-02-image-id-permutation.md);
SCL-09, `df334f5`→`7c031a7`→`e68f7c1`.) A separate **pre-existing** mismatch (the shipped
`card-013` PNG ↔ `card-013` GT disagreement) was reported and **deliberately not
modified**.

### 8.4 Swift `actor` reentrancy misconception

The AI had written a comment claiming "the actor serializes access to at most one active
recognition". This is false: Swift actors are **reentrant across `await` points**, so
actor isolation alone does not prevent overlapping `perform` calls. Review removed the
false claim and added a generation guard plus a deterministic
`staleACannotOverwriteNewerB` test (gated continuations, no sleeps). (Sources:
[ai/changes.md](../changes.md#L2288-L2316); SCL-10, `b0404e2`.)

### 8.5 G-01 detector mis-attribution

The AI's first diagnosis of the recognition failures was not the true cause. Analysis
showed the *detector* was auto-accepting tiny decorative quads (area 0.007–0.024)
rather than a Vision recognition defect, and a diagnostic full-image OCR pass recovered
every failing sample. The fix was the area gate (§6.6). This case is the project's
clearest example of **not accepting the first attribution**: the wrong root cause would
have led to tuning OCR instead of the detector.

### 8.6 B-01 / B-02 missing detail-page features

Review found two course-required detail-page behaviors that the implementation had left
out (they had been mis-filed as "cosmetic" surface differences): **B-01** — tapping
phone / email / website rows to invoke the native system action; **B-02** — viewing the
original card image. Both were implemented in Phase 1.1 (`de58eee`): B-01 added
`CardDetailURLMapping` (`tel:` / `mailto:` / safe `https://`, invalid or missing values
return `nil` and trigger no call) plus a DEBUG-only URL-capture hook so UI tests assert
the *initiated* URL; B-02 added a `fullScreenCover` viewer reusing the existing
`ImageAssetStore` (no second image data owner) with a thumbnail → full-screen → close
E2E both after save and after terminate/relaunch. (Source:
[ai/changes.md](../changes.md#L6247-L6260); SCL-12, SCL-13.)

### 8.7 Where AI was reliable, and where it was not

- **Reliable:** producing well-structured SwiftUI/Swift code, scaffolding tests, and
  mechanical refactors once the interface and scope were pinned down.
- **Unreliable:** implicit assumptions about concurrency and framework semantics
  (main-actor-blocking calls, actor reentrancy), attribution of a failure to the wrong
  layer, silently relaxing a frozen invariant "to make it work", and dataset/file
  operations that risk irreversible loss. Review also caught a **wrong preconception
  in a comment** (the reentrancy claim) that would have misled later readers.

### 8.8 Prompt archive — honest limitation

The original **verbatim prompts are not documented**: the prompt archive directory
(`ai/prompts/_local/`) is empty, and no verbatim prompt log exists. The collaboration
record consists of the increment-by-increment *outcomes* and decisions in
`ai/changes.md`, plus the process rules in `ai/README.md`. This is stated as a
limitation (**G-08, NOT DOCUMENTED**) rather than reconstructed.

---

## 9. Limitations, Reproduction and Conclusion

### 9.1 Limitations and open items (by status)

Full status is maintained in
[final-traceability-matrix.md](./final-traceability-matrix.md) §9 and
[final-gap-list.md](./final-gap-list.md).

- **Reference Fidelity PARTIAL (P01–P11).** Behavior passes on all eleven pages; ten
  pages carry an honest, *classified* surface gap (§5.3). Not a pixel-level 100% claim.
- **G-02 — photo-library authorization / platform semantics.** Under iOS 27 the modern
  picker requests no library authorization; a "denied" state does not exist in the same
  sense. `NOT TESTED` on the device path; a **pending human decision**.
- **G-03 — real system PhotosPicker cancel gesture.** Fixture-level cancel is proven;
  the real gesture is `NOT VERIFIED` → **pending**, one short manual capture away.
- **G-04 — CamCard card-005–034.** `NOT OBSERVED`; no invented accuracy. **Pending**;
  whether to supplement with captures versus bound the scope is a ruling, and it is
  **not** inferred that re-capture is forbidden.
- **G-05 — UI Golden Test form.** Manual comparison done; automated snapshot absent;
  automated-form requirement **pending a ruling**.
- **G-06a/b/c — recorded technical debt.** Orphan-image GC, non-throwing repository
  behavior, and corrupt-JSON recovery. These are **DOCUMENTED DEBT** — recorded in the
  delivery documents, **not fixed**, and not required by the frozen acceptance.
- **G-08 — original prompt archive missing.** `NOT DOCUMENTED` (see §8.8).
- **G-10 — final demonstration artifact.** **PENDING / not produced.** The course
  delivery has not yet taken place; this is *not* an "overdue-and-missing" item.
- **G-11 — physical-iPhone verification.** **PARTIAL — USER-REPORTED**: a
  2026-10-23 device session verified the PD-B01/PD-B02 core transition symptoms
  (§4.4). All other device scenarios (persistence, PhotosPicker cancel,
  capture→save reload, backgrounding, system appearance modes) remain **NOT
  TESTED**; the status cannot be upgraded to full PASS without explicit
  per-scenario testing.
- **G-12 — Contacts export surface differences.** Classified as a
  **DOCUMENTED PLATFORM DIFFERENCE** (diff-1..5: denied-page vs alert, macOS account
  selector, label mapping to a generic label, website deliberately not exported,
  macOS/Catalyst Contacts UI). **No explicit human-acceptance record exists**, so it is
  not presented as "approved".
- **B-01 system external-app handoff.** The *initiated* URL is proven via the DEBUG
  capture hook; the final takeover by the system phone / mail / browser apps is
  **NOT TESTED** on the simulator.

Status vocabulary used here is deliberately distinct: **FIXED** (gap closed, evidence
cited) · **DOCUMENTED DEBT / DOCUMENTED PLATFORM DIFFERENCE** (documented, not fixed /
not approved) · **NOT TESTED** · **NOT OBSERVED** · **PENDING HUMAN DECISION**.

### 9.2 Reproduction entry points

Build and test entry points are recorded in [README.md](../../README.md) and are
reproducible:

```bash
# Debug / Release build (simulator)
xcodebuild build -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -configuration Debug
xcodebuild build -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -configuration Release

# Deterministic unit suite (Swift Testing) — serial
xcodebuild test -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardTests -parallel-testing-enabled NO

# Full UI suite (includes the 2 real Contacts integration tests)
xcodebuild test -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardUITests -parallel-testing-enabled NO

# Real Vision OCR evaluation (opt-in, env-gated — never pollutes the deterministic baseline)
TEST_RUNNER_REAL_VISION_EVAL=1 xcodebuild test \
  -scheme SimCamCard -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardTests/RealVision34EvaluationTests -parallel-testing-enabled NO
python3 tools/assemble_real_vision34.py
```

Before assembling, the harness must print `[real-vision-34] cards=34 comparisonRows=306`
(this is the harness' own line, immediately before the EVAL-JSON marker). The assembler
overwrites the evaluation artifacts; back up the directory first if the archived results
matter. Known side effect: the 2 real Contacts tests are stateful against the simulator
address book.

### 9.3 Submission constraints

- **Known course-submission information:** deadline **2026-11-08 23:59 (Beijing time)**;
  **Canvas final submission = 1 file.** These are recorded as known course-delivery
  facts.
- The **assignment text does not** specify a particular ZIP type, a size limit, or a
  recording format for the final demonstration; any such Canvas-specific limit remains
  **unverified / to be confirmed**. No packaging artifact is produced in this step.

### 9.4 Conclusion

SimCamCard is a **bounded black-box replication** of the CamCard
Business-Card-Digitization slice, developed through a direct-Markdown SDD loop with
Git, a contemporaneous change log and test evidence, and a human acceptance gate at
every phase. On the deterministic side, all 20 required scenarios pass and the
incremental UI/unit gates are green at their recorded baselines (Phase 1.1
historical baseline: Unit 466/466, UI 62/62, hook isolation 16/16, Debug/Release
PASS). On the **final** code (`9c994c2`), Unit is re-verified at 466/466 and the
scanner-entry UI tests re-pass 2/2, while the remaining UI suites were not
re-run in full (27 BLOCKED by a simulator service failure, 33 NOT RUN — §4.2);
two physical-device defects (PD-B01/PD-B02) were additionally found and fixed
with user-reported core-symptom confirmation (§4.4). On the probabilistic side, the real Vision pipeline reaches
a **70.4% present-field match rate** against Ground Truth on the frozen 34-card dataset,
with **0 genuine fabrication** — reported as a field-level match rate, not a
character-level OCR accuracy, and not a direct CamCard comparison. Reference fidelity is
honestly **PARTIAL** on ten of eleven pages, with every difference classified by cause.

The project's central lesson, which the evidence supports, is that AI can generate code
and extract information quickly, but its output is probabilistic, may drift from a frozen
specification, and may mis-attribute a failure to the wrong layer — so **every AI change
was required to pass tests and human review before acceptance**. The residual gaps
(platform semantics, an un-exercised real picker gesture, unobserved reference cards, an
unverified physical device, and a documented technical-debt list) are named rather than
concealed, and none is presented as resolved where evidence is absent.
