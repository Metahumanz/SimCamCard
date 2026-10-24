# Final Traceability Matrix — SDD Requirements → Implementation → Verification

Phase 2A-2 / Step 2 deliverable. Companion documents:
[spec-change-ledger.md](./spec-change-ledger.md) (SCL-01–13),
[course-compliance-matrix.md](./course-compliance-matrix.md),
[final-gap-list.md](./final-gap-list.md),
[final-acceptance.md](../final-acceptance.md),
[final-reference-audit.md](../final-reference-audit.md),
[real-vision-34/summary.md](../evaluation/real-vision-34/summary.md).

- Repository: `Metahumanz/SimCamCard`, branch `week4/structured-recognition`.
- HEAD at time of writing: `bdac7b0cb5194401031099e0b4e78e3c72dda148`
  (Phase 2A-1 documentation audit, 2026-10-19).
- Environment of all quoted test runs: iPhone 18 Pro Simulator, iOS 27.0
  (`5B32D815-5F37-4EE0-825C-85DE864E0B02`), `-parallel-testing-enabled NO`,
  serial execution only. Recorded toolchain baseline: Xcode 27.0; the actually
  measured Xcode 27.1 (build 27A9275) is explicitly recorded in
  [README.md](../../README.md).
- **No test was re-run for this document.** Every number below is quoted from
  the named repository record with its date and Git SHA.

---

## 1. Purpose and Scope

This matrix demonstrates the relationship between **course requirements**
(assignment v2), the **frozen specification** (`spec.md` + `spec/`),
**implementation**, **tests**, and **acceptance results**, for final delivery
review. It is a traceability index, not the final course report; detailed
narrative belongs to Step 3.

In scope: assignment v2 requirement set, T01–T20, P01–P11 (dual axis), the
34-card real Vision OCR / field-extraction evaluation, SCL-01–13
cross-reference, and the G-series open items.

Out of scope: the retired CamScanner assignment text (never used as a source);
any re-execution of tests; any physical-iPhone claim.

---

## 2. Source of Truth

Read in this priority order (per [SDD-README.md](../../SDD-README.md)):

1. `assignment/` — immutable instructor source, **v2** (English + Chinese,
   content-identical).
2. [spec.md](../../spec.md) and [spec/](../../spec/) — derived SDD baseline,
   frozen at `46f6ebe` (2026-09-29), calibrated at `b5dcf4d` (same day).
3. [evidence/screenshots/](../../evidence/screenshots/) — immutable CamCard
   8.63.1 black-box observation (40 REF images).
4. [dataset/](../../dataset/) — 34 frozen card PNGs + Ground Truth (+ 1
   separately-counted T20 non-card fixture).
5. [ai/changes.md](../changes.md) — 6302-line contemporaneous increment log.
6. [spec-change-ledger.md](./spec-change-ledger.md) — SCL-01–13 change ledger.
7. [final-acceptance.md](../final-acceptance.md) — T01–T20 behavioral
   acceptance (baseline `5ec0803`, 2026-10-05; Human Accepted 2026-10-09,
   `f5533b3`).
8. [final-reference-audit.md](../final-reference-audit.md) — P01–P11 fidelity.
9. [course-compliance-matrix.md](./course-compliance-matrix.md) — requirement
   coverage audit (2026-10-12 + Phase 2A-1 update).
10. [final-gap-list.md](./final-gap-list.md) — classified gaps + Phase 1.1
    resolutions.
11. [ai/evaluation/real-vision-34/](../evaluation/real-vision-34/) — real
    Vision OCR evaluation artifacts (summary/raw-ocr.jsonl/
    structured-results.jsonl/comparison.csv).
12. [ai/validation/](../validation/) — manual screenshot evidence per
    increment.
13. Test sources `SimCamCardTests/`, `SimCamCardUITests/` and Git history.

---

## 3. Traceability Method and Status Vocabulary

Each traced item records eleven fields: **Requirement ID · Assignment Source ·
Specification Reference · Implementation Location · Test Function / Manual
Procedure · Evidence Artifact · Observed Result · Status · Related Commit /
Baseline · Human Decision / Decision Scope · Limitation / Open Issue.**

**Three independent audit dimensions.** A single "chain complete / partial"
number is not used in this document, because it conflates three separate
questions. Every item is graded on each dimension separately, and the three
tallies are reported separately in §10.

| Dimension | Question it answers | COMPLETE / PASS criterion | PARTIAL / MISSING criterion |
|---|---|---|---|
| **A. Traceability Completeness** | Can every segment (requirement, specification, implementation, test, evidence, result, human decision) be **located**? | All seven segments are locatable by an explicit, resolvable reference (file, test function, artifact, record) | Any segment cannot be located, or is only inferable |
| **B. Verification Coverage** | Was the **relevant behavior directly exercised** by an automated test or a documented manual procedure? | The behavior named by the requirement was directly exercised, within a declared scope | The behavior was not exercised, or only a proxy/fixture stands in for the real interaction |
| **C. Reference Fidelity** | How close is the surface/behavior to the **observed CamCard Reference**? | Pixel/behavior match with observed Reference evidence | Surface differs, or the Reference behavior was never observed (`NOT OBSERVED`) |

Rules that follow from this split:

- A criterion is **not** failed because the item has a functional PARTIAL
  somewhere; conversely, a **locatable** reference is **not** proof that the
  real behavior was verified (dimension A ≠ dimension B).
- Dimension B is graded **within the item's declared platform scope**; a
  "simulator-only" item can still be B-COMPLETE while the physical-device
  question is carried as a separate platform item (G-11).
- Dimension C is graded against **observed** Reference evidence only; an
  unobserved Reference behavior is recorded as `NOT OBSERVED`, never as a
  match.

Status vocabulary (used identically in every table below):

| Status | Meaning |
|---|---|
| **PASS** | Implementation exists AND direct automated/manual evidence supports the requirement |
| **PARTIAL** | Behavior or evidence partially satisfied; the gap is classified |
| **MISSING** | Required-form evidence or artifact does not exist |
| **NOT VERIFIED** | A specific assertion was never independently exercised |
| **NOT OBSERVED** | CamCard-side behavior never observed; no value may be invented |
| **NOT TESTED** | Not executed on the relevant platform (e.g. physical iPhone) |
| **N/A** | Excluded by assignment §15 / optional field / satisfied alternative |
| **PENDING** | Awaiting a human ruling |
| **FIXED** | A recorded gap closed by a verified change (evidence cited) |

Mapping to [course-compliance-matrix.md](./course-compliance-matrix.md)
vocabulary: `MISSING-EVIDENCE` → **MISSING**; `NOT-IMPLEMENTED` is unused here
(no such item remains); `N/A-EXCLUDED` → **N/A**. No status conflicts exist
between the two documents.

**Phase/Increment-level `Accepted` records** (e.g. "Accepted — 2026-10-09",
"Accepted — 2026-10-18") are cited as **phase-level scope only**; they are
never presented as per-requirement individual approvals.

---

## 4. Course Requirement Mapping

Assignment v2 major requirements, mapped to specification, implementation,
verification and status. Cross-referenced to the compliance matrix rows
(A1–A11 / B1–B9 / C) without restating them.

