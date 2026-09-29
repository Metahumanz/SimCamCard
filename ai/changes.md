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

## 2026-09-29 — Week 2 Increment 2: Repository abstraction + In-memory Repository

### Task
Introduce the BusinessCardRepository data-access protocol and a Week 2-only in-memory implementation, so later ViewModels depend on the abstraction rather than concrete storage.

### Context Provided
- `spec/data-model.md` (§BusinessCard stable id; §Persistence rule)
- `spec/reference-tests.md` (T12 Save, T17 Delete, T18 Persistence)
- `spec/state-inventory.md` S01 Card Holder (empty / populated, immediate list update after save/delete)
- `ai/README.md`
- Increment 1 accepted Domain Model (`SimCamCard/Model/*`)

### Constraints
- Swift 6 concurrency-safe; `actor` implementation; no mutable class, no locks, no `@unchecked Sendable`.
- Do NOT modify the Domain Model, ViewModel, View, Navigation, App root, `ContentView.swift`, Mock runtime injection, Camera/OCR, any persistence (SwiftData/Core Data/SQLite/files), Contacts export, UI Tests, frozen spec, or `project.pbxproj`.
- Do NOT pre-design DTOs, Codable schemas, migrations, disk paths, or a persistence protocol hierarchy for Week 5.

### AI Changes
New files (3; auto-registered via filesystem-synchronized groups, no pbxproj edit):
- `SimCamCard/Repository/BusinessCardRepository.swift` — `nonisolated protocol BusinessCardRepository: Sendable` with `allCards() async -> [BusinessCard]`, `card(id:) async -> BusinessCard?`, `save(_:) async`, `delete(id:) async`.
- `SimCamCard/Repository/InMemoryBusinessCardRepository.swift` — `actor InMemoryBusinessCardRepository: BusinessCardRepository`; `init(initialCards: [BusinessCard] = [])`; `[BusinessCard]` storage; insert-or-replace by id (never duplicated); delete is a safe no-op for absent ids. (Internal array/positioning is an implementation detail, not a contract — see correction below.)
- `SimCamCardTests/Repository/InMemoryBusinessCardRepositoryTests.swift` — 10 Swift Testing async cases.

