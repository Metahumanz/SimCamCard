# AI Changes

Use one section per AI-assisted change.

## Template

### Date
YYYY-MM-DD

### Task
Small, bounded task.

### Context Provided
- spec file(s)
- source file(s)
- relevant test(s)

### Constraints
- architecture/interface constraints
- files that must not change

### AI Changes
- changed files
- behavior implemented

### Verification
- tests run
- manual checks
- result

### Regression
- existing tests rerun
- regressions found/fixed

### Human Decision
Accepted / Rejected / Revised

## 2026-09-29 — Observation baseline update

### Task
Incrementally update the Week 1 SDD evidence after additional black-box observation.

### New verified behavior
- T16: group deletion.
- T18: persistence after full quit and relaunch.
- T19: successful save to system Contacts and field mapping.

### Documentation changes
- Filled reference environment values supplied by the student.
- Updated Reference Test Suite statuses.
- Updated state inventory.
- Added newly retained evidence screenshots.
- Removed T16/T18/T19 from the remaining observation-gap list.

### Human verification
The student manually performed the reference-app interactions and confirmed the observed results.

## 2026-09-29 — T20 negative-sample observation update

### Task
Record fixed exception/negative samples for T20.

### New verified behavior
- Minimal card containing only name + mobile produces only those structured fields.
- A valid non-card landscape image did not trigger a dedicated recognition-failure dialog in CamCard 8.63.1; it entered Edit Card with an empty recognition result.

### Specification impact
- Missing fields must remain empty and must not be fabricated.
- Do not invent a recognition-failure UI when the reference version instead exposes an empty editable result.
- Preserve cancel/back/retake and permission-recovery as regression cases.

### Human verification
The student manually imported both fixed samples and captured the resulting CamCard screens.

## 2026-09-29 — Week 1 SDD baseline closeout

### Task
Reconcile frozen Week 1 SDD baseline so documentation, dataset metadata, Git hygiene, and actual file state are consistent.

### Context Provided
- `spec.md`
- `spec/reference-environment.md`
- `spec/reference-tests.md`, `spec/observation-index.md`, `spec/page-inventory.md`, `spec/state-inventory.md`, `spec/data-model.md`
- `dataset/README.md`, `dataset/cards/`, `dataset/ground-truth/`, `dataset/exception-samples/`
- `evidence/image-manifest.md`, `evidence/excluded-observations.md`, `evidence/screenshots/`
- `SDD-README.md`, `README.md`
- `SimCamCard.xcodeproj/project.pbxproj`

### Constraints
- Do not amend/reset/rebase the existing Week 1 freeze commit.
- Do not modify `assignment/`, evidence images, dataset images, or Ground Truth business fields.
- Do not implement Week 2 features (OCR, camera, persistence, repository, ViewModel, new UI).
- Do not silently change the Swift language mode in `project.pbxproj`.

### AI Changes
- `spec.md`: status changed from "Week 1 Draft / Black-Box Observation Baseline" to "Frozen — Week 1 SDD Baseline"; §11 Test Dataset rewritten to reflect 34 cards + Ground Truth + T20 exception; §12 replaced stale "Open Items Before Week 1 Freeze" with "Known Follow-up / Future Verification".
- `spec/reference-environment.md`: Dataset section corrected to 34 cards / 34 Ground Truth / 1 T20 exception; Swift line split into compiler/toolchain version (6.4) and Swift language mode (`SWIFT_VERSION = 5.0`); `project.pbxproj` left unchanged.
- `dataset/README.md`: rewritten from "three synthetic cards" to the frozen 34-card + Ground Truth + exception-samples description.
- `SDD-README.md`: rewritten from stale package-install/next-actions instructions to a current SDD work entry point.
- `README.md`: written from empty to a concise human-facing project README.
- `.gitignore`: created (`.DS_Store`, `DerivedData/`, `*.xcuserstate`, `xcuserdata/`, `*.xcuserdatad/`, `.build/`).
- `SimCamCard.xcodeproj/xcuserdata/`: removed from Git index only (`git rm -r --cached`); local working files preserved.

### Verification
- `dataset/cards/` contains 34 files `card-001` … `card-034` (verified via `ls`).
- `dataset/ground-truth/` contains 34 files `card-001.json` … `card-034.json` (verified via `ls`).
- `dataset/exception-samples/` contains the T20 non-card fixture (`t20-negative-001-non-card.png` + `t20-negative-001-expected.json`), not counted in the 34.
- `evidence/screenshots/` contains 40 files; `diff` against `evidence/image-manifest.md` is empty.
- `spec/reference-tests.md` evidence references all exist in `evidence/screenshots/`.
- `xcrun swift --version` reports Apple Swift version 6.4; `project.pbxproj` `SWIFT_VERSION = 5.0` left unchanged.
- `assignment/` contains no 30–50 dataset requirement (grep), so the stale "expand to 30–50" TODO wording in spec/dataset README was completed-and-rewritten, not preserved as a standing requirement.
- `grep -R "TODO"` across `spec.md spec/ dataset/ ai/ SDD-README.md README.md` returns no remaining TODO placeholders after edits.
- No Week 1 freeze commit was amended, reset, or rebased.

### Regression
- Documentation-only change; no source code or tests touched. No test suite run applicable.

### Human Decision
Pending human review.