| Req ID | Assignment source | Spec reference | Implementation | Test / manual procedure | Evidence artifact | Observed result | Status | Commit / baseline | Human decision / limitation |
|---|---|---|---|---|---|---|---|---|---|
| CR-01 SDD incremental process | §1, §16 | [spec.md](../../spec.md), [spec/](../../spec/) | Whole repo, 12 increments W1–W4 | Increment-by-increment log review | [ai/changes.md](../changes.md) (6302 lines, 40+ Accepted markers) | SDD loop executed natively; no one-prompt generation | **PASS** | `46f6ebe`→`de58eee` | Per-increment Accepted (increment-level); no OpenSpec artifacts ever existed |
| CR-02 Black-box reference observation | §4 (CamCard observation) | [spec/page-inventory.md](../../spec/page-inventory.md), [spec/state-inventory.md](../../spec/state-inventory.md), [spec/reference-tests.md](../../spec/reference-tests.md), [spec/observation-index.md](../../spec/observation-index.md) | n/a (observation activity) | Manual observation of CamCard 8.63.1 | 40 REF images in [evidence/screenshots/](../../evidence/screenshots/) + [evidence/image-manifest.md](../../evidence/image-manifest.md) | Flows/pages observed; card-005–034 recognition **NOT OBSERVED** (G-04) | **PASS (scoped)** | `46f6ebe` | Week 1 closeout; observation scope limited to card A/B/C + card-004 + 1 non-card |
| CR-03 Deterministic features (UI/navigation/state/persistence/edit/delete/search/tags/export) | §5.1, §7 | [spec/reference-tests.md](../../spec/reference-tests.md) T01–T20 | See T-matrix §5 rows | Unit + deterministic UI | final-acceptance.md T-matrix | T01–T20 20/20 behavioral PASS | **PASS** | `f5533b3` (2026-10-09) | Accepted 2026-10-09 (phase-level) |
| CR-04 Probabilistic OCR + field extraction | §5.2, §7.4–7.5 | spec.md §5 | `CardOCRProcessor`, `CardFieldExtractor` | Real Vision eval harness (env-gated) | [real-vision-34/](../evaluation/real-vision-34/) | Present-field match 164/233 (70.4%); 0 fabrication; error attribution done | **PASS (honest report)** | `de58eee` (2026-10-18) | Accepted 2026-10-18 (phase-level); not a char-level OCR accuracy claim |
| CR-05 Human-in-the-loop correction | §9 | spec.md §5; S05 | `manualEditing` draft, RecognitionView, CardEditView | T11 units + UI before/after | `2026-10-03-w4i3-{before,after}-edit.png` | User corrections replace extracted values; cancel/retake safe | **PASS** | `5ec0803` | Accepted 2026-10-09 (phase-level) |
| CR-06 Detail page incl. tap phone/email/website + view original | §10 | [spec/reference-tests.md](../../spec/reference-tests.md) T13/T14 | `CardDetailURLMapping`, `CardDetailFieldRow`, `CardDetailView` (+B-01/B-02 fixes) | Unit `CardDetailURLMappingTests`; UI `testCardDetailRowTapInitiatesCorrectURL`; E2E in `CardPersistenceUITests` | final-gap-list B-01/B-02 Phase 1.1 sections | tel:/mailto:/https: URLs captured via DEBUG hook; original-image viewer E2E closed loop | **PASS (FIXED, Phase 1.1)** | `de58eee` | Accepted 2026-10-18 (phase-level); system-App final handoff **NOT TESTED**; minimal structural guards only |
| CR-07 Local persistence (save→kill→relaunch→find→open) | §12 | spec.md; T18 | JSON file repositories (schemaVersion 1) + file `ImageAssetStore` | UI terminate/relaunch suite; repository units | `2026-10-04-w4i9-persistence-*-after-relaunch.png` | Cards/edits/tags/notes/both images survive relaunch | **PASS (simulator)** | `5ec0803` | Accepted 2026-10-09 (phase-level); orphan-image GC / non-throwing repo / corrupt-JSON recovery = debt G-06a/b/c |
| CR-08 Contacts export (≥1 of system Contacts / VCF) | §13 | T19 | `SystemContactExporter` (CNContactStore + CNSaveRequest) | 5 denial/failure UI + T19 units; **real** System01/System02 targeted gate | `2026-10-05-w4i11-contact-*.png` + `2026-10-05-w4i11-contacts-fields.png`; Contacts.app field check | Real CNContactStore save verified for 6 mapped fields | **PASS** | `f5533b3` | Accepted 2026-10-09 (phase-level); real Contacts tests mutate simulator address book (known side effect); VCF **N/A** (alternative satisfied) |
| CR-09 Test dataset 30–50 cards + GT | §14 | spec.md §11 | [dataset/](../../dataset/) | Dataset integrity audit; OCR smoke | [dataset-integrity-audit.md](../dataset-integrity-audit.md), [dataset/revisions/](../../dataset/revisions/) | 34 PNG + 34 GT (+1 non-card fixture, counted separately); SHA-256 multiset preserved through SCL-09 permutation fix | **PASS** | `46f6ebe`, `7c031a7` | Dataset revision record (SCL-09); pre-existing card-013 image↔GT mismatch documented, not modified |
| CR-10 Exclusions respected | §15 | [spec/page-inventory.md](../../spec/page-inventory.md) exclusion list | n/a | Code audit | final-gap-list §5 | No excluded feature implemented (CRM/cloud/subscription/segmented-enterprise search…) | **PASS** | — | — |
| CR-11 AI capability boundary (§8 five cases) | §8 | spec.md §5 | Extractor "no guessing" contracts | Per-case test functions — see **§4.1** for the case-by-case evidence table | [CardFieldExtractorTests.swift](../../SimCamCardTests/Recognition/CardFieldExtractorTests.swift), GT regression, [real-vision-34/](../evaluation/real-vision-34/) | **3 of 5 cases directly evidenced (multi-phone, mixed CJK/English, missing-field-no-fabrication); 2 PARTIAL** (ambiguity, name/company — exercised by analogous fixtures, not the assignment's literal examples) | **PARTIAL** | `5ec0803` / `de58eee` | Not all five are asserted complete; standalone-artifact form **PENDING** (G-07) |
| CR-12 AI collaboration records | §18 W6 | — | [ai/README.md](../README.md) process rules | changes.md per-increment logs | [ai/changes.md](../changes.md); `ai/prompts/_local/` **empty** | Collaboration documented; verbatim prompts **NOT DOCUMENTED** | **PARTIAL** | — | Prompt archive not reconstructable; honest-statement ruling **PENDING** (G-08) |
| CR-13 T01–T20 reference tests 100% | §17 | [spec/reference-tests.md](../../spec/reference-tests.md) | See §5 | See §5 | final-acceptance.md | 20/20 behavioral PASS | **PASS** | `f5533b3` | Accepted 2026-10-09 (phase-level) |
| CR-14 Week 5 "UI Golden Test" | §18 W5 | — | 60 deterministic XCUITests (62 `func test*` incl. 2 real-Contacts System01/02) + manual screenshot archive | **Manual** visual comparison, P01–P11 (40 REF vs 55 SimCamCard screenshots) | [evidence/screenshots/](../../evidence/screenshots/) (40 REF), [ai/validation/](../validation/) (55) | Manual visual comparison **has been performed**; an **automated** pixel/snapshot assertion **does not exist** (0 in repo — "snapshot" matches are JSON persistence snapshots, not image goldens) | **PARTIAL** | — | Manual form done; automated form not produced; whether the instructor requires the automated form is **NOT DOCUMENTED** in the assignment text; human ruling **PENDING** (G-05) |
| CR-15 Week 6 final demonstration | §18 W6 | — | — | — | — | No demo artifact exists | **PENDING (not produced)** | — | Course delivery is **not yet due/held** — this is *not* an "overdue-and-missing" item; assignment has no documented Canvas deadline/format. Form ruling **PENDING** (G-10) |
| CR-16 Final delivery + reproducibility | §18 W6 | [README.md](../../README.md) (rebuild + real-Vision reproduction guide) | Whole repo | Documentation audit (Phase 2A-1) | README.md, SDD-README.md, this document set | Reproduction commands recorded (harness line `[real-vision-34] cards=34 comparisonRows=306` precedes EVAL-JSON marker) | **PASS (docs)** | `bdac7b0` | Phase 2A-1 accepted 2026-10-19; ZIP packaging out of scope |

### 4.1 §8 AI capability-boundary — case-by-case evidence (R4)

Assignment §8 names **five** capability boundaries. They are **not** uniformly
evidenced; the table below states, per case, the exact test function, its input,
the observed result, the evidence path, and — importantly — **what the evidence
cannot prove**. Case verdicts: **3 PASS** (multi-phone, mixed CJK/English,
missing-field-no-fabrication) + **2 PARTIAL** (ambiguity, name/company
confusion), which is why CR-11 is **PARTIAL** overall, not "all five done".

| §8 case | Test function(s) | Input / Fixture | Observed result | Evidence path | Cannot prove |
|---|---|---|---|---|---|
| **1. Ambiguous content** | `labelledBilingualStandardCard`, `companyClassification` (test 10), `jobTitleClassification` (test 11), `canonicalName` (test 12), `unlabelledPhoneOther` (test 17), `websiteExtraction` (test 3) | Synthetic labelled OCR lines (label families disambiguate company/title/phone kind); unlabelled numbers deliberately fall to `.other` | Labelled/structured lines classify deterministically; **unlabelled values are never guessed** (honest `.other`) | [CardFieldExtractorTests.swift](../../SimCamCardTests/Recognition/CardFieldExtractorTests.swift) | The assignment's **literal** ambiguity examples are not used as card fixtures: a search for `Jordan`, `Consulting`, `Tongji`, `朱宏明`, `Professor` in the card tests/code returns **none** (`Apple` occurs only as an unrelated bundle id / Apple-guidance comment, never as a card example). Evidence is *analogous* fixtures, not the assignment's own wording. → **PARTIAL** |
| **2. Person-name vs company-name confusion** | `canonicalName` (test 12), `bilingualCompany` (test 14), `labelledBilingualStandardCard` (test 1) + GT `typedLayerExactAcross34Cards`, `semanticLayerMatchesPinnedExceptionRegistry` | Bilingual fixture with same-line `产品总监 \| Product Director`; 34-card frozen GT | Name and company classified into **separate fields**; native-side kept, Latin counterpart left `unclassified` (no cross-assignment) | CardFieldExtractorTests.swift; `SimCamCardTests/Recognition/StructuredGroundTruthRegressionTests.swift` | No `Jordan Lee / Lee Consulting`-style **same-token** disambiguation fixture exists; confusion risk is reduced by label logic, not proven against a dedicated ambiguous-name case. → **PARTIAL** |
| **3. Multiple phone numbers** | `multiplePhones` (test 8), `mobileLabel` (5), `officeLabel` (6), `faxLabel` (7), `duplicatePhoneDedupe` (9), `unlabelledPhoneOther` (17), `unlabelledChineseMobile` (17b) + GT `multiPhoneCardsCorrect` + UI `testStructuredMultiplePhoneFixtureShowsMobileOfficeFax` | Label families 手机/Mobile、电话/座机/Tel/Phone、传真/Fax; bare `1[3-9]`→mobile, other bare→`.other` | GT multi-phone regression **23/23**; UI fixture shows Mobile/Office/Fax rows simultaneously | CardFieldExtractorTests.swift; StructuredGroundTruthRegressionTests.swift; `SimCamCardUITests/ScanCameraUITests.swift` | Does **not** claim unlabelled real-world numbers are always typed correctly — real eval reports **30** `kind_misclassification` events (unlabeled → `.other`), documented in summary §4. → **PASS (scope = labelled + GT regression)** |
| **4. Chinese / English mixed layout** | `bilingualName` (13), `bilingualCompany` (14), `labelledBilingualStandardCard` (1) + real Vision OCR smoke `card001StandardBilingual`, `card013EnglishBioPhotographed`, `card016EnglishSoftwareEngineer` + GT `languageProfile` | Bilingual synthetic lines; real frozen cards 001/013/016 through real `RecognizeTextRequest` | Native and Latin forms both recognised and kept on the native side; mixed cards flow end-to-end | CardFieldExtractorTests.swift; `SimCamCardTests/OCR/OCRPipelineDatasetSmokeTests.swift`; [real-vision-34/](../evaluation/real-vision-34/) | Not a per-language accuracy claim; only the frozen 34-card set is measured and no character-level bilingual metric is asserted. → **PASS** |
| **5. Missing field must not be fabricated** | `websiteAbsent` (4), `noWebsiteFabricationFromEmail` (18), `emptyOCREmptyFields` (16), `rawOCRPreserved` (20), `typedLayerExactAcross34Cards` + UI `testStructuredMissingFieldFixtureOmitsWebsiteRow`, `testCardDetailMinimalCardDoesNotFabricateFields`, `testCompositeCMinimalCardShowsOnlyExistingFields` | Website-bearing vs website-absent lines; email-only line; empty OCR lines; minimal card (card-004); frozen non-card fixture | Absent website stays `nil`; email domain never promoted to website; empty OCR → all-empty result, no error; real eval **0 genuine fabrication** across 73 GT-absent cells; UI omits the absent row | CardFieldExtractorTests.swift; StructuredGroundTruthRegressionTests.swift; ScanCameraUITests.swift; CardDetailUITests.swift; real-vision-34 summary §5 | Proves absence-handling for the **tested fields** (website/email/empty); does not exhaustively enumerate every possible fabricated field. → **PASS** |

---

## 5. T01–T20 Behavioral Acceptance Matrix

**Final manual acceptance source (2026-10-24):** the owner completed a full
manual sweep of T01–T20 on a physical iPhone, all scenarios **USER-REPORTED
PASS** — [final-device-acceptance.md](../validation/physical-device/final-device-acceptance.md).
This manual evidence class supplements, and does not rewrite, the automated
per-row results below.

Source: [final-acceptance.md](../final-acceptance.md) (baseline `5ec0803`,
2026-10-05; **Human Decision: Accepted — 2026-10-09, phase-level**, `f5533b3`),
carried through Phase 1.1 (`de58eee`, Accepted 2026-10-18). Specification
column cites [spec/reference-tests.md](../../spec/reference-tests.md) reference
status. Automated rows are simulator-based; physical-device evidence enters only
through the 2026-10-23/24 user-reported sessions (G-11) referenced above.

### T01 — First Launch / Empty Holder
- **Assignment:** §7.1 Feature 1 · **Spec:** T01 (Reference: Observed)
- **Implementation:** `SimCamCard/View/CardHolder/CardHolderView.swift` (`card-holder-empty`)
- **Test:** UI `CardHolderEmptyUITests`; Holder unit suite · **Evidence:** `ai/validation/2026-09-29-increment3-empty-holder.png`
- **Observed result:** Empty state, scan entry, zero `card-row-*` · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** none

### T02 — Enter Scanner
- **Assignment:** §7.2 · **Spec:** T02 (Observed)
- **Implementation:** `SimCamCard/View/Scan/ScanEntryView.swift` (`scan-entry-view`); **final entry mechanism (post-PD-B02, `9c994c2`):** Card Holder toolbar Button + `.navigationDestination(isPresented:)` with stable `ToolbarItem(id: "card-holder-scan-entry")` — standard horizontal NavigationStack push (entry was `NavigationLink(value:)` before the fix)
- **Test:** UI `ScanEntryUITests` (re-run **2/2 PASS on final code, 2026-10-23**); Week-2 integration · **Evidence:** `ai/validation/2026-09-29-increment6-scan-entry.png`
- **Observed result:** Scan entry opens scanner UI with preview/capture/import/close · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** simulator; PD-B02 device symptom tracked in §9.1 (USER-REPORTED PASS, core symptom only)

### T03 — Camera Permission
- **Assignment:** §7.2 (camera permission denied must be a defined state; denial never crashes; system dialogs stay native) · **Spec:** T03 (Reference: Partial — only the native system dialog was observed)
- **Implementation:** `SimCamCard/ViewModel/ScanViewModel.swift` **camera**-authorization mapping (unknown/authorized/denied/restricted); stable `scan-permission-denied` fallback page with no capture/import actions; native AVFoundation request (no replica dialog)
- **Test:** UI `testDeniedShowsStableFallbackWithoutSessionUI`, `testNotDeterminedGrantedResolvesToPreview`, `testNotDeterminedDeniedResolvesToFallback` (`ScanCameraUITests.swift`); camera permission units · **Evidence:** `ai/validation/2026-10-07-w4i12-camera-denied.png`, `2026-09-30-increment1-camera-preview-authorized-fixture.png`
- **Observed result:** **Camera** allow / deny / restricted map to defined states; camera denial stable, no crash · **Status:** **PASS (behavior)**; the custom denied fallback is beyond the frozen dialog-only evidence (P02 deferred cosmetic)
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09
- **Limitation (T03's own, from its own evidence):** the three camera-permission UI tests are **DEBUG-fixture-driven** — the permission state is injected through the camera seam, and `final-acceptance.md` labels the `2026-10-07-w4i12-camera-denied.png` evidence "(fixture)". A real system camera-permission dialog interaction (a human tapping Allow/Deny in the native dialog) was therefore **not independently exercised**. This limitation belongs to T03 itself and is **not** borrowed from G-02.
- **Separate item — not a T03 limitation:** `spec/reference-tests.md` §T03 "Additional detailed checks" additionally lists *photo library allowed / photo library denied*. That photo-library sub-item is tracked as **its own item G-02** (§9) and is neither part of T03's camera-permission status nor covered by T03's evidence. T03's PASS must not be credited to, or debited against, G-02.

### T04 — Capture
- **Assignment:** §7.2 · **Spec:** T04 (Observed)
- **Implementation:** real AVCapture still capture → crop → OCR auto-chain; DEBUG capture fixtures
- **Test:** UI capture/crop tests; capture units · **Evidence:** `ai/validation/2026-10-01-increment2-captured-photo-fixture.png`
- **Observed result:** Captured card enters recognition workflow · **Status:** **PASS (simulator)**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** automated evidence simulator-only; physical-iPhone capture **USER-REPORTED PASS** in the 2026-10-24 manual sweep (G-11)

### T05 — Photo Import
- **Assignment:** §7.2 (import from photo library; cancel safe) · **Spec:** T05 (Observed)
- **Implementation:** real system `PhotosPicker`; DEBUG imported/cancel/load-failure fixtures; `handleImportCancel` ordering (preview restart, no crop/OCR/draft)
- **Test:** UI import happy/cancel/failure tests; import-cancel units · **Evidence:** `ai/validation/2026-10-01-increment3-photo-import-fixture.png`
- **Observed result:** Fixture-driven import/cancel/load-failure outcomes asserted via the real PhotosPicker integration seam · **Status:** **PASS (behavioral mechanics)**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09
- **Limitation (T05's own):** the import / cancel / load-failure outcomes are driven by DEBUG fixtures through the real `PhotosPicker` integration seam; a real user-initiated **cancel gesture inside the system PhotosPicker UI** was never exercised. Tracked as **G-03** (§9).
- **Clarification of association:** **T05 is photo-library import**; the camera-permission item is **T03**. The `PhotosPicker` belongs to T05, **not** to T03 camera permission. **T05 PASS must not be read as G-03 PASS**, and G-02 (photo-library *authorization* / `PhotosPicker` platform semantics) is a further distinct item that T05 does not exercise either.

### T06 — Boundary Detection
- **Assignment:** §7.3 (detect/visualize/adjust/confirm/retake + dataset result requirement) · **Spec:** T06 (Observed)
- **Implementation:** real Vision rectangle detection; `CardRegionGeometry.minimumDetectedArea = 0.05` gate (SCL-11); `CardCropProcessor` perspective/orientation correction; `CardCropView` handles
- **Test:** UI crop auto/manual/confirm/retake; crop units; real-pipeline dataset smoke (cards 001–004); `CardRegionGeometryTests` +3, `CardCropProcessorTests` +3 (Phase 1.1) · **Evidence:** `ai/validation/2026-10-01-increment5-crop-*.png`; [real-vision-34/summary.md](../evaluation/real-vision-34/summary.md) §2/§9
- **Observed result:** All 14 historical tiny-quad lock-ons now fall back (zero-OCR-line cards 14→0, pipeline errors 2→0) · **Status:** **PASS (simulator; G-01 FIXED)**
- **Baseline:** `de58eee` · **Decision:** phase-level Accepted 2026-10-18 · **Limitation:** physical-device detection **accuracy** not quantitatively measured (functional coverage user-reported 2026-10-24)

### T07 — OCR Raw Text
- **Assignment:** §7.4 (preserve intermediate process) · **Spec:** T07 (Reference: **Partial** — CamCard never exposed a raw-text screen)
- **Implementation:** `SimCamCard/OCR/CardOCRProcessor.swift` (RecognizeTextRequest .accurate, auto language, correction off); `OCRLine` top-1 verbatim; `BusinessCard.rawOCRText` persisted
- **Test:** OCR/extractor units (incl. real Vision textless-image and rendered-text); raw fixture UI · **Evidence:** `ai/validation/2026-10-01-increment6-raw-ocr-fixture.png`, `2026-10-02-increment7-camera-to-raw-ocr.png`; [raw-ocr.jsonl](../evaluation/real-vision-34/raw-ocr.jsonl)
- **Observed result:** Raw text preserved verbatim and persisted; intermediates consumable for analysis · **Status:** **PASS (preservation contract)**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** no in-app raw-text viewer (Reference never exposed one; fidelity gap only)

### T08 — Structured Extraction
- **Assignment:** §7.5 (8 required fields) · **Spec:** T08 (Observed)
- **Implementation:** `SimCamCard/Recognition/CardFieldExtractor.swift` (Phase A typed tokens + Phase B semantic; deterministic, no fabrication)
- **Test:** Unit T08 + real Vision smoke card-001 + fixture UI; GT regression 34 cards · **Evidence:** `ai/validation/2026-10-02-w4i2-structured-recognition.png`
- **Observed result:** name/company/jobTitle/mobile/office/fax/email/website/address classified · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** Department/Postal Code **N/A** (assignment-optional, absent from Domain)

### T09 — Missing Field (no fabrication)
- **Assignment:** §7.5 + §8 missing-field case · **Spec:** T09 (Observed)
- **Implementation:** website only from `www.`/`http(s)://` tokens; email-domain masking; nil stays nil
- **Test:** Unit card-002 + extractor website rules; GT regression 0 website false positives · **Evidence:** `ai/validation/2026-10-02-w4i2-missing-field.png`
- **Observed result:** Absent website never fabricated (real eval: 0 genuine fabrication across 73 GT-absent cells) · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** none

### T10 — Multiple Phones
- **Assignment:** §7.5 + §8 multi-phone case · **Spec:** T10 (Observed)
- **Implementation:** label families 手机/Mobile、电话/Tel、传真/Fax; bare `1[3-9]` → mobile, other bare numbers honestly `.other`
- **Test:** Unit card-003; real Vision smoke; GT multi-phone 23/23 · **Evidence:** `ai/validation/2026-10-02-w4i2-multiple-phones.png`
- **Observed result:** Labeled phones classified separately; GT regression 23/23 · **Status:** **PASS (deterministic)**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** real-eval kind_misclassification 30 (unlabeled numbers → `.other`, reported honestly in summary §4)

### T11 — Manual Correction
- **Assignment:** §9 · **Spec:** T11 (Observed)
- **Implementation:** `RecognitionState.manualEditing(RecognitionDraft)`; draft preserves `source: StructuredRecognitionResult`; blank corrections dropped
- **Test:** Unit T11 suite; UI before/after + retake-discard · **Evidence:** `ai/validation/2026-10-03-w4i3-{before-edit,after-edit}.png`
- **Observed result:** Corrected values replace extracted values; original recognition immutable · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** none

### T12 — Save
- **Assignment:** §7.1 (immediate list update) + §12 · **Spec:** T12 (Observed)
- **Implementation:** `SaveState` idle/saving/saveSucceeded; `isSaveInFlight` guard; image bytes stored before card write; raw OCR retained
- **Test:** Unit T12 suite (11 cases incl. gating/byte-exact assets); UI direct-save + corrected-save · **Evidence:** `ai/validation/2026-10-03-w4i4-{p06-save-success,holder-after-save,detail-saved-card}.png`
- **Observed result:** Save succeeds; new card appears immediately; both images persisted · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** none

### T13 — Detail
- **Assignment:** §10 · **Spec:** T13 (Observed)
- **Implementation:** `CardDetailView` all scalars + multi-value rows + image strip + full-screen original viewer (B-02) + URL-mapping actions (B-01)
- **Test:** UI detail tests (001 full, 004 minimal); VM units; B-01/B-02 Phase 1.1 tests (see CR-06) · **Evidence:** `ai/validation/2026-09-29-increment5-card-detail-001-full.png`, `2026-09-29-increment5-card-detail-004-minimal.png` (actual files dated 2026-09-29; final-acceptance.md prints 09-30 — pre-existing record typo, that document is read-only this step)
- **Observed result:** All saved fields visible; original card viewable; phone/email/website tappable · **Status:** **PASS (behavior)**; P07 fidelity **PARTIAL**
- **Baseline:** `de58eee` · **Decision:** phase-level Accepted 2026-10-09 + 2026-10-18 · **Limitation:** fidelity gaps classified in final-reference-audit P07

### T14 — Edit
- **Assignment:** §10 · **Spec:** T14 (Observed)
- **Implementation:** `BusinessCardEditDraft` (separate from RecognitionDraft); preserves id/images/rawOCRText/createdAt/tags/notes; phone IDs stable
- **Test:** Unit T14 (save/cancel/re-entrant); UI edit/cancel · **Evidence:** `ai/validation/2026-10-04-w4i5-existing-edit-*.png`
- **Observed result:** Edited values reflected in stored/detail data immediately and after relaunch · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** none

### T15 — Search
- **Assignment:** §11 (name/company/job title/phone/email) · **Spec:** T15 (Observed for name/company only)
- **Implementation:** `CardSearchView` + deterministic matcher (case-insensitive contains; phone digit-normalized); presentation-only, no repository mutation
- **Test:** Unit five scopes + empty/clear/non-mutation; UI no-result + clear + group composition (E14/E19) · **Evidence:** `ai/validation/2026-10-04-w4i6-search-{name,company}.png`
- **Observed result:** All five required scopes pass · **Status:** **PASS (required scopes)**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** 综合/企业 segmented surfaces **N/A** (§15 exclusion, P08)

### T16 — Tag / Group
- **Assignment:** §11 (Create→Assign→View→Delete keeps cards) · **Spec:** T16 (Observed)
- **Implementation:** independent group catalog; delete removes tag only
- **Test:** Unit T16 (incl. delete-keeps-cards); UI full + delete; `testCreateGroupCancelLeavesCatalogAndCardsUnchanged` (E12, both create cancels) · **Evidence:** `ai/validation/2026-10-04-w4i7-group-*.png`
- **Observed result:** Full workflow incl. both cancel paths proven · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** none

### T17 — Delete
- **Assignment:** §7.1/§10 · **Spec:** T17 (Observed)
- **Implementation:** `DeleteState` confirming; guarded delete; cancel no-op
- **Test:** Unit T17 (confirm/cancel/re-entrant, safe missing-id); UI · **Evidence:** `ai/validation/2026-10-04-w4i8-{delete-confirmation,holder-after-delete}.png`
- **Observed result:** Confirmation precedes delete; card gone afterward · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** orphan image files remain (debt G-06a)

### T18 — Persistence
- **Assignment:** §12 · **Spec:** T18 (Observed)
- **Implementation:** JSON file repositories (schemaVersion 1); file image store; namespaced UI-test storage; absent-file/missing-UUID stability (E17/E18)
- **Test:** UI terminate(.notRunning)/relaunch suite; file repository units; Phase 1.1 original-image E2E across relaunch · **Evidence:** `ai/validation/2026-10-04-w4i9-persistence-*-after-relaunch.png`
- **Observed result:** Cards, edited fields, groups/tags, notes, original + processed images survive full quit/relaunch · **Status:** **PASS (simulator)**
- **Baseline:** `de58eee` · **Decision:** phase-level Accepted 2026-10-09 + 2026-10-18 · **Limitation:** G-06a/b/c technical debt recorded (orphan GC, non-throwing repo, corrupt-JSON recovery)

### T19 — Export to Contacts
- **Assignment:** §13 (six-field mapping) · **Spec:** T19 (Observed)
- **Implementation:** `SystemContactExporter` (CNContactStore + CNSaveRequest); pure mappers; DEBUG scripted exporter for denial/failure
- **Test:** 5 fake permission/failure UI tests + T19 units (six-field mapping, multi-value, double-write guard); **real** System01/System02 targeted gate + Contacts.app field verification (stateful, run separately) · **Evidence:** `ai/validation/2026-10-05-w4i11-{contact-permission,contact-export-success,contact-denied,contacts-fields}.png` (four actual filenames; final-acceptance.md's brace expansion prints `contact-contacts-fields.png` — pre-existing record typo, actual file is `contacts-fields.png`)
- **Observed result:** Real CNContactStore save; name/company/title/phone/email/address mapped · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** P11 fidelity PARTIAL (diff-1..5, macOS/Catalyst reference surface, G-12); real tests mutate simulator Contacts

### T20 — Exception Handling
- **Assignment:** §7.2 (denial), §9, frozen negative fixtures · **Spec:** T20 (Observed for key negative inputs)
- **Implementation:** E06 failure offers Retake + Cancel (`scan-recognition-cancel`); E07 `canSaveCurrentCard` guard + disabled Save on empty result; E08 DEBUG `.minimal` fixture (rides existing hook, no new strings)
- **Test:** UI `ExceptionHandlingUITests` (composite B non-card empty: Save visible-but-disabled + tap no-op; composite C minimal; failure→Cancel→Holder); Unit E07 1/2/3; prior E01–E20 re-audited · **Evidence:** `ai/validation/2026-10-07-w4i12-{camera-denied,non-card-empty-result,minimal-card,recognition-failure}.png` (xcresult attachments)
- **Observed result:** Two-layer negative-fixture proof: (1) deterministic DEBUG empty fixture drives state mapping + save guard; (2) frozen real non-card PNG through the real production pipeline → wasDetected=false, 0 OCR canonical fields (targeted gated run, scratch deleted) · **Status:** **PASS**
- **Baseline:** `f5533b3` · **Decision:** phase-level Accepted 2026-10-09 · **Limitation:** the two layers are not interchangeable; GT-synthetic regression is a separate parser layer

**T-matrix totals: 20/20 behavioral PASS.** Per-axis tallies are recomputed
independently in §10 (dimensions A / B / C). The following IDs are **distinct
and must not be merged**:

- **T03 = camera permission** (own limitation: fixture-driven states; the real
  native dialog interaction was not independently exercised).
- **T05 = photo-library import** (own limitation: the system-picker real cancel
  gesture is not verified → **G-03**).
- **G-02 = photo-library authorization / iOS 27 `PhotosPicker` platform
  semantics** — a **separate item**, historically listed under the spec's §T03
  "additional detailed checks" but **not** a T03 sub-status and **not** covered
  by T05's mechanics PASS.

T04 / T06 / T18 are simulator-scoped; T07's verification is complete and its
only gap is reference-fidelity / reference-observability.

---

## 6. P01–P11 Reference Fidelity Matrix

Dual axis per page — **Behavioral Acceptance** and **Reference Fidelity** are
independent; a behavior PASS never covers a fidelity PARTIAL. Source:
[final-reference-audit.md](../final-reference-audit.md) (baseline `5ec0803`).

| Page | Behavioral acceptance (proof) | Reference fidelity (classification) | Commit | Limitation |
|---|---|---|---|---|
| P01 Card Holder | **PASS** (T01/T15/T16/T17, E14/E19) | **PARTIAL** (deferred cosmetic: row chrome, pushed search page) | `f5533b3` | cosmetic only |
| P02 Scanner | **PASS** (fixture + real AVCapture on simulator) | **PARTIAL** (no physical-device frames; custom denied page beyond frozen evidence) | `f5533b3` | platform boundary |
| P03 Photo Picker | **PASS mechanics**; system-picker cancel **NOT VERIFIED** (G-03) | **PARTIAL** (system surface) | `f5533b3` | G-03 open |
| P04 Crop / Boundary | **PASS** (T06, E05) | **PASS** (functional; minor cosmetic) | `de58eee` | physical accuracy not claimed |
| P05 Recognition / Edit | **PASS** (incl. T20 empty/minimal/failure rules E06–E08) | **PARTIAL** (deferred cosmetic; Save-disabled state beyond observed evidence; raw transitional surface) | `f5533b3` | evidence boundary documented |
| P06 Save Result | **PASS** (T12) | **PARTIAL** (deferred cosmetic: success illustration) | `f5533b3` | cosmetic only |
| P07 Card Detail | **PASS** (T13/T14 + B-01/B-02 fixes) | **PARTIAL** (W2I5 recorded gaps: avatar/header/star/more-menu/action-bar; 展开/收起 distinct state not implemented) | `de58eee` | cosmetic + frozen-domain; tel/mailto/URL reclassified to course-required (B-01, FIXED) |
| P08 Search Results | **PASS** (five scopes, E14/E19) | **PARTIAL** (excluded segmented surfaces) | `f5533b3` | §15 exclusion |
| P09 Group Management | **PASS** (incl. E12 create-cancel evidence) | **PARTIAL** (deferred cosmetic) | `f5533b3` | cosmetic only |
| P10 Notes | **PASS** (unit + UI, W4I10) | **PARTIAL** (deferred cosmetic; frozen-domain inline summary row) | `f5533b3` | cosmetic + frozen-domain |
| P11 Contact Export | **PASS** (real CNContactStore proof) | **PARTIAL** (diff-1..5: denied surface, macOS account selector, label mapping, website not exported) | `f5533b3` | platform / frozen-domain (G-12) |

**Axis totals: Behavioral 11/11 PASS · Fidelity 1/11 PASS (P04) + 10/11
PARTIAL · Open real-blockers: 0.** No PARTIAL was silently flipped.

---

## 7. OCR and Probabilistic Evaluation

Source: [ai/evaluation/real-vision-34/](../evaluation/real-vision-34/)
(summary.md header "Generated: 2026-10-15"; content reflects the gated
after-run with §9 before/after tables; harness env-gated
`TEST_RUNNER_REAL_VISION_EVAL=1`, does not pollute the deterministic baseline).

**Timeline (R6 check — three dates must not be conflated):**

- **Measurement / generation date: 2026-10-15** — `summary.md` header
  "Generated: 2026-10-15"; `environment.md` "Run date (UTC, device clock):
  2026-10-15T04:45:25Z" (`Xcode: 27.0`, `iOS: 27.0`). Both payload files carry
  on-disk mtimes of 2026-10-15 (`_eval-payload.json` 12:45,
  `_eval-payload-pre-gate-baseline.json` 13:11).
- **Repository / revision date: 2026-10-18** — the whole
  `ai/evaluation/real-vision-34/` directory first appears in Git in
  `de58eee` (2026-10-18); it does **not** exist at `5ec0803` (2026-10-05) or
  `f5533b3` (2026-10-09). `git log` for `summary.md` shows only `de58eee`.
- **Phase 1.1 Accepted date: 2026-10-18** — same commit, phase-level acceptance
  (not a per-requirement approval).

**Recorded facts — run count not inferred:** §9's before/after tables depend on
the G-01 area gate, while `minimumDetectedArea` is committed only at `de58eee`
(2026-10-18). Two payload files are stored side by side: `_eval-payload.json`
(after-gate) and `_eval-payload-pre-gate-baseline.json` (pre-gate).
`environment.md` states that the pre-gate baseline was produced by temporarily
reverting and restoring the gate for measurement. **The number of actual runs and
the config-switch timing are not separately logged**, so they are **not
inferred** here. The three dates listed above are all that the repository
records; no additional run count or run date is asserted.

**The 164/233 (70.4%) figure is a present-field match rate** — matches over
cells where GT is non-null — computed by `compact`/`digits` substring
normalization (see `environment.md` §Normalization). **It is not a
character-level OCR accuracy figure**, and no character-level metric is claimed
anywhere in this document (consistent with §7 item 4 below).

Layer separation (must not be conflated):

1. **Vision OCR output** — raw text lines from real
   `RecognizeTextRequest` (.accurate, auto-language, correction off): 316 lines,
   0 zero-line cards, 0 pipeline errors (after run). Preserved verbatim in
   [raw-ocr.jsonl](../evaluation/real-vision-34/raw-ocr.jsonl) (per-line
   confidence + detection region/area + full-image diagnostic OCR).
2. **Field parsing** — deterministic `CardFieldExtractor`: given the GT anchor
   reached raw text (219/233, 94.0% coverage), extractor classified correctly
   164/219 (74.9% conditional).
3. **Ground Truth comparison** — 306 rows (34×9) in
   [comparison.csv](../evaluation/real-vision-34/comparison.csv) against frozen
   GT; per-card matrix in summary §6.
4. **Present-field match rate** — **164/233 = 70.4%** (strict `M` + bilingual
   native-side `N`). Pre-gate baseline: 109/233 = 46.8% (same harness/GT/
   normalization; per-card before/after in summary §9). **This is a field-level
   match rate, not a character-level OCR accuracy figure; no character-level
   metric is claimed anywhere.**
5. **GT-absent classification** — 73 absent cells, four mutually exclusive
   buckets, identical definition before/after: strict canonical absence
   68→**64**, alternate-language exact 3→**7**, alternate-language partial
   2→**2**, genuine fabrication 0→**0**. Partial overlaps (e.g. `BioSystems` /
   `Stonepine BioSystems`) are marked PARTIAL and never counted as exact.
6. **CamCard comparison data** — real CamCard recognition observed only for
   card A/B/C (=card-001/002/003), card-004 (minimal-behavior) and 1 non-card;
   **card-005–034 NOT OBSERVED** — no CamCard accuracy numbers exist for the
   34-card dataset beyond those, and none may be invented (G-04).

Per-field after-run (present denominator): name 28/34 (82.4%), company 15/20
(75.0%), jobTitle 28/33 (84.8%), address 11/31 (35.5%), mobile 19/32 (59.4%),
office 8/23 (34.8%), fax 2/4 (50.0%), email 29/31 (93.5%), website 24/25
(96.0%). Card-level all-9-fields match: 9/34.

Root-cause split of the 69 non-matching present cells (after run):
**4 detector/crop · 10 OCR recognition · 55 extractor** (summary §2).

**G-01 before/after evidence:** area gate `minimumDetectedArea = 0.05`
(SCL-11, `de58eee`): detection accepted 33→19, fallback 1→15, zero-OCR-line
cards 14→0, pipeline errors 2→0, present-field match 109→164. Dataset mapping
correction (SCL-09) preceded evaluation: SHA-256 multiset identical
before/after permutation; contact sheets re-generated and human-verified
([dataset/revisions/2026-10-02-image-id-permutation.md](../../dataset/revisions/2026-10-02-image-id-permutation.md)).

**GT-level parser regression (separate layer, not real Vision):**
`StructuredGroundTruthRegressionTests` — typed 34/34, full-exact 32/34 (2
pinned parser exceptions: card-019 マネージャー, card-030 "UX Researcher"),
0 fabrications, multi-phone 23/23.

---

## 8. SCL Change Cross-Reference

Full 12-field records live in [spec-change-ledger.md](./spec-change-ledger.md);
this index links Change ID → requirement → implementation → verification
without duplicating the ledger body.

| Change | Requirement / spec link | Implementation (commit) | Verification | Ledger § |
|---|---|---|---|---|
| SCL-01 Week 1 freeze calibration | spec.md §11/§12, header | `b5dcf4d` | doc-only; `git show b5dcf4d -- spec.md` | §5 SCL-01 |
| SCL-02 Required image references | spec.md §12 (persistence) | `6fa0910` | `BusinessCardTests`; Domain-import audit | §5 SCL-02 |
| SCL-03 Repository ordering un-freeze + T12/T17 traceability | T12/T17 | `d2c477e`* (Implementation present, dedicated commit absent) | `InMemoryBusinessCardRepositoryTests` | §5 SCL-03 |
| SCL-04 Camera-session concurrency architecture | S02/S03 | `eeefbbe` (actor first appears here — verified) | camera unit 50/50 + UI 13/13 | §5 SCL-04 |
| SCL-05 Initial start failure → cameraUnavailable | S02, T03 | `eeefbbe` | camera contract tests | §5 SCL-05 |
| SCL-06 Vision aspect-ratio semantics + rollback + orientation wording | T06, S02/S03 | `db0cc90`* | T06 deterministic UI + crop units | §5 SCL-06 |
| SCL-07 Crop confirmation interaction freeze | T06 2nd half, S04 | `68d242c`* | crop UI/unit | §5 SCL-07 |
| SCL-08 Photo-import presentation binding | T05, S03 | `08745a4`* | import unit + UI | §5 SCL-08 |
| SCL-09 Dataset image-ID permutation correction | spec.md §11, assignment §14 | `df334f5`→`7c031a7`→`e68f7c1` | contact sheets + revision doc + SHA-256 multiset | §5 SCL-09 |
| SCL-10 Actor reentrancy wording correction | spec.md §5 | `b0404e2` (verified in tree) | `staleACannotOverwriteNewerB` | §5 SCL-10 |
| SCL-11 G-01 detector area gate | §7.3 dataset result requirement | `de58eee` (verified: absent at `68d242c`, present at `de58eee`) | `CardRegionGeometryTests`+3, `CardCropProcessorTests`+3, 34-card re-eval | §5 SCL-11 |
| SCL-12 B-01 detail-page tap phone/email/website | assignment §10 | `de58eee` | `CardDetailURLMappingTests`, UI openURL-capture tests | §5 SCL-12 |
| SCL-13 B-02 original-card viewer | assignment §10 | `de58eee` (verified: `fullScreenCover`/`originalImage` absent at `5ec0803`) | VM byte-level unit + `CardPersistenceUITests` E2E | §5 SCL-13 |

\* folded into increment commits; attribution by increment/date (ledger §4
marker, §6.2 "Implementation present, dedicated commit absent").

---

## 9. G-Series Open Issue Matrix

Source: [final-gap-list.md](./final-gap-list.md) (+ Phase 1.1 / 2A-1 updates).
No item upgraded without new evidence.

**Status vocabulary for this section** (distinct meanings — do not merge):
**FIXED / RESOLVED** (gap closed by a verified change, evidence cited) ·
**DOCUMENTED PLATFORM DIFFERENCE** (difference explained and attributed to the
platform / frozen domain; **no explicit human-acceptance record** — explained is
**not** approved) ·
**DOCUMENTED DEBT** (recorded in docs only — **not** the same as fixed) ·
**PENDING HUMAN DECISION** (awaiting a ruling) ·
**NOT TESTED** (not executed on the relevant platform) ·
**NOT OBSERVED** (reference-side behavior never seen; no value may be invented) ·
**ADDRESSED (context note)** (documentation/context handled, no behavior claim).

| ID | Item | Category | Direct evidence exists? | Status | Human ruling still needed |
|---|---|---|---|---|---|
| G-01 | Vision detector tiny-quad lock-on (14/34) | probabilistic defect | yes (summary §9 before/after) | **FIXED** (`de58eee`, area gate) | none |
| G-02 | Photo-library permission-denied test item | platform limitation | `REF-permission-02` + load-failure fixture only | **PENDING HUMAN DECISION / NOT TESTED** | (a) platform-statement report, (b) constrained/legacy repro, or (c) instructor ruling |
| G-03 | Real system PhotosPicker cancel gesture | missing validation evidence | fixture-level cancel proven; real gesture not exercised | **NOT VERIFIED / PENDING HUMAN DECISION** | ~2-minute manual capture + archive |
| G-04 | CamCard comparison scope card-005–034 | reference observation gap | none for those 30 cards | **NOT OBSERVED / PENDING HUMAN DECISION** | supplementary captures vs bounded-scope statement (no ruling on record; **no inference** that re-capture is forbidden) |
| G-05 | Week 5 "UI Golden Test" form | missing evidence (automated form) | **manual** visual comparison done (40 REF vs 55 SimCamCard screenshots); **0** automated pixel/snapshot assertions; 60 deterministic XCUITests (62 funcs) | **PARTIAL / PENDING HUMAN DECISION** | instructor-form ruling (manual vs automated) — assignment text does **not** state the required form |
| G-06a/b/c | Orphan-image GC; non-throwing repository; corrupt-JSON recovery | non-blocking debt | recorded in final-acceptance §35 | **DOCUMENTED DEBT** (each; recorded, **not** fixed) | none (not required by frozen acceptance) |
| G-07 | AI capability-boundary standalone document | course-required content, artifact form open | content exists scattered (§4.1 case evidence, extractor units, GT regression, changes.md) | **Content done / artifact PENDING HUMAN DECISION** | compile standalone vs cite in report (ledger §8) |
| G-08 | Prompt-level collaboration archive | course-required content, evidence unrecoverable | changes.md 6302 lines + 40+ Accepted markers; `ai/prompts/_local/` empty | **NOT DOCUMENTED (prompts) / PENDING HUMAN DECISION** | accept honest statement vs substitute form |
| G-09 | README stale ("Week 1 Frozen") | doc debt | Phase 2A-1 rewrite | **RESOLVED** (`bdac7b0`) | none |
| G-10 | Final demonstration artifact | course-required, form open | none | **PENDING HUMAN DECISION (artifact not produced)** | Canvas delivery-spec ruling — delivery **not yet due/held**, not "overdue and missing" |
| G-11 | Physical-iPhone verification | platform limitation | **2026-10-24 owner-reported full manual acceptance sweep on a physical iPhone** covering T01–T20 behaviours, PD-B01/PD-B02, capture/retake/cancel, PhotosPicker import+cancel, boundary detection + manual crop, OCR fields, manual edits, save/detail/edit, search/tags/delete, kill→relaunch persistence, contacts export, camera-permission denial + recovery, backgrounding/appearance/safe-area ([final-device-acceptance.md](../validation/physical-device/final-device-acceptance.md)); earlier 2026-10-23 session covered the PD-B01/PD-B02 core transition symptoms ([PD-B01-PD-B02-device-validation.md](../validation/physical-device/PD-B01-PD-B02-device-validation.md), code `9c994c2`) | **USER-REPORTED PASS (full manual sweep)** | evidence class stays **user-reported**: no automated device runner, no captured artifacts, device model / iOS version NOT PROVIDED; quantitative device-side detection accuracy remains unmeasured |
| G-12 | Contacts export surface differences | platform / frozen-domain | final-reference-audit P11 diff-1..5 | **DOCUMENTED PLATFORM DIFFERENCE** (diff-1..5 explained/classified; **no explicit human-acceptance record** — not "approved") | none on record |
| G-13 | `evidence/image-manifest.md` header stale | doc debt (frozen file) | revision draft exists, not applied | **PENDING HUMAN DECISION** | file stays frozen; header revision decision |
| G-14 | changes.md historical pre-commit voice | doc context | Retrospective Summary appended (Phase 2A-1) | **ADDRESSED (context note)** | none |

**Status tally (replaces any earlier single "N open" total).** 14 tracked IDs
(G-06 counted once as a/b/c sub-items):

- **Closed (evidence-backed): 2** — G-01 **FIXED**, G-09 **RESOLVED**.
- **Context-only (no behavior claim): 1** — G-14 **ADDRESSED**.
- **Documented platform difference (explained, not approved): 1** — G-12.
- **Documented debt (not fixed): 1 ID (3 sub-items)** — G-06a/b/c.
- **Pending a human decision: 8** — G-02, G-03, G-04, G-05, G-07, G-08, G-10, G-13.
- **Not tested / not observed (platform or reference boundary, no ruling
  possible while the constraint stands): carried inside the pending set** —
  G-02 (NOT TESTED), G-04 (NOT OBSERVED). G-11 was previously carried here as
  NOT TESTED; after the 2026-10-23 core-symptom session and the **2026-10-24
  full manual acceptance sweep** it is **USER-REPORTED PASS (manual evidence
  class — no automated device run, no captured artifacts)** (see the G-11 row).

So the honest split is **3 items closed or context-only, 1 documented platform
difference, 1 documented-debt ID, 8 awaiting a human decision, and 1
user-reported on device across a full manual sweep (G-11)** — the earlier
shorthand "14 items, 9 remain open" is **withdrawn** (it merged debt, platform
differences and pending decisions into one count).

---

### 9.1 Implementation-fix traceability: PD-B01 / PD-B02 (post-baseline, 2026-10-23/24)

These are **implementation bugfixes against the frozen specification**, not new
spec changes — no SCL entry is created for them (ledger classification rule:
implementation fixes to frozen-spec behaviour are not spec modifications).
Evidence: code commit `9c994c2`, validation record commit `a12492e`
([PD-B01-PD-B02-device-validation.md](../validation/physical-device/PD-B01-PD-B02-device-validation.md)).

| ID | Phenomenon (physical iPhone, user-reported) | Root cause (code-level judgement, **not** UIKit-log-proven) | Fix | Automated evidence on final code | Device result |
|---|---|---|---|---|---|
| PD-B01 | Card Holder flashed dark for one frame when returning from the Scanner | `.preferredColorScheme(.dark)` is window-level; its preference lingered during the NavigationStack pop | view-local `.environment(\.colorScheme, .dark)` on ScanEntryView / CardCropView / RecognitionView | Debug Build PASS; Unit 466/466; ScanEntryUITests 2/2 PASS (2026-10-23) | **USER-REPORTED PASS (core symptom)** 2026-10-23; no regression reported in the 2026-10-24 full manual sweep |
| PD-B02 | Source bar's trailing "+" ToolbarItem clipped at the screen edge during the push into the Scanner (bar hidden on destination) | destination page had no navigation bar to receive the source item; stable-id + always-present content matches the community-reported iOS 26+ Liquid Glass pattern | `.navigationDestination(isPresented:)` + `ToolbarItem(id: "card-holder-scan-entry")` + always-present Button (failed attempts — transparent bar + `ignoresSafeArea` regression, fullScreenCover vertical animation, conditional Button removal — recorded in the validation doc) | same as PD-B01 | **USER-REPORTED PASS (core transition symptom)** 2026-10-23; no regression reported in the 2026-10-24 full manual sweep |

Automated-test boundary for both fixes (2026-10-23): Unit **466/466 PASS**;
ScanEntryUITests **2/2 PASS**; ScanCameraUITests (24) + ExceptionHandlingUITests
(3) **BLOCKED — 0 executed** (`DTServiceHubClient` simulator service failure);
other 33 UI tests **NOT RUN**. A single re-run was attempted on 2026-10-24 and
also **BLOCKED — 0 executed**: build-for-testing failed with
`swift-plugin-server produced malformed response` (macro toolchain environment
failure; the identical code compiled cleanly the same day). The historical
Phase 1.1 **62/62** full-UI result is a pre-bugfix baseline and is **not**
restated as verification of the final code. On 2026-10-24 the owner completed a
**full manual acceptance sweep on a physical iPhone** — all scenarios
user-reported PASS ([final-device-acceptance.md](../validation/physical-device/final-device-acceptance.md));
this manual evidence does not convert the automated gaps into passes.

---

## 10. Evidence Coverage Audit

Graded per §3 on three **independent** dimensions (A traceability
completeness, B verification coverage, C reference fidelity). A single
"chain complete/partial" statistic is deliberately **not** used: the earlier
formulation ("17 complete / 3 partial: T03, T05, T07") merged A, B and C and is
**superseded** by the per-row grading below. Values are READ rather than
recomputed from the running system; the tallies sum the rows in this section.

### 10.1 T01–T20 per-row grading

Chain segments: RQ = requirement · SP = specification · IM = implementation ·
TS = test · EV = evidence artifact · RS = observed result · HD = human decision.

| Row | A — segments locatable | B — behavior exercised | C — reference fidelity | Segment / B-scope note |
|---|---|---|---|---|
| T01 | **COMPLETE** (RQ SP IM TS EV RS HD) | **COMPLETE** | **PARTIAL** (P01) | all seven segments resolve; deterministic UI |
| T02 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P02) | — |
| T03 | **COMPLETE** | **PARTIAL** | **PARTIAL** (P02) | 2 of 3 clauses exercised (allow/deny→states, denial-no-crash); the "dialogs stay native" clause is bypassed by the fixture seam → real dialog interaction not exercised |
| T04 | **COMPLETE** | **COMPLETE (simulator scope)** | **PARTIAL** (P02) | workflow exercised through the capture fixture seam; real camera frames are platform-limited (G-11) |
| T05 | **COMPLETE** | **PARTIAL** | **PARTIAL** (P03) | import/cancel/load-failure exercised via fixture seam; real system-picker cancel gesture not exercised (G-03) |
| T06 | **COMPLETE** | **COMPLETE (simulator scope)** | **PASS** (P04) | gate fix verified by +6 unit tests and 34-card re-eval |
| T07 | **COMPLETE** | **COMPLETE** | **NOT OBSERVED** (raw screen) | preservation contract exercised (units + real Vision); the Reference raw-text screen was never observed — a C-dimension observation gap, not a B gap |
| T08 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P05) | — |
| T09 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P05) | — |
| T10 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P05) | GT multi-phone 23/23 |
| T11 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P05) | — |
| T12 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P06) | — |
| T13 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P07) | B-01/B-02 add real proof; fidelity gaps remain |
| T14 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P07) | — |
| T15 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P08) | segmented surfaces excluded |
| T16 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P09) | both create-cancel paths exercised (E12) |
| T17 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P01) | — |
| T18 | **COMPLETE** | **COMPLETE (simulator scope)** | **PARTIAL** (P06/P07 chrome) | terminate/relaunch exercised; physical-device persistence **USER-REPORTED PASS** 2026-10-24 (G-11) |
| T19 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P11) | real CNContactStore gate (System01/02) exercised |
| T20 | **COMPLETE** | **COMPLETE** | **PARTIAL** (P05) | two-layer fixture proof, layers not interchangeable |