### Design decisions
1. **`nonisolated protocol`**: App target defaults to `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; without `nonisolated` the protocol would be MainActor-isolated and the `actor` could not conform. All requirements are `async`, allowing actor-isolated witnesses and future persistence implementations.
2. **`actor` storage**: serialized mutable state, automatic `Sendable`; actor-isolated sync methods witness the protocol's nonisolated async requirements.
3. **Array, not dictionary**: Week 2 card counts are small; an array is sufficient and no product sort rule is introduced (the frozen spec defines no order). id uniqueness is enforced via `firstIndex` upsert. Array order is an in-memory implementation detail, not a Repository contract (see correction below).
4. **No field mutation on save**: repository stores entities verbatim and never rewrites `updatedAt`; timestamp maintenance is a future business-layer responsibility.
5. **`delete` returns Void, no throws**: frozen spec defines no error for deleting an absent card.

### Verification
- `xcodebuild -only-testing:SimCamCardTests test` (iPhone 18 Pro / iOS 27.0): **TEST SUCCEEDED**. 30 cases passed — 10 new `InMemoryBusinessCardRepositoryTests` + 14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 pre-existing placeholder. Increment 1 regression fully green.
- `grep "^import" SimCamCard/Repository/*.swift`: only `import Foundation` (no SwiftUI/UIKit).
- `git status`: only new `SimCamCard/Repository/` and `SimCamCardTests/Repository/` directories; no existing file changed except this log.

### Semantics verified by tests
- Empty default repository; deterministic initializer injection returns the seed card set (membership only).
- Duplicate seed ids collapse into one unique id (later value wins, no duplicate).
- `save` inserts new / replaces existing id / stores entity verbatim (incl. unchanged `updatedAt`).
- `delete` removes existing / no-ops on absent id.
- Interleaved save/delete sequence converges to the expected member set; concurrent saves of distinct ids from a task group are all retained (actor serialization).
- Tests assert set membership and id-based lookup only; no ordering is frozen (see correction below).

### Reference test traceability (scope)
- **T12 Save: repository-level prerequisite/support only.** Increment 2 provides the save storage semantics; the full T12 UI behavior ("new card immediately appears in holder") requires ViewModel + View and is verified in a later increment. Increment 2 does NOT claim T12 passed.
- **T17 Delete: repository-level prerequisite/support only.** Increment 2 provides the delete storage semantics; the full T17 UI behavior ("card disappears afterward", incl. confirmation) requires ViewModel + View. Increment 2 does NOT claim T17 passed.
- T18 Persistence intentionally not implemented: in-memory data is lost on termination, as expected for Week 2.

### Specification clarifications (recorded, not blocking)
1. `allCards()` order: frozen spec defines none — ordering is NOT part of the Repository contract; insertion order/position is a current in-memory implementation detail only (see correction below).
2. Save does not auto-advance `updatedAt` — repository is storage only.

### Regression
- All Increment 1 unit tests pass unchanged. Domain Model untouched. UI tests not run (out of Increment 2 scope).

### Human Decision
Accepted — 2026-09-29 (human review).

## 2026-09-29 — Week 2 Increment 2 correction: unfreeze ordering + fix T12/T17 traceability

### Task
SDD consistency corrections before final Accept of Increment 2:
1. Do not freeze unspecified ordering — the frozen spec defines no order for `allCards()`; tests must not make insertion order / update position / duplicate-seed position part of the Repository contract.
2. Fix reference-test traceability — Repository alone does not complete T12/T17 UI behavior; mark both as repository-level prerequisite/support only.
3. Run an independent standalone build acceptance, then re-run unit tests.

### Files changed (allowed set only)
- `SimCamCardTests/Repository/InMemoryBusinessCardRepositoryTests.swift` — assertions rewritten to set membership + id-based lookup.
- `SimCamCard/Repository/InMemoryBusinessCardRepository.swift` — doc comments only (storage/init/save) clarifying insertion order/position is a CURRENT IN-MEMORY IMPLEMENTATION DETAIL, not a protocol guarantee.
- `ai/changes.md` — this record; Increment 2 entry wording corrected.
Repository API, Domain Model, other layers, and `project.pbxproj` untouched.

### Test corrections
- `initializerInjectionReturnsSeedCards`: asserts seed set membership (`Set(ids)`) and per-id lookup; no order.
- `duplicateSeedIdsCollapse`: asserts id uniqueness, single record per id, latest value retrievable by id; no array position.
- `saveExistingIdReplacesWithoutDuplicate`: asserts count unchanged, unique ids, id lookup returns the new entity; position assertion removed.
- `interleavedSavesAndDeletes`: asserts final member set + entity content + absence of deleted ids; no order.
- `concurrentSavesAllPersist` (renamed from `...AreSerialized`): asserts all writes present; task execution order not assumed.
- `deleteExistingCardRemoves` / `deleteAbsentIdIsNoOp` / `saveNewCardInserts`: set-based membership.
- File header documents: ordering is not a contract; T12/T17 are repository-level prerequisites only.

### Traceability correction
- T12 Save → **repository-level prerequisite/support only**; "new card immediately appears in holder" awaits ViewModel + View.
- T17 Delete → **repository-level prerequisite/support only**; "card disappears afterward" (incl. confirmation) awaits ViewModel + View.
- Increment 2 must not claim T12/T17 passed.

### Verification
- Standalone `xcodebuild ... build` (iPhone 18 Pro / iOS 27.0): **BUILD SUCCEEDED** (only a benign AppIntents metadata note).
- `xcodebuild -only-testing:SimCamCardTests test`: **TEST SUCCEEDED**. 30 cases passed — 10 `InMemoryBusinessCardRepositoryTests` + 14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 placeholder. Increment 1 regression green.
- Repository files still `import Foundation` only (no SwiftUI/UIKit).
- `git status`: no `project.pbxproj` modification; only the two new Repository directories plus this log.

### Human Decision
Accepted — 2026-09-29 (human review) — correction applied before final Accept of Increment 2.

## 2026-09-29 — Week 2 Increment 2 final calibration: remove residual ordering assertions

### Task
Final ordering-unfreeze cleanup in the Repository test file (test file + this log only; Repository API and implementation logic untouched):
1. The update test still compared ids as an ordered list — remove the residual position guarantee.
2. Duplicate-initial-id first-wins/last-wins is unspecified by the frozen spec — delete that test rather than encode an unspecified behavior.
3. Exhaustively confirm no positional/ordering assertions remain.

### Files changed
- `SimCamCardTests/Repository/InMemoryBusinessCardRepositoryTests.swift`
- `ai/changes.md` (this record)

### Changes
- `saveExistingIdReplacesWithoutDuplicate`: id comparison is now fully order-independent —
  `#expect(Set(ids) == Set([first.id, target.id, third.id]))`, plus `ids.count == 3` and
  `Set(ids).count == ids.count` (id uniqueness) and `await repo.card(id: target.id) == updated`.
  No update-position retention is asserted.
- DELETED `duplicateSeedIdsCollapse`: the frozen spec defines neither first-wins nor last-wins
  for repeated seed ids. A comment documents why it is absent; post-`save` id uniqueness remains
  covered by the update test.
- Full-file scan confirms no remaining `cards[n]` indexing, no `.first`/`.last` ordering use, no
  ordered `map(\.id) == [...]` comparisons (all 6 array-literal comparisons are `Set`-wrapped),
  no update-position or concurrent-execution-order assertions. Remaining "order" occurrences are
  comments/test names that explicitly disavow ordering.

### Verification
- `xcodebuild -only-testing:SimCamCardTests test` (iPhone 18 Pro / iOS 27.0): **TEST SUCCEEDED**.
  29 cases passed — 9 `InMemoryBusinessCardRepositoryTests` (was 10; duplicate-seed test deleted)
  + 14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 placeholder. Increment 1 regression green.
- Repository API and implementation logic unchanged; `project.pbxproj` unchanged.

### Human Decision
Accepted — 2026-09-29 (human review) — final calibration; Increment 2 Accepted.

## 2026-09-29 — Week 2 Increment 3: Navigation + CardHolderViewModel + Empty Card Holder

### Task
Move the App from the Xcode Hello World template into the architecture skeleton. Empty-repository Card Holder Empty State matching frozen Reference Evidence. Corresponds to P01 Card Holder, S01 empty state, T01 Empty Card Holder, REF-card-holder-01-empty.

### Context Provided
- `spec/page-inventory.md` P01 Card Holder (empty state, main exits)
- `spec/state-inventory.md` S01 Card Holder empty (zero saved cards, scan entry remains available)
- `spec/reference-tests.md` T01 First Launch / Empty Holder
- `spec/observation-index.md` REF-card-holder-01-empty.png
- `evidence/screenshots/REF-card-holder-01-empty.png`
- `ai/README.md`, `ai/prompts/week2-skeleton.md`
- Increment 1 accepted Domain Model (`SimCamCard/Model/*`)
- Increment 2 accepted Repository (`SimCamCard/Repository/*`)

### Constraints
- `CardHolderViewModel`: `@MainActor`, `@Observable`, depends on `any BusinessCardRepository`, sole owner of card state; View does NOT hold its own `[BusinessCard]`.
- App composition root: construct Repository, construct ViewModel, host `NavigationStack`; do NOT pass concrete repository into View.
- Minimal `AppRoute`; do NOT pre-implement Detail/Scan destinations.
- One state, one owner: Repository = data source abstraction; ViewModel = UI-facing state + orchestration; View = rendering + user intent.
- UI based on frozen reference screenshot; no "modern iOS" redesign; no "Coming soon" / "Not implemented" text.
- Do NOT implement: Populated Card Holder, mock runtime injection, Card Detail, ScanEntryView/scanner shell, AVFoundation/camera, photo picker, OCR, crop, search, tags/notes, edit/delete, persistence, contacts export, modifying Domain Model / Repository API / frozen spec / `project.pbxproj`.
- Unit tests = Swift Testing; UI tests = XCTest.

### AI Changes
New files (6; auto-registered via filesystem-synchronized groups, no pbxproj edit):
- `SimCamCard/App/AppRoute.swift` — minimal `enum AppRoute: Hashable` with no active cases; documents planned future cases (`.scan`, `.detail`) but does not implement them.
- `SimCamCard/App/SimCamCardApp.swift` — composition root (`@main struct SimCamCardApp: App`). `@State` holds `CardHolderViewModel(repository: InMemoryBusinessCardRepository())`. `body` hosts `NavigationStack { CardHolderView(viewModel:) }` with `.task { await viewModel.loadCards() }`. Concrete repository not passed into View.
- `SimCamCard/ViewModel/CardHolderViewModel.swift` — `@MainActor @Observable final class`. `private(set) var cards: [BusinessCard] = []`; `private let repository: any BusinessCardRepository`; `func loadCards() async { cards = await repository.allCards() }`. Sole owner of card state.
- `SimCamCard/View/CardHolder/CardHolderView.swift` — root content view. `navigationTitle("名片夹")`; toolbar trailing `+` button (accessibilityLabel "扫描", non-triggering). Empty state: `ContentUnavailableView` with `Label("名片 (0张)", systemImage: "rectangle.stack")`. Populated state: `List(viewModel.cards)` with `Text(card.name ?? "未命名")` rows (not exercised this increment).
- `SimCamCardTests/ViewModel/CardHolderViewModelTests.swift` — 6 Swift Testing cases (`@MainActor @Suite`): fresh ViewModel empty, loadCards on empty repo, loadCards on populated repo (membership), idempotency, loadCards after save, loadCards after delete.
- `SimCamCardUITests/CardHolderEmptyUITests.swift` — 1 XCTest case: verifies navigation title "名片夹", scan button "扫描" exists, no card rows, no "Coming soon"/"Not implemented" text.

Deleted (2):
- `SimCamCard/SimCamCardApp.swift` — old template (migrated to `SimCamCard/App/SimCamCardApp.swift` as composition root).
- `SimCamCard/ContentView.swift` — Xcode Hello World template, no longer needed.

No existing files modified. Domain Model, Repository, spec, `project.pbxproj` untouched.

### Design decisions
1. **`@MainActor @Observable`** (not Combine `ObservableObject`): Swift Observation framework; `@State` holds the ViewModel (standard for `@Observable` classes in iOS 17+). View reads `viewModel.cards` in `body` — automatic tracking; no `@Bindable` needed (View is read-only).
2. **NavigationStack in App composition root**: App owns the navigation container; `CardHolderView` is a pure content view setting `navigationTitle`/`toolbar` picked up by the enclosing `NavigationStack`.
3. **`AppRoute` with no active cases**: establishes the routing pattern without pre-implementing destinations. Not a "large placeholder" — a 1-line enum documenting the future shape.
4. **`+` button is non-triggering**: empty action body, no `NavigationLink`/`navigationDestination`/sheet. T02 scanner navigation is deferred; no "Coming soon" text.
5. **`ContentUnavailableView` for empty state**: iOS system standard (system-carried UI). Text "名片 (0张)" is directly from the reference's section header, not invented.
6. **Test struct is `@MainActor`**: the Tests target does not set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so the struct must be explicitly `@MainActor` to access `CardHolderViewModel`'s isolated properties.

### UI evidence → View element mapping (REF-card-holder-01-empty.png)

| Reference element | SimCamCard | Status |
|---|---|---|
| Window title "名片全能王" | App bundle name (project setting) | System |
| Search bar "请输入姓名/公司/职位搜索" | NOT shown | Deferred (Search prohibited) |
| `+` add button (header) | Toolbar trailing `+` (scan entry, non-triggering) | Implemented |
| Quick Action Grid (4 cards) | NOT shown | Excluded/deferred |
| "名片 (0张)" section header | `navigationTitle("名片夹")` + `ContentUnavailableView("名片 (0张)")` | Implemented |
| "管理" (Manage) button | NOT shown | Deferred |
| Tutorial card "30秒快速认识CC" | NOT shown | Excluded (promotional) |
| Bottom tab bar (5 tabs) | NOT shown | Excluded (switches to excluded pages) |
| Center camera button (tab bar) | Toolbar `+` replaces it | Replaced |

### T01 acceptance criteria verification
1. ✅ App launches without crash on empty `InMemoryBusinessCardRepository()`.
2. ✅ Card Holder page is root (`navigationTitle("名片夹")`).
3. ✅ No card rows displayed (empty state via `ContentUnavailableView`).
4. ✅ Scan entry CTA (`+` button, accessibilityLabel "扫描") visible.
5. ✅ `+` button does not trigger T02 scanner navigation (empty action).
6. ✅ No "Coming soon" / "Not implemented" text.
7. ✅ No populated mock data injected.

**T01 PASSES.**

### Reference test traceability
- **T01 Empty Card Holder: PASS.** Empty Card Holder shown when no cards exist; scan entry available.
- T02 Enter Scanner: NOT implemented (scan entry is non-triggering; deferred).
- T13 Card Detail: NOT implemented (no detail view, no navigation destination).

### Specification / evidence ambiguity (deliberate interpretations, not blocking)
1. **Empty state visual**: Reference empty state main visual is a promotional tutorial card ("30秒快速认识CC"). page-inventory.md excludes "Promotional Home content". SimCamCard uses the reference's own "名片 (0张)" count indicator via `ContentUnavailableView` (system-carried UI).
2. **Bottom tab bar**: Reference has 5 tabs (Home/Card Holder/Camera/Enterprise/Login); only Card Holder is in scope. Tab bar not replicated; scan entry via toolbar `+` (matches reference's header `+` button).
3. **Search bar**: Search functionality prohibited this increment. Search bar not shown to avoid placeholder.
4. **Quick Action Grid**: All 4 items excluded (Contact Map = nearby-contacts; Contact Analytics = CRM/BI) or deferred (Group Management = T16; New Contacts = promotional/digital business card).
5. **Reference platform**: Reference is CamCard macOS screenshot; SimCamCard is iOS. System-carried UI uses iOS patterns (NavigationStack/List/toolbar) while matching in-scope content elements.

### Verification
- Standalone `xcodebuild ... build` (iPhone 18 Pro / iOS 27.0): **BUILD SUCCEEDED**.
- `xcodebuild -only-testing:SimCamCardTests test`: **TEST SUCCEEDED**. 36 cases passed — 6 `CardHolderViewModelTests` + 9 `InMemoryBusinessCardRepositoryTests` + 14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 placeholder + 1 template `SimCamCardTests/example()`. Increment 1 & 2 regression fully green.
- `xcodebuild -only-testing:SimCamCardUITests/CardHolderEmptyUITests test`: **TEST SUCCEEDED**. `testEmptyCardHolderOnFirstLaunch()` passed (38.4s).
- `git status`: only 2 deleted template files + 6 new files; Domain/Repository/spec/pbxproj untouched.
- No `NavigationLink`/`navigationDestination`/sheet in CardHolderView (T02/T13 not overflowed).

### Explicitly not implemented (supported but deferred)
- T02 Scanner navigation; T13 Card Detail; Populated Card Holder; Mock data injection; Search; Tags/Notes; Edit/Delete; Persistence; Contacts export; Quick Action Grid; Bottom tab bar; Tutorial card; "管理" bulk operations.

### Regression
- All Increment 1 & 2 unit tests pass unchanged. Domain Model and Repository untouched. T01 UI test green.

### Human Decision
Accepted — 2026-09-29 (human review).

## 2026-09-29 — Week 2 Increment 3 SDD consistency correction

### Task
Six corrections before final Accept of Increment 3. No Increment 4 work.

### 1. Reference UI scope wording correction
The original entry described Search as "deferred (Search prohibited)" — correct for behavior, but the wording implied the search bar UI was excluded. P01 Card Holder's frozen spec (page-inventory.md) includes search as a main exit; search is **in-scope UI whose behavior is deferred to a later increment**, not permanently excluded.

Similarly, T16 Group Management quick action is **in scope but deferred**, not excluded.

Corrected scope categories:
- **In scope, behavior deferred**: Search (P08), Group Management (T16)
- **Truly excluded** (page-inventory.md "Explicitly observed but excluded"): Promotional Home content, Digital business card, Enterprise verification, VIP/subscription, Enterprise enrichment, Nearby-contacts map, CRM/business-intelligence, Multi-card capture enhancements

Frozen spec not modified.

### 2. T01 conclusion correction
The original entry claimed "T01 PASSES" without distinguishing behavioral acceptance from Reference UI fidelity.

Corrected:
- **T01 behavioral acceptance: PASS** — empty repository → empty Card Holder shown; scan entry available. Verified by unit test + UI test.
- **Reference UI fidelity: PARTIAL** — current SimCamCard UI differs significantly from REF-card-holder-01-empty.png.

Specifically:
- `ContentUnavailableView` is a **Week 2 scaffold**, not a verified replica of the Reference empty-state visual (which is a tutorial card — promotional, excluded from replication, but the scaffold has not been validated as an equivalent substitute).
- Native toolbar `+` is a **Week 2 scaffold**, not a verified replica of the Reference header `+` button.
- Search UI is in scope but not yet implemented.
- These differences are NOT simply macOS-vs-iOS platform differences. Per spec/reference-environment.md, application-owned pages/workflows are authoritative iPhone visual references; only macOS-hosted system dialogs/photo picker are not. The Reference empty Card Holder page is application-owned and is an authoritative visual reference for SimCamCard's iOS implementation.

### 3. T01 UI test enhancement
Added `card-holder-empty` accessibility identifier to the empty-state `ContentUnavailableView` in `CardHolderView.swift`.

Enhanced `CardHolderEmptyUITests.testEmptyCardHolderOnFirstLaunch()` now verifies:
1. Card Holder root exists (navigationBars["名片夹"])
2. "名片 (0张)" empty indicator exists (staticTexts containing "名片 (0张)")
3. "card-holder-empty" accessibility identifier exists
4. Scan entry UI exists (buttons["扫描"])
5. No card-row / list-cell elements exist (app.cells.count == 0)

The old assertion `XCTAssertFalse(app.staticTexts["未命名"].exists)` was replaced — it did not prove the absence of card rows. The `app.cells.count == 0` check is a structural empty-state assertion.

No card-row identifier infrastructure was added (populated UI is deferred — no premature implementation).

### 4. Test count correction
The original entry reported "36 cases passed". Actual `xcodebuild` output confirms **35 cases passed**:
- 6 CardHolderViewModelTests
- 9 InMemoryBusinessCardRepositoryTests
- 14 BusinessCardTests
- 5 PhoneNumberTests
- 1 SimCamCardTests/example() placeholder

6 + 9 + 14 + 5 + 1 = 35. The "36" was an arithmetic error in the original report.

### 5. AppRoute deletion
`SimCamCard/App/AppRoute.swift` was a zero-case enum with no active routes. A grep for `AppRoute` across all `.swift` files found **zero references** outside its own definition file. It was dead scaffolding with no functional use.

Deleted `AppRoute.swift`. When the first real Scan/Detail route is needed in a future increment, `AppRoute` can be recreated with actual cases and wiring at that time.

### 6. Reference UI validation screenshot
Launched the current App on iPhone 18 Pro / iOS 27.0 simulator and captured a validation screenshot at `ai/validation/2026-09-29-increment3-empty-holder.png` (separate from frozen `REF-*` evidence — does not overwrite reference screenshots).

**Observed SimCamCard UI (from validation screenshot):**
- White background (light mode)
- Large title "名片夹" (iOS large title, left-aligned)
- Toolbar trailing `+` button (gray outline, system "plus" symbol)
- Empty state: centered gray "rectangle.stack" SF Symbol + "名片 (0张)" text
- No search bar, no quick action grid, no tutorial card, no bottom tab bar, no "管理" button

**Observed differences vs REF-card-holder-01-empty.png:**

| # | Element | REF-card-holder-01-empty | SimCamCard (validation) |
|---|---|---|---|
| 1 | Background | Dark mode (#1E1E1E–#2D2D2D) | White (light mode) |
| 2 | Title | "名片全能王" window title + "名片 (0张)" section header | "名片夹" large title only |
| 3 | Search bar | Prominent, with placeholder text | Absent |
| 4 | `+` button | Circular header button | iOS toolbar trailing button |
| 5 | Quick Action Grid | 4 cards (新的人脉/分组管理/人脉地图/人脉分析) | Absent |
| 6 | Tutorial card | "30秒快速认识CC" + subtitle | Absent (replaced by ContentUnavailableView) |
| 7 | "管理" button | Next to section header | Absent |
| 8 | Bottom tab bar | 5 tabs with center camera button | Absent |
| 9 | Empty state visual | Tutorial/promotional card | System ContentUnavailableView with icon + count text |

These differences are real application-owned UI gaps, not macOS-vs-iOS system differences. Reference UI fidelity is PARTIAL.

### Files changed (this correction)
- `SimCamCard/View/CardHolder/CardHolderView.swift` — added `.accessibilityIdentifier("card-holder-empty")`; scope comments corrected (search = in-scope deferred, not excluded; Group Mgmt = in scope deferred).
- `SimCamCardUITests/CardHolderEmptyUITests.swift` — rewritten with 5 enhanced verifications.
- `SimCamCard/App/AppRoute.swift` — DELETED (dead scaffolding, zero references).
- `ai/validation/2026-09-29-increment3-empty-holder.png` — NEW validation screenshot.
- `ai/changes.md` — this correction record; prior Increment 3 entry's test count (36→35) and scope wording noted as corrected here.

No Domain Model, Repository, frozen spec, or `project.pbxproj` changes.

### Verification
- Standalone `xcodebuild build` (iPhone 18 Pro / iOS 27.0): **BUILD SUCCEEDED**.
- `xcodebuild -only-testing:SimCamCardTests test`: **TEST SUCCEEDED**. 35 cases passed.
- `xcodebuild -only-testing:SimCamCardUITests/CardHolderEmptyUITests test`: **TEST SUCCEEDED**. Enhanced `testEmptyCardHolderOnFirstLaunch()` passed (16.1s).
- `git status`: AppRoute.swift deleted; no Domain/Repository/spec/pbxproj in diff.
- Validation screenshot captured at `ai/validation/2026-09-29-increment3-empty-holder.png`.
- T02/T13 still not implemented (no navigation destinations wired).

### Human Decision
Accepted — 2026-09-29 (human review).

## 2026-09-29 — Week 2 Increment 4: Deterministic Mock Data + Populated Card Holder + SwiftUI Previews

### Task
Establish deterministic mock fixtures, implement Card Holder S01 populated state, and add formal SwiftUI Previews — without changing the normal empty-repository launch behavior. Covers S01 empty + populated in the same `CardHolderView`.

### Context Provided
- `spec/page-inventory.md` P01 Card Holder (list / empty state / search / scan entry)
- `spec/state-inventory.md` S01 populated (one or more cards shown; list updates immediately after save/delete)
- `spec/reference-tests.md` T01 Empty Holder / T12 Save (card appears immediately after save — Repository → ViewModel → View path)
- `spec/observation-index.md` REF-card-holder-02-after-save.png
- `evidence/screenshots/REF-card-holder-02-after-save.png`
- `spec/data-model.md` §BusinessCard minimum field table, §Multi-value observation, §Missing-field rule, §OCR Pipeline Data
- `dataset/ground-truth/card-001.json` (full bilingual), `card-002.json` (missing website), `card-004.json` (minimal)
- Increment 1 Domain Model, Increment 2 Repository, Increment 3 CardHolderViewModel + Empty Card Holder
- `ai/README.md`

### Constraints
- MockBusinessCards: DEBUG / Preview / UI-test only. NOT Release / default runtime data. Fixed UUIDs, Dates, image reference tokens. No `Date.now` / `UUID()` / random content.
- Normal `app.launch()` stays empty. Mock injected only via launch argument.
- Previews: both `#Preview("Empty Card Holder")` and `#Preview("Populated Card Holder")` with `NavigationStack`. Populated Preview uses Repository → ViewModel real data path, not hardcoded `[BusinessCard]` in View. `.task` for async `loadCards()`, no fake ViewModel initializer.
- Card row accessibility: `card-row-<UUID>` stable identifier. UI tests verify membership, not row position.
- Repository contract defines no order — UI tests verify set membership, not `allCards()` return order.
- Do NOT modify: Domain Model, Repository protocol, InMemory Repository semantics, frozen spec, `project.pbxproj`.
- Do NOT implement: T02 Scanner nav, T13 Detail nav, T15 Search, T16 Group, Delete UI, Persistence, OCR/Camera, Contacts export, full Card Holder UI redesign, default mock injection.

### AI Changes

New files (5; auto-registered via filesystem-synchronized groups, no pbxproj edit):
- `SimCamCard/View/PreviewSupport/MockBusinessCards.swift` — `#if DEBUG`-wrapped deterministic fixtures. 3 representative cards from `dataset/ground-truth/`: `card001` (full bilingual, multi-phone), `card002` (T09 missing-website), `card004` (T20 minimal — name + mobile only). Fixed UUIDs (`00000000-0000-0000-0000-000000000001/002/004`), fixed `Date(timeIntervalSince1970: 1735689600)`, fixed image ref tokens (`mock-card-001-original` etc.). API: `MockBusinessCards.all` (3 cards), `MockBusinessCards.single` (1 card).
- `SimCamCard/View/PreviewSupport/SimCamCardFixture.swift` — launch-argument parser. `-SimCamCardFixture populated` → `MockBusinessCards.all`; `-SimCamCardFixture single` → `MockBusinessCards.single`. `#if DEBUG` branch reads `ProcessInfo.processInfo.arguments`; `#else` stub returns `[]` (no mock references in Release).
- `SimCamCard/View/CardHolder/BusinessCardRow.swift` — row subview. `VStack(alignment: .leading)` with `Text(card.name ?? "未命名").font(.body.weight(.semibold))` + secondary line `[card.jobTitle, card.company].compactMap { $0 }.joined(separator: " · ")`. Secondary line omitted entirely when both nil (Card 004). 3 `#Preview` blocks for individual row variants.
- `SimCamCardUITests/CardHolderPopulatedUITests.swift` — S01 populated-state UI test (NOT a T12 Save test — T12 remains unimplemented). Launches with `-SimCamCardFixture populated`; verifies: root exists, empty state absent, each of the three fixed `card-row-<UUID>` identifiers exists (membership), fixture-visible texts exist (names + secondary lines), no Detail/Scan navigation. No accessibility-node count assertions — 3 cards were observed to produce 5 matching elements in the SwiftUI accessibility tree, so node count is not a stable contract. No row-position assertions.
- `ai/validation/2026-09-29-increment4-populated-holder.png` — populated validation screenshot.

Modified files (4):
- `SimCamCard/App/SimCamCardApp.swift` — `@State viewModel` now seeds `InMemoryBusinessCardRepository(initialCards: SimCamCardFixture.initialCards())`. Normal launch: `SimCamCardFixture.initialCards()` returns `[]` → empty repository. DEBUG UI tests opt in via launch argument. Release `#else` stub always returns `[]`.
- `SimCamCard/View/CardHolder/CardHolderView.swift` — populated state upgraded from `Text(card.name ?? "未命名")` to `List(viewModel.cards) { card in BusinessCardRow(card: card).accessibilityIdentifier("card-row-\(card.id.uuidString)") }`. Added `#Preview("Empty Card Holder")` and `#Preview("Populated Card Holder")` — both with `NavigationStack`; Populated Preview uses Repository + ViewModel real data path + `.task { await viewModel.loadCards() }`.
- `SimCamCardTests/ViewModel/CardHolderViewModelTests.swift` — added 1 `#if DEBUG`-wrapped case: `loadCardsWithMockBusinessCardsFixtureReturnsExpectedMembership` verifies membership via `Set` comparison, no order assertion. Total: 7 `CardHolderViewModelTests` cases.
- `SimCamCardUITests/CardHolderEmptyUITests.swift` — replaced `app.cells.count == 0` with `card-row-*` absence via `NSPredicate(format: "identifier BEGINSWITH %@", "card-row-")`. Long-term contract per Increment 4 brief — does not depend on XCTest cell-count proxy.

No existing Domain Model, Repository, frozen spec, or `project.pbxproj` changes.

### Design decisions
1. **`#if DEBUG` guard on MockBusinessCards + SimCamCardFixture**: mock fixtures are compiled out of Release builds entirely. Release `SimCamCardFixture.initialCards()` is a hardcoded `[]` stub with zero references to `MockBusinessCards`. Mock fixtures never become default runtime data.
2. **Launch-argument pattern (`-SimCamCardFixture <mode>`)**: follows XCTest launch-argument convention. The `-` prefix prevents the value from being interpreted as a URL scheme. Normal `app.launch()` (no argument) → empty repository; `app.launchArguments = ["-SimCamCardFixture", "populated"]` → seeded repository.
3. **`BusinessCardRow` subview**: multi-line row content (Name + Title · Company) is non-trivial to inline in `List`; the subview is reusable across `CardHolderView` and individual Previews. The secondary line is omitted entirely when both `jobTitle` and `company` are nil (Card 004 minimal).
4. **Populated Preview uses real Repository + ViewModel path**: `let viewModel = CardHolderViewModel(repository: InMemoryBusinessCardRepository(initialCards: MockBusinessCards.all))` + `.task { await viewModel.loadCards() }`. No fake ViewModel initializer; no hardcoded `[BusinessCard]` in View. The Preview exercises the same data path as production code.
5. **Card row accessibility `card-row-<UUID>`**: stable per-card identifier. T01 empty test asserts NO `card-row-*` exists via `NSPredicate` (replaces `app.cells.count` proxy). Populated test asserts each UUID's row exists (membership, not position).
6. **No accessibility-node count assertions (final calibration)**: SwiftUI's `List` accessibility element hierarchy may produce multiple matching elements per row — 3 business cards were observed to produce 5 matching `card-row-*` elements (cell wrapper + row content). Per human-review calibration, ALL count-based assertions (including `XCTAssertGreaterThanOrEqual(matches.count, 3)`) were removed from the populated UI test. Membership is verified by per-UUID existence checks only; visible-text verification uses existence checks only. Accessibility-node count is explicitly NOT a stable contract.
7. **UI test text verification uses existence checks**: `descendants(matching: .any)[rowID].staticTexts[...]` does not reliably expose `staticTexts` as children of an element identified by `.accessibilityIdentifier`. The test uses global `app.staticTexts[...].exists` existence queries for each fixture-visible text (names "张伟"/"李娜" and both secondary lines "产品总监 | Product Director · 上海智云科技有限公司" / "市场总监 | Marketing Director · 上海智云科技有限公司"). Existence, not count.

### UI evidence → View element mapping (REF-card-holder-02-after-save.png)

| Reference element | SimCamCard | Status |
|---|---|---|
| Search bar | NOT shown | In-scope, deferred (per Increment 3 correction) |
| Quick Action Grid (4 cards) | NOT shown | Group Mgmt = in scope, deferred; Contact Map/Analytics = excluded |
| "名片 (1张)" section header with count | NOT shown | Application-owned UI gap — Week 2 scaffold |
| Card thumbnail | NOT shown | Domain Model has String reference tokens only; real image loading deferred |
| Card Name (bold) | `Text(card.name ?? "未命名").font(.body.weight(.semibold))` | Implemented (evidence-supported) |
| Card Title · Company (secondary) | `Text([jobTitle, company].compactMap { $0 }.joined(separator: " · "))` | Implemented (evidence-supported) |
| Three-dot per-row menu | NOT shown | Per-row actions / context menu deferred |
| Bottom tab bar | NOT shown | Excluded (switches to excluded pages) |
| "+" header button | Toolbar trailing `+` (non-triggering) | Week 2 scaffold (same as empty state) |

### T01 / S01 acceptance criteria verification

**T01 Empty Card Holder (unchanged from Increment 3):**
- behavioral acceptance: PASS — empty repository → empty Card Holder shown; scan entry available.
- Reference UI fidelity: PARTIAL — `ContentUnavailableView` and toolbar `+` are Week 2 scaffolds.

**S01 populated behavioral acceptance: PASS** — repository → ViewModel → View path correctly renders cards; membership-based loading verified by unit + S01 populated-state UI test; normal launch remains empty; fixture launch is populated; no Detail/Scan/Search/Group behavior implemented (deferred).

**T12 Save**: NOT implemented. Full T12 ("card immediately appears in holder after save") requires the OCR/Camera pipeline to produce a real card — deferred to a later increment. The fixture-injected populated state verifies the rendering path independently, but does not claim T12 PASS.

**Reference UI fidelity (populated): PARTIAL** — populated row renders evidence-supported fields (name, title, company) but omits thumbnail, section count header, three-dot menu, search bar, etc.

### Verification

**Standalone build:**
- `xcodebuild build` (iPhone 18 Pro / iOS 27.0): **BUILD SUCCEEDED**. `__preview.dylib` compiled (Preview macros active).

**Unit tests:**
- `xcodebuild -only-testing:SimCamCardTests test`: **TEST SUCCEEDED**. 36 cases passed — 7 `CardHolderViewModelTests` (6 prior + 1 new fixture membership) + 9 `InMemoryBusinessCardRepositoryTests` + 14 `BusinessCardTests` + 5 `PhoneNumberTests` + 1 placeholder. Increment 1–3 regression fully green.

**UI tests:**
- `CardHolderEmptyUITests.testEmptyCardHolderOnFirstLaunch()`: **PASSED** (7.1s). Enhanced with `card-row-*` absence via `NSPredicate` (replaces `app.cells.count == 0`). Verifies: root exists, "名片 (0张)" indicator, `card-holder-empty` id, scan button, no `card-row-*` elements.
- `CardHolderPopulatedUITests.testPopulatedCardHolderShowsMockCardsByMembership()`: **TEST SUCCEEDED** (final calibrated form, rerun 2026-09-29 19:25). Launches with `-SimCamCardFixture populated`; verifies: root exists, empty state absent, each of the three fixed `card-row-<UUID>` identifiers exists, fixture-visible texts exist (names + secondary lines), no Detail navigation, no Scan behavior. No accessibility-node count assertions, no row-position assertions. (Two earlier runs hit simulator infrastructure issues — one 600s launch timeout, one `launchd_sim` clone-boot crash with the actual test case PASSED on Clone 1; the final clean run used an explicit device UDID with `-parallel-testing-enabled NO`.)

**Preview verification:**
- `Preview code/build: PASS` — both `#Preview` macros (`Empty Card Holder` / `Populated Card Holder`) and the 3 `BusinessCardRow` row Previews compile; the standalone build produced `__preview.dylib` successfully.
- `Xcode Canvas rendering: not independently verified` — no Xcode Canvas session was opened to visually confirm Preview rendering. The simulator populated screenshot (`ai/validation/2026-09-29-increment4-populated-holder.png`) validates the runtime app, not Xcode Canvas.

**Validation screenshot:**
- `ai/validation/2026-09-29-increment4-populated-holder.png` captured (separate from frozen `REF-*` evidence). Shows 3 mock cards: Card 001 (张伟 / 产品总监 | Product Director · 上海智云科技有限公司), Card 002 (李娜 / 市场总监 | Marketing Director · 上海智云科技有限公司), Card 004 (张伟 / no secondary line). Navigation title "名片夹" + toolbar `+` visible. Light mode.

**Boundary check:**
- `git diff --name-only | grep -E "^SimCamCard/Model/|^SimCamCard/Repository/|^spec/|project.pbxproj"` → no matches. Domain Model, Repository, frozen spec, `project.pbxproj` all untouched.
- T02 Scanner nav, T13 Detail nav, T15 Search, T16 Group, Delete UI, Persistence, OCR/Camera all NOT implemented (deferred/prohibited).

### Specification / evidence ambiguity (recorded, not blocking)
1. **Thumbnail rendering**: Reference shows actual card image thumbnail. Domain Model has only `String` reference tokens (no `UIImage`); real image loading deferred (no capture pipeline). Row omits thumbnail — Week 2 scaffold gap.
2. **Three-dot per-row menu**: Reference shows per-row three-dot menu. Per-row actions / context menu / delete deferred — not implemented this increment.
3. **Section header count "名片 (N张)"**: Reference shows count above list. Current populated state shows rows directly via `List` with no count header. Application-owned UI gap.
4. **Row field layout**: Reference shows Name + Title (one line) + Company (next line). Current implementation uses `Name` (bold) + `JobTitle · Company` (secondary, joined by ` · `). Week 2 scaffold layout, not pixel-validated.
5. **Card-001 vs Card-004 name collision**: Both ground-truth cards have name "张伟". UI test distinguishes by UUID, not name. Membership-based per-UUID checks handle the collision.
6. **SwiftUI List accessibility element hierarchy**: `descendants(matching: .any).matching(NSPredicate(identifier BEGINSWITH "card-row-"))` returns 5 elements for 3 cards — SwiftUI creates multiple accessibility elements per row (cell wrapper + row content). Per final human-review calibration, the populated UI test contains NO accessibility-node count assertions at all; membership is verified by per-UUID existence checks and visible-text existence checks only.

### Explicitly not implemented (supported but deferred)
- T02 Scanner navigation; T12 Save (full save flow — requires OCR/Camera pipeline; only the rendering path on a pre-seeded repository is exercised by the S01 populated-state UI test, which does NOT claim T12 PASS); T13 Card Detail navigation; T15 Search behavior; T16 Group behavior; Delete UI; Persistence; OCR/Camera; Contacts export; Quick Action Grid; Bottom tab bar; Section count header; Card thumbnail; Three-dot per-row menu; Search bar.

### Regression
- All Increment 1–3 unit tests pass unchanged (36 cases total). Domain Model, Repository, frozen spec, `project.pbxproj` untouched. T01 empty UI test green with enhanced `card-row-*` assertion. New populated fixture UI test green.

### Human Decision
Accepted — 2026-09-29 (human review).

Final conclusions (unchanged on acceptance):
- S01 populated behavioral acceptance: PASS
- Reference UI fidelity: PARTIAL
- T12 Save: NOT implemented / NOT claimed passed
- Preview code/build: PASS
- Xcode Canvas rendering: not independently verified
- Repository ordering remains unspecified
- UI tests verify per-UUID membership, not row position or accessibility node count
- Simulator / parallel clone failures were test-infrastructure issues, not business failures
