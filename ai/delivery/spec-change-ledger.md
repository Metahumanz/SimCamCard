# SimCamCard — Specification Change Ledger

Retrospective traceability ledger for specification interpretations, architectural
corrections, implementation fixes, evaluation corrections, and human decisions that
actually occurred during SimCamCard development.

- **Status:** Phase 2A-2 / Step 1 deliverable. Pending Human Review.
- **Document date:** 2026-10-19.
- **Nature of this document:** **retrospective reconstruction**, assembled after the
  fact from existing contemporaneous records. It is **not** an OpenSpec Proposal,
  **not** a Delta Spec, and **not** a record of having used the OpenSpec CLI.
  SimCamCard never used an OpenSpec tooling workflow; the required SDD loop
  (Specification → Architecture → Implementation → Test → Difference Analysis →
  Revision → Regression) was run directly, with `ai/changes.md` and Git commits as
  the primary evidence.

---

## 1. Purpose and Scope

### 1.1 Purpose

This ledger answers, per change: *where did the requirement come from; what
changed in spec or observable behavior; why; who approved it; where is the code,
test, and evidence; and how was it archived.*

It exists to make the following provable from repository evidence alone:

- The original requirement or specification source for each change.
- Whether a change was **fixing code to conform to an already-frozen
  specification**, or **actually modifying the specification itself**.
- Whether each change was reviewed by a human and how that decision is recorded.
- Which code, test, and evidence artifacts verify the result.

### 1.2 Scope

**In scope:** changes that affected observable behavior, specification
interpretation, architectural constraints, or acceptance criteria, plus their
verification and human decisions.

**Out of scope:** routine feature increments with no interpretive change; the full
increment-by-increment development log (that lives in
[ai/changes.md](../changes.md) — this ledger cites and summarizes, it does not
duplicate).

### 1.3 Explicit non-claims

- No OpenSpec Proposal, Delta Spec, or archive action existed at any time.
  Repository-wide search for `openspec` / `delta-spec` / `.opsx` artifacts returns
  **zero** results.
- No prompt-level archive exists: `ai/prompts/_local/` is **empty**. Prompt text is
  therefore **NOT DOCUMENTED** and cannot be retroactively reconstructed.
- Testing figures quoted here carry their measured date and commit. They are
  **historical** results, not re-executions performed while writing this document.

---

## 2. Source of Truth and Historical Baselines

### 2.1 Priority order (inherited from [SDD-README.md](../../SDD-README.md))

1. `assignment/` — immutable instructor source.
2. [spec.md](../../spec.md) and [spec/](../../spec/) — derived SDD baseline.
3. [evidence/screenshots/](../../evidence/screenshots/) — immutable black-box observation.
4. [dataset/](../../dataset/) — frozen test cards and Ground Truth.

### 2.2 Verified baselines (SHAs confirmed to exist in this repository)

| Baseline | SHA | Date | Role |
|---|---|---|---|
| Week 1 SDD freeze | `46f6ebe` | 2026-09-29 | Frozen spec + dataset + evidence baseline |
| Week 1 closeout calibration | `b5dcf4d` | 2026-09-29 | Final spec-status/scope calibration (see SCL-01) |
| Week 3 baseline merge | `dcd2fda` | 2026-10-02 | Camera/crop/OCR chain merge |
| Week 4 Increment 12 (T20 + acceptance sweep) | `5ec0803` | 2026-10-05 | `final-acceptance.md` / `final-reference-audit.md` baseline |
| Phase 1 final acceptance | `f5533b3` | 2026-10-09 | T20 exception handling + final acceptance |
| Phase 1.1 fixes | `de58eee` | 2026-10-18 | B-01 / B-02 / G-01 fixes + 34-card re-evaluation |
| Phase 2A-1 documentation audit | `bdac7b0` | 2026-10-19 | README / SDD-README / delivery-doc refresh |

**HEAD at time of writing:** `bdac7b0cb5194401031099e0b4e78e3c72dda148`, branch
`week4/structured-recognition`, working tree clean.

### 2.3 Frozen-surface integrity (verified)

- `git diff --name-only f5533b3..HEAD -- spec.md spec/ dataset/ evidence/ assignment/`
  → **empty**. The frozen surface was untouched across Phase 1.1 and Phase 2A-1.
- `git log -- spec.md` / `git log -- spec/`: the **last** modifications were
  `b5dcf4d`, `bc9a517`, `8cff0bf` — all dated **2026-09-29**. Of these, `b5dcf4d`
  is the Week 1 closeout **functional-requirement** calibration (SCL-01), while
  `bc9a517` / `8cff0bf` are **reference-environment record** updates
  (`spec/reference-environment.md`, Swift 6 language mode) — environment records,
  not functional-requirement edits. **No spec or spec/ change occurred during
  Weeks 2–4 or Phase 1.1.**

---

## 3. Change Classification Rules

### 3.1 Categories

| Category | Definition |
|---|---|
| **Specification Clarification** | A specification interpretation was made explicit, or the spec text itself was calibrated. Includes resolving cases where the implementation had silently weakened a frozen requirement. |
| **Behavioral Change** | Observable app behavior changed (what the user sees or can do). |
| **Implementation Fix** | Defect fixed so code conforms to an **already-frozen** requirement. The specification is not modified. |
| **Architecture Correction** | Internal design (ownership, concurrency, layering) changed without changing the frozen external contract. |
| **Evaluation Correction** | Test asset, dataset mapping, or evaluation methodology corrected. No product behavior change. |

### 3.2 The key distinction required by this ledger

> **Fixing code to satisfy an existing frozen specification is NOT a spec change.**
> Only edits to [spec.md](../../spec.md) / [spec/](../../spec/) content, or an explicit
> reinterpretation of a frozen requirement, qualify as Specification Clarification.

Applying this rule across the specification timeline:

- `46f6ebe` (2026-09-29) — Week 1 **initial freeze**.
- `b5dcf4d` (2026-09-29) — Week 1 **closeout calibration**: the only
  **functional-requirement** specification calibration on record (SCL-01), still
  inside the Week 1 closeout.
- `bc9a517`, `8cff0bf` (2026-09-29) — Week 1 **reference-environment record**
  updates only (`spec/reference-environment.md`, Swift 6 language mode). These are
  environment records, not functional-requirement specification edits, and are not
  counted as specification changes.
- Weeks 2–4 and Phase 1.1 — **no frozen-specification content modification found**
  (`git log -- spec.md spec/` shows no modification after 2026-09-29).

Every other entry in this ledger either fixes code to meet the frozen spec, changes
observable behavior within the frozen contract, corrects
architecture/test/evaluation, or records a clarification that was already implied
by the frozen text.

### 3.3 Significance tiers

- **Tier 1 (significant):** changes to observable behavior, architecture, the true
  spec text, or acceptance criteria. Full 12-field record below.
- **Tier 2 (contract/traceability corrections):** corrections to tests, wording, or
  traceability with no observable behavior change. Tier 2 entries keep the same
  12-field structure as Tier 1; their per-field content is more concise.

### 3.4 Record provenance

- **Contemporaneous** — the record was written at the time of the change, inside
  `ai/changes.md` or the commit itself.
