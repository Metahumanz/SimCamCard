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

## 2026-09-29 — Swift 6 language mode migration

### Task
Migrate the project's Swift language mode from 5.0 to 6.0. Documentation-only correction here; no project configuration or source code is modified in this change.

### Context
- `SimCamCard.xcodeproj/project.pbxproj`
- `spec/reference-environment.md`
- `README.md`

### Changes
- Swift compiler / toolchain: Apple Swift 6.4 (unchanged; ships with Xcode 27.0).
- `SWIFT_VERSION` changed from 5.0 to 6.0 across all 6 build configurations in `project.pbxproj` (App / Tests / UI Tests × Debug / Release).
- `spec/reference-environment.md` and `README.md` updated to reflect Swift language mode 6.0.

### Verification
- `xcrun swift --version`: Apple Swift version 6.4.
- `grep -n "SWIFT_VERSION" SimCamCard.xcodeproj/project.pbxproj`: 6 occurrences, all `SWIFT_VERSION = 6.0`.
- `xcodebuild` invocation uses `-swift-version 6`.
- iPhone 18 Pro / iOS 27.0 simulator build succeeded.

### Regression
- No application source behavior changed by the language-mode migration.

### Human Decision
Pending human review.

## 2026-09-29 — Week 2 Increment 1: Domain Model

### Task
Create the Domain Model layer (BusinessCard, PhoneNumber, CardTag, CardNote) with Swift Testing unit tests, following spec/data-model.md and the 10 architecture revisions.

### Context Provided
- `spec/data-model.md` (§BusinessCard, §Multi-value observation, §Missing-field rule, §OCR Pipeline Data)
- `spec.md` (§8 Data Model)
- Ground-truth fixtures: `card-001.json` (full bilingual, multi-phone), `card-002.json` (missing website), `card-004.json` (minimal — only name + mobile), `card-011.json` (mobile + office + fax), `card-024.json` (multi-phone, has non-spec fields)
- `ai/README.md`, `ai/prompts/week2-skeleton.md`

### Constraints
- Model does not depend on UIKit / SwiftUI (revision 6).
- `originalImage` / `processedImage` use `String?` reference fields, not `UIImage` (revision 6).
- `rawOCRText` is an optional domain field; Week 2 default is `nil` (revision 7).
- `nameLatin` / `companyLatin` / `department` / `languageProfile` are present in ground-truth JSON but not in `spec/data-model.md` minimum field table; per revision 8 they are NOT added and are recorded as specification clarifications.
- `phones: [PhoneNumber]` is the single source of truth; no single-value `mobile` / `officePhone` / `fax` properties (revision 9).
- Unit Tests use Swift Testing; UI Tests use XCTest (revision 10).
- Do NOT modify: Repository, ViewModel, View, Navigation, Camera, OCR, Persistence, Mock runtime injection, UI Tests, `project.pbxproj`, `ContentView.swift`, `SimCamCardApp.swift`, spec, dataset, evidence.
- Do NOT add Codable speculatively.

### AI Changes
New files (6):
- `SimCamCard/Model/BusinessCard.swift` — `nonisolated struct BusinessCard: Identifiable, Sendable, Hashable`. Fields: `id: UUID`, `originalImageReference: String?`, `processedImageReference: String?`, `rawOCRText: String?`, `name: String?`, `company: String?`, `jobTitle: String?`, `website: String?`, `address: String?`, `phones: [PhoneNumber]`, `emails: [String]`, `tags: [CardTag]`, `notes: [CardNote]`, `createdAt: Date`, `updatedAt: Date`. Provides `phones(of:)` and `firstPhone(of:)` kind-filtered accessors in a `nonisolated extension`.
- `SimCamCard/Model/PhoneNumber.swift` — `nonisolated struct PhoneNumber: Identifiable, Sendable, Hashable` with nested `enum Kind: String { case mobile, office, fax, other }`.
- `SimCamCard/Model/CardTag.swift` — `nonisolated struct CardTag: Identifiable, Sendable, Hashable` (id + name only; no group-management logic).
- `SimCamCard/Model/CardNote.swift` — `nonisolated struct CardNote: Identifiable, Sendable, Hashable` (id + text + createdAt).
- `SimCamCardTests/Model/BusinessCardTests.swift` — 16 Swift Testing cases covering: default init, card-001/002/004/011 shapes, missing-field rule, multi-phone preservation (including same-kind duplicates), `rawOCRText` default nil, image references nil + String tokens, tags/notes default empty + populated, equality/identity, accessor edge cases, `updatedAt` independence.
- `SimCamCardTests/Model/PhoneNumberTests.swift` — 5 Swift Testing cases covering: Kind enum coverage, init, id uniqueness, equality, explicit id preservation.

No existing files modified. No `project.pbxproj` edits (filesystem-synchronized groups automatically registered new files).

### Design decisions
1. **`nonisolated` type prefix on all 4 model types**: the App target has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (Xcode 27.0 SwiftUI template default). Without `nonisolated`, all types are implicitly `@MainActor`-isolated, which would conflict with the future `actor InMemoryBusinessCardRepository` (revision 5) and prevent nonisolated test access. `nonisolated` explicitly opts out of the module-level default.
2. **`emails: [String]`**: spec §Multi-value observation explicitly says "potentially multiple email addresses" and "emails[]". Tension with minimum field table's `email: text?` (single value) recorded as spec clarification §4.
3. **`company: String?` (single value)**: spec minimum field table lists `company: text?`. §Multi-value observation suggests `organizations[]` with "for example" (not mandatory). Per revision 8, not expanded. Recorded as spec clarification §2.
4. **`id: UUID`**: spec says "stable identifier"; UUID is Swift standard, Identifiable-native, Sendable.
5. **`originalImageReference` / `processedImageReference` as `String?`**: spec marks these "Required" but source is "Capture/Import" which Week 2 does not have. Mock values are `nil`. Recorded as spec clarification §1.

