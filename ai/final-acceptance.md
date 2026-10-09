# SimCamCard — Final Behavioral Acceptance (T01–T20)

Week 4 Increment 12 (T20 Exception Handling + final acceptance sweep).

- Baseline: `5ec080368fc7d3f4bc4595233ba5f88ffb7f577e` on
  `week4/structured-recognition`, tree clean at start.
- Target: iPhone 18 Pro / iOS 27.0 simulator
  (`5B32D815-5F37-4EE0-825C-85DE864E0B02`),
  `-parallel-testing-enabled NO`.
- Result bundles: `/tmp/w4i12-*.xcresult`; logs `/tmp/w4i12-*.log`.
- No physical iPhone exists in this environment; no physical-device
  claim is made anywhere in this acceptance.
- Companion docs: [final-reference-audit.md](./final-reference-audit.md)
  (P01–P11 fidelity), [changes.md](./changes.md) (W4I12 E01–E20 matrix +
  implementation log).

## Verdict

- **Behavioral Reference Tests: 20 / 20 PASS**
  (T07/T03/T05 carry the frozen-spec "Partial/observed" reference-status
   caveats documented per row; SimCamCard behavioral acceptance PASS).
- Build: Debug PASS · Release PASS.
- Automated regression: Unit **431/431** (35 suites); deterministic UI
  **55/55** (total XCTest functions 57; the 2 real-Contacts tests are
  excluded from this count and reported separately).
- Release DEBUG hook isolation: **13/13 ABSENT**; fresh Debug positive
  control **13/13 PRESENT** (no new hook string in T20).
- Dataset: 34/34 cards present; GT-level structured regression
  typed-layer 34/34 exact, 0 fabricated fields, multi-phone 23/23,
  full-exact 32/34 (2 pinned parser exceptions); 1 independent T20
  non-card exception fixture, counted separately.
- Working tree: review scope only (see scope audit in changes.md).
- **Submission readiness: READY FOR FINAL DELIVERY PREPARATION.**
- Human Decision: Accepted — 2026-10-09 (human review). T20 behavioral
  acceptance: PASS. T01–T20: 20 / 20 PASS. Full Reference fidelity:
  PARTIAL (documented non-blocking differences).

## T01–T20 matrix

Columns: Reference expectation → Implementation → Automated proof →
Evidence → Status. UI = XCTest deterministic suite (SimCamCardUITests);
Unit = Swift Testing suite (SimCamCardTests).

### T01 — First Launch / Empty Holder
- Expected: empty Card Holder when no cards exist.
- Implementation: `CardHolderView` empty state `card-holder-empty`,
  scan entry, zero `card-row-*`.
- Proof: UI `CardHolderEmptyUITests`; Holder units.
- Evidence: `2026-09-29-increment3-empty-holder.png`.
- **PASS.**

### T02 — Enter Scanner
- Expected: scan entry opens the scanner.
- Implementation: `scan-entry` → `ScanEntryView` (`scan-entry-view`,
  preview, capture, import, close).
- Proof: UI `ScanEntryUITests`; Week2 integration.
- Evidence: `2026-09-29-increment6-scan-entry.png`.
- **PASS.**

### T03 — Camera Permission
- Expected: allow/deny produce defined states; denial never crashes;
  system dialogs stay native.
- Implementation: `ScanViewModel` authorization mapping
  (unknown/authorized/denied/restricted); stable application
  `scan-permission-denied` fallback with no capture/import actions;
  native AVFoundation request (no replica dialog).
- Proof: UI `testDeniedShowsStableFallbackWithoutSessionUI`,
  `testNotDeterminedGrantedResolvesToPreview`,
  `testNotDeterminedDeniedResolvesToFallback` (+ close → Holder);
  permission units.
- Evidence: `2026-10-07-w4i12-camera-denied.png` (fixture),
  `2026-09-30-increment1-camera-preview-authorized-fixture.png`.
- **PASS (behavior).** Custom denied fallback is beyond the frozen
  dialog-only evidence → classified deferred cosmetic surface in the
  P02 fidelity row.

