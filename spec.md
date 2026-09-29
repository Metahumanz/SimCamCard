# SimCamCard Specification

Version: 0.1
Status: Frozen — Week 1 SDD Baseline
Reference observation date: 2026-09-28

## 1. Purpose

SimCamCard replicates the instructor-defined CamCard feature slice:

**Business Card Digitization and Contact Management**

The project follows Specification-Driven Development (SDD):

Product Behavior → Specification → Architecture → Implementation → Test → Difference Analysis → Revision → Regression.

Implementation must be based on externally observable behavior and the assignment requirements. Unknown CamCard behavior must remain marked as unknown rather than being invented.

## 2. Source of Truth

Priority order:

1. `assignment/` — instructor-provided assignment documents.
2. This specification and the files in `spec/`.
3. Black-box evidence in `evidence/screenshots/`.
4. Fixed test cards and Ground Truth in `dataset/`.

When implementation behavior conflicts with a confirmed specification, the implementation must be corrected rather than silently changing the specification.

## 3. Core Scope

### Included

- Card Holder / business-card list
- Empty state
- Scan entry
- Camera preview and permission flow
- Photo-library import
- Business-card region detection
- Manual crop / boundary adjustment
- Perspective/orientation correction
- OCR
- Preservation of raw OCR output
- Structured field extraction
- Manual verification and correction
- Save
- Detail view
- Edit
- Delete
- Search
- Groups/tags
- Notes
- Local persistence
- Export to system Contacts or VCF
- Required exception paths

### Excluded from the six-week core

- User registration and membership
- Subscription/payment/VIP functionality
- Advertising
- Cloud account synchronization
- Multi-device synchronization
- Team card libraries
- Salesforce/CRM synchronization
- Enterprise organization/permission systems
- Digital business-card design/templates
- QR-based card exchange
- Email signatures / virtual backgrounds
- AI business intelligence/company analysis/financial analysis/recommendations
- Meeting recording/summarization
- Sales pipeline
- CamCard enterprise-data enrichment and online company matching
- Nearby-contact maps and other non-core discovery features

Observed excluded UI must not become an implementation requirement.

## 4. End-to-End Workflow

Card Holder  
→ Scan or Import  
→ Detect Card Region  
→ Correct Crop / Perspective / Orientation  
→ OCR Raw Text  
→ Structured Field Extraction  
→ Human Verification / Manual Correction  
→ Save  
→ Card Holder  
→ Detail / Search / Group / Notes / Edit  
→ Reopen after relaunch  
→ Contact Export

## 5. Deterministic vs Probabilistic Behavior

### Deterministic

UI, navigation, state transitions, persistence, editing, deletion, search, groups/tags, notes, and export must be deterministic and testable.

### Probabilistic

OCR and field classification are probabilistic. SimCamCard must:

- preserve original image;
- preserve processed image;
- preserve raw OCR text;
- preserve structured extraction result;
- allow manual correction;
- compare extraction against Ground Truth;
- calculate field-level accuracy;
- record error-analysis cases;
- never fabricate missing information.

## 6. Reference UI Principles

- Replicate application-owned UI and observable interaction flow within the assignment scope.
- System-owned permission dialogs, photo picker, Contacts UI, browser/mail/phone UI are invoked through native system APIs; do not draw fake copies of macOS/iOS system dialogs.
- Current evidence was captured from CamCard running on Apple Silicon Mac compatibility mode, so host-system dialogs are evidence of state transitions, not pixel-perfect iPhone UI references.
- Commercial/promotional/enterprise-only content is out of scope.

## 7. Pages and States

See:

- `spec/page-inventory.md`
- `spec/state-inventory.md`

## 8. Data Model

See:

- `spec/data-model.md`

## 9. Acceptance Tests

See:

- `spec/reference-tests.md`

## 10. Evidence

See:

- `spec/observation-index.md`
- `evidence/screenshots/`

## 11. Test Dataset

Frozen Week 1 baseline:

- 34 synthetic business-card samples, `card-001` through `card-034`, located in `dataset/cards/`.
- 34 Ground Truth records (`card-001.json` through `card-034.json`) located in `dataset/ground-truth/`.
- A separate non-card T20 exception fixture (`dataset/exception-samples/`) is **not** counted as a business-card sample and is used only for T20 exception behavior.

Dataset index and consolidated Ground Truth for the back 30 cards are available as `dataset/card-index-005-034.csv` and `dataset/ground-truth-005-034.jsonl`; `card-001` through `card-004` retain individual JSON files.

## 12. Known Follow-up / Future Verification

These items are future implementation or acceptance verification work and do not affect the Week 1 freeze:

- T03 full allow/deny implementation regression (including denial recovery).
- T07 raw OCR text preservation — must be verified after SimCamCard OCR implementation.
- T15 search by job title, phone, and email (black-box evidence directly verifies only name and company).
- T20 explicit cancel / back / retake / permission-recovery regression paths.
- Physical-iPhone-specific native behavior verification (camera, iOS permission presentation, safe areas, native Contacts export, external phone/mail/web actions).