### Verification
- `xcodebuild build` succeeded (iPhone 18 Pro / iOS 27.0 simulator).
- `xcodebuild -only-testing:SimCamCardTests test` succeeded: all 21 tests passed (16 BusinessCardTests + 5 PhoneNumberTests + 1 pre-existing placeholder).
- `grep -n "^import" SimCamCard/Model/*.swift`: only `import Foundation` in all 4 files (no SwiftUI, no UIKit).
- `grep "SWIFT_DEFAULT_ACTOR_ISOLATION" project.pbxproj`: confirmed MainActor on App target (not modified); model types use `nonisolated` to opt out.
- No `project.pbxproj` modifications (filesystem-synchronized groups auto-registered new files).

### Specification clarifications (recorded, not blocking)
1. `originalImage` / `processedImage` Required vs. Week 2 no capture pipeline — **RESOLVED by the SDD consistency fix below (2026-09-29): fields are required `String`; test/preview fixtures supply deterministic tokens.**
2. `company` single value vs. `organizations[]` multi-value — current single `company: String?`.
3. `nameLatin` / `companyLatin` / `department` / `languageProfile` present in ground-truth JSON but not in spec minimum table — not added.
4. `emails[]` vs. `email: text?` — current `emails: [String]`.

### Regression
- No existing source code or tests modified. No Week 2 features beyond Domain Model added. Pre-existing `SimCamCardTests/example()` placeholder still passes.

### Human Decision
Accepted — 2026-09-29 (human review). Domain Model accepted together with the SDD consistency correction below; the required-image-reference form is the accepted final state.

## 2026-09-29 — Week 2 Increment 1 correction: required image references (SDD consistency fix)

### Task
Fix an SDD consistency issue before freezing Increment 1: `spec/data-model.md` defines `originalImage` / `processedImage` as Required. The initial Increment 1 implementation relaxed the domain invariant to `String?` (default nil) to accommodate Week 2 having no camera pipeline. That let implementation weaken a frozen specification. Human review required the fields be non-Optional required `String` references; fixtures supply deterministic tokens.

### Context Provided
- `spec/data-model.md` §BusinessCard minimum field table (`originalImage | image reference | Yes`, `processedImage | image reference | Yes`)
- `SimCamCard/Model/BusinessCard.swift`
- `SimCamCardTests/Model/BusinessCardTests.swift`

### Constraints
- Fields stay image *references* (`String`); no UIKit / `UIImage` introduced.
- No other Domain design changes (phones/emails/tags/notes/rawOCRText/conformances unchanged).
- Do not enter Increment 2.

### AI Changes
- `SimCamCard/Model/BusinessCard.swift`
  - `originalImageReference: String?` → `originalImageReference: String` (required, no default).
  - `processedImageReference: String?` → `processedImageReference: String` (required, no default).
  - Initializer parameters changed accordingly (required, no default value); other parameters untouched.
  - Header and doc comments updated: fields now document the frozen-spec Required invariant and deterministic fixture tokens (`"card-001-original"` / `"card-001-processed"`); stale "Week 2 leaves this nil / clarification §1" wording removed.
- `SimCamCardTests/Model/BusinessCardTests.swift`
  - Deleted `imageReferencesAreNilByDefault()` (tested behavior that violates the frozen spec).
  - Replaced `imageReferencesAcceptStringTokens()` with `requiredImageReferencesAreStored()` verifying both required tokens are stored (`card-001-original` / `card-001-processed`).
  - Renamed default-init case to `initWithRequiredReferencesLeavesOptionalsNilAndCollectionsEmpty()`; it now passes the two required tokens and still asserts all genuinely-optional fields are nil and collections empty.
  - Every fixture construction now supplies deterministic references: `card-001-*`, `card-002-*`, `card-004-*`, `card-011-*` for ground-truth-shaped cases and `test-original` / `test-processed` for generic cases.
- `ai/changes.md`: this record; prior clarification §1 marked resolved.

### Verification
- `xcodebuild -only-testing:SimCamCardTests test` (iPhone 18 Pro / iOS 27.0): **TEST SUCCEEDED**. 20 cases passed — 14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 pre-existing `SimCamCardTests/example()` placeholder.
- `xcodebuild build` succeeded as part of the same test action.
- `grep "^import" SimCamCard/Model/*.swift`: only `import Foundation` (no SwiftUI/UIKit).
- No changes to `project.pbxproj` or any file outside the two Domain/test files plus this log.

### SDD note
The Required invariant is now enforced at compile time: `BusinessCard` cannot be constructed without both image references. Week 2 absence of a real capture pipeline is handled at the fixture/mock layer (deterministic reference tokens), not by weakening the Domain Model. This record supersedes the field-optionality parts of the earlier Increment 1 entry above.

### Regression
- All pre-existing Increment 1 unit cases updated and passing. No other Domain types changed. UI tests not run (out of Increment 1 scope).

### Human Decision
Accepted — 2026-09-29 (human review).