### T04 — Capture
- Expected: standard card enters the recognition workflow.
- Implementation: real AVCapture still capture → crop → OCR auto-chain;
  DEBUG capture fixtures for deterministic UI.
- Proof: UI capture/crop tests; capture units.
- Evidence: `2026-10-01-increment2-captured-photo-fixture.png`.
- **PASS (simulator).** Physical-iPhone capture NOT claimed.

### T05 — Photo Import
- Expected: selecting a card image enters the workflow; cancel is safe.
- Implementation: real system `PhotosPicker`; DEBUG imported/cancel/
  load-failure fixtures; `handleImportCancel` ordering guarantees
  preview restart with no crop/OCR/draft (E04).
- Proof: UI import happy/cancel/failure tests; import-cancel units.
- Evidence: `2026-10-01-increment3-photo-import-fixture.png`.
- **T05 Photo Import behavioral mechanics: PASS** (fixture-driven
  import/cancel/load-failure outcomes asserted via the real
  `PhotosPicker` integration seam; not faked).
- **Native system PhotosPicker cancel gesture: NOT independently
  verified** — a real user-initiated cancel inside the system picker
  UI was not exercised on this simulator. This is a **platform
  validation gap** (§31), not a claim that native cancellation was
  really verified.

### T06 — Boundary Detection
- Expected: detected boundary shown; manual adjust + confirm.
- Implementation: real Vision rectangle detection, normalized region,
  handles, perspective-corrected upright PNG.
- Proof: UI crop auto/manual/confirm/retake; crop units; real-pipeline
  dataset smoke (001–004 PNGs through Vision).
- Evidence: `2026-10-01-increment5-crop-{auto-detected,manual-adjust,confirmed}.png`.
- **PASS (simulator).** Physical-device detection NOT claimed.

### T07 — OCR Raw Text
- Expected: OCR produces and preserves raw text verbatim.
- Implementation: real Vision OCR `CardOCRProcessor`, `OCRLine`
  top-1 verbatim, `rawText` join preserved onto the saved card;
  minimal transitional raw surface (Reference never exposed its raw
  screen — frozen T07 status Partial).
- Proof: OCR/extractor units (incl. real Vision textless-image and
  rendered-text tests); raw fixture UI.
- Evidence: `2026-10-01-increment6-raw-ocr-fixture.png`,
  `2026-10-02-increment7-camera-to-raw-ocr.png`.
- **PASS (preservation contract).**

### T08 — Structured Extraction
- Expected: name/company/title/phone/email/website/address classified.
- Implementation: deterministic `CardFieldExtractor` (Phase A typed
  tokens, Phase B semantic; no fabrication, no OCR correction).
- Proof: Unit T08 + real Vision smoke card-001 + fixture UI; §28 GT
  regression 34 cards.
- Evidence: `2026-10-02-w4i2-structured-recognition.png`.
- **PASS.**

### T09 — Missing Field
- Expected: absent website must not be fabricated.
- Implementation: website recognized only from `www.`/`http(s)://`
  tokens; email-domain masking prevents inference; nil stays nil.
- Proof: Unit card-002 + extractor website rules; UI; §28 (nil
  website on every GT card without one — 0 false positives).
- Evidence: `2026-10-02-w4i2-missing-field.png`.
- **PASS.**

### T10 — Multiple Phones
- Expected: mobile / office / fax classified separately.
- Implementation: label families 手机/Mobile, 电话/Tel, 传真/Fax;
  deterministic IDs; bare +86 1[3-9]… auto-mobile, other bare numbers
  honestly `.other`.
- Proof: Unit card-003; real Vision smoke; §28 multi-phone correctness
  23/23.
- Evidence: `2026-10-02-w4i2-multiple-phones.png`.
- **PASS.**

### T11 — Manual Correction
- Expected: user-corrected value replaces extracted value in final card.
- Implementation: `manualEditing` draft (scalars/phones/emails), blank
  corrections dropped, source result immutable.
- Proof: Unit T11 suite; UI before/after + retake-discard.
- Evidence: `2026-10-03-w4i3-{before-edit,after-edit}.png`.
- **PASS.**