**T tallies — A: 20/20 COMPLETE. B: 18 COMPLETE + 2 PARTIAL (T03, T05).
C: 1 PASS (T06) + 18 PARTIAL + 1 NOT OBSERVED (T07).**

### 10.2 P01–P11 per-row grading

| Row | A — segments locatable | B — behavior exercised | C — reference fidelity |
|---|---|---|---|
| P01 Card Holder | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P02 Scanner | **COMPLETE** | **COMPLETE (simulator scope)** | **PARTIAL** |
| P03 Photo Picker | **COMPLETE** | **PARTIAL** (cancel sub-behavior not exercised) | **PARTIAL** |
| P04 Crop | **COMPLETE** | **COMPLETE** | **PASS** |
| P05 Recognition / Edit | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P06 Save Result | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P07 Card Detail | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P08 Search Results | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P09 Group Management | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P10 Notes | **COMPLETE** | **COMPLETE** | **PARTIAL** |
| P11 Contact Export | **COMPLETE** | **COMPLETE** | **PARTIAL** |

**P tallies — A: 11/11 COMPLETE. B: 10 COMPLETE + 1 PARTIAL (P03).
C: 1 PASS (P04) + 10 PARTIAL.**

Note on P03: `final-reference-audit.md` prints its behavior verdict as
"PASS mechanics; system-picker cancel NOT INDEPENDENTLY VERIFIED". That source
verdict is **not reclassified**; this audit simply grades dimension B on the
same evidence as PARTIAL, because the cancel sub-behavior was never exercised.
No source verdict is overwritten anywhere in this document.