- **Retrospective** — the record was assembled later from contemporaneous evidence.
  This entire document is Retrospective; individual entries note whether their
  underlying evidence is contemporaneous.

---

## 4. Chronological Change Index

| ID | Date | Title | Category | Tier | Related commit |
|---|---|---|---|---|---|
| SCL-01 | 2026-09-29 | Week 1 SDD baseline freeze calibration (true spec edit) | Specification Clarification | 1 | `b5dcf4d` |
| SCL-02 | 2026-09-29 | Required image references enforced at compile time | Specification Clarification | 1 | `6fa0910` |
| SCL-03 | 2026-09-29 | Repository `allCards()` ordering unfreeze + T12/T17 traceability | Evaluation Correction | 2 | `d2c477e` * |
| SCL-04 | 2026-09-30 → 10-01 | Camera session concurrency: MainActor-owned design superseded | Architecture Correction | 1 | `eeefbbe` |
| SCL-05 | 2026-10-01 | Initial camera-session start failure contract | Behavioral Change | 1 | `eeefbbe` |
| SCL-06 | 2026-10-01 | Vision aspect-ratio semantics + configure rollback + orientation wording | Specification Clarification | 2 | `db0cc90` * |
| SCL-07 | 2026-10-01 | Crop confirmation interaction freeze + P04 edge-midpoint calibration | Specification Clarification | 2 | `68d242c` * |
| SCL-08 | 2026-10-01 | Photo-import presentation-binding + contract corrections | Implementation Fix | 2 | `08745a4` * |
| SCL-09 | 2026-10-02 | Dataset image-ID permutation correction | Evaluation Correction | 1 | `df334f5` → `7c031a7` → `e68f7c1` |
| SCL-10 | 2026-10-02 | Swift actor reentrancy wording correction | Specification Clarification | 2 | `b0404e2` |
| SCL-11 | 2026-10-18 | G-01 Vision detector area gate + sub-threshold fallback | Behavioral Change | 1 | `de58eee` |
| SCL-12 | 2026-10-18 | B-01 detail-page phone / email / website tap | Behavioral Change | 1 | `de58eee` |
| SCL-13 | 2026-10-18 | B-02 original-card viewer in detail page | Behavioral Change | 1 | `de58eee` |

\* **Commit attribution confidence:** `d2c477e`, `db0cc90`, `68d242c`, `08745a4`
carry pre-Accept corrections that were **folded into the increment commit and not
separately committed** (the `ai/changes.md` correction entries for this period
record that no independent commit was made). Attribution is by increment and date,
**not independently re-verified** at the byte level. Entries without this marker
were verified directly against the committed tree.

---

## 5. Detailed Significant Changes

### SCL-01 — Week 1 SDD baseline freeze calibration

1. **Change ID:** SCL-01
2. **Title:** Week 1 SDD baseline freeze calibration (status, dataset scope, §12 re-scope)
3. **Category:** **Specification Clarification — the only true functional-requirement
   spec-content edit on record** (made inside the Week 1 closeout itself; see §3.2).
4. **Original requirement / spec reference:** [spec.md](../../spec.md) §11 Test Dataset, §12 Open Items, header status line.
5. **Problem / reason:** After the initial freeze (`46f6ebe`), the spec header still
   read `Status: Week 1 Draft`, §11 described only a three-card synthetic baseline
   ("must be expanded to approximately 30–50 cards"), and §12 was titled
   "Open Items Before Week 1 Freeze". The actual frozen dataset had already become
   34 cards + Ground Truth. Week 1 closeout calibration aligned the spec text with
   the frozen reality.
6. **Before / After behavior (spec text):**
   - Header: `Status: Week 1 Draft / Black-Box Observation Baseline` → `Status: Frozen — Week 1 SDD Baseline`.
   - §11: "Card 001–003 … only the first three cards; dataset must be expanded"
     → "34 synthetic samples `card-001`…`card-034` + 34 Ground Truth records + a
     separately-counted T20 non-card fixture".
   - §12: "Open Items Before Week 1 Freeze" → "Known Follow-up / Future Verification"
     (T03, T07, T15, T20, physical-iPhone items re-framed as **future** verification,
     explicitly "do not affect the Week 1 freeze").
7. **Scope and affected files:** [spec.md](../../spec.md),
   [spec/reference-environment.md](../../spec/reference-environment.md),
   [dataset/README.md](../../dataset/README.md), [README.md](../../README.md),
   [SDD-README.md](../../SDD-README.md), [ai/changes.md](../changes.md).
   (`simplified .gitignore` + a scheme plist also in the commit.)
8. **Related implementation commit:** `b5dcf4d` (2026-09-29).
9. **Verification tests and evidence:** Documentation-only change; no test
   executed. Fork/verification: `git show b5dcf4d -- spec.md` is the primary
   artifact. Later environment syncs: `bc9a517`, `8cff0bf`
   (`spec/reference-environment.md`, Swift 6 language mode).
10. **Human Decision / Status:** Recorded as Week 1 closeout calibration.
    **Accepted — 2026-09-29** period (recorded in `ai/changes.md` Week 1 closeout entry).
11. **Record provenance:** **Contemporaneous** (commit + `ai/changes.md`).
12. **Remaining limitation:** The freeze status was applied at Week 1 closeout, not
    at the initial `46f6ebe` commit; a reader looking only at `46f6ebe` would see
    "Draft". This ledger records the correction explicitly rather than silently
    rewriting the earlier state.

---

### SCL-02 — Required image references enforced at compile time

1. **Change ID:** SCL-02
2. **Title:** `BusinessCard.originalImageReference` / `processedImageReference` made required (`String`, non-optional)
3. **Category:** Specification Clarification (implementation had weakened a frozen requirement)
4. **Original requirement / spec reference:** [spec/data-model.md](../../spec/data-model.md) §BusinessCard minimum-field table:
   `originalImage | image reference | Yes`, `processedImage | image reference | Yes`.
5. **Problem / reason:** The initial Increment 1 implementation relaxed the Domain
   invariant to `String?` (default `nil`) because Week 2 had no camera pipeline.
   That let implementation weaken a frozen specification. Human review required the
   fields to be non-optional required `String` references, with fixtures supplying
   deterministic tokens.
6. **Before / After behavior:** Before — `originalImageReference: String?`,
   `processedImageReference: String?` (both defaulted `nil`). After —
   `originalImageReference: String`, `processedImageReference: String` (required,
   no default); `BusinessCard` can no longer be constructed without both.
7. **Scope and affected files:** [SimCamCard/Model/BusinessCard.swift](../../SimCamCard/Model/BusinessCard.swift),
   [SimCamCardTests/Model/BusinessCardTests.swift](../../SimCamCardTests/Model/BusinessCardTests.swift),
   [ai/changes.md](../changes.md).
8. **Related implementation commit:** `6fa0910` (2026-09-29).
   **Verified:** `git show 6fa0910:SimCamCard/Model/BusinessCard.swift` already
   contains `var originalImageReference: String` (required).
9. **Verification tests and evidence:** Unit run at the time:
   `xcodebuild -only-testing:SimCamCardTests test` → **TEST SUCCEEDED**, 20 cases
   (14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 placeholder). Domain-only
   Foundation import verified by `grep "^import" SimCamCard/Model/*.swift`.
   Old `imageReferencesAreNilByDefault()` deleted (it tested violating behavior).