### T12 — Save
- Expected: save succeeds; new card appears immediately in Holder;
  original + processed images persisted.
- Implementation: `SaveState` idle/saving/saveSucceeded,
  isSaveInFlight guard, repository + image-asset writes, raw OCR text
  retained.
- Proof: Unit T12 suite (11 cases incl. gating/byte-exact assets);
  UI direct-save + corrected-save.
- Evidence: `2026-10-03-w4i4-{p06-save-success,holder-after-save,detail-saved-card}.png`.
- **PASS.**

### T13 — Detail
- Expected: saved structured fields visible.
- Implementation: `CardDetailView` all scalars + multi-value rows +
  image resolution + action entries.
- Proof: UI detail tests (001 full, 004 minimal); VM units.
- Evidence: `2026-09-30-increment5-card-detail-001-full.png`,
  `…-card-detail-004-minimal.png`.
- **PASS behavior; P07 fidelity PARTIAL** (see reference audit).

### T14 — Edit
- Expected: edited value reflected in stored/detail data.
- Implementation: `EditState` mutual-exclusion, corrected save updates
  card/updatedAt, cancel discards.
- Proof: Unit T14 (save/cancel/re-entrant); UI edit/cancel.
- Evidence: `2026-10-04-w4i5-existing-edit-*.png`.
- **PASS.**

### T15 — Search
- Expected: name/company/title/phone/email search.
- Proof: Unit all five scopes + empty/clear/non-mutation; UI no-result
  + clear + group composition (E14/E19).
- Evidence: `2026-10-04-w4i6-search-{name,company}.png`.
- **PASS for required scopes.** 综合/企业 segmented surfaces excluded
  (P08 row).

### T16 — Tag / Group
- Expected: create → assign → filtered view → delete group keeps cards.
- Implementation: independent group/tag catalog; delete removes tag
  only; filter banner clear.
- Proof: Unit T16 suite (incl. delete-keeps-cards); UI full + delete;
  **W4I12 new:** `testCreateGroupCancelLeavesCatalogAndCardsUnchanged`
  covering BOTH create cancels (selection toolbar; alert after typing)
  → catalog empty, no filter, all cards intact (E12).
- Evidence: `2026-10-04-w4i7-group-*.png`.
- **PASS.**

### T17 — Delete
- Expected: confirmation precedes delete; card gone afterward.
- Implementation: `DeleteState` confirming, guarded delete, cancel
  no-op.
- Proof: Unit T17 (confirm/cancel/re-entrant, safe missing-id delete);
  UI.
- Evidence: `2026-10-04-w4i8-{delete-confirmation,holder-after-delete}.png`.
- **PASS.**

### T18 — Persistence
- Expected: after full quit/relaunch saved cards, edited fields,
  groups/tags, notes, both images remain.
- Implementation: JSON file repositories (schemaVersion 1), file image
  store, namespaced UI-test storage; absent-file and missing-UUID
  stability (E17/E18).
- Proof: UI terminate(.notRunning)/relaunch persistence suite; file
  repository units.
- Evidence: `2026-10-04-w4i9-persistence-*-after-relaunch.png`.
- **PASS (simulator).** Known non-blocking debts preserved: orphan
  image GC not implemented; repository protocol non-throwing (disk
  write failure = known limitation, no T20 refactor); corrupt-JSON
  recovery not built.

### T19 — Export to Contacts
- Expected: system contact save with name/company/title/phone/email/
  address.
- Implementation: `SystemContactExporter` (CNContactStore + CNSaveRequest),
  pure mappers, DEBUG scripted exporter for denial/failure branches.
- Proof (deterministic): 5 fake permission/failure UI tests + T19
  units (mapping all six fields, multiple values, double-write guard,
  dismiss). Proof (real, separate gate): System01/System02 targeted
  tests + Contacts.app field verification.
- Evidence: `2026-10-05-w4i11-contact-{permission,export-success,denied,contacts-fields}.png`.
- **PASS behavior; P11 fidelity PARTIAL** (diff-1..5 in reference
  audit; System tests are stateful and excluded from the deterministic
  count).