### 10.3 Segment-level evidence notes (R6 checks)

- **Test functions cited in this matrix were verified to exist in the
  repository**, not assumed: `testDeniedShowsStableFallbackWithoutSessionUI`,
  `testNotDeterminedGrantedResolvesToPreview`,
  `testNotDeterminedDeniedResolvesToFallback` (`ScanCameraUITests.swift`);
  `testCreateGroupCancelLeavesCatalogAndCardsUnchanged`
  (`CardGroupUITests.swift`); `testCardDetailRowTapInitiatesCorrectURL`,
  `testCardDetailAddressRowDoesNotInitiateURL`,
  `testCardDetailMissingOriginalImageGracefulDegradation`
  (`CardDetailUITests.swift`); `ExceptionHandlingUITests`,
  `CardPersistenceUITests`, `CardHolderEmptyUITests`, `ScanEntryUITests`.
- **Evidence-artifact filename check:** all cited `ai/validation/*.png` files
  exist on disk. Two **pre-existing filename typos in the read-only
  `final-acceptance.md`** were found and are flagged at the T13 and T19 rows
  above (T13 screenshots are dated `2026-09-29`, not `2026-09-30`; the contacts
  field screenshot is `2026-10-05-w4i11-contacts-fields.png`, not
  `contact-contacts-fields.png`). The actual files exist under their correct
  names; the historical document is not modified.