10. **Human Decision / Status:** **Accepted — 2026-09-29 (human review)**, recorded
    in [ai/changes.md](../changes.md#L246-L247).
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** None affecting behavior. The fixtures carry
    deterministic reference tokens (e.g. `card-001-original`) because no real image
    bytes existed at Week 2 — this is a test-fixture convention, not a product
    limitation.

---

### SCL-03 — Repository `allCards()` ordering unfreeze + T12/T17 traceability

1. **Change ID:** SCL-03
2. **Title:** Do not freeze unspecified ordering; T12/T17 corrected to repository-level prerequisites only
3. **Category:** Evaluation Correction (test assertion over-freezing — **not** a spec change)
4. **Original requirement / spec reference:** [spec/reference-tests.md](../../spec/reference-tests.md)
   (T12 Save, T17 Delete), [spec/state-inventory.md](../../spec/state-inventory.md) S01.
   The frozen spec defines **no** ordering for `allCards()`.
5. **Problem / reason:** Repository tests had begun to assert insertion order /
   update position / duplicate-seed position, which the spec never specified.
   Separately, the Increment 2 record had implied T12/T17 were satisfied by the
   Repository alone, whereas the Repository is only a prerequisite.
6. **Before / After behavior:** Before — tests asserted positional/ordering outcomes;
   Increment 2 claimed T12/T17 pass. After — assertions rewritten to `Set`
   membership + id-based lookup; ordering documented as a **current in-memory
   implementation detail, not a protocol guarantee**; T12/T17 marked
   **repository-level prerequisite/support only**.
7. **Scope and affected files:**
   [SimCamCardTests/Repository/InMemoryBusinessCardRepositoryTests.swift](../../SimCamCardTests/Repository/InMemoryBusinessCardRepositoryTests.swift),
   [SimCamCard/Repository/InMemoryBusinessCardRepository.swift](../../SimCamCard/Repository/InMemoryBusinessCardRepository.swift)
   (doc comments only), [ai/changes.md](../changes.md#L307-L342).
8. **Related implementation commit:** `d2c477e` (2026-09-29) — attribution by
   increment/date; the correction was pre-Accept and folded into the increment
   commit, **not separately committed**.
9. **Verification tests and evidence:** Unit run: **TEST SUCCEEDED**, 30 cases
   (10 repository + 14 BusinessCard + 5 PhoneNumber + 1 placeholder). Renamed
   `concurrentSavesAllPersist` (from `…AreSerialized`) asserts presence without
   assuming task order.
10. **Human Decision / Status:** **Accepted — 2026-09-29 (human review)**, applied
    before final Accept of Increment 2 ([ai/changes.md](../changes.md#L341-L342)).
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** Ordering is intentionally **unspecified** in the frozen
    spec and must not be relied upon by future tests.

---

### SCL-04 — Camera session concurrency architecture correction

1. **Change ID:** SCL-04
2. **Title:** `CameraSessionController` moved off the MainActor to a dedicated serial actor executor (supersedes MainActor-owned session design)
3. **Category:** Architecture Correction
4. **Original requirement / spec reference:** [spec/state-inventory.md](../../spec/state-inventory.md)
   S02 (camera states), [spec/reference-tests.md](../../spec/reference-tests.md) T03,
   [spec/reference-environment.md](../../spec/reference-environment.md).
   Requirement is behavioral (states + no-crash on denial); the ownership design is
   not spec-frozen, so this is an architecture correction, not a spec change.
5. **Problem / reason:** The original Increment 1 implementation isolated the entire
   `AVCaptureSession` lifecycle on the MainActor and documented it as an "accepted
   trade-off". Apple AVFoundation guidance states configuration is expensive and
   `startRunning()` / `stopRunning()` are blocking calls that must not run on the main
   thread. This was a production camera-foundation fix, not a deferred optimization.
6. **Before / After behavior (architecture):** Before — `@MainActor final class
   CameraSessionController` owning the session, synchronous `configure()` /
   `start()` / `stop()` on the main thread. After — `CameraSessionController` is an
   **`actor`** running on a dedicated serial executor
   (`DispatchSerialQueue("com.metahumanz.SimCamCard.camera.session")`); all configure
   / start / stop strictly serialized off-main; `configureIfNeeded() async throws`,
   `start() async throws`, `stop() async`; protocol explicitly `nonisolated` because
   `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. `ScanViewModel` stays
   `@MainActor @Observable` and `await`s these calls.
7. **Scope and affected files:**
   [SimCamCard/Camera/CameraSessionController.swift](../../SimCamCard/Camera/CameraSessionController.swift),
   `SimCamCard/Camera/CameraSessionControlling`, `SimCamCard/View/Scan/CameraPreviewView.swift`,
   `SimCamCard/Camera/Debug/DebugCameraFakes.swift`,
   `SimCamCard/ViewModel/ScanViewModel.swift`, camera unit/UI tests,
   [ai/changes.md](../changes.md#L1263-L1306).
8. **Related implementation commit:** `eeefbbe` (2026-10-01).
   **Verified:** `git show eeefbbe:SimCamCard/Camera/CameraSessionController.swift`
   already documents the `actor` design; `CameraSessionController.swift` first
   appears in `eeefbbe` (i.e. the pre-correction MainActor version was **never
   committed**).
9. **Verification tests and evidence (all rerun at the time; prior round not carried
   over):** Debug build PASS; Release build PASS; Unit **50/50 PASS** (48 prior + 2
   new serialization-contract tests: 16 concurrent `configureIfNeeded` →
   `configureCount == 1`; three appear/disappear cycles → configure 1 / start 3 /
   stop 3); UI regression **13/13 PASS**; boundary audit grep for
   `Task.detached` / `nonisolated(unsafe)` / `@unchecked` → zero usages.
   [ai/changes.md](../changes.md#L1283-L1289).
10. **Human Decision / Status:** **Accepted — 2026-10-01 (human review)**
    ([ai/changes.md](../changes.md#L1304-L1306)).
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** S02 real live-preview runtime verification remained
    **PENDING physical-device verification** at the time; no physical iPhone exists
    in this environment (see §8). `@preconcurrency import AVFoundation` is a narrow
    compat bridge and does **not** itself guarantee thread safety.

---

### SCL-05 — Initial camera-session start failure contract

1. **Change ID:** SCL-05
2. **Title:** Failed initial `AVCaptureSession` start maps to `cameraUnavailable`, never `preview`
3. **Category:** Behavioral Change (closing a contract gap)
4. **Original requirement / spec reference:** [spec/state-inventory.md](../../spec/state-inventory.md)
   S02, [spec/reference-tests.md](../../spec/reference-tests.md) T03.
5. **Problem / reason:** `AVCaptureSession.startRunning()` does **not** report an
   initial start failure via Swift `throw`. The prior implementation called
   `startRunning()` and unconditionally set state to `.preview`, so a failed initial
   start would have been misreported as a working preview.
6. **Before / After behavior:** Before — configure success → start requested →
   state set to `.preview` unconditionally. After — configure success → start
   requested → session actually starts → `.preview`; configure success → initial
   start failure → `.cameraUnavailable`, **not** `.preview`.
7. **Scope and affected files:**
   [SimCamCard/Camera/CameraSessionController.swift](../../SimCamCard/Camera/CameraSessionController.swift),
   [SimCamCard/ViewModel/ScanViewModel.swift](../../SimCamCard/ViewModel/ScanViewModel.swift),
   camera tests, [ai/changes.md](../changes.md#L1308-L1377).
8. **Related implementation commit:** `eeefbbe` (2026-10-01) — same commit as
   SCL-04; the second correction entry is dated 2026-10-01.
9. **Verification tests and evidence:** Contract tests for
   configure-failure → `cameraUnavailable` and start-failure → `cameraUnavailable`
   are in the camera test suites; see [ai/changes.md](../changes.md#L1308-L1377).
10. **Human Decision / Status:** **Accepted — 2026-10-01 (human review)**, recorded
    in the W3I1 correction-2 entry ([ai/changes.md](../changes.md#L1308-L1377)).
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** None known; the failure mapping is asserted by
    deterministic tests, not by physical-device hardware failure injection.

---

### SCL-06 — Vision aspect-ratio semantics + configure rollback + orientation wording

1. **Change ID:** SCL-06
2. **Title:** Pre-Accept correction: Vision aspect-ratio semantics, transaction rollback ordering, orientation wording
3. **Category:** Specification Clarification (interpretation + wording calibration)
4. **Original requirement / spec reference:** [spec/reference-tests.md](../../spec/reference-tests.md)
   T06, [spec/page-inventory.md](../../spec/page-inventory.md), S02/S03 states.
5. **Problem / reason:** Pre-Accept calibration of Vision rectangle/coordinate
   semantics (top-left origin, normalized range), the transactional
   configure rollback order, and orientation wording.
6. **Before / After behavior:** Interpretation/wording corrected; the app-visible
   T06 behavior (detected boundary shown, manual adjust + confirm) is unchanged.
7. **Scope and affected files:**
   [SimCamCard/Detection/CardRegionDetector.swift](../../SimCamCard/Detection/CardRegionDetector.swift),
   [SimCamCard/Detection/CardRegion.swift](../../SimCamCard/Detection/CardRegion.swift),
   [SimCamCard/Camera/CameraTopologyTransaction.swift](../../SimCamCard/Camera/CameraTopologyTransaction.swift),
   [SimCamCard/Imaging/ImageOrientationResolver.swift](../../SimCamCard/Imaging/ImageOrientationResolver.swift),
   [ai/changes.md](../changes.md#L1875-L1947).
8. **Related implementation commit:** `db0cc90` (2026-10-01) — **attribution by
   increment/date; pre-Accept correction folded into the increment commit.**
9. **Verification tests and evidence:** See the W3I4 pre-Accept corrections entry
   ([ai/changes.md](../changes.md#L1875-L1947)); detection covered by T06
   deterministic UI + crop unit proof.
10. **Human Decision / Status:** Accepted within the W3I4 Accept sequence
    ([ai/changes.md](../changes.md#L1948-L2038) region).
11. **Record provenance:** **Contemporaneous** (`ai/changes.md`).
12. **Remaining limitation:** Attribution commit not independently re-verified; the
    correction is documented but was not a separately-committed change.

---

### SCL-07 — Crop confirmation interaction freeze + P04 edge-midpoint calibration

1. **Change ID:** SCL-07
2. **Title:** Pre-Accept correction: crop confirmation interaction freeze; P04 edge-midpoint evidence/visual calibration
3. **Category:** Specification Clarification (interaction freeze)
4. **Original requirement / spec reference:** [spec/reference-tests.md](../../spec/reference-tests.md)
   T06 second half, S04 crop/boundary state.
5. **Problem / reason:** Freeze the crop confirmation interaction contract and
   calibrate the P04 edge-midpoint evidence against the Reference observation.
6. **Before / After behavior:** Interaction contract made explicit; observable crop
   flow (auto-detected → manual adjust → confirm) unchanged.
7. **Scope and affected files:**
   [SimCamCard/View/Scan/CardCropView.swift](../../SimCamCard/View/Scan/CardCropView.swift),
   [SimCamCard/Crop/CropDraft.swift](../../SimCamCard/Crop/CropDraft.swift),
   [ai/changes.md](../changes.md#L2039-L2182).
8. **Related implementation commit:** `68d242c` (2026-10-01) — **attribution by
   increment/date; pre-Accept correction folded in.**
9. **Verification tests and evidence:** Crop UI/unit tests (T06);
   evidence `2026-10-01-increment5-crop-*.png`.
10. **Human Decision / Status:** Accepted within the W3I5 sequence
    ([ai/changes.md](../changes.md#L2039-L2182) region).
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** Attribution commit not independently re-verified.

---

### SCL-08 — Photo-import presentation-binding + contract corrections

1. **Change ID:** SCL-08
2. **Title:** Pre-Accept corrections for system photo import (presentation binding, cancel ordering)
3. **Category:** Implementation Fix (conforms to frozen T05 requirement)
4. **Original requirement / spec reference:** [spec/reference-tests.md](../../spec/reference-tests.md)
   T05 Photo Import; [spec/state-inventory.md](../../spec/state-inventory.md) S03.
5. **Problem / reason:** Pre-Accept correction of the import flow presentation
   binding and import-cancel ordering so cancel is safe and returns to preview with
   no crop/OCR/draft.
6. **Before / After behavior:** Cancel ordering guaranteed; observable import
   behavior (happy / cancel / load-failure) conforms to the frozen T05 requirement.
7. **Scope and affected files:**
   [SimCamCard/View/Scan/ScanEntryView.swift](../../SimCamCard/View/Scan/ScanEntryView.swift),
   [SimCamCard/ViewModel/ScanViewModel.swift](../../SimCamCard/ViewModel/ScanViewModel.swift),
   [ai/changes.md](../changes.md#L1581-L1721).
8. **Related implementation commit:** `08745a4` (2026-10-01) — **attribution by
   increment/date; two pre-Accept correction commits were folded in.**
9. **Verification tests and evidence:** Unit import-cancel ordering tests; UI import
   happy/cancel/failure tests; evidence
   `2026-10-01-increment3-photo-import-fixture.png`.
10. **Human Decision / Status:** **Accepted — 2026-10-01**, recorded as
    "Week 3 Increment 3 Accepted: final conclusions"
    ([ai/changes.md](../changes.md#L1722-L1774)).
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** The native system `PhotosPicker` real user-gesture
    cancel was **NOT INDEPENDENTLY VERIFIED** at the time (see G-03, §8). **Note:**
    this limitation concerns the **system PhotosPicker** (photo-import picker), **not
    the system camera**; T05 is photo import.

---

### SCL-09 — Dataset image-ID permutation correction

1. **Change ID:** SCL-09
2. **Title:** Eight card images were mapped to incorrect card IDs; permutation corrected without modifying image bytes
3. **Category:** Evaluation Correction (dataset path↔content mapping; **not** a product behavior change)
4. **Original requirement / spec reference:** [spec.md](../../spec.md) §11 Test Dataset,
   [dataset/README.md](../../dataset/README.md),
   [assignment/](../../assignment/) §14 (Ground Truth dataset requirement).
5. **Problem / reason:** Phase A integrity audit
   ([ai/dataset-integrity-audit.md](../dataset-integrity-audit.md)) found eight card
   images assigned to incorrect card IDs (a closed permutation in the 005–014 range).
   The image bytes were correct; only the path-to-content mapping was scrambled.
6. **Before / After behavior:** Before — 8 PNGs mis-mapped (e.g. `card-005` PNG
   showed the card-010 GT identity). After — canonical paths corrected via a
   lossless permutation. **No image bytes modified**; SHA-256 multiset preserved.
7. **Scope and affected files:**
   `dataset/cards/*` (paths), [dataset/README.md](../../dataset/README.md),
   [dataset/revisions/2026-10-02-image-id-permutation.md](../../dataset/revisions/2026-10-02-image-id-permutation.md),
   [ai/dataset-integrity-audit.md](../dataset-integrity-audit.md),
   `SimCamCardTests/OCR/OCRPipelineDatasetSmokeTests.swift`,
   `ai/validation/dataset-integrity/*`.
8. **Related implementation commits:** `df334f5` (audit, 2026-10-02) →
   `7c031a7` (permutation fix, 2026-10-02) → `e68f7c1` (merge, 2026-10-02).
9. **Verification tests and evidence:** Contact sheets
   `ai/validation/dataset-integrity/cards-*.png`; revision doc
   `dataset/revisions/2026-10-02-image-id-permutation.md`; dataset-integrity audit;
   OCR smoke test placeholder documents the corrected mapping.
10. **Human Decision / Status:** Dataset correction recorded as a **dataset
    revision** ([dataset/revisions/…](../../dataset/revisions/2026-10-02-image-id-permutation.md));
    audit + fix commits. No separate product-level Human Decision entry was found
    in the contemporaneous records (**NOT DOCUMENTED** at that granularity) — this
    is stated as a records fact, not as a claim that approval was unnecessary.
    Status: **Applied** (dataset revision).
11. **Record provenance:** **Contemporaneous** (revision doc + audit + commits).
12. **Remaining limitation:** The audit also confirmed a **pre-existing** mismatch
    beyond the permutation (e.g. the shipped `card-013` PNG ↔ `card-013` GT
    disagreement) that was **reported but not modified** — the frozen dataset was not
    altered to "fix" it (see [ai/changes.md](../changes.md#L2260-L2286)). This
    remains a documented dataset caveat, not a corrected state.

---

### SCL-10 — Swift actor reentrancy wording correction

1. **Change ID:** SCL-10
2. **Title:** Removed the false claim that an actor serializes access to at most one active OCR recognition
3. **Category:** Specification Clarification (implementation-doc/assertion claim corrected)
4. **Original requirement / spec reference:** [spec.md](../../spec.md) §5 Deterministic
   vs Probabilistic; ScanViewModel ownership contracts.
5. **Problem / reason:** The `CardOCRProcessor` actor comment claimed "actor
   serializes access to at most one active recognition". Swift actors **are
   reentrant across await points**, so actor isolation alone does not prevent two
   `perform` calls from overlapping. The claim was false and was removed; the actual
   guarantee is the recognition-generation contract.
6. **Before / After behavior:** Wording corrected (no warning that does not hold).
   Actual semantics clarified: **`ScanViewModel` owns at most one current recognition
   `Task`** (new recognition cancels + supersedes the old one; `recognitionGeneration`
   guards stale completions). No product behavior change in this entry.
7. **Scope and affected files:**
   `SimCamCard/OCR/CardOCRProcessor.swift` (comment),
   [SimCamCard/ViewModel/ScanViewModel.swift](../../SimCamCard/ViewModel/ScanViewModel.swift),
   `SimCamCardTests/ViewModel/ScanViewModelTests.swift`
   (new `staleACannotOverwriteNewerB`), [ai/changes.md](../changes.md#L2260-L2348).
8. **Related implementation commit:** `b0404e2` (2026-10-02).
   **Verified:** `git show b0404e2:SimCamCard/OCR/CardOCRProcessor.swift` already
   contains the corrected reentrancy wording.
9. **Verification tests and evidence:** New deterministic test
   `staleACannotOverwriteNewerB` (stale A cannot resurrect recognition; B owns final
   state; entered counts A=1, B=1; no sleep, gate-based)
   ([ai/changes.md](../changes.md#L2306-L2316)).
10. **Human Decision / Status:** Applied as pre-Accept correction to Increment 6
    ([ai/changes.md](../changes.md#L2260-L2262): "amends Increment 6 before Accept").
11. **Record provenance:** **Contemporaneous**.
12. **Remaining limitation:** Task cancellation does **not** guarantee an
    already-running Vision request aborts immediately; underlying early-abort
    behavior remains framework-dependent and is explicitly not promised.

---

### SCL-11 — G-01 Vision detector area gate + sub-threshold fallback

1. **Change ID:** SCL-11
2. **Title:** `CardRegionGeometry.minimumDetectedArea` (0.05) area gate + sub-threshold quadrant fallback in the auto-accept path
3. **Category:** Behavioral Change (probabilistic-pipeline performance fix)
4. **Original requirement / spec reference:** [spec/reference-tests.md](../../spec/reference-tests.md)
   T06, [assignment/](../../assignment/) §7.3 ("must satisfy behavior and result
   requirements specified by the instructor's test dataset") + §5.2 (probabilistic
   acceptance framework).
5. **Problem / reason:** The Vision rectangle detector locked onto small box-art
   decorations on 14/34 teacher dataset cards in the auto-accept path (detected
   region area 0.007–0.024 vs normal crop 0.47–0.93; outputs 50–93 px with no text →
   0 OCR lines; card-012/029 below the geometric lower bound → `invalidRegion`).
   Full-image diagnostic OCR recovered all 14, proving a **detection/crop root
   cause**, not an OCR defect. 93 of the 124 unmatched present fields traced to
   detection/crop.
6. **Before / After behavior:** After — a calibrated area gate (`minimumDetectedArea
   = 0.05`, threshold justified by a >10× gap between correct crops 0.47–0.93 and
   mis-locked quads 0.007–0.024, not single-sample tuning) rejects sub-threshold
   auto-detections and routes them to a fallback inset/full path. Measured
   before/after (same harness/GT/normalization): detection accepted **33→19**,
   fallback **1→15**, pipeline error **2→0**, zero-OCR-line cards **14→0**,
   present-field match **109/233 (46.8%) → 164/233 (70.4%)**.
7. **Scope and affected files:**
   [SimCamCard/Crop/CardRegionGeometry.swift](../../SimCamCard/Crop/CardRegionGeometry.swift),
   [SimCamCard/Crop/CardCropProcessor.swift](../../SimCamCard/Crop/CardCropProcessor.swift)
   (`prepare()` auto-accept branch only; Core Image main chain and live-preview path
   unchanged), new `CardRegionDetecting` protocol seam,
   [SimCamCardTests/Crop/CardRegionGeometryTests.swift](../../SimCamCardTests/Crop/CardRegionGeometryTests.swift) (+3),
   [SimCamCardTests/Crop/CardCropProcessorTests.swift](../../SimCamCardTests/Crop/CardCropProcessorTests.swift) (+3),
   [ai/evaluation/real-vision-34/](../evaluation/real-vision-34/) artifacts.
8. **Related implementation commit:** `de58eee` (2026-10-18).
   **Verified:** `minimumDetectedArea` / `isAcceptableAutoDetection` are **absent**
   from `git show 68d242c:SimCamCard/Crop/CardRegionGeometry.swift` and **present** in
   `de58eee`. (Also "kept FIXED, no algorithm expansion" per Phase 1.1.)
9. **Verification tests and evidence:** Unit `CardRegionGeometryTests` (+3, area-gate
   boundaries) and `CardCropProcessorTests` (+3, stub-injected reject/accept/no-detect
   fallback); 34-card re-evaluation before/after in
   [summary.md §9](../evaluation/real-vision-34/summary.md);
   GT-absent buckets (same definition before/after): strict canonical absence
   **68→64**, alt-language exact **3→7**, alt-language partial **2→2**, genuine
   fabrication **0→0**; baseline payload
   [_eval-payload-pre-gate-baseline.json](../evaluation/real-vision-34/_eval-payload-pre-gate-baseline.json)
   vs [_eval-payload.json](../evaluation/real-vision-34/_eval-payload.json).
10. **Human Decision / Status:** **FIXED** — accepted in
    **Phase 1.1, Accepted — 2026-10-18 (human review)**; recorded in
    [final-gap-list.md](./final-gap-list.md#L197-L226).
11. **Record provenance:** **Contemporaneous** at fix level (`final-gap-list.md`
    Phase 1.1 section, written during calibration); this ledger entry is
    Retrospective.
12. **Remaining limitation:** The app already offers manual P04 corner adjustment,
    so a user can correct before confirming; this evaluation measured the
    **auto-accept** path. 164/233 (70.4%) is a **present-field match rate, not a
    character-level OCR accuracy**. CamCard's own accuracy on this dataset was
    **never observed** → **NOT OBSERVED**.

---

### SCL-12 — B-01 detail-page phone / email / website tap

1. **Change ID:** SCL-12
2. **Title:** Detail page supports tapping phone / email / website (tel: / mailto: / https:)
3. **Category:** Behavioral Change (implementing a frozen, explicitly required behavior)
4. **Original requirement / spec reference:** [assignment/](../../assignment/) §10:
   detail page must support "Tap phone number; Tap email address; Tap website"
   ("涉及外部系统调用的功能可以调用系统原生组件"). Frozen **must-support** list — so
   the prior absence was an implementation gap against an **already-frozen**
   requirement, not a spec change.
5. **Problem / reason:** Phase 1 audit found the three taps entirely unimplemented:
   `CardDetailView.swift` carried the comment "Deliberately NOT implemented:
   phone/email/web invocation (no tel:/URL wiring)" and `CardDetailFieldRow.swift`
   was a plain `HStack` with no `Button`/`Link`/`onTapGesture`/`openURL`.
6. **Before / After behavior:** Before — tapping a phone/email/website row did
   nothing. After — rows are wired to `tel:` / `mailto:` / safe `https://` via an
   `openURL` seam; invalid or missing values return `nil` and do **not** trigger a
   call. Minimal structural guards were added during calibration (phone requires at
   least one dialable digit; email requires single `@`, non-empty local/domain,
   dotted domain, no whitespace; explicit non-web schemes such as `ftp://` / `file://`
   are no longer silently upgraded).
7. **Scope and affected files:**
   [SimCamCard/View/CardDetail/CardDetailURLMapping.swift](../../SimCamCard/View/CardDetail/CardDetailURLMapping.swift),
   [SimCamCard/View/CardDetail/CardDetailFieldRow.swift](../../SimCamCard/View/CardDetail/CardDetailFieldRow.swift),
   [SimCamCard/View/Debug/DebugOpenURLCapture.swift](../../SimCamCard/View/Debug/DebugOpenURLCapture.swift),
   [SimCamCardTests/ViewModel/CardDetailURLMappingTests.swift](../../SimCamCardTests/ViewModel/CardDetailURLMappingTests.swift),
   [SimCamCardUITests/CardDetailUITests.swift](../../SimCamCardUITests/CardDetailUITests.swift),
   [ai/delivery/final-gap-list.md](./final-gap-list.md#L64-L98).
8. **Related implementation commit:** `de58eee` (2026-10-18).
   **Verified:** neither `fullScreenCover` nor a URL-mapping seam exists in
   `git show 5ec0803:SimCamCard/View/CardDetail/CardDetailView.swift`; the mapping
   file is **added** in `de58eee`.
9. **Verification tests and evidence:** Unit `CardDetailURLMappingTests`
   (valid / separator / invalid / percent-encoding); UI
   `testCardDetailRowTapInitiatesCorrectURL` actually taps the mobile / office /
   email / website rows and asserts captured
   `tel:+86%20138%200013%208000` / `tel:+86%2021%205555%201234` /
   `mailto:wei.zhang@zhiyuntech.com` / `https://www.zhiyuntech.com`;
   `testCardDetailAddressRowDoesNotInitiateURL` asserts the address row triggers no
   URL. DEBUG-only `-SimCamCardCaptureOpenURL 1` hook captures the App-emitted URL
   without forwarding to a system App.
10. **Human Decision / Status:** **FIXED — behavioral verification: PASS**
    (Phase 1.1, **Accepted — 2026-10-18 (human review)**).
11. **Record provenance:** **Contemporaneous** at fix level; this entry Retrospective.
12. **Remaining limitation:** The hook proves the URL the **App** emits; the **system
    Apps'** (Phone / Mail / Safari) final takeover behavior was **NOT tested** on a
    physical device. The added validation is **minimal structural guards**, not full
    phone/email format validation — representative invalid-value counterexamples
    passing does **not** imply every arbitrary invalid input is rejected.

---

### SCL-13 — B-02 original-card viewer in detail page

1. **Change ID:** SCL-13
2. **Title:** Detail page renders the saved original card image with a full-screen viewer
3. **Category:** Behavioral Change (implementing a frozen, explicitly required behavior)
4. **Original requirement / spec reference:** [assignment/](../../assignment/) §10:
   "View original business card / 查看原始名片"; §12 persistence guarantee that the
   original image still exists after relaunch.
5. **Problem / reason:** Phase 1 audit found the original image bytes were persisted
   but no detail-page view rendered any card image (no image viewer anywhere;
   `originalImageReference` was not consumed by any View). Whether §10 required a
   viewable viewer or merely traceability was flagged for human adjudication.
6. **Before / After behavior:** Before — the detail page rendered no card image.
   After — a `card-detail-original-image` strip (maxHeight 200) plus a
   `fullScreenCover` viewer renders `originalImageReference`, lazily loaded through
   the existing `ImageAssetStore`; when the image is missing the strip is simply not
   rendered (graceful degradation, other rows unaffected).
7. **Scope and affected files:**
   [SimCamCard/View/CardDetail/CardDetailView.swift](../../SimCamCard/View/CardDetail/CardDetailView.swift),
   [SimCamCard/ViewModel/CardDetailViewModel.swift](../../SimCamCard/ViewModel/CardDetailViewModel.swift),
   [SimCamCardUITests/CardDetailUITests.swift](../../SimCamCardUITests/CardDetailUITests.swift),
   [SimCamCardUITests/CardPersistenceUITests.swift](../../SimCamCardUITests/CardPersistenceUITests.swift),
   [SimCamCardTests/ViewModel/CardDetailViewModelTests.swift](../../SimCamCardTests/ViewModel/CardDetailViewModelTests.swift),
   [ai/delivery/final-gap-list.md](./final-gap-list.md#L100-L121).
8. **Related implementation commit:** `de58eee` (2026-10-18).
   **Verified:** `fullScreenCover` / `originalImage` are **absent** from
   `git show 5ec0803:SimCamCard/View/CardDetail/CardDetailView.swift`.
9. **Verification tests and evidence:** UI
   `testCardDetailMissingOriginalImageGracefulDegradation`; positive E2E in
   `CardPersistenceUITests`: first save → Detail → assert thumbnail → tap → assert
   full-screen viewer → close → terminate/relaunch → reopen same card → assert
   thumbnail → tap → assert viewer → close (both stages pass). Unit
   `loadOriginalImageUsesOriginalReferenceNotProcessed` injects two distinguishable
   payloads (original = PNG signature, processed = JPEG signature) and asserts the VM
   reads `originalImageReference`, not `processedImageReference`.
10. **Human Decision / Status:** **FIXED — behavioral verification: PASS**
    (Phase 1.1, **Accepted — 2026-10-18 (human review)**).
11. **Record provenance:** **Contemporaneous** at fix level; this entry Retrospective.
12. **Remaining limitation:** Physical-device rendering of the original image was
    **NOT tested** (see §8); all SimCamCard acceptance evidence is simulator-based.

---

## 6. Verification and Acceptance Mapping

### 6.1 Where each change's verification lives

| Change | Deterministic test | Evidence artifact | Human decision record |
|---|---|---|---|
| SCL-01 | none (doc-only) | `git show b5dcf4d -- spec.md` | `ai/changes.md` Week 1 closeout |
| SCL-02 | `BusinessCardTests` | Domain-only import audit | `ai/changes.md#L246-L247` |
| SCL-03 | `InMemoryBusinessCardRepositoryTests` | — | `ai/changes.md#L341-L342` |
| SCL-04 | camera unit (50/50) + UI (13/13) | `ai/validation/2026-09-30-*`, `2026-10-01-*` | `ai/changes.md#L1304-L1306` |
| SCL-05 | camera contract tests | — | `ai/changes.md#L1308-L1377` |
| SCL-06 | T06 crop/detection tests | `ai/validation/2026-10-01-increment4-*` | `ai/changes.md`(W3I4) |
| SCL-07 | crop UI/unit | `ai/validation/2026-10-01-increment5-crop-*` | `ai/changes.md`(W3I5) |
| SCL-08 | import unit + UI | `ai/validation/2026-10-01-increment3-photo-import-fixture.png` | `ai/changes.md#L1722-L1774` |
| SCL-09 | OCR smoke + contact sheets | `ai/validation/dataset-integrity/*`, `dataset/revisions/…` | revision doc + commits |
| SCL-10 | `staleACannotOverwriteNewerB` | — | `ai/changes.md#L2260` |
| SCL-11 | `CardRegionGeometryTests` (+3), `CardCropProcessorTests` (+3) | `ai/evaluation/real-vision-34/` (summary §9, dual payloads) | `final-gap-list.md#L197-L226` |
| SCL-12 | `CardDetailURLMappingTests`, `testCardDetailRowTapInitiatesCorrectURL`, `testCardDetailAddressRowDoesNotInitiateURL` | [ai/delivery/final-gap-list.md](./final-gap-list.md#L64-L98) | `final-gap-list.md` / `course-compliance-matrix.md` |
| SCL-13 | `CardDetailViewModelTests`, `testCardDetailMissingOriginalImageGracefulDegradation`, `CardPersistenceUITests` E2E | [ai/delivery/final-gap-list.md](./final-gap-list.md#L100-L121) | `final-gap-list.md` / `course-compliance-matrix.md` |

### 6.2 The seven-segment chain does not hold uniformly

The chain **Requirement → Specification → Implementation → Test → Evidence → Result
→ Human Decision** is **not** complete on every entry. Specifically:

- **Human Decision is per-increment, not per-test.** A phase-level `Accepted`
  (e.g. "Week 3 Increment 3 Accepted") covers a set of changes; it must **not** be
  read as a separate Human Decision for every individual assertion. This ledger
  records the decision at the granularity the repository actually documents.
- **Doc-only changes (SCL-01)** have Implementation but no automated test segment.
- **Some corrections (SCL-03, 06, 07, 08)** have no separately committed
  Implementation segment — they were folded into their increment commits. This must
  **not** be read as "implementation missing": the implementation **is present** in
  the committed tree — `d2c477e` contains the rewritten
  `InMemoryBusinessCardRepositoryTests` (SCL-03), `db0cc90` contains
  `CardRegionDetector` / `CameraTopologyTransaction` / `ImageOrientationResolver`
  (SCL-06), `68d242c` contains `CardCropView` / `CropDraft` (SCL-07), `08745a4`
  contains `ScanEntryView` / `ScanViewModel` (SCL-08). Status for these four:
  **Implementation present, dedicated commit absent** (attribution by
  increment/date, flagged `*` in §4).
- **30–50 card instructor dataset**: the assignment asks for a 30–50 card set with
  Ground Truth; the frozen dataset is **34 cards**, with the T20 non-card fixture
  counted separately — this is within range but the **consolidated per-card GT for
  card-001–004** is individual JSON while **005–034** use JSONL/CSV (documented in
  [spec.md](../../spec.md) §11).

### 6.3 Status vocabulary used

`PASS` · `PARTIAL` · `NOT TESTED` · `NOT OBSERVED` · `NOT VERIFIED` ·
`NOT APPLICABLE`. Nothing here upgrades an entry that lacks direct evidence to `PASS`.

---

## 7. Retrospective Reconstruction Limitations

1. **This document was written after the fact.** The underlying records are
   contemporaneous, but the assembly, classification, and linking are Retrospective
   (2026-10-19).
2. **No prompt-level evidence exists.** `ai/prompts/_local/` is empty; the
   "Context Provided" blocks inside `ai/changes.md` are summaries, not archived
   prompt text. Prompt wording is **NOT DOCUMENTED**.
3. **No OpenSpec workflow existed.** The SDD loop was run natively; there were no
   Proposals or Delta Specs. This ledger must not be read as evidence of tooling
   that was never used.
4. **Commit attribution for four Tier-2 corrections is by inference.** SCL-03, 06,
   07, 08 were pre-Accept corrections folded into their increment commits; the
   mapping is by date and increment, **not independently re-verified** at byte level
   (flagged with `*` in §4).
5. **Raw terminal output is not archived.** Test totals quoted here come from
   `ai/changes.md` summaries and the final acceptance documents; they are **not**
   re-executed here and must not be presented as current runs.
6. **The Phase 1.1 retrospectives are themselves Retrospective.** The Phase 1.1
   content in [ai/changes.md](../changes.md#L6234-L6302) is explicitly labeled as a
   post-hoc summary, distinct from the contemporaneous W4I12 log body.

---

## 8. Open Decisions and Unresolved Issues

### Blocking

- **None** identified for the ledger itself. The Git baseline was clean at the start
  of Step 1 (`bdac7b0`, tree clean). *(Historical note: a push of `bdac7b0` to
  `origin/week4/structured-recognition` occurred on 2026-10-19 11:45; its operator is
  **UNKNOWN** from repository evidence and was carried over from Step 0 for human
  confirmation — it does not affect this ledger.)*

### Important

- **G-04 — CamCard comparison scope:** Only card-001…004 + 1 non-card sample have
  real CamCard observations; **card-005…034 = NOT OBSERVED**
  ([course-compliance-matrix.md §D, G-04 row](./course-compliance-matrix.md#L169)). Status:
  **Pending** — requires a human ruling between (a) arranging supplementary CamCard
  captures, or (b) bounding the comparison scope explicitly in the report.
  **No human ruling is on record, so this ledger does not presume any option —
  importantly, it does not presume that supplementary capture is forbidden.**
- **G-03 — real system PhotosPicker cancel gesture:** `NOT VERIFIED`
  (fixture-driven cancel has UI/Unit proof, but a real user cancel inside the system
  picker UI of **T05 photo import** was never exercised). Requires a ~2-minute manual
  capture; classified **Important**, not Optional.
- **G-02 — Photo-library permission denial:** `NOT TESTED` under iOS 27
  `PhotosPicker` semantics (the modern picker runs out-of-process and requests no
  library authorization, so a "denied" state does not exist). Requires a platform
  statement, a constrained-library/legacy-API reproduction, or an instructor ruling.
- **G-05 — UI Golden Test form:** the assignment (§18, Week 5) names "UI Golden Test"
  as **in-course work**, but the course text does not fix its form (automated vs
  manual). The repository has **60 deterministic XCUITests** (62 `func test*` incl.
  2 real-Contacts System01/02; the W4I12 gate recorded 55/55 for its own subset),
  **55** manual screenshots under `ai/validation/` (plus 4 dataset-integrity contact
  sheets), and **40** CamCard Reference captures under `evidence/screenshots/`; the
  **manual** visual comparison has been performed, and there is **no** pixel/snapshot
  assertion (no image-golden string anywhere). Requires an instructor-form ruling.
- **G-11 — physical-device verification:** all **SimCamCard runtime/acceptance**
  evidence is simulator-based (iPhone 18 Pro / iOS 27.0). Native capture,
  real-light detection, and external phone/mail/web handoff are **NOT TESTED** on
  hardware. No physical iPhone exists in this environment. (Scope note: this
  statement covers SimCamCard's own run/acceptance evidence only; the CamCard
  **Reference** observations in `evidence/screenshots/` — partly captured on
  macOS / Mac Catalyst surfaces — are a separate evidence class and are not
  claimed to be simulator-based.)

### Course-required — artifact form pending human ruling

The following items are **not optional**: the underlying course-required content
exists or is required; what remains open is the **artifact form** and, in one case,
unrecoverable original evidence. Each is stated across four dimensions —
(a) whether the course-required content is complete, (b) whether a standalone
artifact is mandatory, (c) whether the original evidence exists, (d) the human
ruling still needed.

- **G-07 — AI capability-boundary analysis.** (a) Content: the assignment §8 five
  capability-boundary cases are exercised and evidenced in the repository
  (extractor unit tests, GT regression, `changes.md` records) — content **done**.
  (b) Standalone artifact: whether a separate capability-boundary document is
  mandatory for delivery is **not fixed in the course text** — pending ruling.
  (c) Original evidence: **exists**, scattered across the sources above.
  (d) Ruling needed: compile into a standalone document vs. cite in-place in the
  final report.
- **G-08 — prompt-level AI collaboration archive.** (a) Content: AI collaboration
  itself is extensively documented in `ai/changes.md` (per-increment "Context
  Provided" summaries) — collaboration **happened and is described**.
  (b) Standalone artifact: whether the raw prompt archive is mandatory is pending
  ruling. (c) Original evidence: the verbatim prompt text is **NOT DOCUMENTED** —
  `ai/prompts/_local/` is empty and the archive is not reconstructable; this entry
  must keep stating that fact, not paper over it. (d) Ruling needed: accept the
  honest "original prompts not archived" statement vs. require any substitute
  form.
- **G-10 — final demonstration artifact.** (a) Content: a final course
  demonstration is a course requirement and has not yet been produced in any
  artifact form. (b) Standalone artifact: the required form (video, live demo,
  slides, screenshots deck) is pending the Canvas delivery-specification ruling.
  (c) Original evidence: the underlying demonstrable app and evidence set
  **exist**; no demo artifact itself exists yet. (d) Ruling needed: artifact form
  per Canvas requirements.

### Optional

- **G-13 — `evidence/image-manifest.md` header:** remains `"Week 1 SDD baseline"`.
  **This file stays frozen and is out of Phase 2A-2 scope**; a revision draft exists
  but is not applied here.

### Platform limitations carried forward

- **G-12 — Contacts export surface:** CamCard evidence came from macOS / Mac Catalyst;
  iOS has no account selector (diff-2/5). Reference-side surface difference.
- **`NOT OBSERVED` items must never be back-filled.** CamCard's accuracy on the 34
  dataset cards beyond card-001…004 has never been observed; no number may be invented.

---

## 9. Summary

- **13 tracked changes** across five categories:
  - Specification Clarification: **5** (SCL-01 true spec edit; SCL-02, 06, 07, 10)
  - Behavioral Change: **4** (SCL-05, 11, 12, 13)
  - Architecture Correction: **1** (SCL-04)
  - Implementation Fix: **1** (SCL-08)
  - Evaluation Correction: **2** (SCL-03, SCL-09)
- **Only one true functional-requirement specification-content edit exists on
  record**: **SCL-01** (`b5dcf4d`, 2026-09-29) — and it sits **inside** the Week 1
  closeout, not "after Week 1". `bc9a517` / `8cff0bf` (same day) touched only
  reference-environment records. Weeks 2–4 and Phase 1.1 show **no** frozen-spec
  modification; all later entries fix code, architecture, tests, or evaluation to
  conform to the frozen specification.
- **All Human Decisions are recorded where the repository actually documents them**
  (per-increment or per-phase `Accepted`, or dataset-revision records), never invented
  per-test.
- **No OpenSpec proposal, delta spec, or CLI history ever existed.**
- **The frozen surface** (`spec.md`, `spec/`, `dataset/`, `evidence/`, `assignment/`,
  Domain, Persistence schema) was verified clean across Phase 1.1 and Phase 2A-1.
- **Unresolved:** G-02 / G-03 / G-04 / G-05 / G-07 / G-08 / G-10 / G-11 / G-12 / G-13
  and the physical-device `NOT TESTED` set — all carried as open items in §8, none
  upgraded to `PASS`.