### T20 — Exception Handling
- Expected (frozen): permission denial handled; card-004 minimal card
  keeps only present fields; a valid non-card image enters the edit
  screen with an EMPTY result (no failure dialog, no fabricated data);
  explicit cancel/retake/back paths regression-tested.
- Implementation + W4I12 changes:
  1. E06 fix — `RecognitionView.failedContent` now offers both
     `scan-recognition-retake` (重拍) and `scan-recognition-cancel`
     (取消 → dismiss straight to Holder); no Save exists on failure.
  2. E07 fix — `ScanViewModel.canSaveCurrentCard` (false for
     inactive/processing/failed/zero-canonical-field states) + guard
     inside `saveCurrentCard()`; P05 Save button disabled on the empty
     result, so an all-empty card can never be materialized.
  3. E08 capability — DEBUG `OCRFixtureMode.minimal` (reuses the
     existing `-SimCamCardOCR` hook; zero new hook strings): bare
     张伟 + `+86 138 0013 8000` → name + one mobile only.
- Proof (new in W4I12):
  - UI `ExceptionHandlingUITests`: composite B non-card empty →
    Save present-but-disabled + tap no-op + retake/close → unchanged
    empty Holder; composite C minimal → only name+mobile-0, no
    company/title/email/website value, Save enabled; failure →
    Cancel → Holder directly.
  - UI E12 create-group cancel (see T16 row).
  - Unit T20 E07 1/2/3: empty result save = no card/no assets/idle;
    all-cleared manual draft not saveable until a real value exists;
    failed recognition not saveable.
  - Full-chain stale-async/retake/cancel coverage from prior
    increments re-audited (E01–E20 matrix in changes.md), not
    duplicated.
- Evidence: `2026-10-07-w4i12-{camera-denied,non-card-empty-result,minimal-card,recognition-failure}.png`
  (all exported from real xcresult attachments, no staged screens).
- T20 negative fixture (`dataset/exception-samples/t20-negative-001`):
  the frozen proof is explicitly layered and the two layers are NOT
  interchangeable:
  1. **Deterministic DEBUG empty fixture** → the empty-OCR fixture
     drives the real `ScanViewModel`/P05 UI: empty structured fields
     → `nonCardEmptyResult` → Save affordance visible-but-disabled +
     tap no-op + retake/cancel exits (UI composite B; unit E07 1/2/3).
     This layer proves the state mapping and save guard.
  2. **Frozen actual non-card PNG — targeted real Vision integration
     (human-review blocker closure)**: the real file
     `dataset/exception-samples/t20-negative-001-non-card.png` was run
     through the real production pipeline
     `PNG Data → CapturedPhoto → CardCropProcessor.prepare`
     `(real Vision rectangle detection; no-detection → production
     inset fallback, wasDetected=false) → perspectiveCorrect
     (Core Image upright PNG) → CardOCRProcessor.recognize
     (real Swift-native Vision OCR) → CardFieldExtractor.extract`.
     Observed: wasDetected=false (fallback region 0.06–0.94),
     source 725×597 → processed 638×526, OCR raw line count 0
     (rawText empty), canonical name/company/jobTitle nil,
     phones/emails empty, website/address nil, unclassifiedText empty
     → **zero canonical structured fields = PASS**. Raw OCR text was
     not required to be empty; Vision noise with still-zero canonical
     fields would also satisfy `structuredContactFields: "empty"`.
     Targeted run (scratch, gated, deleted after the run):
     `/tmp/w4i12-scratch.xcresult`; the scratch test file was removed
     and is NOT part of the deterministic full suite.
  These two layers together constitute the frozen T20 negative-fixture
  proof. The §28/§29 synthetic empty-lines regression is a separate
  GT-level parser harness and is NOT quoted as actual-PNG proof.
  Counted as **1 exception fixture**, never in the 34 business-card
  totals.
- **PASS.**

## Dataset regression (plan §28/§29) — GT level, explicitly not real-Vision