- **Human-decision level:** every T/P row cites a **phase-level** `Accepted`
  (2026-10-09 and/or 2026-10-18) or an increment-level record in
  `ai/changes.md`. No per-assertion Human Decision is claimed; none exists in
  the repository for individual tests.
- **Git SHA ≠ support:** SHA existence was verified separately from content.
  Spot-checks of the cited commits' actual diffs are listed in §12.
- Evidence file existence is never equated with a test PASS: every PASS cites
  the executing test function or an explicit manual procedure.

---

## 11. Outstanding Verification and Human Decisions

**Verification gaps (no new evidence may be fabricated):**

1. G-02 photo-library **authorization** / `PhotosPicker` platform semantics —
   **NOT TESTED**; this is a **separate item** from T03 camera permission and
   from T05 import mechanics (§5, §9); ruling among three documented options.
2. G-03 real system PhotosPicker cancel — **NOT VERIFIED**; one manual capture.
3. G-04 CamCard card-005–034 — **NOT OBSERVED**; supplementary captures vs
   bounded-scope statement (no ruling on record; **no inference** that
   re-capture is forbidden).
4. G-05 Week 5 "UI Golden Test" form — **manual** comparison done; **automated**
   pixel/snapshot form not produced (**0** assertions in repo); instructor
   ruling on whether the automated form is required (assignment text does not
   state it).
5. G-07 / G-08 / G-10 — course-required content whose **artifact form** needs a
   ruling (see ledger §8 "Course-required — artifact form pending human
   ruling"); G-08 raw prompts stay **NOT DOCUMENTED**. G-10 (final
   demonstration) is **not yet due/held**, not "overdue and missing".
6. G-11 physical iPhone — **USER-REPORTED PASS (full manual sweep,
   2026-10-24)** covering all acceptance scenarios ([final-device-acceptance.md](../validation/physical-device/final-device-acceptance.md));
   evidence class stays manual (no automated device run, no captured artifacts);
   quantitative device-side detection accuracy remains unmeasured.
7. G-13 image-manifest header — frozen file; revision decision pending.
8. System phone/mail/Safari final handoff after B-01 URL initiation —
   **NOT TESTED** on simulator (DEBUG capture hook proves the initiated URL
   only).
9. Canvas delivery format details (ZIP structure, demo form) — pending.

**Human Decisions on record (with scope):**

- Week 1 closeout calibration — `b5dcf4d` (2026-09-29).
- Per-increment Accepts, Weeks 2–4 — recorded in
  [ai/changes.md](../changes.md) (increment-level scope).
- W4I12 / T01–T20 final acceptance — **Accepted 2026-10-09 (phase-level)**,
  `f5533b3`.