`StructuredGroundTruthRegressionTests` feeds deterministic, GT-derived
synthetic OCR lines (bilingual labels for typed fields, bare semantic
lines) straight to the pure `CardFieldExtractor`, then compares against
the frozen GT JSON. It measures parser/classifier behavior only; it is
not quoted as Vision OCR accuracy.

```text
LEVEL: GT-derived synthetic OCR lines → CardFieldExtractor (NOT Vision)
total business cards: 34
typed-layer exact (mobile/office/fax/email/website/address): 34/34
full exact (typed + name/company/title): 32/34
missing-field false positives (fabrications): 0
multi-phone cards correct: 23/23
pinned semantic parser exceptions: 2
  card-019 jobTitle マネージャー  — katakana title, no CJK/latin keyword
  card-030 jobTitle "UX Researcher" — "Researcher" not in latin title table
independent exception fixtures: 1 (t20-negative-001; zero canonical fields)
business cards 34 + exception fixtures 1 are counted separately
```

Real Vision integration over dataset PNGs is the anchor-level
`StructuredExtractionDatasetSmokeTests` (cards 001–004) and targeted
real-pipeline gates; it is a different layer and is reported as such.

## Gates (W4I12 reruns)

| Gate | Command/scope | Result |
|---|---|---|
| Unit | full `SimCamCardTests`, iOS 27 sim, no parallel | **431/431 PASS, 35 suites, 0 failures/unexpected** (`/tmp/w4i12-unit.{xcresult,log}`) |
| UI deterministic | full `SimCamCardUITests` minus System01/System02 | **55/55 PASS, 0 failures/unexpected** in 1037.7s (`/tmp/w4i12-ui.{xcresult,log}`) |
| Real Contacts (separate, stateful) | `-only-testing:` System01, System02 | targeted gate, see changes.md (not rerun destructively in the final sweep; simulator Contacts state) |
| Debug build | Debug iphonesimulator | PASS (`/tmp/w4i12-debug-build.log`) |
| Release build | Release iphonesimulator | PASS (`/tmp/w4i12-release-build.log`) |
| Hook isolation | `strings -a` Release binary ×13 hooks | **13/13 ABSENT**; fresh Debug dylib **13/13 PRESENT** |

The 13 isolated DEBUG symbols (unchanged set; T20 added no hook):
8 fixture (`SimCamCardOCR`, `DebugOCRProcessor`, `DebugCameraEnvironment`,
`SimCamCardCamera`, `SimCamCardDetection`, `SimCamCardCrop`,
`SimCamCardPhotoImport`, `DebugCameraFakes`), 3 storage
(`SimCamCardStorage`, `SimCamCardStorageNamespace`,
`SimCamCardResetStorage`), 2 export (`SimCamCardContactExportMode`,
`DebugContactExporter`). The new `.minimal` OCR case rides the existing
`-SimCamCardOCR` argument, so the list stays at 13.

## Real-integration scope (plan §31, honest boundaries)

- Camera: real AVCapture session exercised on the simulator; fixture
  UI for states; **no physical iPhone** — physical hardware behavior is
  not validated.
- Vision OCR: real Vision framework in crop/OCR units and dataset smoke;
  simulator-only; no physical-camera OCR claim.
- Contacts: real `CNContactStore` targeted proof (System01/02), run
  separately because it mutates simulator Contacts; deterministic
  denial/failure via DEBUG fakes.
- Persistence: real file storage with full terminate/relaunch UI proof.

## Known non-blocking limitations (preserved from prior increments, §35)

- No physical-device validation (camera/native hardware).
- P07/P08/P09/P10/P11 remain fidelity-PARTIAL for the classified
  reasons in final-reference-audit.md; no PARTIAL was silently flipped.
- Orphan image garbage collection not implemented (technical debt, not
  required by frozen acceptance).
- Repository protocol is non-throwing; disk write failure handling is a
  recorded limitation, not a T20 protocol change.
- Corrupt-JSON recovery path not built.
- Real system photo-picker cancel gesture not independently verified.