- Phase 1.1 (B-01/B-02/G-01) — **Accepted 2026-10-18 (phase-level)**,
  `de58eee`.
- Phase 2A-1 documentation audit — accepted 2026-10-19, `bdac7b0`.
- Step 1 of Phase 2A-2 (spec-change-ledger) — Accepted with Minor
  Documentation Corrections (corrections applied in this step).

All of the above are **phase- or increment-level** records. **No document on
record approves any of the open G-items individually**, and none is upgraded to
PASS by this matrix.

---

## 12. Summary

- **Course requirements:** 16 mapped (CR-01–16): 12 PASS, 2 PARTIAL (CR-11,
  CR-12 artifact form), 1 PARTIAL (CR-14 — manual form done, automated form
  absent), 1 PENDING-not-produced (CR-15).
- **T01–T20, three independent dimensions** (replaces the retired single
  "chain" count — see §10):
  - **A. Traceability Completeness: 20/20 COMPLETE.**
  - **B. Verification Coverage: 18 COMPLETE + 2 PARTIAL (T03, T05).**
  - **C. Reference Fidelity: 1 PASS (T06) + 18 PARTIAL + 1 NOT OBSERVED (T07).**
- **P01–P11:** A 11/11 COMPLETE; B 10 COMPLETE + 1 PARTIAL (P03); C 1 PASS
  (P04) + 10 PARTIAL; zero blockers.
- **OCR evaluation:** present-field match 164/233 (70.4%) after the G-01 gate
  (46.8% before); 0 genuine fabrication; root causes 4/10/55 across
  detector/OCR/extractor; CamCard dataset-level comparison NOT OBSERVED beyond
  card-001–004. Measurement date 2026-10-15; committed `de58eee` 2026-10-18
  (see §7).
- **Gates on record (not re-run here):** W4I12 (`5ec0803`, 2026-10-05):
  Unit 431/431 (35 suites), deterministic UI 55/55 (+2 real Contacts targeted
  separately), hook isolation 13/13, Debug/Release PASS. Phase 1.1 calibration
  (`de58eee`, 2026-10-18): Unit 466/466, **62/62 full UI regression including
  2 real Contacts integration tests (System01/System02)**, hook isolation
  16/16 ABSENT (Release) / 16/16 PRESENT (Debug dylib), Debug/Release PASS.
- **SCL:** 13/13 cross-referenced; only one true functional-requirement
  spec-content edit (SCL-01, inside the Week 1 closeout).
- **G-series (status split, §9):** G-01 **FIXED** + G-09 **RESOLVED** (closed);
  G-14 **ADDRESSED** (context note); G-12 **DOCUMENTED PLATFORM DIFFERENCE**
  (explained, **not** human-approved); G-06a/b/c **DOCUMENTED DEBT** (recorded,
  not fixed); **8 pending a human decision** (G-02, G-03, G-04, G-05, G-07,
  G-08, G-10, G-13), with G-11 **USER-REPORTED PASS (full manual sweep,
  2026-10-24; manual evidence class)**.
  The earlier shorthand "14 items / 9 open" is **withdrawn**.
- **§12 commit-diff spot-checks (SHA existence ≠ content support):**
  `minimumDetectedArea` **absent** at `68d242c`, **present** at `de58eee`
  (`git grep -c` → `CardRegionGeometry.swift:2`) → supports SCL-11 / G-01;
  `fullScreenCover` **absent** at `5ec0803` → supports SCL-13 / B-02;
  `actor CameraSessionController` present at `eeefbbe` → supports SCL-04;
  reentrancy wording present at `b0404e2` → supports SCL-10; SCL-02 `6fa0910`
  `BusinessCard` keeps `originalImageReference` / `processedImageReference`
  **non-optional** → "required image references".
- Frozen surfaces (`spec.md`, `spec/`, `dataset/`, `evidence/`, `assignment/`,
  production + test code, `ai/changes.md`) were **not modified** in this step.
