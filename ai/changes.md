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

## 2026-09-29 — Week 2 Increment 5: Card Detail Skeleton + Card Selection Navigation

### Task
From the populated Card Holder, select a BusinessCard and push a read-only Card Detail page presenting frozen-evidence-supported structured fields through the same Domain Model. Detail skeleton only — no Edit / Delete / Group / Notes / Export. Covers P07, S06 `detailCollapsed`, T13.

### Context Provided
- `spec/page-inventory.md` P07 Card Detail ("View structured data and card actions"; exits Edit/Group/Note/Delete/Export)
- `spec/state-inventory.md` S06 (`saveSucceeded` / `detailCollapsed` / `detailExpanded` / `editing` / `deleted`)
- `spec/reference-tests.md` T13 Detail ("Saved structured fields are visible in detail view.")
- `spec/data-model.md` §BusinessCard, §Multi-value observation (`phones[]` mobile/office/fax/other, `emails[]`), §Missing-field rule
- `spec/observation-index.md` Detail evidence list
- `evidence/screenshots/REF-detail-01-collapsed.png`, `REF-detail-02-phone-picker.png`, `REF-detail-03-after-edit-expanded.png`, `REF-detail-04-more-actions.png`
- `dataset/ground-truth/card-001.json`
- Current BusinessCard / PhoneNumber, CardHolderView / BusinessCardRow, CardHolderViewModel, MockBusinessCards, `ai/README.md`

### Evidence re-read summary
- REF-detail-01 (collapsed): dark header card with surname avatar, name/title/company, primary phone + address; action grid (电话/地址/备注/编辑); 未分组 row; notes row; collapsed field list (1 phone + email + address) with 「展开」; 更多资料/昵称; bottom bar (存入通讯录/递名片/分享名片).
- REF-detail-03 (expanded): both phones with kind labels (+86 138 0013 8000 **手机**, +86 2155551234 **工作电话**), email (**工作邮箱**), address (**公司地址**), company rows incl. English company name, website (**首页**), 「收起」.
- REF-detail-02 confirms phone-kind labels via the phone picker; REF-detail-04 confirms the deferred more-actions menu (保存通讯录/编辑/分组/备注/提醒/删除).

### Constraints
- Only add routes actually used: `AppRoute.cardDetail(UUID)` — no `.scan/.edit/.group/.notes/.export`.
- Selection by stable UUID/BusinessCard value, never row index; Repository ordering remains unspecified.
- Multi-value fields rendered as `phones[]` / `emails[]` — no invented single mobile/email properties.
- Missing fields hidden, never fabricated (T20 Card 004 negative case).
- No fake image/thumbnail (Domain holds String references only); no "Coming soon"/"Not implemented".
- Do NOT modify: Domain Model, Repository protocol/semantics, frozen spec, `project.pbxproj`.

### AI Changes

New files (6; auto-registered via filesystem-synchronized groups):
- `SimCamCard/App/AppRoute.swift` — `enum AppRoute: Hashable { case cardDetail(UUID) }`. First real route; UUID-based selection.
- `SimCamCard/ViewModel/CardDetailViewModel.swift` — `@MainActor @Observable final class`; holds `private(set) var card: BusinessCard`; read-only; no DTO, no repository, no actions.
- `SimCamCard/View/CardDetail/CardDetailView.swift` — read-only Detail: identity header (name/jobTitle/company, nil-hidden) + structured-field List (all phones with kind labels, all emails, website, address). Accessibility identifiers on root/header/each field. Two `#Preview`s (card001 full / card004 minimal) in NavigationStack.
- `SimCamCard/View/CardDetail/CardDetailFieldRow.swift` — stateless row: SF Symbol + value + secondary Chinese label.
- `SimCamCardTests/ViewModel/CardDetailViewModelTests.swift` — 3 Swift Testing cases (full fixture value fidelity; 3 phones + 2 emails preservation; card004 minimal no-fabrication).
- `SimCamCardUITests/CardDetailUITests.swift` — 2 XCTest cases (full 001 field presence + back navigation; 004 minimal negative case). Both attach a `keepAlways` screenshot used for validation evidence.

Modified files (3):
- `SimCamCard/View/CardHolder/CardHolderView.swift` — populated rows are now `NavigationLink(value: AppRoute.cardDetail(card.id))` wrapping `BusinessCardRow`, retaining `card-row-<UUID>`. Added `.navigationDestination(for: AppRoute.self)` resolving UUID via `viewModel.cards.first(where:)` and constructing `CardDetailViewModel(card:)` with the full value.
- `SimCamCard/View/CardHolder/BusinessCardRow.swift` — comments only (row now navigates); no visual/behavior change to the row itself.
- `ai/changes.md` — this record.

New validation artifacts (2): `ai/validation/2026-09-29-increment5-card-detail-001-full.png`, `ai/validation/2026-09-29-increment5-card-detail-004-minimal.png` (exported from XCTAttachments; separate from frozen `REF-*`).

No Domain Model, Repository, frozen spec, `project.pbxproj`, or `MockBusinessCards.swift` changes.

### Design decisions
1. **No second repository lookup for Detail.** The holder already owns the complete aggregate; navigation carries the stable UUID and the holder resolves it to the full `BusinessCard` value it already holds. Frozen spec defines no re-fetch requirement for detail open; Week 2 has no edit/persistence flow. `CardDetailViewModel(card:)` takes the value directly. Future T14/T18 can introduce repository access if an actual need appears.
2. **Typed route with UUID, not value or index.** `AppRoute.cardDetail(UUID)` keeps selection stable regardless of unspecified Repository `allCards()` ordering; resolution happens at the holder (the cards' owner).
3. **All multi-value fields shown; no collapse interaction.** REF-detail-01's collapsed view hides secondary phones behind 「展开」, while the brief explicitly requires `phones[]/emails[]` to render without loss and to be UI-tested. The skeleton therefore renders every structured field at once (content-wise closer to REF-detail-03 expanded) without implementing 展开/收起. Consequence recorded honestly against S06: `detailCollapsed` is PARTIAL / not implemented as a distinct state, `detailExpanded` is a PARTIAL scaffold, and the expand/collapse interaction is NOT IMPLEMENTED (allowed Week 2 skeleton gap). Multi-value visibility is deliberately retained and must not be regressed to mimic the collapsed screenshot.
4. **View-layer phone-kind labels.** Chinese labels (mobile→手机, office→工作电话, fax→传真, other→其他) live in a `private extension PhoneNumber.Kind` inside `CardDetailView.swift`; the Domain Model stays UI-independent. Email label is neutral 「邮箱」 because frozen Domain `emails: [String]` has no kind (Reference shows 工作邮箱; kind not in model — see ambiguity).
5. **Absent fields = hidden rows.** No empty placeholders; Card 004 renders header name + one mobile row only.
6. **No behaviorless control farm; gaps classified as P07 in-scope.** The dark header/avatar/card image, 电话/地址/备注/编辑 action buttons, group row, notes row, favorite star, more menu, bottom action area, and expand/collapse control are all **P07 application-owned UI** present in the Reference. They are recorded as `P07 in-scope visual gap / behavior deferred` — their *behaviors* map to T14/T16/T17/T19/P10 (and the image pipeline to Week 3), but the visual elements themselves are **not** out of scope merely because their behaviors land later. None are stubbed as non-functional controls in this skeleton.
7. **Accessibility contract:** root `card-detail`; header `card-detail-name/-job-title/-company`; `card-detail-phone-<PhoneNumber.id>`; `card-detail-email-<array-index>` (emails are untyped Strings); `card-detail-website`; `card-detail-address`. Holder rows keep `card-row-<UUID>` so the test flow is tap-by-stable-id with no positional assumptions.

### UI evidence → View element mapping (REF-detail-01 / REF-detail-03)

| Reference element | SimCamCard | Status |
|---|---|---|
| Nav title 名片详情 + back | `navigationTitle("名片详情")` inline; system back | Implemented (native scaffold) |
| Header name / title / company | VStack of Text, nil-hidden | Implemented (plain light scaffold) |
| Surname avatar (张) | NOT shown | P07 in-scope visual gap / behavior deferred (scaffold; derived styling only) |
| Dark header card / card image strip | NOT shown | P07 in-scope visual gap / behavior deferred (String image refs only; no fabricated image; pipeline is Week 3) |
| phones[] with 手机/工作电话 labels | One `CardDetailFieldRow` per PhoneNumber | Implemented, all kinds |
| emails[] with label | One row per email, label 邮箱 | Implemented (neutral label — no email kind in Domain) |
| website (首页) | Row when non-nil | Implemented |
| address (公司地址) | Row when non-nil | Implemented |
| English company (Shanghai Zhiyun…) / 昵称 | NOT shown | Excluded from frozen Domain (Revision 8) — not a P07 gap |
| 展开/收起 toggle | NOT implemented | P07 in-scope visual gap; expand/collapse interaction NOT IMPLEMENTED; all fields shown directly |
| Action buttons (电话/地址/备注/编辑) / star / more menu / group row / notes row / bottom action area | NOT shown | P07 in-scope visual gaps / behaviors deferred (T14/T16/T17/T19/P10); no behaviorless stubs |

### T13 acceptance

- **T13 read-only detail field visibility/navigation: PASS** — selecting a holder row pushes Detail via real in-app NavigationStack navigation; every fixture-backed structured field is visible; multi-phone (mobile+office) and multi-value email are preserved (no loss); back returns to the populated holder; Card 004 minimal path shows only name + mobile with zero fabricated fields.
- **T12 → T13 saved-card end-to-end workflow: NOT IMPLEMENTED** — the Detail screen is driven by deterministic mock fixtures, not by a card persisted through the T12 Save workflow (T12 Save itself remains unimplemented). The PASS above is scoped to read-only rendering and navigation only; it must not be read as a complete save-then-view end-to-end T13 workflow.

### S06 state coverage

- **`detailCollapsed`: PARTIAL / not implemented as a distinct state** — there is no collapsed representation that hides secondary phones/emails behind 展开.
- **`detailExpanded`: PARTIAL scaffold** — all phones/emails/website/address are shown at once, so the *content* is closer to the expanded Reference, but expanded-state chrome and interactions do not exist.
- **expand/collapse interaction (展开/收起): NOT IMPLEMENTED** — allowed Week 2 skeleton gap. The all-fields-at-once rendering must not be described as having completed `detailCollapsed`.
- Multi-value design intentionally unchanged: all `phones[]` and `emails[]` stay visible, missing fields stay hidden, Card 004 stays fabrication-free. The second phone must not be re-hidden just to mimic the collapsed screenshot.

### P07 Reference fidelity

- **Reference UI fidelity: PARTIAL** — light-mode plain List/header vs. Reference dark card. The missing elements (header/avatar/card image, action buttons, group row, notes row, more menu, bottom action area, expand/collapse control) are **P07 in-scope visual gaps with behavior deferred** to the increments owning T14/T16/T17/T19/P10 and the Week 3 image pipeline — they are P07 application-owned UI, not out-of-scope items.

### Verification
- Standalone `xcodebuild build` (iPhone 18 Pro / iOS 27.0): **BUILD SUCCEEDED**.
- Unit tests (`-only-testing:SimCamCardTests`, `-parallel-testing-enabled NO`): **TEST SUCCEEDED**. Swift Testing "Test run with 39 tests in 6 suites passed" — 36 prior + 3 new CardDetailViewModel (full fixture values + `card == MockBusinessCards.card001` no-DTO check; 3 phones/2 emails no-loss; card004 nil/empty assertions).
- New UI tests (`CardDetailUITests`, populated fixture, explicit device UDID, no parallel clones): **TEST SUCCEEDED**.
  - `testCardDetailShowsFullFixtureFields`: passed (11.8s on rerun; first run 23.7s).
  - `testCardDetailMinimalCardDoesNotFabricateFields`: passed (9.1s on rerun; first run 39.9s).
- Regression: `CardHolderEmptyUITests` (6.2s) + `CardHolderPopulatedUITests` (7.1s): both **PASSED** unchanged. Increment 4's "no Detail navigation while on holder" guarantee still holds (no taps ⇒ no push).
- Validation screenshots inspected: 001 full shows header + 2 phones with kind labels + email + website + address; 004 minimal shows only 张伟 + one 手机 row.
- Boundary check: `git diff --name-only` contains no `SimCamCard/Model/`, `SimCamCard/Repository/`, `spec/`, or `project.pbxproj`.

### Specification / evidence ambiguity (recorded, not blocking)
1. **Collapsed vs. multi-value requirement**: S06 names `detailCollapsed`, whose Reference hides secondary phones behind 展开; the brief requires all `phones[]/emails[]` visible. Resolved by showing all fields without the toggle. Recorded consequence: S06 `detailCollapsed` is PARTIAL / not implemented as a distinct state, `detailExpanded` is a PARTIAL scaffold, and the expand/collapse interaction is NOT IMPLEMENTED (allowed Week 2 skeleton gap). Multi-value visibility is intentionally retained; the second phone must not be re-hidden to mimic the collapsed screenshot.
2. **Email kind label**: Reference labels the address 工作邮箱; frozen Domain `emails: [String]` has no kind. Neutral 「邮箱」 used rather than fabricating a kind.
3. **Address normalization**: Reference renders "中国 上海市 浦东新区世纪大道 100号 200120" (added country + spacing); fixture/UI render the ground-truth string "上海市浦东新区世纪大道100号 200120" verbatim. Normalization is an OCR/enrichment concern, not fabricated here.
4. **Avatar/header card image**: Reference shows a surname avatar and a card-photo strip; Domain only stores String references and no capture pipeline exists. Neither an image nor a placeholder is fabricated; header is plain text.
5. **Header-vs-list field duplication**: Reference repeats company (+title) in the expanded field list. The skeleton shows name/title/company once in the header; duplicate rows omitted as scaffold simplification.
6. **Email row identifiers use array index** (`card-detail-email-<index>`) because `emails` is an untyped String collection; current fixtures carry one email each. If the Domain later adds an email id/kind, identifiers should migrate to stable ids.

### Explicitly not implemented (supported but deferred)
T02 Scanner; T12 Save flow; **T12 → T13 saved-card end-to-end workflow (Detail is fixture-driven; not a save-then-view flow)**; T14 Edit; T15 Search; T16 Group; T17 Delete; T18 Persistence; T19 Export; P10 Notes; S06 expand/collapse interaction (展开/收起) with distinct `detailCollapsed`/`detailExpanded` states; phone/email/web invocation (no tel:/mailto/URL wiring).

P07 application-owned UI present in Reference but absent from this skeleton (**P07 in-scope visual gap / behavior deferred**, not out of scope): favorite star; more menu; 电话/地址/备注/编辑 action buttons; group row; notes row; bottom action area; surname avatar; header card image / card-photo strip; expand/collapse control.

### Human Decision
Accepted — 2026-09-29 (human review).

Final conclusions (unchanged on acceptance):
- T13 read-only detail field visibility/navigation: PASS
- T12 → T13 saved-card end-to-end workflow: NOT IMPLEMENTED (Detail is fixture-driven; T12 Save remains unimplemented)
- S06 `detailCollapsed`: PARTIAL / not implemented as a distinct state
- S06 `detailExpanded`: PARTIAL scaffold
- expand/collapse interaction (展开/收起): NOT IMPLEMENTED (allowed Week 2 skeleton gap)
- P07 Reference UI fidelity: PARTIAL
- P07 application-owned visual gaps (header/avatar/card image, action buttons, group row, notes row, more menu, bottom action area, expand/collapse control) remain in scope as P07 in-scope visual gaps; behavior deferred to T14/T16/T17/T19/P10 and the Week 3 image pipeline
- Multi-value design unchanged: all `phones[]` / `emails[]` remain visible; the second phone was not re-hidden to mimic the collapsed screenshot
- Missing fields are not fabricated (Card 004 minimal path shows name + one mobile only)
- Build: PASS; Unit tests 39/39 PASS; Detail UI tests PASS; Holder UI regression PASS (results remain as previously verified)
- Domain Model / Repository protocol & semantics / frozen spec / project.pbxproj unchanged

## 2026-09-29 — Week 2 Increment 6: Scan Entry UI Shell

### Task
Establish real P01 → P02 navigation and the static Scanner page shell:
Card Holder → Scan Entry → Scanner UI shell → Back. Week 2 final
functional increment. No real Camera / AVFoundation / Permission / Photo
Import / Capture / OCR / Detection.

### Frozen sources re-read
- `spec/page-inventory.md` P01 Card Holder (exit: Scanner), P02 Scanner (Camera preview and card detection; exits Capture / Photo Import / Back)
- `spec/state-inventory.md` S02 Camera / Scanner (permissionUnknown / permissionDenied / preview / cardNotDetected / cardDetected / captured / cancelled)
- `spec/reference-tests.md` T02 Enter Scanner ("Scan entry opens scanner/camera UI."); T03/T04/T05/T06 read as later-boundary references only
- `spec/observation-index.md` Scanner / Permissions / Import evidence list
- `evidence/screenshots/REF-scanner-01-initial.png` — viewed directly; sole primary visual basis for the initial scanner state
- Boundary-only viewing: `REF-scanner-02-card-detected.png` (blue detection frame, live feed, "发现名片，点击拍摄" — deliberately NOT built); `REF-permission-01-camera.png`, `REF-import-01-photo-picker.png`, `REF-crop-01-manual-adjust.png` not opened/replicated
- Current `AppRoute.swift`, `CardHolderView.swift`, `SimCamCardApp.swift`, existing UI tests, `ai/README.md`

### Evidence classification (REF-scanner-01-initial.png)
- **System/host-owned, not replicated:** macOS traffic lights and window title "名片全能王"; on iOS the status bar / home indicator remain host-owned (dark appearance only via `preferredColorScheme(.dark)`).
- **Application-owned, built this increment:** close ✕ (real back); 基础识别 / AI高精度识别 segmented selector (static, 基础识别 selected); ••• more glyph (static); full-black viewport with thin white rounded aiming frame (pure SwiftUI shape, no camera content); guidance capsule "请将镜头靠近名片" (frozen user-guidance copy, not a developer placeholder); capture-mode tabs 连续拍摄 / 多张拍摄 / 单张拍摄 (selected, blue indicator) / 二维码 (static); 相册 entry (visual shell, empty action); shutter (visual shell, empty action); batch stack glyph (static; badge "5" omitted — zero captures exist in the shell, so the number would be fabricated state).
- **No UI added without evidence:** no flash control, no tips beyond the one observed capsule, no detection frame styling beyond the static white guide.

### Files changed
New files (2; auto-registered via filesystem-synchronized groups):
- `SimCamCard/View/Scan/ScanEntryView.swift` — single-file static scanner shell; no ViewModel (no camera/capture/permission/business state exists); two `#if DEBUG`-independent sections (no mock data) and one `#Preview("Scanner Shell")` in NavigationStack.
- `SimCamCardUITests/ScanEntryUITests.swift` — 2 XCTest cases (enter shell + evidence-supported static controls; close returns to Holder with state unchanged).

Modified files (3):
- `SimCamCard/App/AppRoute.swift` — added exactly one route, `case scan`; final enum is `{ case cardDetail(UUID); case scan }`. No `.capture/.photoImport/.crop/.recognition/.permission/.edit/...`.
- `SimCamCard/View/CardHolder/CardHolderView.swift` — toolbar "+" changed from empty-action Button to `NavigationLink(value: AppRoute.scan)` (accessibilityLabel "扫描", identifier `scan-entry`; T01 contract preserved); `navigationDestination(for: AppRoute.self)` switch extended with `case .scan: ScanEntryView()` (exhaustive; Detail case untouched).
- `ai/changes.md` — this record.

New validation artifact: `ai/validation/2026-09-29-increment6-scan-entry.png` (XCTAttachment; separate from frozen `REF-*`).

### Route / navigation design
- Same NavigationStack + typed `AppRoute` system as Detail; no second Bool/sheet state and no second NavigationStack.
- Holder "+" → push `ScanEntryView()`; the Scanner hides the system nav bar and renders its own ✕ that calls `@Environment(\.dismiss)` — a standard system NavigationStack pop (Holder → Scan → Back → Holder). The interactive swipe-back gesture remains available.
- Switch over AppRoute stays exhaustive; adding `.scan` did not alter `.cardDetail` resolution.

### Controls and actual behavior
| Control | Identifier | Behavior in this increment |
|---|---|---|
| Holder "+" | `scan-entry` | Real push navigation to Scanner |
| Scanner ✕ | `scan-close` | Real `dismiss()` pop back to Holder |
| 相册 | `scan-photo-import` | Visual shell; empty action — NO PhotosPicker / photo permission (T05 deferred). UI test taps it and asserts the page is unchanged |
| Shutter | `scan-capture` | Visual shell; empty action — no capture, no Recognition, no BusinessCard, no Repository change (T04 deferred). UI test taps it and asserts the page is unchanged |
| Segmented selector / mode tabs / ••• / batch glyph | — | Static non-interactive chrome (tabs/selector combined into single accessibility elements; glyphs hidden from accessibility); no mode switching, no menu, no batch review |
| Batch badge "5" | — | Deliberately not rendered (would fabricate a captured-image count) |

No AVFoundation / Vision / Photos imports; no `NSCameraUsageDescription` change; no entitlements; no OCR/detection/crop; no fake camera image and no developer placeholder text.

### Implementation note (real defect fixed during verification)
First UI-test run exposed a SwiftUI accessibility behavior: an `.accessibilityIdentifier` attached to the container that parents Buttons propagates down and overrides the Buttons' own explicit identifiers (all three controls reported identifier `scan-entry-view` with their own labels). Fix: the root `scan-entry-view` marker is attached to the childless `Color.black` background layer inside the root ZStack; the interactive VStack is a sibling layer, so button identifiers remain their own. Documented in code comments.

### S02 state-by-state status
- Scanner shell / entry presentation: **PASS**
- S02 `preview`: **PARTIAL — visual shell only, no live camera preview** (black surface + static aiming frame)
- S02 `permissionUnknown`: **NOT IMPLEMENTED as a real camera state**
- S02 `permissionDenied`: **NOT IMPLEMENTED**
- S02 `cardNotDetected` visual presentation: **PARTIAL** — the initial shell already presents the static "no card detected" guidance capsule ("请将镜头靠近名片") and aiming frame observed in REF-scanner-01, but there is no real detection state and no transition into or out of it
- S02 `cardNotDetected` dynamic detection state/transition: **NOT IMPLEMENTED**
- S02 `cardDetected`: **NOT IMPLEMENTED** (blue frame / "发现名片，点击拍摄" from REF-scanner-02 not built)
- S02 `captured`: **NOT IMPLEMENTED**
- Scanner close/back navigation behavior: **PASS** — tapping ✕ pops the NavigationStack back to the Card Holder (verified by UI test; holder card state unchanged)
- S02 `cancelled` state: **NOT MODELED / PARTIAL** — only the user-initiated ✕ NavigationStack return is verified; that navigation behavior is NOT equivalent to having built a complete `cancelled` state (no cancellation side effects, state transitions or post-cancel camera lifecycle exist)

### T02 status
- **T02 scan-entry navigation / scanner-shell behavior: PASS** — holder scan entry opens the scanner UI via real in-app NavigationStack navigation; evidence-supported static shell is presented; ✕ returns to the holder.
- Explicitly NOT claimed: live camera preview NOT IMPLEMENTED; camera permission NOT IMPLEMENTED; capture NOT IMPLEMENTED; photo import NOT IMPLEMENTED. This is not "T02 full camera behavior PASS", and P02 camera functionality is not complete.

### Validation screenshot comparison (REF-scanner-01-initial.png vs runtime)
Matched: overall full-black surface; top-leading ✕; centered segmented selector with white 基础识别 pill and blue AI高精度识别 text; trailing •••; large white thin rounded aiming frame over black; top-inner translucent capsule "请将镜头靠近名片"; bottom mode tabs 连续拍摄/多张拍摄/单张拍摄(selected white bold + blue indicator)/二维码； bottom-leading photo glyph + 相册 label; centered white shutter with gray ring; trailing batch stack glyph; white status-bar content on the dark surface.

Missing / different (deliberate Week 2 gaps or platform differences):
- macOS window chrome (traffic lights, title) — host-owned, N/A on iPhone.
- Live black camera surface is a static `Color.black`; no camera feed (S02 preview PARTIAL).
- Batch badge "5" omitted on purpose (no fabricated captured count).
- The batch/photo glyphs use SF Symbol approximations of the Reference glyphs.
- Static chrome is non-interactive (segmented/mode tabs/•••/batch); no flash control exists in the initial Reference and none was added.
- Pixel-level spacing/corner radii/font metrics are approximations within the iPhone layout, not measured replicas of the macOS window.

Reference UI fidelity: **PARTIAL** — strong initial-state visual correspondence, but all camera-dependent and interactive behaviors are absent by design.

### Verification (iPhone 18 Pro / iOS 27.0 Simulator, explicit UDID, -parallel-testing-enabled NO)
1. Standalone build: **BUILD SUCCEEDED** (re-verified on final sources after the identifier fix).
2. Full `SimCamCardTests`: **TEST SUCCEEDED** — Swift Testing "Test run with 39 tests in 6 suites passed" (unchanged; no new unit-test surface — no business logic was added).
3. Clean final UI run (one clean PASS round): **TEST SUCCEEDED**, 6/6 business cases:
   - CardHolderEmptyUITests.testEmptyCardHolderOnFirstLaunch — PASS (6.6s; scan entry still found as button "扫描").
   - CardHolderPopulatedUITests.testPopulatedCardHolderShowsMockCardsByMembership — PASS (6.8s; deterministic populated fixture unaffected).
   - CardDetailUITests.testCardDetailMinimalCardDoesNotFabricateFields — PASS (12.1s).
   - CardDetailUITests.testCardDetailShowsFullFixtureFields — PASS (12.3s; Detail route intact after the enum/switch change).
   - ScanEntryUITests.testEnterScannerShowsStaticShell — PASS (11.4s).
   - ScanEntryUITests.testCloseReturnsToCardHolderWithStateUnchanged — PASS (12.0s).
   - An earlier combined run failed the 2 new Scan cases on the accessibility-identifier propagation defect (business failure, not infrastructure); fixed and re-verified green; the final round above is clean.
4. Normal launch remains empty; populated fixture remains deterministic; Detail route still works (regression cases above).
5. Boundary check: `git diff --name-only` contains no `SimCamCard/Model/`, `SimCamCard/Repository/`, `spec/`, `dataset/`, `project.pbxproj`, `MockBusinessCards.swift`, or `CardDetailViewModel.swift`. Preview code/build: PASS. Xcode Canvas rendering: not independently verified.
6. No camera permission was requested during any test (no permission-dialog dependency).

### Explicitly deferred / not implemented
Live camera (AVFoundation preview), T03 camera permission states and dialogs, T04 shutter capture workflow, T05 photo import (PhotosPicker) and S03 states, T06/S04 boundary detection & crop, OCR/Vision/recognition (P05), recognition-mode switching （基础/AI), capture-mode switching （连续/多张/二维码）, more menu (•••), batch review stack + count badge, save/repository mutation from the scanner. No Domain draft model was introduced.

### Ambiguity recorded
1. Reference shows a batch badge "5" even on the "initial" screenshot; the shell has zero captures, so the count is omitted rather than fabricated.
2. The Reference is macOS dark CamCard window chrome; the iPhone rendering keeps application-owned elements and drops host chrome per the reference-environment rule.
3. Static tab/selector chrome is rendered non-interactive (combined accessibility elements) to avoid presenting fake controls as individually actionable while preserving visible fidelity.

### Human Decision
Accepted — 2026-09-29 (human review).

Final conclusions (unchanged on acceptance):
- T02 scan-entry navigation / scanner-shell behavior: PASS
- S02 Scanner shell / entry presentation: PASS
- S02 `preview`: PARTIAL — visual shell only, no live camera preview
- S02 `cardNotDetected` visual presentation: PARTIAL (static guidance capsule + aiming frame shown; no real detection state/transition)
- S02 `cardNotDetected` dynamic detection state/transition: NOT IMPLEMENTED
- S02 `permissionUnknown` / `permissionDenied`: NOT IMPLEMENTED (permissionUnknown not implemented as a real camera state)
- S02 `cardDetected`: NOT IMPLEMENTED
- S02 `captured`: NOT IMPLEMENTED
- Scanner close/back navigation behavior: PASS (✕ pops NavigationStack to Card Holder; card state unchanged)
- S02 `cancelled` state: NOT MODELED / PARTIAL (navigation back verified; not a complete cancelled state machine)
- Live camera preview / camera permission / capture / photo import: NOT IMPLEMENTED — not "T02 full camera behavior PASS"; P02 camera functionality is not complete
- Reference UI fidelity: PARTIAL
- Build: PASS; Unit tests 39/39 PASS; Scan UI tests PASS; Holder UI regression PASS; Detail UI regression PASS (results remain as previously verified)
- Boundary check unchanged: no Domain Model / Repository / spec / dataset / project.pbxproj / MockBusinessCards / CardDetailViewModel changes; Preview code/build PASS; Xcode Canvas rendering not independently verified

## 2026-09-30 — Week 2 Increment 7: Integration / Regression / Reference Review

### Task
Week 2 final increment: no new production feature. Validate that Increments 1–6 compose into one stable navigation skeleton via a new integration smoke test; run full regression; audit architecture, dead code, boundaries, and traceability; produce the Week 2 acceptance matrix and readiness conclusion.

### Starting baseline
- branch: `week2/skeleton`
- HEAD: `504604f feat(scan): 建立扫描入口骨架`
- merge-base with `main`: `8cff0bf` (Week 1 SDD baseline)
- relative to main: ahead 6 / behind 0
- working tree at start: clean except for the local-only Increment 7 plan file (untracked). That plan file has been moved out of the repository before final readiness assessment. After Increment 7 implementation, the working tree contains only this increment's own deliverables: `ai/changes.md` (modified), `SimCamCardUITests/Week2IntegrationUITests.swift` (new), and `ai/validation/2026-09-29-week2-integration.png` (new). No unrelated or untracked files remain.

### Frozen sources re-read
`spec/page-inventory.md` (P01/P02/P07), `spec/state-inventory.md` (S01/S02/S06), `spec/data-model.md`, `spec/reference-tests.md`, `spec/observation-index.md`, `spec/reference-environment.md`, `ai/README.md`, `ai/changes.md`. Verified that frozen spec content is unchanged and that every prior increment's traceability conclusions still hold.

### Architecture audit

**Domain (`SimCamCard/Model/`, 4 files):**
`BusinessCard` — `nonisolated struct`, `Identifiable`, `Sendable`, `Hashable`. No UIKit/SwiftUI dependency. `phones: [PhoneNumber]` is the single source of truth (no single-value mobile/officePhone/fax). `originalImageReference`/`processedImageReference` are required `String` references (no UIImage, not Optional). `nameLatin`/`companyLatin`/`department`/`languageProfile` are NOT in the Domain (Revision 8 exclusion). `rawOCRText: String?` preserves the OCR interface shape (Week 2 default nil). `tags`/`notes` collections exist for interface shape; UI deferred.

**Repository (`SimCamCard/Repository/`, 2 files):**
`BusinessCardRepository` protocol — `nonisolated`, `async`. `InMemoryBusinessCardRepository` — actor, `initialCards: []` default. Ordering is implementation-defined (not a contract). `save` = upsert by id. `delete` of missing id = safe no-op. No persistence (SwiftData/CoreData/Contacts). No presentation sorting contract.

**ViewModels (`SimCamCard/ViewModel/`, 2 files):**
`CardHolderViewModel` (`@MainActor @Observable`) — owns `cards` state sourced from the Repository; no duplicate DTO; no sorting contract. `CardDetailViewModel` (`@MainActor @Observable`) — read-only; receives the full `BusinessCard` value from the holder; no second Repository lookup; no edit/persistence actions. No `ScanViewModel` — the Scanner shell has no camera/capture/permission/business state.

**Views (`SimCamCard/View/`, 5 files):**
`CardHolderView` — `NavigationStack` + typed `AppRoute`; holder List rows wrapped in `NavigationLink(value: .cardDetail(id))`; toolbar "+" is `NavigationLink(value: .scan)`. `CardDetailView` — read-only `List` with identity header + fields Section; all phones/emails visible; nil fields hidden; no fabrication. `ScanEntryView` — static dark shell; no AVFoundation; ✕ = `dismiss()`; shutter/photo entry = empty action visual shell. `BusinessCardRow` — stateless card row. `CardDetailFieldRow` — stateless field row.

**PreviewSupport (`SimCamCard/View/PreviewSupport/`, 2 files):**
`SimCamCardFixture` — DEBUG-only launch-argument-driven fixture switch. `MockBusinessCards` — deterministic UUIDs, fixed Date, three fixtures (001 full bilingual multi-phone, 002 missing website, 004 minimal name+mobile). No `Date.now` or `UUID()` in fixture generation.

### AppRoute audit
```swift
enum AppRoute: Hashable {
    case cardDetail(UUID)
    case scan
}
```
No speculative routes (`.edit`, `.group`, `.notes`, `.export`, `.capture`, `.photoImport`, `.crop`, `.recognition`, `.permission` — all absent). `navigationDestination(for: AppRoute.self)` switch is exhaustive; `.cardDetail` resolves UUID to the full `BusinessCard` the holder already owns (no index dependency, no second lookup); `.scan` pushes `ScanEntryView()`.

### Dead code / speculative scaffold audit
**CLEAN.** No empty enums, no empty ViewModels, no unused routes, no `ContentView`, no placeholder pages, no "Coming soon"/"Not implemented" user-facing text (only in code comments as prohibition notes), no `fatalError`/`preconditionFailure`. Every declared type, route, and ViewModel has at least one real consumer.

### Boundary / dependency audit
**CLEAN.** No `import AVFoundation`, `Vision`, `Photos`/`PhotosUI`, `SwiftData`, `CoreData`, `Contacts`/`ContactsUI`, or `UIKit` in the production app target. No `Date.now` or random `UUID()` in production source (only standard default-parameter values in Model `init`). No `NSCameraUsageDescription` change, no entitlements, no `project.pbxproj` edit (filesystem-synchronized groups). Mock fixtures use deterministic UUIDs and fixed `Date` only.

### New integration smoke test
**New file:** `SimCamCardUITests/Week2IntegrationUITests.swift` — 1 case:
`testWeek2NavigationSkeletonPreservesHolderState()` — launches populated fixture → verifies Holder → taps card-001 row → verifies Detail root + name/company visible → system Back → verifies card-001 row still exists → taps scan-entry → verifies Scanner root → taps scan-close → verifies return to Holder → verifies card-001 row still exists (full round trip: Holder → Detail → Holder → Scanner → Holder). Takes a validation screenshot attachment.

No OCR, Save, Camera, Search, Groups, or persistence is exercised. The test proves the three Increments 3–6 compose into one stable navigation graph and that holder state is preserved.

### Verification (iPhone 18 Pro / iOS 27.0 Simulator, explicit UDID, -parallel-testing-enabled NO)

1. **Standalone build:** `** BUILD SUCCEEDED **`
2. **Unit tests:** `Test run with 39 tests in 6 suites passed` — 39/39 PASS (unchanged; no new business logic).
3. **Full UI regression — one clean PASS round, 7/7:**
   | Test Case | Suite | Result | Duration |
   |---|---|---|---|
   | testEmptyCardHolderOnFirstLaunch | CardHolderEmptyUITests | PASS | 6.2s |
   | testPopulatedCardHolderShowsMockCardsByMembership | CardHolderPopulatedUITests | PASS | 6.4s |
   | testCardDetailShowsFullFixtureFields | CardDetailUITests | PASS | 11.8s |
   | testCardDetailMinimalCardDoesNotFabricateFields | CardDetailUITests | PASS | 11.1s |
   | testEnterScannerShowsStaticShell | ScanEntryUITests | PASS | 11.1s |
   | testCloseReturnsToCardHolderWithStateUnchanged | ScanEntryUITests | PASS | 11.9s |
   | testWeek2NavigationSkeletonPreservesHolderState | Week2IntegrationUITests | PASS | 18.9s |
   No infrastructure failures (no boot timeout, no clone failure, no launchd_sim crash).

### Git diff audit
- **Production source changes: 0** — `git diff --name-only` is empty for all `SimCamCard/` production files.
- **New files (2):** `SimCamCardUITests/Week2IntegrationUITests.swift`, `ai/validation/2026-09-29-week2-integration.png`.
- **Modified files (1):** `ai/changes.md` (this record).
- No integration defects, no frozen-contract violations, no regressions detected.

### Reference validation review

**Page/reference validation** (used to compare implemented structural elements against frozen REF evidence):
- `ai/validation/2026-09-29-increment3-empty-holder.png` ↔ `REF-card-holder-01-empty.png`
- `ai/validation/2026-09-29-increment4-populated-holder.png` ↔ `REF-card-holder-02-after-save.png`
- `ai/validation/2026-09-29-increment5-card-detail-001-full.png` ↔ `REF-detail-01-collapsed.png` / `REF-detail-03-after-edit-expanded.png`
- `ai/validation/2026-09-29-increment5-card-detail-004-minimal.png` ↔ T20 negative case
- `ai/validation/2026-09-29-increment6-scan-entry.png` ↔ `REF-scanner-01-initial.png`

Implemented structural elements are consistent with frozen evidence; recorded visual/deferred gaps remain. Overall Reference UI fidelity: **PARTIAL** — by design for a Week 2 skeleton. No pixel polishing, no production UI redesign.

**Week 2 integration screenshot** (integration/navigation-state evidence only, NOT used as Reference UI fidelity evidence):
- `ai/validation/2026-09-29-week2-integration.png` — proves `Holder → Detail → Holder → Scanner → Holder` round trip preserves populated holder state. Not compared against any frozen REF screenshot.

### Final acceptance matrix

**Implemented / verified:**
- Domain Model (BusinessCard, PhoneNumber, CardTag, CardNote)
- Repository abstraction (protocol + InMemory actor)
- S01 `empty`: PASS
- S01 `populated`: PASS
- S01 `searching`: NOT IMPLEMENTED
- S01 `groupFiltered`: NOT IMPLEMENTED
- Deterministic fixtures (3 cards: full / missing-website / minimal)
- Card Detail navigation (stable-id, no index, no second lookup)
- Card Detail read-only rendering (T13 read-only detail field visibility/navigation: PASS)
- T12→T13 saved-card end-to-end workflow: NOT IMPLEMENTED
- Multi-value presentation (phones[]/emails[] all visible)
- T09 supporting missing-field / no-fabrication semantics: VERIFIED with deterministic fixture
- T09 real recognition/OCR workflow: NOT IMPLEMENTED
- T10 supporting multi-phone Domain/rendering semantics: VERIFIED with deterministic fixture
- T10 real recognition/classification workflow: NOT IMPLEMENTED
- T20 minimal-card no-fabrication supporting behavior: VERIFIED
- T20 full exception-handling workflow: NOT IMPLEMENTED
- Scanner entry navigation (T02 scan-entry navigation / scanner-shell behavior: PASS)
- Scanner static shell (S02 entry/preview-shell PASS, detection/capture/permission NOT IMPLEMENTED)
- Back navigation (Detail Back + Scanner ✕ both PASS)
- SwiftUI Previews compile

**Partial:**
- Card Holder Reference UI fidelity (dark header card, avatar, search, group — P01 in-scope visual gaps, behavior deferred)
- P07 Detail Reference UI fidelity (header/avatar/card image, action buttons, group/notes rows, more menu, bottom bar, expand/collapse — P07 in-scope visual gaps, behavior deferred)
- S06 detailCollapsed / detailExpanded (PARTIAL / PARTIAL scaffold; expand/collapse NOT IMPLEMENTED)
- S02 preview (visual shell only, no live camera)
- S02 cardNotDetected visual presentation (static guidance shown, no dynamic detection state/transition)
- Scanner Reference UI fidelity (batch badge omitted, static chrome non-interactive)

**Not implemented / future increments (full workflows):**
- T03 Camera Permission, T04 Capture, T05 Photo Import, T06 Boundary Detection
- T07 OCR Raw Text, T08 Structured Extraction
- T11 Manual Correction, T12 Save, T12→T13 saved-card end-to-end
- T14 Edit, T15 Search, T16 Group, T17 Delete, T18 Persistence, T19 Export
- Full T20 exception-handling workflow

### Page / State / Test traceability summary

| Item | Behavior | Reference fidelity |
|---|---|---|
| T01 Empty Holder | PASS | PARTIAL |
| T02 Scanner entry | PASS (navigation + shell) | NOT IMPLEMENTED (full camera) |
| T13 Card Detail | PASS (read-only detail field visibility/navigation) | PARTIAL |
| T12→T13 saved-card e2e | NOT IMPLEMENTED | — |
| T09 supporting semantics | VERIFIED with deterministic fixture (missing-field / no-fabrication) | — |
| T09 real OCR workflow | NOT IMPLEMENTED | — |
| T10 supporting semantics | VERIFIED with deterministic fixture (multi-phone Domain/rendering) | — |
| T10 real classification workflow | NOT IMPLEMENTED | — |
| T20 supporting behavior | VERIFIED (minimal-card no-fabrication) | — |
| T20 full exception workflow | NOT IMPLEMENTED | — |
| S01 `empty` | PASS | PARTIAL |
| S01 `populated` | PASS | PARTIAL |
| S01 `searching` | NOT IMPLEMENTED | — |
| S01 `groupFiltered` | NOT IMPLEMENTED | — |
| S02 Scanner | PASS (shell) / PARTIAL (preview, cardNotDetected visual) / NOT IMPLEMENTED (permission, detection, capture, cancelled state machine) |
| S06 Detail | PARTIAL (collapsed/expanded) / NOT IMPLEMENTED (expand/collapse interaction) |

All six prior increments remain Accepted.

### Week 2 readiness conclusion

All readiness criteria met:
- Build clean ✓
- Unit clean (39/39) ✓
- All UI regression clean (7/7 one-round PASS) ✓
- Integration smoke clean ✓
- Production source 0 changes ✓
- No boundary violation ✓
- No dead speculative scaffold ✓
- Traceability accurate (S01 state-by-state, T09/T10/T20 supporting-vs-full-workflow, validation screenshot classification) ✓
- Working tree: no unrelated/untracked files remain (local-only plan file moved out of repository) ✓
- All six prior increments remain Accepted ✓

Documented PARTIAL / future-state gaps are all Week 3+ scope items; none represent a Week 2 contract violation.

**Week 2 skeleton readiness: READY FOR HUMAN MERGE/TAG DECISION with documented deferred gaps.**

### Human Decision
Accepted — 2026-09-30 (human review).

Final conclusions (unchanged on acceptance):
- Build: PASS
- Unit tests: 39/39 PASS
- Full UI regression: 7/7 clean PASS
- Integration smoke test: PASS
- Production source changes: 0
- Architecture / dependency / boundary / dead-code audits: PASS
- S01 `empty` / `populated`: PASS
- S01 `searching` / `groupFiltered`: NOT IMPLEMENTED
- T09 / T10 supporting semantics: VERIFIED with deterministic fixture; real OCR / classification workflows: NOT IMPLEMENTED
- T20 minimal no-fabrication supporting behavior: VERIFIED; full exception-handling workflow: NOT IMPLEMENTED
- T02 scan-entry navigation / scanner-shell behavior: PASS
- T13 read-only detail field visibility / navigation: PASS
- T12→T13 real saved-card end-to-end workflow: NOT IMPLEMENTED
- Reference UI fidelity: PARTIAL
- Week 2 skeleton readiness: READY FOR HUMAN MERGE/TAG DECISION with documented deferred gaps

## 2026-09-30 — Week 3 Increment 1: Camera Permission + Real Live Preview

### Task

T03 Camera Permission + S02 live preview state machine: Card Holder → Scanner → check/request camera permission → authorized shows the real `AVCaptureVideoPreviewLayer` live preview; denied/restricted stays on a stable minimal fallback (no crash, no session); Back stops the camera session. Shutter / 相册 remain visual-only (T04/T05 deferred).

Frozen scope:
- `spec/page-inventory.md` P02 Scanner (Camera preview and card detection; exits: Capture, Photo Import, Back)
- `spec/state-inventory.md` S02: `permissionUnknown` / `permissionDenied` / `preview`
- `spec/reference-tests.md` T02 Enter Scanner, T03 Camera Permission ("Allow/deny must produce defined states; denial path must not crash.")
- Evidence: `REF-scanner-01-initial.png` (scanner chrome), `REF-permission-01-camera.png` (the NATIVE system permission dialog — owned/presented by iOS, never replicated), `REF-scanner-02-card-detected.png` (later-state boundary reference only — detection NOT built)

Baseline: branch `week3/camera-ocr` @ `2cdcea9` (merge 完成Week 2软件骨架), tag `week2-skeleton-baseline`. Xcode 27 / Swift 6.0 language mode / iOS 27.0 target / `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` / `SWIFT_APPROACHABLE_CONCURRENCY = YES` / `GENERATE_INFOPLIST_FILE = YES`.

### Constraints

- No `AVCapturePhotoOutput`, metadata/rectangle/QR output, Vision/OCR, `PhotosPicker`/Photos, SwiftData, audio input — no microphone permission is ever requested.
- Native system permission dialog only; the app never builds a custom pre-permission dialog.
- No `@unchecked Sendable` / `nonisolated(unsafe)` suppression; single (MainActor) session execution context.
- No Domain Model / Repository / frozen spec / MockBusinessCards changes.
- Mock/fake camera dependencies are DEBUG-only; normal launch and Release builds always use real AVFoundation.
- Accessibility IDs preserved: `scan-entry`, `scan-entry-view`, `scan-close`, `scan-capture`, `scan-photo-import`; new IDs: `scan-camera-preview`, `scan-permission-denied`, `scan-camera-unavailable`.
- Verification split is explicit: state/orchestration = automated PASS; native permission dialog + real-device live frames = NOT INDEPENDENTLY VERIFIED (never claimed as PASS).
- Plan file kept out of the repository working tree; no commit/merge/tag by AI.

### AI Changes

Build settings:
- `SimCamCard.xcodeproj/project.pbxproj` — added `INFOPLIST_KEY_NSCameraUsageDescription = "需要访问相机以扫描和识别名片。";` to the SimCamCard app target Debug and Release configurations only (exactly 2 added lines; verified in the built Release `Info.plist`). No manual Info.plist file is introduced (build-generated plist remains in use). Test targets untouched.

New production source:
- `SimCamCard/Camera/CameraAuthorizationProviding.swift` — `CameraAuthorizationStatus` (`notDetermined / authorized / denied / restricted`, `Sendable, Equatable`) and `@MainActor protocol CameraAuthorizationProviding` (`videoAuthorizationStatus()`, `requestVideoAccess() async -> Bool`).
- `SimCamCard/Camera/AVCameraAuthorizationProvider.swift` — production adapter mapping `AVCaptureDevice.authorizationStatus(for: .video)` and requesting via `AVCaptureDevice.requestAccess(for: .video)`; `@unknown default` conservatively maps to `.denied`. Owns no UI state.
- `SimCamCard/Camera/CameraSessionController.swift` — `CameraSessionError { noVideoDevice, cannotAddVideoInput }`, `@MainActor protocol CameraSessionControlling` and `CameraSessionController`: one rear wide-angle video input on one `AVCaptureSession`; configure-once / start-many / stop-many with idempotency guards; `canAddInput` checked; no photo/metadata/audio outputs.
- `SimCamCard/View/Scan/CameraPreviewView.swift` — `UIViewRepresentable` presentation adapter over `AVCaptureVideoPreviewLayer` (`videoGravity = .resizeAspectFill`, black background). Presentation only: never owns/starts/stops the session and never requests permission.
- `SimCamCard/ViewModel/ScanViewModel.swift` — `@MainActor @Observable final class`, `State { permissionUnknown, permissionDenied, preview, cameraUnavailable(CameraSessionError) }`; exposes the session for the preview layer; lifecycle `scannerDidAppear() async` / `scannerDidDisappear()`.

Modified production source:
- `SimCamCard/View/Scan/ScanEntryView.swift` — Week 2 static shell upgraded: body switches on `viewModel.state`. `permissionUnknown` and `preview` render the same Week 2 evidence-driven chrome (aiming frame + 「请将镜头靠近名片」 tip + mode tabs + control bar); `CameraPreviewView` (id `scan-camera-preview`) is inserted into the viewport only in `.preview`. `permissionDenied` → minimal functional fallback (id `scan-permission-denied`, camera.slash / 无法访问相机 / 系统设置指引, no shutter/album/capture-mode controls); `cameraUnavailable` → id `scan-camera-unavailable`. `.task { await viewModel.scannerDidAppear() }` / `.onDisappear { viewModel.scannerDidDisappear() }`. DEBUG `#Preview` blocks for authorized/denied. All Week 2 chrome and accessibility IDs preserved (root `scan-entry-view` remains on the childless background sibling to avoid SwiftUI identifier propagation onto child controls).

DEBUG-only fixtures (compiled into the app target under `#if DEBUG`; absent from Release):
- `SimCamCard/Camera/Debug/DebugCameraFakes.swift` — `DebugCameraAuthorizationProvider` (with `requestCount`), `DebugCameraSessionController` (counts, injectable `configureError`, never calls `startRunning()`), `DebugCameraEnvironment` parsing `-SimCamCardCamera <mode>` (`authorized / denied / restricted / notDeterminedGranted / notDeterminedDenied`), and `ScanViewModel.configuredForDebugLaunch()` (fixture VM when the argument is present, otherwise the real production VM — a bare DEBUG launch without the argument uses real AVFoundation).

Tests:
- `SimCamCardTests/ViewModel/ScanViewModelTests.swift` — Swift Testing, 9 tests with test-local fakes: fresh state = `permissionUnknown`; notDetermined+grant → preview with exactly 1 request + configure/start; notDetermined+deny → `permissionDenied`, zero session calls; authorized → preview with zero requests; denied → no re-prompt, no session; restricted → same; disappear → stop once; re-entry → configure once, start twice, stop once (no duplicate inputs); configure failure with granted permission → `.cameraUnavailable(.noVideoDevice)` and no start.
- `SimCamCardUITests/ScanCameraUITests.swift` — 4 fixture-driven UI cases: authorized (preview container + Week 2 overlays + visual shutter remains non-navigating + close returns), denied (fallback exists, no preview/shutter/album, no crash, close returns), notDeterminedGranted (request path → preview), notDeterminedDenied (request path → fallback).
- `SimCamCardUITests/ScanEntryUITests.swift` — Week 6 scanner regression helper now launches with `["-SimCamCardCamera", "authorized"]` so no native dialog is involved; existing chrome/back/no-side-effect assertions retained; adds a `scan-camera-preview` existence assertion.
- `SimCamCardUITests/Week2IntegrationUITests.swift` — populated-holder integration launch arguments extended with `["-SimCamCardCamera", "authorized"]` for the Scanner leg; all existing assertions unchanged.

Validation evidence (fixture-driven UI state, NOT frozen REF, NOT a real camera feed):
- `ai/validation/2026-09-30-increment1-camera-preview-authorized-fixture.png`
- `ai/validation/2026-09-30-increment1-camera-permission-denied-fixture.png`

### Design decisions

- **Permission state machine** (all transitions driven from `scannerDidAppear()`):

  | AVAuthorizationStatus | Behavior | Resulting state |
  |---|---|---|
  | `.notDetermined` | set `permissionUnknown`, call `requestAccess(for: .video)` once (iOS presents the native dialog) | granted → `preview`; denied → `permissionDenied` |
  | `.authorized` | start preview, NO request | `preview` |
  | `.denied` | stable fallback, never re-prompt | `permissionDenied` |
  | `.restricted` | same as denied (restricted ≠ authorized) | `permissionDenied` |
  | `@unknown default` | conservative deny mapping | `permissionDenied` |

- **Infrastructure failure is a distinct state.** Permission can be granted while the hardware cannot produce a preview (e.g. simulator, missing rear camera, input conflict). Such failures are `.cameraUnavailable(CameraSessionError)`, never disguised as `permissionDenied`.
- **Denied UI = minimal functional fallback**, not a large "去设置" page and not a custom dialog: the frozen evidence (`REF-permission-01-camera.png`) documents only the native macOS/iOS permission dialog; Reference fidelity for an in-app denied page is not established. The fallback keeps the page stable, explains the path via system Settings, and the top-bar ✕ remains the real Back.
- **Overlays are state-independent.** The aiming frame and guidance tip render identically over the pre-permission shell and the live feed; no fake camera image is ever shown.
- **Session lifecycle**: configure once (reused across Scanner re-entry, so no duplicate inputs), start on entry, stop on disappear; all three operations are idempotent and guarded by configuration/running flags.
- **Concurrency ownership**: `ScanViewModel`, both protocols, the production controller and all fakes are `@MainActor`; the `AVCaptureSession`, its input and the `AVCaptureVideoPreviewLayer` never leave the MainActor, so no non-Sendable reference crosses an isolation boundary and no suppression annotations exist. Accepted trade-off (documented): `startRunning()` / `stopRunning()` are synchronous AV calls and block the main executor briefly; if profiling later shows a meaningful hitch, a dedicated session queue can be introduced in a later increment.
- **Testability seam**: production code depends on the two protocols; unit tests inject local fakes, UI tests inject DEBUG launch-argument fakes. No test-only hooks exist in Release.

### Verification

- Debug standalone build (iOS Simulator iPhone 18 Pro): **BUILD SUCCEEDED**, zero errors/warnings of isolation relevance.
- Release standalone build: **BUILD SUCCEEDED** — verifies the `#if DEBUG` DI composition compiles out and Release uses the real `ScanViewModel()`; built `Info.plist` confirmed to contain `NSCameraUsageDescription = 需要访问相机以扫描和识别名片。`.
- Unit tests (Swift Testing, simulator UDID `5B32D815-5F37-4EE0-825C-85DE864E0B02`, `-parallel-testing-enabled NO`): **48/48 PASS** (39 Week 2 + 9 new ScanViewModel tests; 0.066 s).
- UI regression, one clean round: **13/13 PASS** (11 business cases + 2 template tests) — Holder empty/populated (2), Detail full/minimal (2), ScanEntry shell/close (2), Week2 integration (1), new camera states (4), template launch tests (2).
- Boundary audit vs `2cdcea9`: changed tracked files limited to `project.pbxproj` (2 added NSCameraUsageDescription lines only), `ScanEntryView.swift`, and the two adapted UI test files; zero changes under `SimCamCard/Model/`, `SimCamCard/Repository/`, `spec/`, `dataset/`, MockBusinessCards. Grep for `PhotoOutput|Vision|VNImage|PhotosUI|PHPhotoLibrary|SwiftData|MovieFileOutput|AVAudioSession|metadataOutput|@unchecked Sendable|nonisolated(unsafe)` in app source: comment-only matches documenting exclusion, zero usages.

Verification level (honest split):
- T03 permission STATE/ORCHESTRATION (allow/deny/restricted/no-reprompt defined states, denial does not crash): **PASS** (9 unit + 4 fixture UI tests).
- S02 `permissionUnknown` / `permissionDenied` / `preview` UI states: **PASS (fixture-driven UI)**.
- Preview layer wiring (`AVCaptureVideoPreviewLayer` + real session configuration path): implementation complete, compiles Debug+Release; **real live camera frames on a physical device: NOT INDEPENDENTLY VERIFIED** (simulator has no camera; fixture sessions intentionally never start hardware).
- Native iOS permission dialog presentation/result: implementation uses the standard `AVCaptureDevice.requestAccess` path with the usage string present; **native dialog interaction on device: NOT INDEPENDENTLY VERIFIED** (not automatable; fixtures deliberately bypass it).
- `cameraUnavailable` state: unit-tested via injected error; no standalone UI test (the simulator real-hardware path is nondeterministic).

### Regression

- Week 2 suite fully green (unit 39 prior tests unchanged; all 7 Week 2 business UI cases pass under the authorized camera fixture).
- Scanner visual shell is pixel-comparable to Week 2 in the fixture screenshot: same top bar/mode selector/aiming frame/tip/tabs/shutter/album; root and control accessibility IDs unchanged.
- Card Holder / Detail flows and the populated-fixture repository remain untouched (boundary audit confirms zero Model/Repository changes).
- T04 shutter / T05 相册 remain visual-only: tapping the shutter in the authorized fixture keeps the user on the Scanner; no output/picker is added.

### S02 / T03 traceability update

| Item | This increment status |
|---|---|
| T03 Camera Permission — state machine / no crash on denial | PASS (automated) |
| T03 native system dialog (device) | NOT INDEPENDENTLY VERIFIED |
| S02 `permissionUnknown` | IMPLEMENTED (shell shown while request is pending) |
| S02 `permissionDenied` | IMPLEMENTED (minimal functional fallback; denied + restricted; Reference fidelity not established) |
| S02 `preview` | IMPLEMENTED; real live frames on device PENDING verification |
| S02 `cardNotDetected` visual | remains PARTIAL (static guidance only; dynamic detection NOT IMPLEMENTED — T06 scope) |
| S02 `cardDetected` / `captured` | NOT IMPLEMENTED (T04/T06 scope) |
| S02 `cancelled` | NOT MODELED in the frozen state inventory; Back stops the session and pops (behavior exists, no state value) |
| T04 Capture / T05 Photo Import | NOT IMPLEMENTED (visual controls only) |

### Human Decision

Accepted — 2026-10-01 (human review). Acceptance is recorded with final conclusions in the correction-2 entry below. Plan file was moved out of the repository working tree (`ai/Week 3 IncrementCamera Permission + Live Preview` → `/tmp/w3i1-plan.md`) and is not part of the change set.

## 2026-09-30 — Week 3 Increment 1 correction: Camera session concurrency (SUPERSEDES MainActor-owned session design)

### Task

Architecture correction before Accept: the original Increment 1 implementation isolated the entire `AVCaptureSession` lifecycle (creation / configure / start / stop) on the MainActor. This is superseded because Apple AVFoundation guidance states configuration is expensive and `startRunning()` / `stopRunning()` are blocking calls that must not execute on the main thread. This is a production camera-foundation fix, not a profiling-deferred optimization.

### What was superseded

- Original: `@MainActor final class CameraSessionController` owning `AVCaptureSession`; synchronous `configure()` / `start()` / `stop()` executed on the main thread; documented as an "accepted trade-off".
- Corrected: camera session lifecycle moved OFF the MainActor entirely.

### Corrected architecture

- **Ownership**: `CameraSessionController` is now an `actor` (in `SimCamCard/Camera/CameraSessionController.swift`). It owns the `AVCaptureSession`, the `isConfigured` flag and the full ordering contract.
- **Executor/queue**: the actor runs on a dedicated serial executor — `DispatchSerialQueue(label: "com.metahumanz.SimCamCard.camera.session")` exposed via `nonisolated var unownedExecutor`. ALL of `beginConfiguration` / `commitConfiguration` / input mutation / `startRunning` / `stopRunning` execute strictly serialized on that one non-main serial context; `startRunning` can never run concurrently with configuration.
- **Async API**: `configureIfNeeded() async throws`, `start() async throws`, `stop() async` (protocol `nonisolated protocol CameraSessionControlling: Sendable` — explicitly `nonisolated` because `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would otherwise force the protocol onto the MainActor and block actor conformance). `ScanViewModel` (still `@MainActor @Observable`, still owns permissionUnknown/permissionDenied/preview/cameraUnavailable and the mapping to UI state) now `await`s these calls; `.onDisappear` hops to the service via `Task { await viewModel.scannerDidDisappear() }`.
- **Ordering contract preserved**: configure once (a failed configure leaves the session unconfigured so a later entry may retry), start many, stop many; all idempotent.
- **Preview isolation boundary**: `CameraPreviewView` remains a pure presentation adapter (no configure/start/stop in the UIViewRepresentable). Current SDK exposes AVCaptureSession as non-Sendable for this Swift 6 build, so `@preconcurrency import AVFoundation` is used as a narrow compatibility/interoperability bridge for the preview-session reference. Concurrency safety therefore relies on the explicit ownership contract: all AVCaptureSession mutation/configure/start/stop occurs on CameraSessionController's dedicated serial actor executor; MainActor/UI only attaches the session to AVCaptureVideoPreviewLayer for presentation; UI code does not mutate session topology/lifecycle. `@preconcurrency` only relaxes compile-time diagnostics — it does NOT itself guarantee thread safety. There is NO `@unchecked Sendable`, NO `nonisolated(unsafe)`, NO `Task.detached`. The session instance is created inline (`nonisolated let session = AVCaptureSession()` — instantiating an empty session is cheap; the expensive lifecycle runs on the serial queue), and only the actor ever mutates it.
- **DEBUG fakes**: `DebugCameraSessionController` is now an actor mirroring the same serialized contract (configure-once / start-many / stop-many counters, error injection via init). The permission provider stays `@MainActor` (no blocking capture-session work).

### Verification (all rerun — prior round's results NOT carried over)

- Debug build (iOS Simulator iPhone 18 Pro): **BUILD SUCCEEDED** (three compile iterations fixed: protocol `nonisolated`, inline `nonisolated let session`, `@preconcurrency` bridge).
- Release build: **BUILD SUCCEEDED** (DEBUG DI composition still compiles out; production path uses the actor service).
- Unit tests: **50/50 PASS** (48 prior + 2 new serialization-contract tests). All 9 original behavior contracts still hold (notDetermined→grant / notDetermined→deny / authorized / denied / restricted / configure-failure→cameraUnavailable / disappear→stop / re-enter→configure-once+start-many). New tests prove the orchestration API serialization/idempotency via counters (16 concurrent `configureIfNeeded` calls → configureCount == 1; three appear/disappear cycles → configure 1 / start 3 / stop 3) — no wall-clock timing, no thread identity.
- UI regression, one clean round: **13/13 PASS** (unchanged case set; the `-SimCamCardCamera` fixture path now drives the actor-based service).
- Boundary audit: grep for `Task.detached` / `nonisolated(unsafe)` / `@unchecked` in app+test source: comment-only matches (documenting exclusion), zero usages. Zero changes under Model/Repository/spec/dataset/MockBusinessCards.

### Traceability calibration (supersedes the coarser wording in the Increment 1 entry above)

- T03 permission state-machine / deny-no-crash automated verification: **PASS**
- T03 native system permission dialog allow/deny: **NOT INDEPENDENTLY VERIFIED**
- S02 `permissionUnknown` orchestration/UI: **PASS**
- S02 `permissionDenied` orchestration/UI: **PASS**
- S02 `preview` state + preview-layer wiring: **PASS**
- S02 real live-preview runtime verification: **PENDING physical-device verification**
- S02 `preview` overall verification: **PARTIAL pending real-device frames**
- S02 `cardNotDetected` visual: remains PARTIAL (static guidance only; dynamic NOT IMPLEMENTED — T06 scope)
- S02 `cardDetected` / `captured`: NOT IMPLEMENTED (T04/T06 scope); `cancelled`: NOT MODELED (Back behavior exists, no state value)
- T04 Capture / T05 Photo Import / T06 Detection / Crop / OCR / extraction: NOT IMPLEMENTED

### Human Decision

Accepted — 2026-10-01 (human review). Final conclusions recorded in the correction-2 entry below.

## 2026-10-01 — Week 3 Increment 1 correction 2: initial camera-session start failure contract + @preconcurrency wording calibration

### Task

1. Close the initial camera-session start failure gap: `AVCaptureSession.startRunning()` does NOT report an initial start failure via Swift `throw`. The prior implementation called `startRunning()` and unconditionally set state to `.preview` — a failed initial start would have been misreported as preview. Contract required: configure success → start requested → session actually starts → preview; configure success → initial start failure → cameraUnavailable, NOT preview.
2. Calibrate `@preconcurrency` wording in code comments and this file (removes unverifiable "Apple-sanctioned / AVCam-sample" claims).

### Changes

- `SimCamCard/Camera/CameraSessionController.swift`
  - New error case `CameraSessionError.startFailed`.
  - Protocol + actor: `start() async` → `start() async throws`. Implemented contract (exact scope):
    1. configuration succeeds (`configureIfNeeded()`);
    2. `startRunning()` is invoked on the dedicated serial camera executor;
    3. when the initial start attempt returns but `session.isRunning == false`, `start()` throws `CameraSessionError.startFailed`;
    4. `ScanViewModel.beginPreview()` maps this to `.cameraUnavailable(.startFailed)`;
    5. the state must not become `.preview`.
  - Explicitly NOT IMPLEMENTED (deferred robustness, NOT part of this increment's completion scope): post-start `AVCaptureSessionRuntimeErrorNotification` handling, interruption handling, automatic recovery/retry, media-services-reset recovery. The contract above covers the INITIAL start attempt only.
- `SimCamCard/ViewModel/ScanViewModel.swift` — `beginPreview()` now `try await sessionController.start()`; a thrown initial start failure maps to `.cameraUnavailable(.startFailed)`, never `.preview`.
- `SimCamCard/Camera/Debug/DebugCameraFakes.swift` — fake `start()` signature updated to `async throws` (never throws in UI fixtures).
- `SimCamCardTests/ViewModel/ScanViewModelTests.swift` — FakeSession gains deterministic `startError` injection; new test: authorized → configure succeeds → initial start fails (`.startFailed`) → state == `.cameraUnavailable(.startFailed)` AND state != `.preview`, with configureCount == 1 / startCount == 1. No real hardware involved.
- Wording calibration (code comments in `CameraSessionController.swift` / `CameraPreviewView.swift` and the correction-1 entry above): `@preconcurrency import AVFoundation` is described accurately as a narrow compatibility/interoperability bridge for the display-only preview-session reference that relaxes COMPILE-TIME diagnostics only; safety derives from the explicit ownership contract (all mutation on the actor's serial executor; UI only attaches the session to the preview layer). No `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached`.

### Verification (full rerun — production lifecycle was modified)

- Debug build: **BUILD SUCCEEDED**
- Release build: **BUILD SUCCEEDED**
- Unit tests: **51/51 PASS** (50 prior + 1 new initial-start-failure contract test)
- UI regression, one clean round: **13/13 PASS** (count unchanged per instruction; internal failure contract needs no new UI case)
- Boundary audit unchanged: no banned constructs, no Model/Repository/spec/dataset changes, no PhotoOutput/Photos/Vision/OCR.

### Traceability (unchanged + one addition)

- T03 permission state-machine / denial no-crash automated verification: PASS
- T03 native permission-dialog allow/deny: NOT INDEPENDENTLY VERIFIED
- S02 `permissionUnknown` orchestration/UI: PASS
- S02 `permissionDenied` orchestration/UI: PASS
- S02 `preview` state + preview-layer wiring: PASS
- S02 real live-preview runtime verification: PENDING physical-device verification
- S02 `preview` overall verification: PARTIAL
- Initial camera-session start failure → cameraUnavailable: **PASS (automated)**
- Post-start AVCaptureSession runtime-error notification handling / interruption handling / automatic recovery: **NOT IMPLEMENTED — deferred robustness work** (not part of this increment's completion scope)
- Debug build: PASS; Release build: PASS; Unit tests: 51/51 PASS; UI regression: 13/13 PASS
- No `@unchecked Sendable`; no `nonisolated(unsafe)`; no `Task.detached`
- T04/T05/T06/OCR/extraction: NOT IMPLEMENTED

### Human Decision

**Accepted — 2026-10-01 (human review).** Week 3 Increment 1 (Camera Permission + Real Live Preview) final conclusions, unchanged at acceptance:

- Camera permission abstraction: PASS
- ScanViewModel state ownership (@MainActor): PASS
- Dedicated serial CameraSessionController actor executor (DispatchSerialQueue custom executor): PASS
- MainActor blocking lifecycle issue: FIXED (session lifecycle runs off the main thread on the actor's serial executor)
- Initial camera-session start failure → cameraUnavailable (never preview): PASS (automated)
- S02 `permissionUnknown` orchestration/UI: PASS
- S02 `permissionDenied` orchestration/UI: PASS
- S02 `preview` state + preview-layer wiring: PASS
- S02 real live-preview runtime verification: PENDING physical-device verification
- S02 `preview` overall verification: PARTIAL
- T03 automated permission state-machine / denial no-crash: PASS
- Native system permission dialog allow/deny: NOT INDEPENDENTLY VERIFIED
- Post-start runtime-error notification handling / interruption handling / automatic recovery: NOT IMPLEMENTED — deferred robustness work
- Debug build: PASS; Release build: PASS
- Unit tests: 51/51 PASS; UI regression: 13/13 PASS
- T04/T05/T06/OCR/extraction: NOT IMPLEMENTED
- No `@unchecked Sendable`; no `nonisolated(unsafe)`; no `Task.detached`

AI did not commit, merge or tag. Increment 2 not entered.

## 2026-10-01 — Week 3 Increment 2: Still Capture (T04 mechanics)

### Task

T04 still-photo capture mechanics: Scanner preview → tap shutter → AVCapturePhotoOutput captures one real still → stable captured-photo value → S02 `captured` state. Baseline: branch `week3/camera-ocr` @ `eeefbbe` (Increment 1 accepted). Explicitly out of scope: Card Detection, Crop, OCR, Recognition/Edit, BusinessCard creation, Repository save, PhotosPicker.

### Files

New (filesystem-synchronized groups; no pbxproj change):
- `SimCamCard/Camera/CapturedPhoto.swift` — camera-pipeline transport value (`nonisolated struct`, `Sendable, Equatable`): raw `data: Data` (AVCapturePhoto.fileDataRepresentation bytes, EXIF orientation metadata preserved — never stripped) + `capturedAt: Date`. NOT a Domain Model; no OCR text/rectangle/structured fields/BusinessCard id/tags/notes.
- `SimCamCard/Camera/PhotoCaptureProcessor.swift` — one-shot `AVCapturePhotoCaptureDelegate` bridge; `nonisolated final class` (only state is the immutable continuation let). Converts `AVCapturePhoto` → `Data` INSIDE the delegate callback; `AVCapturePhoto` never crosses any actor/Sendable boundary and is never claimed Sendable.
- `ai/validation/2026-10-01-increment2-captured-photo-fixture.png` — fixture-driven captured-state presentation evidence. NOT physical camera capture proof.

Modified:
- `SimCamCard/Camera/CameraSessionController.swift` — `configureIfNeeded()` now also adds ONE `AVCapturePhotoOutput` inside the same begin/commitConfiguration transaction (input once + output once + configure once; re-entry never re-adds). `canAddOutput == false` → new `CameraSessionError.cannotAddPhotoOutput` (infrastructure, never disguised as permissionDenied). New `capturePhoto() async throws -> CapturedPhoto`: guards configured+running and single in-flight (atomic check-and-set on the serial executor), minimal `AVCapturePhotoSettings()` defaults (no flash UI/burst/bracket/RAW/Live Photo/depth/portrait/metadata output), processor strongly held in `inFlightCapture` for the whole capture and cleared via `defer` on both paths. New errors `captureFailed` (delegate error / not running) and `emptyPhotoData` (no usable bytes).
- `SimCamCard/ViewModel/ScanViewModel.swift` — new frozen S02 state `case captured(CapturedPhoto)` (Equatable preserved); transient `isCaptureInFlight` Bool (NOT added to the frozen enum); `capture()` accepts only `.preview` and not-in-flight, otherwise ignored. Success: capture → stop session → `.captured(photo)`. Failure: no crash, never `.captured`, never permissionDenied — mapped to `.cameraUnavailable(...)` infrastructure fallback (no retry UI).
- `SimCamCard/View/Scan/ScanEntryView.swift` — shutter `scan-capture` is now the real capture action, disabled (dimmed) while in flight; new `.captured` branch renders `capturedSection`: the ACTUAL captured bytes decoded to UIImage in the View layer only (Data remains source of truth; UIImage is a transient rendering adapter, never stored/persisted), root id `scan-captured-photo`; existing top-bar ✕ is the back path. No 识别中/完成/下一步/重拍 buttons, no crop handles, no recognition fields. Reference fidelity: functional transitional UI; reference fidelity not established. 相册 `scan-photo-import` remains visual-only (T05 NOT IMPLEMENTED).
- `SimCamCard/Camera/Debug/DebugCameraFakes.swift` — DEBUG-only fake gains `capturePhoto()` returning a deterministic fixed VALID tiny PNG (4×4 green, 71 bytes) + `captureCount`. Release builds compile all fakes out (`#if DEBUG`); Release never touches the fake capture path.
- Tests: `SimCamCardTests/ViewModel/ScanViewModelTests.swift` (fake gains `captureError` injection + `captureCount`; 7 new tests); `SimCamCardUITests/ScanCameraUITests.swift` (new fixture capture test; removed obsolete "shutter is visual-only" tap assertion); `SimCamCardUITests/ScanEntryUITests.swift` (shell test updated: photo-import still visual-only no-op; shutter now verified to reach captured).

### Architecture preserved

ScanViewModel stays @MainActor UI state owner; CameraSessionController stays an actor on its dedicated `DispatchSerialQueue` custom executor; CameraPreviewView stays presentation-only. ALL session configuration / input mutation / output mutation / startRunning / stopRunning / capture-request orchestration execute on the camera actor executor. No `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached`. The `@preconcurrency import AVFoundation` compatibility bridge is retained under the same ownership contract (it relaxes compile-time diagnostics only; it does not itself guarantee thread safety).

### Orientation contract (prompt §14)

What this increment actually guarantees:

- Raw captured photo bytes/attachments preservation: **PASS** — `AVCapturePhoto.fileDataRepresentation()` returns the photo image data with AVFoundation attachments/metadata retained; `CapturedPhoto.data` preserves those returned bytes without stripping any metadata.

What this increment does NOT establish:

- Correct upright/canonical captured orientation: **NOT ESTABLISHED** in this increment.
- Physical-device orientation verification (portrait / landscape / iPad rotation): **PENDING**.
- RotationCoordinator / explicit preview+capture connection rotation (no `AVCaptureDevice.RotationCoordinator` use, no explicit rotation angle set on the AVCapturePhotoOutput video connection): **DEFERRED** — must be resolved before Detection/OCR consumes canonical image orientation.

### Verification (all rerun — production camera lifecycle modified)

- Debug standalone build: **BUILD SUCCEEDED** (one compile iteration: PhotoCaptureProcessor needed explicit `nonisolated` because SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor would otherwise pin the NSObject delegate subclass to MainActor, making it unusable from the camera actor).
- Release build: **BUILD SUCCEEDED** (DEBUG fake capture path compiled out; production capture path uses real AVFoundation).
- Unit tests: **58/58 PASS** (51 prior + 7 new): capture success (session stopped, captured(photo), in-flight cleared); capture failure → cameraUnavailable, never captured, in-flight cleared; capture ignored in permissionDenied / permissionUnknown / cameraUnavailable (captureCount == 0); double-tap single-in-flight (captureCount == 1, counter-based, no wall-clock timing); re-entry after capture (configure 1 / start 2 / stop 2). All Increment 1 contracts (configure once, start/stop many, serialization under concurrency, initial-start-failure) still pass.
- UI regression, one clean round: **14/14 PASS** (13 prior + 1 new fixture capture test). `ScanEntryUITests.testEnterScannerShowsStaticShell` was updated for the now-real shutter (first UI run caught the stale visual-only assertion; corrected and rerun green).
- Boundary audit: zero changes under SimCamCard/Model, SimCamCard/Repository, spec/, dataset/, MockBusinessCards.swift; project.pbxproj untouched; no PhotosPicker/Vision/OCR/AppRoute additions.
- Concurrency audit: no `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached` anywhere in app/tests.
- Release fake-isolation audit: DebugCameraFakes.swift wrapped in `#if DEBUG`; Release build succeeds without any fake capture path.

### Traceability

- T04 still-photo capture mechanics: **PASS (automated / fixture supported)**
- T04 physical-device still capture: **NOT INDEPENDENTLY VERIFIED**
- T04 capture → recognition workflow: **NOT IMPLEMENTED**
- T04 overall: **PARTIAL**
- S02 `permissionUnknown` orchestration/UI: PASS
- S02 `permissionDenied` orchestration/UI: PASS
- S02 `preview` state + preview-layer wiring: PASS
- S02 real live-preview runtime verification: PENDING physical-device verification
- S02 `preview` overall verification: PARTIAL
- S02 `captured` state/orchestration: **PASS**; captured fixture-driven presentation: **PASS**; physical-device captured photo: **PENDING**
- S02 `cardNotDetected` dynamic state: NOT IMPLEMENTED; `cardDetected`: NOT IMPLEMENTED (REF-scanner-02-card-detected.png is NOT evidence of implemented detection); `cancelled`: NOT MODELED
- T05 Photo Import / T06 Detection / T07 OCR / Crop / structured extraction: NOT IMPLEMENTED
- Fixture-driven capture UI: PASS; physical-device photo capture: NOT INDEPENDENTLY VERIFIED

### Correction before acceptance

1. **Capture failure releases camera session** — [ScanViewModel.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/ViewModel/ScanViewModel.swift) `capture()`: both success and failure paths now `await sessionController.stop()` before updating state, so the camera session is never left running behind the error fallback. Updated unit test assertion: `captureCount == 1 && stopCount == 1 && state == .cameraUnavailable(...) && state != .captured`.
2. **Orientation wording calibrated** — changes.md orientation section rewritten to distinguish "raw bytes/attachments preservation: PASS" from "correct upright/canonical orientation: NOT ESTABLISHED"; `RotationCoordinator` and explicit connection rotation explicitly deferred.
3. **Git working tree cleaned** — `git restore ai/prompts/week2-skeleton.md`; untracked prompt file moved to `/tmp/w3inc2-plan.md`; final `git status --short` shows only Increment 2 files plus validation screenshot.

### Human Decision

**Accepted — 2026-10-01 (human review).** Week 3 Increment 2 (Still Capture) final conclusions, unchanged at acceptance:

- T04 still-photo capture mechanics: PASS (automated / fixture)
- Capture success → stop session → captured: PASS
- Capture failure → stop session → cameraUnavailable (never captured): PASS
- Delegate lifetime (PhotoCaptureProcessor strongly held until callback resumes): PASS
- Double-capture prevention (single in-flight contract): PASS
- S02 captured state/presentation: PASS (fixture-driven)
- Physical-device still capture: NOT INDEPENDENTLY VERIFIED
- Raw captured bytes/attachments preservation: PASS
- Correct upright/canonical captured orientation: NOT ESTABLISHED
- Physical-device orientation verification: PENDING
- RotationCoordinator / explicit preview+capture connection rotation: DEFERRED — must be resolved before Detection/OCR consumes canonical image orientation
- T04 capture → recognition workflow: NOT IMPLEMENTED
- T04 overall: PARTIAL
- T05 Photo Import / T06 Detection / T07 OCR / Crop / structured extraction: NOT IMPLEMENTED
- Debug build: PASS; Release build: PASS
- Unit tests: 58/58 PASS; UI regression: 14/14 PASS

AI did not commit, merge or tag. Increment 3 not entered.

## 2026-10-01 — Week 3 Increment 3: System Photo Import (T05)

### Task
Implement T05 system photo import mechanics: Scanner → tap 相册 → system `PhotosPicker` → choose one image → convert to stable `Data` → `imageSelected` state. Extends the existing T04 single-card capture path so both camera capture and photo-library import feed the same `CapturedPhoto` transport. **NOT** implemented in this increment: Card Detection (T06), Crop (T06), OCR (T07), Recognition/Edit, Structured Extraction, Save.

### Context Provided
- `ai/prompts/TRAE - Week 3 Increment 3: Photo Import.md` (plan; NOT committed)
- Increment 2 accepted camera/capture code (`CapturedPhoto.swift`, `ScanViewModel.swift`, `ScanEntryView.swift`, `DebugCameraFakes.swift`)
- Apple PhotosUI / PHPickerViewController documentation (out-of-process picker; no `NSPhotoLibraryUsageDescription` required for selected-photo flow)
- `spec/reference-tests.md` T05 (相册 import), `spec/state-inventory.md` S03 scanner states

### Constraints
- Single-card contract: exactly one `CapturedPhoto` flows through the scanner at a time (camera capture OR photo import, never both).
- Reuse the T04 captured-image presentation for the imported image; do NOT create a separate `ImportedPhoto` type.
- Photo import must NOT require photo-library **write** or full-library **read** permission. `PhotosPicker` runs out-of-process and hands back the selected asset; the app only consumes the returned `Data`. No `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription` added; no `PHPhotoLibrary.requestAuthorization` call; `project.pbxproj` UNCHANGED.
- `ScanViewModel` stays `@MainActor @Observable`; camera `State` (S02) and new photo-import state are composed, NOT merged into one enum.
- `CameraSessionController` stays an actor on its `DispatchSerialQueue` custom executor.
- No `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached`.
- Do NOT modify: Model, Repository, spec, dataset, MockBusinessCards.swift, frozen reference evidence.
- Do NOT implement: Detection, Crop, OCR, Recognition/Edit, Structured Extraction, Save, `AppRoute.crop`, `AppRoute.recognition`.
- Do NOT commit the Week 3 plan file; do NOT restore `week2-skeleton.md`.

### AI Changes

Modified files (5 production + 3 test):

- **`SimCamCard/Camera/CapturedPhoto.swift`** — Added `nonisolated enum ImageSource: Sendable, Equatable { case camera, case photoLibrary }`. Added `source: ImageSource` property to `CapturedPhoto` with default `.camera`. Camera path uses the default; photo import sets `.photoLibrary`. Unified transport for both sources.

- **`SimCamCard/ViewModel/ScanViewModel.swift`** — 
  - Added `#if DEBUG enum PhotoImportFixtureMode: String { case imported, cancel, loadFailure = "loadfailure" }` and `typealias PhotoImportFixtureParam` (`PhotoImportFixtureMode?` in DEBUG, `Never?` in Release) at file scope.
  - Added `enum PhotoImportState: Equatable { case idle, pickerPresented, imageSelected(CapturedPhoto), importFailed }`.
  - Added `private(set) var photoImport: PhotoImportState = .idle` and `private(set) var isPickerPresented = false`.
  - Added `private let photoImportFixture: PhotoImportFixtureParam` + init param (unconditional, default nil).
  - Added `beginPhotoImport() async` — guard `state == .preview && !isPickerPresented && photoImport == .idle`; `await sessionController.stop()`; if DEBUG fixture mode → simulate result directly; else `isPickerPresented = true; photoImport = .pickerPresented`.
  - Added `handleSelectedImage(_ data: Data)` — `isPickerPresented = false; photoImport = .imageSelected(CapturedPhoto(data: data, source: .photoLibrary))`.
  - Added `handleImportCancel() async` — `isPickerPresented = false; photoImport = .idle; await restartPreview()`.
  - Added `handleImportLoadFailure()` — `isPickerPresented = false; photoImport = .importFailed`.
  - Added private `restartPreview() async` — `try await sessionController.start(); state = .preview`; failure → `.cameraUnavailable`.

- **`SimCamCard/View/Scan/ScanEntryView.swift`** — 
  - Added `import PhotosUI`.
  - Added `@State private var selectedItem: PhotosPickerItem?` and `@State private var didSelectItem = false`.
  - 相册 button now calls `Task { await viewModel.beginPhotoImport() }`.
  - Body renders `viewModel.photoImport` with priority: `.imageSelected` → `imageSection(photo, identifier: "scan-imported-photo")`; `.importFailed` → fallback id `scan-import-failed`; else fall through to camera `state`.
  - Renamed `capturedSection` → `imageSection(_:identifier:)` shared by both camera capture (`scan-captured-photo`) and import (`scan-imported-photo`).
  - Added `.photosPicker(isPresented: ..., selection: $selectedItem, matching: .images)`.
  - Added `.onChange(of: selectedItem)` → `didSelectItem = true`; async `loadTransferable(type: Data.self)` → success → `handleSelectedImage(data)`, failure/empty → `handleImportLoadFailure()`.

- **`SimCamCard/Camera/Debug/DebugCameraFakes.swift`** — Added `static let photoImportArgument = "-SimCamCardPhotoImport"`. `makeViewModelIfRequested` parses optional `-SimCamCardPhotoImport <imported|cancel|loadfailure>` via `parsePhotoImportFixture`, passes `photoImportFixture` to `ScanViewModel`. Release compiles fakes out entirely (`#if DEBUG`).

- **`SimCamCardTests/ViewModel/ScanViewModelTests.swift`** — Added 6 photo-import unit tests:
  1. `photoImportSelectionStopsSessionAndEntersImageSelected` — preview → begin → stop → handleSelectedImage → imageSelected with `source == .photoLibrary`, camera stays stopped.
  2. `photoImportCancelRestartsPreview` — cancel → idle, startCount == 2, state == .preview.
  3. `photoImportLoadFailureEntersImportFailed` — importFailed, never imageSelected.
  4. `photoImportIgnoredWhenNotPreview` — denied state ignores begin.
  5. `photoImportDoesNotPresentTwice` — duplicate guard.
  6. `photoImportSelectionKeepsCameraStopped` — select → no restart.

- **`SimCamCardUITests/ScanCameraUITests.swift`** — Added 2 photo-import fixture UI tests:
  - `testPhotoImportFixtureShowsImportedPhoto` — launch `authorized` + `imported` → tap 相册 → assert `scan-imported-photo` exists, `scan-capture` absent, no crash. Captures screenshot `w3i3-scan-imported-photo-fixture`.
  - `testPhotoImportCancelReturnsToPreview` — launch `authorized` + `cancel` → tap 相册 → assert preview returns (`scan-camera-preview` + `scan-capture`), no imported photo.
  - `launchAndEnterScanner` now accepts optional `photoImportMode` parameter.

- **`SimCamCardUITests/ScanEntryUITests.swift`** — Removed stale "photo import remains visual-only" tap/assertions (T05 now implemented; tapping 相册 presents the system picker which would interfere with the subsequent capture test). The scan-entry shell test now goes straight to the shutter capture assertion.

- **`ai/validation/2026-10-01-increment3-photo-import-fixture.png`** — NEW validation screenshot: fixture-driven imported state (NOT native picker proof).

### Design decisions

1. **Unified transport via `CapturedPhoto.ImageSource`**: Extended `CapturedPhoto` with `source: ImageSource` (default `.camera`) instead of creating a separate `ImportedPhoto` type. Camera capture and photo import both produce a `CapturedPhoto`; the `source` tag distinguishes them for Increment 4+'s Detection/Crop pipeline. The existing T04 captured-image presentation (`imageSection`) is reused for the imported image with a different accessibility identifier.

2. **Composed state, not merged enum**: `photoImport: PhotoImportState` is a separate property from `state: State` (camera). The View renders `photoImport` first (`.imageSelected` / `.importFailed` take priority), falling through to camera `state` when `photoImport == .idle` or `.pickerPresented`. This keeps S02 camera states intact and avoids a combinatorial state explosion.

3. **Camera lifecycle on import**: `beginPhotoImport()` → `sessionController.stop()` (release camera before presenting picker). Cancel → `restartPreview()` (restart camera). Selection → camera stays stopped (the imported image replaces the preview). This matches the reference behavior: picking a photo leaves the camera off.

4. **DEBUG fixture for deterministic UI regression**: `beginPhotoImport()` checks `photoImportFixture` and simulates the result directly (bypassing the real `PhotosPicker`). This enables deterministic UI tests without driving the out-of-process system picker. The fixture uses `DebugCameraSessionController.fixtureImageData` (valid PNG bytes), so the imported image presentation is real (not a placeholder).

5. **No photo-library permission**: `PhotosPicker`/`PHPickerViewController` runs out-of-process; Apple docs confirm "the user doesn't need to explicitly authorize your app to select photos." Therefore NO `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription` added, NO `PHPhotoLibrary.requestAuthorization` called, `project.pbxproj` UNCHANGED.

6. **`handleImportCancel() async`**: Made cancel async (awaits `restartPreview()` directly) so unit-test assertions on `startCount` are deterministic. The View's `Binding.set` wraps it in `Task { await viewModel.handleImportCancel() }`.

7. **`didSelectItem` guard**: The `PhotosPicker` `isPresented` binding's setter fires when the picker dismisses. A `didSelectItem` flag distinguishes "user selected an item" (don't call cancel — the `.onChange` handler already processed it) from "user cancelled" (call `handleImportCancel()`).

### Verification

- **Debug build**: BUILD SUCCEEDED.
- **Release build**: BUILD SUCCEEDED (DEBUG fakes compiled out; production `PhotosPicker` path intact).
- **Unit tests**: **64/64 PASS** (58 prior + 6 new photo-import tests; all Increment 1 & 2 contracts green).
- **UI tests**: **16/16 PASS** (14 prior + 2 new import fixture tests). `ScanEntryUITests.testEnterScannerShowsStaticShell` updated (stale visual-only photo-import assertion removed; now goes straight to shutter capture).
- **Boundary audit**: zero changes under `SimCamCard/Model`, `SimCamCard/Repository`, `spec/`, `dataset/`, `MockBusinessCards.swift`; `project.pbxproj` untouched.
- **Forbidden-API audit**: no `PHPhotoLibrary`, `Vision`, `VNDetectRectanglesRequest`, `VNRecognizeTextRequest`, `AppRoute.crop`, `AppRoute.recognition` in production code. `PhotosPicker` is allowed.
- **Concurrency audit**: no `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached` anywhere in app/tests.
- **Release fake-isolation audit**: `DebugCameraFakes.swift` wrapped in `#if DEBUG`; `PhotoImportFixtureMode` / fixture block in `ScanViewModel` guarded by `#if DEBUG`; Release build succeeds.
- **Validation screenshot**: `ai/validation/2026-10-01-increment3-photo-import-fixture.png` captured (fixture-driven imported state).

### Traceability

- T05 Photo Import mechanics (system picker → selected image → stable Data → imported state): **PASS (automated / fixture supported)**
- T05 Native system `PhotosPicker` runtime selection: **NOT INDEPENDENTLY VERIFIED** (fixture bypasses the out-of-process picker; selection→`Data` conversion uses real `loadTransferable`)
- T05 imported image presentation (reuses captured-image section): **PASS**
- T05 cancel → returns to preview: **PASS**
- T05 load-failure → importFailed fallback: **PASS**
- T05 overall: **PARTIAL** (mechanics + fixture UI pass; native picker runtime not independently verified)
- T04 still capture: unchanged, **PASS (automated / fixture)**
- T06 Detection / T07 OCR / Crop / Recognition / Structured Extraction / Save: **NOT IMPLEMENTED**

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 4 not entered.

## 2026-10-01 — Week 3 Increment 3 presentation-binding correction (pre-Accept)

### Task
Fix the real-PhotosPicker presentation race: after a selection, the system dismisses the sheet while `loadTransferable` is still running; the custom `isPresented` Binding getter still returned `isPickerPresented == true`, risking picker re-presentation / stale presentation state. DEBUG fixtures bypass the native picker, so fixture UI tests cannot cover this — the presentation transition is moved into the ViewModel as a unit-testable contract.

### 1. Selection dismissal ≠ cancel

New minimal presentation-only method in [ScanViewModel.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/ViewModel/ScanViewModel.swift):

- `photoPickerDidDismissAfterSelection()` — clears ONLY `isPickerPresented`. No camera restart, no `photoImport = .idle`, no selection-success marking, no image load.

[ScanEntryView.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/Scan/ScanEntryView.swift) Binding setter now dispatches:

```text
dismissed && didSelectItem  → photoPickerDidDismissAfterSelection()  // NOT a cancel
dismissed && !didSelectItem → handleImportCancel()                   // first-class cancel
```

### 2. Selection async loading contract

```text
selected → system dismiss → isPickerPresented = false (immediately)
         → photoImport stays .pickerPresented while Data loads
         → camera remains stopped
load success → imageSelected
load failure → importFailed
```

No camera restart on either terminal selection path.

### 3. PhotosPicker selection state reset

After a terminal selection result (success or load failure), the View sets `selectedItem = nil` so a later picker session never holds the previous `PhotosPickerItem`. The `onChange` handler returns immediately on nil; the nil reset is never treated as a cancel (cancel is only dispatched from the `isPresented` binding's dismissal path).

### 4. New unit contract tests (+2)

- `photoPickerDismissalAfterSelectionKeepsImportResolving` — begin import → `photoPickerDidDismissAfterSelection()` → `isPickerPresented == false`, `photoImport == .pickerPresented`, camera stopped (`startCount == 1`); then `handleSelectedImage` → `imageSelected` with `.photoLibrary` source, still no restart.
- `photoPickerDismissalThenLoadFailureEntersImportFailed` — dismissal-after-selection → `handleImportLoadFailure` → `importFailed`, `isPickerPresented == false`, no restart.

No UI automation drives the real system picker; native presentation/selection remains NOT INDEPENDENTLY VERIFIED.

### 5. Verification (rerun — production presentation code modified)

- Debug build: **BUILD SUCCEEDED**.
- Release build: **BUILD SUCCEEDED** (DEBUG fakes compiled out).
- Unit tests: **71/71 PASS** (69 prior + 2 new). All prior contracts green: capture blocked in `pickerPresented` / `imageSelected` / `importFailed`; cancel → restart → idle; restart failure → `cameraUnavailable` + idle.
- UI regression: **16/16 PASS** (all 7 suites).
- Boundary audit: Model / Repository / spec / dataset / MockBusinessCards.swift untouched; `project.pbxproj` unchanged; no PhotoKit permission request; `preferredItemEncoding: .current`; no app-side transcoding; bit-for-bit original asset NOT GUARANTEED; canonical orientation NOT ESTABLISHED.
- Concurrency audit: no `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached`.

### Traceability (unchanged)

- Photo-import orchestration: **PASS (automated)**
- Fixture-driven selected-image UI: **PASS**
- Native system PhotosPicker presentation/selection: **NOT INDEPENDENTLY VERIFIED**
- Selected image → Recognition/Edit: **NOT IMPLEMENTED**
- T05 overall: **PARTIAL**

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 4 not entered.

## 2026-10-01 — Week 3 Increment 3 contract corrections (pre-Accept)

### Task
Two state/contract corrections after main-review approval, before Accept. No Increment 4 work.

### 1. Photo Import active state gates camera-only actions

**Problem**: after `beginPhotoImport()` stops the camera session, `state` remains `.preview`. Camera-only actions keyed on `state == .preview` alone were therefore reachable while the session was stopped behind the import flow.

**Fix** ([ScanViewModel.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/ViewModel/ScanViewModel.swift)):
- `capture()` now requires the REAL scanner-ready state:
  `guard state == .preview, photoImport == .idle, !isPickerPresented, !isCaptureInFlight`.
  Every active Photo Import state (`pickerPresented` / `imageSelected` / `importFailed`) blocks still capture. Business correctness does NOT rely on the system picker sheet visually covering the shutter.
- `beginPreview()` (the other camera-start intent, reached via `scannerDidAppear`) is also gated: `guard photoImport == .idle, !isPickerPresented` — a re-fired appear must never restart the camera behind an imported image. `scannerDidDisappear` → `stop()` is idempotent and stays ungated.

### 2. Cancel → restart → idle ordering contract

**Problem**: `handleImportCancel()` set `photoImport = .idle` BEFORE awaiting the camera restart, so `.idle` was observable while the camera was still restarting.

**Fix**: ordering is now
```
picker cancelled
→ isPickerPresented = false
→ await restartPreview()
→ restart succeeded: state = .preview
→ photoImport = .idle        // terminal marker, set LAST
```
On restart failure: `state = .cameraUnavailable(startFailed)` (never `.preview`), and `photoImport` still ends cleanly in `.idle` — the import lifecycle is over; the camera failure is surfaced through the camera state. `photoImport == .idle` is now a TERMINAL marker meaning the import lifecycle has FULLY ended; it never means "camera still restarting". No `restartingPreview` state was added — the existing enum plus ordering satisfies the contract.

### 3. Photo encoding contract

[ScanEntryView.swift](file:///Users/metahumanz/codework/SimCamCard/SimCamCard/View/Scan/ScanEntryView.swift) `.photosPicker` now passes `preferredItemEncoding: .current` (was default `.automatic`).

Final accurate contract:
- `PhotosPicker preferredItemEncoding: .current`
- SimCamCard performs NO app-side image transcoding.
- The system is asked to preserve the item's current encoding when possible.
- The `Data` returned by `PhotosPicker` (`loadTransferable(type: Data.self)`) is preserved unchanged by SimCamCard after loading.
- Bit-for-bit original photo-library asset identity: **NOT GUARANTEED**.
- JPEG / PNG / HEIC etc. actual system representations enter the later pipeline as opaque image `Data`.
- Canonical orientation: **NOT ESTABLISHED** — deferred to rotation normalization before Increment 4.

### 4. Permission semantics (unchanged)

PhotosPicker selected-item path does NOT require `PHPhotoLibrary` authorization. No `PHPhotoLibrary.requestAuthorization`. No `NSPhotoLibraryUsageDescription`. No `NSPhotoLibraryAddUsageDescription`. `project.pbxproj` unchanged. S03 `photoPermissionRequired` / `photoPermissionDenied`: not exercised by the current PhotosPicker path. No artificial permission prompt was manufactured to match the frozen reference.

### 5. New unit contract tests (+5)

- `photoImportPickerPresentedBlocksCapture` — preview → beginPhotoImport → capture() → `captureCount == 0`; state stays `.preview`, import stays `pickerPresented`.
- `photoImportImageSelectedBlocksCapture` — imported image survives a blocked capture; `captureCount == 0`.
- `photoImportFailedBlocksCapture` — `importFailed` blocks capture; `captureCount == 0`.
- `photoImportCancelBecomesIdleOnlyAfterRestartCompletes` — uses a minimal gated-fake seam (`enableStartGate`/`releaseStartGate` suspends `start()` after incrementing the counter; deterministic, no wall-clock): mid-restart `photoImport` is still `pickerPresented` (NOT idle); after gate release, `idle` + `.preview`.
- `photoImportCancelWithRestartFailureLeavesPickerFlowCleanly` — fake fails only the 2nd `start()` (`startErrorOnCall: 2`): cancel → `.cameraUnavailable(.startFailed)` + `photoImport == .idle`, never `.preview`.

### 6. Verification (rerun — production state lifecycle modified)

- Debug build: **BUILD SUCCEEDED**.
- Release build: **BUILD SUCCEEDED** (DEBUG fakes compiled out).
- Unit tests: **69/69 PASS** (64 prior + 5 new). All Increment 1/2 contracts green.
- UI regression: **16/16 PASS** (all suites: CardDetail / CardHolderEmpty / CardHolderPopulated / ScanCamera / ScanEntry / SimCamCard / Week2Integration).
- Boundary audit: Model / Repository / spec / dataset / MockBusinessCards.swift untouched; `project.pbxproj` unchanged; no `PHPhotoLibrary` / Vision / OCR / `AppRoute.crop` / `AppRoute.recognition`.
- Concurrency audit: no `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached`.

### Traceability (unchanged, honest)

- Photo-import orchestration: **PASS (automated)**
- Fixture-driven selected-image UI: **PASS**
- Native system PhotosPicker presentation/selection: **NOT INDEPENDENTLY VERIFIED**
- Selected image → Recognition/Edit: **NOT IMPLEMENTED**
- T05 overall: **PARTIAL**

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 4 not entered.

## 2026-10-01 — Week 3 Increment 3 Accepted: final conclusions

**Accepted — 2026-10-01 (human review).** Week 3 Increment 3 (System Photo Import, T05 mechanics) final conclusions, unchanged at acceptance:

- System `PhotosPicker`: IMPLEMENTED
- PhotoKit authorization request: NOT REQUIRED by current selected-item picker path
- `NSPhotoLibraryUsageDescription`: NOT ADDED
- `project.pbxproj`: unchanged
- camera/photo-library unified image transport (`CapturedPhoto` + `ImageSource`): PASS
- `preferredItemEncoding: .current`: PASS
- app-side image transcoding: NONE
- bit-for-bit original asset identity: NOT GUARANTEED
- canonical image orientation: NOT ESTABLISHED

- photo-import active states block still capture: PASS
- `beginPreview` does not restart camera while photo import owns scanner content: PASS
- cancel → camera restart → idle: PASS
- idle is not exposed until restart resolves: PASS
- restart failure → cameraUnavailable + clean import termination: PASS

- selection dismissal ≠ cancel: PASS
- system dismissal immediately clears picker presentation flag: PASS
- selection-load transient (`isPickerPresented == false` + `photoImport == pickerPresented` + camera stopped) is a valid state
- load success → imageSelected: PASS
- load failure → importFailed: PASS
- selected `PhotosPickerItem` reset after terminal handling: PASS

- Unit tests: 71/71 PASS
- UI regression: 16/16 PASS
- Debug build: PASS
- Release build: PASS

S03:

- pickerPresented: IMPLEMENTED / automated orchestration PASS
- imageSelected: IMPLEMENTED / fixture verification PASS
- cancelled: IMPLEMENTED / automated + fixture verification PASS
- photoPermissionRequired: not exercised by current system-picker path
- photoPermissionDenied: not exercised by current system-picker path

T05:

- photo-import orchestration: PASS
- selected-image pipeline handoff: PASS
- fixture-driven imported-image presentation: PASS
- native system PhotosPicker runtime selection: NOT INDEPENDENTLY VERIFIED
- selected image → Recognition/Edit workflow: NOT IMPLEMENTED
- overall: PARTIAL

Residual verification note: Apple's public `PhotosPicker` API documents the `isPresented` and `selection` bindings but does not define a callback-order guarantee between their mutations. Current selection-vs-cancel dispatch therefore remains subject to native system-picker runtime verification. This is a verification item, not a blocker for this Increment.

AI did not commit, merge or tag. Increment 4 not entered.

## 2026-10-01 — Week 3 Increment 4: Canonical Orientation + Live Card Detection (T06 first half)

Baseline: 6ddefaa.

### Orientation architecture

Canonical orientation is now ESTABLISHED via a three-part contract:

- capture side: `AVCaptureDevice.RotationCoordinator(device:previewLayer:nil)` owned by the `CameraSessionController` actor; its `videoRotationAngleForHorizonLevelCapture` is observed (KVO callback on main queue → `Task { await actor.applyCaptureRotation(angle) }`) and applied to the `.video` connections of BOTH the photo output and the video data output through the pure `VideoRotationDecision.supportedAngle` seam (unsupported angles are never written to a connection). The capture angle is applied immediately once at configuration and on every subsequent change.
- preview side: a SECOND, independent RotationCoordinator owned by `CameraPreviewView.PreviewContainerView`, observing `videoRotationAngleForHorizonLevelPreview` and writing only `previewLayer.connection?.videoRotationAngle` (guarded by `isVideoRotationAngleSupported`). The View layer's responsibility stays limited to preview presentation + preview-connection rotation; it never touches capture outputs.
- imported/still image side: `ImageOrientationResolver.orientation(of:)` reads EXIF orientation via ImageIO (`CGImageSourceCreateWithData` + `kCGImagePropertyOrientation`) without rewriting bytes; missing metadata or undecodable data → `.up`.

RotationCoordinator live preview behavior on real device rotation: PENDING physical device.

### ImageOrientationResolver contract

Pure read-only metadata lookup: `static func orientation(of data: Data) -> CGImagePropertyOrientation`. No decode, no transcode, no byte mutation. Unit-verified for EXIF orientations 1/3/6/8 (`.up/.down/.right/.left`), no-metadata → `.up`, invalid data → `.up` (test fixtures built with CGImageDestination-injected EXIF).

### AVCaptureVideoDataOutput configuration

Added alongside the existing photo output in the SAME configuration transaction; `canAddOutput` failure throws the new `CameraSessionError.cannotAddVideoDataOutput` (→ `cameraUnavailable`, never misreported as preview). `alwaysDiscardsLateVideoFrames = true`.

### Detection queue ownership / backpressure

Sample-buffer delegate (`VideoFrameProcessor`, `nonisolated final class`, same pattern as `PhotoCaptureProcessor`) runs on a dedicated serial queue `com.metahumanz.SimCamCard.camera.detection` — never MainActor, never the session queue. Frame callback consumes the CMSampleBuffer synchronously (never stored, never crosses an isolation boundary) and publishes only the Sendable `CardRegion?` into an `AsyncStream` with `bufferingNewest(1)`: the ViewModel only ever needs the latest boundary; late frames are dropped by AVFoundation, not queued. `didDrop` is intentionally empty.

### Vision API + detector configuration

Stable `VNDetectRectanglesRequest` / `VNRectangleObservation` only — no beta/experimental Vision APIs, no OCR assistance. Fresh request per frame (no reused mutable request state across calls). `CardRegionDetector.Configuration.businessCardBaseline`: maximumObservations 1, minimumConfidence 0.6, minimumSize 0.1, aspect ratio 0.4…2.5 (covers horizontal ~1.6 and vertical ~0.6 cards with perspective slack), quadratureTolerance 30. Vision failure → `nil` for that frame, never an error state, never `cameraUnavailable`.

### CardRegion coordinate convention

Project-wide: origin top-left, x right, y down, all values clamped to [0,1] by `NormalizedPoint`. Conversion from Vision's lower-left origin: `appY = 1 − visionY` per corner, corner labels preserved. `sourcePixelWidth/Height` carry the ORIENTED source pixel size (axes swapped for 90°/270° still-image orientations) because the aspect-fill overlay mapping requires the source aspect ratio. Vision objects (`VNRectangleObservation`) never leave the detector; only the Sendable value type crosses to the MainActor.

### Aspect-fill mapping

Pure function `AspectFillCoordinateMapper.point`: `scale = max(dW/sW, dH/sH)`, `offset = (dest − source·scale)/2`, `screen = offset + normalized · (source·scale)`. Unit-verified for 1:1, 4:3-in-tall-viewport (width crop), portrait-source-in-landscape (side crop), and a 1920×1080→390×700 four-corner numeric case.

### Dataset smoke-test results (real Vision, no fake)

`CardRegionDetectorTests` run the real `VNDetectRectanglesRequest` on frozen-dataset images read in place via `#filePath` (never copied, never modified):

- card-001-standard-bilingual.png → one valid quadrilateral: PASS
- card-007-vertical-medical-bilingual.png → one valid quadrilateral: PASS
- card-013-english-bio-photographed.png → one valid quadrilateral: PASS
- uniform 64×64 gray image → nil (no throw): PASS

Assertions are smoke-contract only (dataset has no corner ground truth): region non-nil, all corners in [0,1], shoelace area > 0.05, positive source pixel size.

### ViewModel detection lifecycle

`CardDetectionState { inactive, cardNotDetected, cardDetected(CardRegion) }` is a separate state family; it does not alter `.preview` semantics. Consumption starts after successful `beginPreview`/`restartPreview` (initial state `cardNotDetected`); `capture` (success and both failure paths), `beginPhotoImport`, and `scannerDidDisappear` all stop consumption and reset to `.inactive`; stale events after termination cannot reactivate the overlay (state/import guards in the consumer loop). At most one consumer task at a time (previous stream finished before a new one is created); no `Task.detached`.

### Overlay Reference fidelity

Human visual comparison (fixture screenshot vs `evidence/screenshots/REF-scanner-02-card-detected.png`): cyan thin-stroke quadrilateral, no corner handles, no fill, no glow, no animation — MATCH; detected capsule pill "发现名片，点击拍摄" top-center, static white aiming guide REPLACED (not overlaid) — MATCH. Fixture geometry is a deterministic centered region, not a real detected card shape; real-detection geometry fidelity is PENDING physical device. Validation screenshots: `ai/validation/2026-10-01-increment4-card-detected-fixture.png`, `ai/validation/2026-10-01-increment4-card-not-detected-fixture.png`.

### Builds and tests

- Debug build: PASS
- Release build: PASS (`SWIFT_ACTIVE_COMPILATION_CONDITIONS` empty; DEBUG fixture code compiled out)
- Unit tests: 96/96 PASS (was 71; +25: orientation resolver, CardRegion convention/clamping, aspect-fill mapper, real-Vision dataset smoke ×4, ViewModel detection lifecycle ×9, rotation-decision seam)
- UI regression: 18/18 PASS (was 16; +2 detection fixture tests)

### Physical-device pending items

- real camera frame delivery: PENDING physical device
- RotationCoordinator live preview behavior: PENDING physical device
- live Vision business-card detection: PENDING physical device
- fixture overlay: PASS automated
- dataset still-image Vision smoke: PASS automated

### Traceability

- T06 Vision rectangle detector: PASS on dataset smoke
- T06 live detection state orchestration: PASS automated
- T06 detected boundary overlay: PASS fixture-driven
- T06 live physical-device overlay: NOT INDEPENDENTLY VERIFIED
- T06 manual boundary adjustment / confirm: NOT IMPLEMENTED (later half)
- T06 overall: PARTIAL
- S02 cardNotDetected: IMPLEMENTED / PASS automated
- S02 cardDetected: IMPLEMENTED / PASS automated + fixture
- S04 (crop/edit): NOT IMPLEMENTED this increment

### Boundary / concurrency audit

- No `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached` (grep clean; matches only in explanatory comments).
- No Vision/VNRectangle/CMSampleBuffer import or reference in ViewModel/View; Model layer free of SwiftUI/UIKit/Vision/AVFoundation.
- Vision work confined to the dedicated detection queue; no Vision call on MainActor or the session queue.
- CMSampleBuffer consumed synchronously in the callback; only `CardRegion?` crosses actors.
- Model / Repository / spec / dataset / MockBusinessCards.swift / project.pbxproj: unchanged (new files picked up by filesystem-synchronized groups).
- Release DEBUG-fixture isolation: PASS (Release `SWIFT_ACTIVE_COMPILATION_CONDITIONS` has no DEBUG; entire fixture file is `#if DEBUG`).
- `git status` shows no `_local` prompt path (ignored via `.git/info/exclude`).

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 5 not entered.

## 2026-10-01 — Week 3 Increment 4 pre-Accept corrections: Vision aspect-ratio semantics + configure rollback + orientation wording

Human review approved the Increment 4 main architecture; this round fixes two production blockers and calibrates the orientation documentation wording before Accept. Existing history above is not rewritten.

### Blocker 1 — VNDetectRectanglesRequest aspect-ratio semantic correction

The previous `maximumAspectRatio = 2.5` used the wrong semantic. Vision defines BOTH `minimumAspectRatio` and `maximumAspectRatio` as shorter dimension / longer dimension, so every legal value is in 0.0...1.0; horizontal and vertical business cards share the SAME range (no reciprocal >1 value).

Corrected `CardRegionDetector.Configuration.businessCardBaseline`:

- maximumObservations = 1 (unchanged)
- minimumConfidence = 0.6 (unchanged)
- minimumSize = 0.1 (unchanged)
- minimumAspectRatio = 0.4
- maximumAspectRatio = 1.0 (was 2.5)
- quadratureTolerance = 30 (unchanged)

New configuration-contract unit test asserts the baseline stays inside documented legal ranges: minimumAspectRatio ≥ 0, maximumAspectRatio ≤ 1, minimumAspectRatio ≤ maximumAspectRatio, minimumSize ∈ 0...1, minimumConfidence ∈ 0...1, quadratureTolerance ∈ 0...45, maximumObservations == 1. It does NOT test Vision's undocumented internal clamping.

Dataset smoke RERUN with the corrected configuration, real Vision (no fake): card-001 standard horizontal PASS, card-007 vertical PASS, card-013 photographed PASS, uniform featureless image → nil PASS. Detector PASS retained only because the corrected-configuration smoke passed.

### Blocker 2 — configure failure partial-topology rollback

Previously a late rejection (e.g. `canAddVideoDataOutput == false`) still committed the transaction after earlier add steps, leaving a partial topology with `isConfigured == false` for a later retry.

Fix via a minimal seam (`SimCamCard/Camera/CameraTopologyTransaction.swift`), without a large refactor:

- `CaptureSessionTopology` protocol (associated input/output types; witnessed directly by AVCaptureSession's existing begin/commit/canAdd/add/remove methods) exists only to make the ordering contract unit-testable without camera hardware. It is deliberately not Sendable — calls are synchronous on the camera actor's serial executor.
- `CameraTopologyTransaction.apply(...)` runs one attempt: begin → add input → add photo output → add video-data output → commit, tracking exactly which objects THIS attempt added. On any rejection it removes in REVERSE order only the objects added by this attempt (a never-added rejected object is not removed), commits the clean topology, and rethrows the original CameraSessionError. Pre-existing topology is never removed.
- `CameraSessionController.configureIfNeeded()` delegates to the helper; the dedicated actor executor, sessionQueue ownership, start/stop behavior, RotationCoordinator ownership and detectionQueue ownership are unchanged.

Retry contract verification (deterministic fake topology, no AVCaptureSession/hardware): success installs exactly one input + two outputs with one begin/commit; rejected input → empty committed topology + `.cannotAddVideoInput`; rejected photo output → input removed + `.cannotAddPhotoOutput`; rejected video-data output → photo output then input removed (rejected object itself not removed) + `.cannotAddVideoDataOutput`; attempt 1 late failure (clean, configured == false) followed by attempt 2 allowed → exactly one input, two outputs, two begin/commit pairs, configured == true.

### Orientation wording calibration

The blanket phrase "canonical orientation: ESTABLISHED" is withdrawn in favor of per-path status:

- Live camera frame orientation contract: ESTABLISHED at architecture/automated level — RotationCoordinator capture angle; AVCaptureVideoDataOutput connection rotation; Vision receives `.up`-oriented delivered buffers; physical-device verification still PENDING.
- Captured-photo rotation metadata contract: ESTABLISHED at architecture level — capture rotation applied to the AVCapturePhotoOutput connection; physical-device EXIF verification still PENDING.
- Imported/still image orientation-resolution contract: ESTABLISHED as resolver foundation — ImageOrientationResolver reads CGImagePropertyOrientation; EXIF mapping tests PASS; raw bytes unchanged.
- End-to-end still-image Detection/Crop consumption of resolved orientation: NOT IMPLEMENTED YET.

Stated overall: orientation foundation / semantics ESTABLISHED — NOT claimed as "all camera/import image pipelines are end-to-end canonically normalized".

Unchanged (re-affirmed): preview RotationCoordinator mutates only the preview connection; capture RotationCoordinator mutates photo/video-data-output connections on the camera actor; KVO → actor hop; `isVideoRotationAngleSupported` guard; video-data frames analyzed as `.up`; CardRegion top-left normalized coordinates; resizeAspectFill mapper; detected fixture ≠ physical live detection. Overlay UI unchanged.

### Verification totals (actual reruns)

- Debug build: PASS
- Release build: PASS (Release SWIFT_ACTIVE_COMPILATION_CONDITIONS empty; DEBUG fixture compiled out)
- Unit tests: 102/102 PASS (previous 96 + 1 detector configuration contract + 5 topology rollback/retry)
- UI regression: 18/18 PASS
- Real-Vision dataset smoke (corrected config): 4/4 PASS
- Concurrency audit: no `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached`
- Boundary audit: Model / Repository / spec / dataset / MockBusinessCards.swift / project.pbxproj unchanged; `git status` shows no `_local`

### Traceability (unchanged conclusions)

- T06 Vision rectangle detector: PASS (corrected-configuration dataset smoke)
- T06 live detection orchestration: PASS automated
- T06 detected overlay: PASS fixture-driven
- T06 live physical-device detection: NOT INDEPENDENTLY VERIFIED
- T06 manual boundary adjustment: NOT IMPLEMENTED
- T06 confirm: NOT IMPLEMENTED
- T06 overall: PARTIAL
- S04 autoDetected / manualAdjusting / confirmed / retakeRequested: NOT IMPLEMENTED (Scanner live cardDetected does not make S04 autoDetected PASS)

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 5 not entered.

## 2026-10-01 — Week 3 Increment 5: Crop / Boundary Adjust + Perspective Correction (P04 / S04, T06 second half)

Baseline: db0cc90.

### P04 Reference evidence (actual observation of REF-crop-01-manual-adjust.png, 1224×1626@2x)

- Top bar: plain white "取消" top-left (retake semantics — no "重拍" text, no chevron/icon), plain blue "完成" top-right.
- Full-bleed black background; complete image centered aspect-fit with black letterbox.
- Thin bright-blue quadrilateral stroke; NO dim/mask fill inside or outside.
- Four bright-blue filled circular corner handles (~16pt), four-corner-only interaction.
- Four dark slate-gray edge-midpoint dots centered on each edge ARE visible in the Reference (OBSERVED IN REFERENCE). They are rendered for black-box visual replication; PRESENTATION ONLY (`allowsHitTesting(false)`) because the Reference does not establish midpoint-drag semantics (edge-midpoint interaction: NOT ESTABLISHED). (Wording corrected in the pre-Accept correction section below — an earlier draft of this entry wrongly recorded them as NOT OBSERVED / not rendered.)
- No guidance text, magnifier, or animation evidence.
- Reference fidelity for the transient preparing/failed/confirmed pages: NOT ESTABLISHED (Reference shows only the editing page) — these are minimal IMPLEMENTATION BEHAVIOR.

### Shared still pipeline (camera + photo import converge)

`camera capture OR photo import → CapturedPhoto → CardImageDecoder.decode (ImageIO + orientation) → CardRegionDetector (still image, reused from Increment 4) → CropDraft → P04 manual corner adjustment → confirm → CIPerspectiveCorrection → CardCropResult (new upright PNG; original bytes untouched)`. Capture and import run the SAME `ScanViewModel.prepareCrop` path — no duplicated pipelines. Heavy work is confined to the `CardCropProcessor` actor on a dedicated `DispatchSerialQueue` (`com.metahumanz.SimCamCard.crop.processing`); the MainActor ViewModel only holds Sendable values (Data / Int / enums), never CGImage/CIImage/UIImage. No OCR (no VNRecognizeTextRequest), no Recognition/Edit, no structured fields, no BusinessCard creation, no Repository save, no auto enhancement, no multi-card.

### CardImageDecoder + orientation consumption

`CardImageDecoder.decode(_ data:) throws -> DecodedImage` uses ImageIO directly (never UIImage as processing source of truth): primary CGImage + resolved `CGImagePropertyOrientation` (via the existing `ImageOrientationResolver`) + ORIENTED pixel dimensions (axes swapped for `.left/.right` and mirrored variants). Unreadable bytes → `CropError.invalidImageData` (stable, no crash).

### No-detection fallback (IMPLEMENTATION BEHAVIOR, not Reference-observed)

When still detection returns nil, preparation produces an inset axis-aligned rectangle (`fallbackInset = 0.06`) and enters `manualAdjusting` — cropping stays possible instead of dead-ending. Clearly labeled implementation robustness; Reference fidelity not established.

### Geometry validity gate (pure, no UIKit/Core Image)

`CardRegionGeometry.isValid`: all four edges ≥ 1e-4, shoelace area/2 ≥ 0.01 of the normalized square, every consecutive cross product non-zero and same-sign (rejects self-intersecting bow-ties and collinear triples). `NormalizedPoint` clamps to 0...1 before validation. Drag policy: an invalid candidate is silently ignored — the draft can NEVER hold a degenerate region, and confirm is never the first validity gate. The first accepted drag permanently transitions autoDetected → manualAdjusting.

### Aspect-fit coordinate mapping

`AspectFitCoordinateMapper` (pure): `scale = min(cw/sw, ch/sh)` with centered letterbox offsets; forward normalized→view and inverse view→normalized (subtracts letterbox offset, clamps to 0...1, so a drag ending in the letterbox maps to the nearest edge). The Scanner's aspect-fill math is deliberately not reused.

### Perspective correction + PNG contract

`CIPerspectiveCorrection` (typed `CIFilter.perspectiveCorrection()`, crop = true) on the `CIImage.oriented(...)` upright image; extent normalized to (0,0) before corner mapping. Corner conversion `PerspectiveCoordinateMapping.coreImagePoint`: `ciX = x·w`, `ciY = (1−y)·h` on the ORIENTED dimensions (guards against double y-flip and double axis-swap). Output rendered via a shared `CIContext`, encoded PNG with NO properties dictionary → no EXIF orientation is written: the pixels are physically upright and the result's orientation semantics are `.up`. `CardCropResult` carries the untouched `original: CapturedPhoto`, `confirmedRegion`, processed PNG Data and processed pixel dimensions. Guarded errors: `.invalidImageData / .invalidRegion / .correctionFailed`.

### S04 state machine

Separate `CardRegionState` family (deliberately NOT merged into the camera `State` enum): `inactive / preparing / autoDetected(CropDraft) / manualAdjusting(CropDraft) / confirmed(CardCropResult) / retakeRequested / failed(CropError)`. Frozen S04 mapping: autoDetected, manualAdjusting, confirmed, retakeRequested all IMPLEMENTED; `preparing`/`failed` are implementation transients. `confirmCrop()` is guarded by `isCropInFlight` (double tap → exactly one correction; confirmed state has no draft so a later call is a no-op). `retake()` ("取消") discards the draft/result, clears import/picker state, restarts preview and resumes live detection; for a photo-library source it returns to the same Scanner without re-opening the system picker; restart failure maps to the existing `cameraUnavailable` contract. Retake outside an active crop screen is ignored.

### DEBUG fixtures

`-SimCamCardCrop {auto|manual|confirmed}` drives `DebugCropProcessor` (deterministic 600×380 synthetic card PNG + fixed region; prepare is faked, perspectiveCorrect delegates to the REAL processor). The 4×4 capture fixture bytes are replaced by the synthetic image for prepare. Entire fixture surface is `#if DEBUG`.

### Dataset end-to-end smoke (real decode + real Vision + real Core Image, no fixture)

`CropPipelineDatasetSmokeTests`, dataset files read in place via `#filePath`:

- card-001-standard-bilingual.png → prepare detected → correct → decodable upright PNG: PASS
- card-007-vertical-medical-bilingual.png → same: PASS
- card-013-english-bio-photographed.png → same: PASS

Assertions are smoke-contract only: `wasDetected == true`, valid region, positive processed dimensions, output decodes with orientation `.up`, original bytes retained equal.

### Builds and tests (actual reruns)

- Debug build: PASS
- Release build: PASS (`SWIFT_ACTIVE_COMPILATION_CONDITIONS` empty; DEBUG fixtures compiled out)
- Unit tests: 146/146 PASS (was 102; +44 executed cases: geometry validity/clamp/fallback, aspect-fit mapper + round-trip + letterbox clamp, perspective coordinate mapping incl parameterized .up/.down/.left/.right oriented dims, CardImageDecoder, synthetic-image processor success/failure/EXIF-.right physical-upright, 3 real-card dataset smoke, 14 ScanViewModel S04 workflow tests)
- UI regression: 21/21 PASS (was 18; +3 crop tests: auto-detected boundary+4 handles+controls, manual drag page stability, confirm corrected image with handles absent; the existing capture and import fixture tests were UPDATED because capture/import now intentionally flow into P04 — their mechanics assertions are preserved via the crop page + retake path)
- Validation screenshots: `ai/validation/2026-10-01-increment5-crop-auto-detected.png`, `2026-10-01-increment5-crop-manual-adjust.png`, `2026-10-01-increment5-crop-confirmed.png`

### Traceability

- T04 capture mechanics: PASS automated (capture now hands off into P04)
- T05 import mechanics: PASS automated (import shares the same pipeline)
- T06 Vision rectangle detector (live + still): live PASS automated / physical PENDING; still-image Detection→Crop PASS automated incl dataset
- T06 manual boundary adjustment: PASS automated (fixture UI + unit geometry; Reference-fidelity PENDING human)
- T06 confirm + perspective correction: PASS automated (real Core Image on synthetic + dataset images)
- T06 overall: PARTIAL (physical live camera verification outstanding)
- S04 autoDetected / manualAdjusting / confirmed / retakeRequested: IMPLEMENTED / PASS automated

### Orientation status update

End-to-end still-image Detection/Crop orientation consumption: PASS automated (parameterized .up/.down/.left/.right oriented dimensions; EXIF-.right portrait source corrects into landscape physically-upright PNG with no residual EXIF; dataset images pass the real chain). Physical-camera captured-photo EXIF on real hardware: still PENDING. Native `PhotosPicker` runtime selection: still NOT INDEPENDENTLY VERIFIED (DEBUG import fixture bypasses native picker UI as in Increment 3).

### Boundary / concurrency audit

- No `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached` (grep clean; matches only in explanatory comments).
- No Vision/CMSampleBuffer/CIImage/CIFilter import or reference in ViewModel/View (`UIImage(data:)` in CardCropView is a display adapter only); Vision remains confined to Detection and the crop processor's off-main actor.
- Model / Repository / spec / dataset / MockBusinessCards.swift / project.pbxproj: unchanged (new files picked up by filesystem-synchronized groups).
- `git status` shows no `_local` prompt path.

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 6 not entered.

## 2026-10-01 — Week 3 Increment 5 pre-Accept correction: confirmation interaction freeze + P04 edge-midpoint evidence/visual calibration

Human review of the Increment 5 body: approved, subject to this one production concurrency/state blocker and the P04 reference-fidelity calibration. Scope was limited to ViewModel/View/tests; the approved Apple/Core Image path was NOT refactored.

### 1. Confirmation interaction freeze contract (stale-result race prevention)

Blocker: while `isCropInFlight == true` (between `confirmCrop()` entry and the awaited correction settling), Cancel/retake and corner drags could still execute, allowing `confirm A → move to B → confirmed A clobbers B` and `confirm → retake to scanner → old confirm returns → .confirmed reappears`.

Fix (state ownership stays in the ViewModel):

- `ScanViewModel.moveCorner` now starts with `guard !isCropInFlight, let draft = cardRegion.draft else { return }` — the CropDraft is immutable for the duration of a correction.
- `ScanViewModel.retake` now requires `guard cardRegion.isCropScreenActive, !isCropInFlight else { return }` — no workflow reset, no camera restart, no live-detection restart while a correction is running.
- `confirmCrop` retains its existing double-confirm guard (`!isCropInFlight` + editable draft).
- CardCropView mirrors the freeze: `scan-crop-confirm` stays disabled (already), `scan-crop-retake` is now `.disabled(viewModel.isCropInFlight)`, and all four corner handles get `.allowsHitTesting(false)` while in flight. No new loading overlay was introduced; the Reference UI is preserved exactly.

### 2. Deterministic gated correction test (no sleep)

`FakeCropProcessor` gained a continuation gate: `enableCorrectionGate()` makes `perspectiveCorrect` suspend after recording entry (`enteredCorrectionCount` incremented synchronously before suspension); `releaseCorrectionGate()` resumes all waiters. New test `crop intents are frozen while a confirmation correction is in flight`:

- capture → autoDetected(draft A); start `confirmCrop()` in a Task; bounded-yield until the fake reports correction entered; assert `isCropInFlight == true`, workflow still on the captured crop page;
- move while confirming → draft/state unchanged (still autoDetected A);
- retake while confirming → workflow state unchanged, camera start count unchanged, no new detection stream, live detection not restarted (`cardDetection` still `.inactive`);
- release gate → exactly one correction completes, state settles `.confirmed(result)` with `confirmedRegion == A`, `isCropInFlight == false`.

The sequential double-confirm test is retained.

### 3. P04 midpoint evidence calibration (correction of an earlier wrong record)

The earlier entry below stated the edge-midpoint dots were recorded "NOT OBSERVED / not rendered". That was wrong and is withdrawn:

```text
edge-midpoint controls: OBSERVED IN REFERENCE (REF-crop-01)
edge-midpoint interaction semantics: NOT ESTABLISHED
```

Re-measurement on the actual reference PNG (1182×1632): one dark slate-gray filled circle centered on each of the four edges; sampled fill ~RGB(69,69,78), diameter ~15–16pt, no independent stroke (the blue edge passes through the center). The earlier "NOT OBSERVED" wording in the Increment 5 evidence bullet has been corrected in place.

### 4. Midpoint visual fidelity (implemented; presentation only)

CardCropView now renders all four edge-midpoint dots for black-box visual replication:

- positions derived LIVE each layout pass as `midpoint(A,B)` of the current four corners in aspect-fit display coordinates (never fixed screen coordinates);
- small filled circles, `Color(red:0.27,green:0.27,blue:0.31)` sampled from REF-crop-01, diameter 15pt, no animation, no change to quadrilateral geometry;
- `allowsHitTesting(false)` + accessibilityHidden — PRESENTATION ONLY; no edge drag is implemented because the Reference does not establish midpoint interaction semantics.

P04 visual fidelity status:

```text
corner handles:            MATCH
edge midpoint visual:      MATCH / IMPLEMENTED
edge midpoint interaction: NOT ESTABLISHED
```

### 5. Untouched production contracts

Explicitly NOT modified in this correction round: CardCropProcessor orientation pipeline, `CIImage.oriented(...)`, PerspectiveCoordinateMapping, the CIFilter perspective-correction call, the processed PNG contract (no EXIF / physically upright), original CapturedPhoto preservation, no-detection fallback (inset 0.06), geometry validity thresholds, AspectFit mapper, T04/T05 routing, and the S04 state family. Model / Repository / spec / dataset / MockBusinessCards.swift / project.pbxproj remain unchanged.

### 6. Re-verification (actual reruns)

- Debug build: PASS
- Release build: PASS; `SWIFT_ACTIVE_COMPILATION_CONDITIONS` empty and the Release app binary contains neither the `SimCamCardCrop` launch argument nor the `DebugCropProcessor` symbol (DEBUG fixture isolation confirmed)
- Unit tests: 147/147 PASS (was 146; +1 deterministic gated freeze test), including the 3 real-card dataset Detection→Crop smoke tests
- UI regression: 21/21 PASS (unchanged count; all three crop screens re-verified after the view changes); the crop validation screenshots were regenerated and now show the four edge-midpoint dots:
  - ai/validation/2026-10-01-increment5-crop-auto-detected.png
  - ai/validation/2026-10-01-increment5-crop-manual-adjust.png
  - ai/validation/2026-10-01-increment5-crop-confirmed.png
- Concurrency audit: no `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached` (comment mentions only); boundary audit: no Vision/CIImage/CMSampleBuffer use in ViewModel/View; `git status` shows no `_local` path.

### 7. Traceability (unchanged)

- S04 autoDetected / manualAdjusting / confirmed / retakeRequested: IMPLEMENTED / PASS automated
- T06 overall: PARTIAL — physical-device live camera path still NOT INDEPENDENTLY VERIFIED

### Final accepted conclusions (2026-10-01 human review)

Pipeline / contracts:

- shared camera/photo-import still-image crop pipeline: PASS
- original CapturedPhoto bytes preservation: PASS
- orientation resolution + upright processing: PASS
- still-image Vision detection: PASS
- no-detection manual fallback: PASS / implementation behavior
- four-corner manual boundary adjustment: PASS
- quadrilateral validity gate: PASS
- AspectFit forward/inverse coordinate mapping: PASS
- Core Image perspective correction: PASS
- processed upright PNG contract: PASS
- end-to-end dataset Detection→Crop smoke: PASS

Confirmation concurrency:

- double-confirm guard: PASS
- moveCorner blocked while correction is in flight: PASS
- retake blocked while correction is in flight: PASS
- stale correction cannot overwrite a newer manual draft: PASS
- stale correction cannot re-open confirmed state after retake: PASS
- deterministic continuation-gated race test: PASS

P04 Reference:

- black background: MATCH
- aspectFit image presentation: MATCH
- Cancel / 完成 toolbar: MATCH
- blue quadrilateral boundary: MATCH
- four bright-blue draggable corner handles: MATCH
- four dark slate-gray edge-midpoint dots: MATCH / IMPLEMENTED (positions derived dynamically from current edge geometry)
- edge-midpoint interaction semantics: NOT ESTABLISHED — no edge-drag behavior invented
- no dim mask: MATCH
- no unsupported animation/magnifier added

Verification:

- Debug build: PASS
- Release build: PASS
- Unit: 147/147 PASS
- UI: 21/21 PASS
- three Crop UI tests after visual correction: 3/3 PASS
- real dataset Detection→Crop smoke: PASS
- Release DEBUG fixture isolation: PASS
- concurrency audit: PASS
- Model / Repository / spec / dataset / pbxproj unchanged

Traceability:

- S04 autoDetected: IMPLEMENTED / PASS
- S04 manualAdjusting: IMPLEMENTED / PASS
- S04 confirmed: IMPLEMENTED / PASS
- S04 retakeRequested: IMPLEMENTED / PASS
- T04 capture mechanics: PASS; T04 capture → Crop: PASS; T04 capture → Recognition: NOT IMPLEMENTED; T04 overall: PARTIAL
- T05 import mechanics: PASS; T05 import → Crop: PASS; T05 import → Recognition/Edit: NOT IMPLEMENTED; T05 overall: PARTIAL
- T06 automatic detector: PASS automated/dataset; T06 Scanner detected overlay: PASS fixture-driven; T06 P04 auto-detected region: PASS; T06 manual adjustment: PASS; T06 confirm / perspective-corrected output: PASS; T06 physical-device live path: NOT INDEPENDENTLY VERIFIED; T06 overall: PARTIAL

Orientation:

- end-to-end still-image Detection/Crop orientation consumption: PASS automated
- physical-camera captured-photo EXIF path: PENDING physical device
- native PhotosPicker real-asset path: NOT INDEPENDENTLY VERIFIED

### Human Decision

Accepted — 2026-10-01 (human review).

AI did not commit, merge or tag. Increment 6 not entered.

## 2026-10-02 — Week 3 Increment 6: Raw OCR + Raw Text Preservation (T07 raw transport)

Baseline: 68d242c (`feat(crop): 实现名片边界调整与透视校正`). Frozen scope: produce and preserve RAW recognized text only. Structured extraction (name/company/title/phone/email parser), missing-field, multiple-phone and manual correction (T08–T11, P05/P06/P07) remain Week 4 and are deliberately absent.

### Engine choice — Swift-native Vision API

The recognizer uses the iOS 26+ Swift-native `RecognizeTextRequest` (Vision's async `request.perform(on:orientation:)`), NOT the legacy `VNRecognizeTextRequest`/completion-handler API: the native async API eliminates hand-rolled continuation bridges, and the codebase builds with the iOS 27 SDK / Swift 6.4 language mode. Request configuration (`OCRConfiguration`, pure and Equatable): `.accurate`; `recognitionLanguages = [zh-Hans, en-US]` in that preference order; `automaticallyDetectsLanguage = true`; **`usesLanguageCorrection = false`**; **no `customWords`**. Rationale: in T07 nothing may rewrite Vision output before Week 4 extraction — correction/lexicon would silently alter the preserved raw string (the card-001 result below is direct evidence that raw Vision output is imperfect; preservation beats prettification at this stage). Revision stays at the system default. No reading-order reorder: Vision observation order is kept as returned.

### Raw value contract (pipeline transport, NOT a domain model)

- `OCRLine { text: String; confidence: Float }` — one observation's TOP-1 candidate; only surrounding whitespace/newlines trimmed; interior spaces, punctuation, digits, letter case and CJK characters preserved verbatim; no dedup/merge. Confidence is metadata only — never used to filter or reorder.
- `CardOCRResult { cropResult: CardCropResult; lines: [OCRLine]; rawText: String }` — `rawText = lines.map(\.text).joined(separator: "\n")`, computed exactly once at initialization; empty when Vision returned no usable text. This is a transport value, not `BusinessCard`: no identity, no tags/notes, no Repository persistence.
- `OCRError.recognitionFailed` — any request execution failure (invalid bytes / Vision error) maps to this stable case. A request that RUNS and returns ZERO observations is NOT an error: it yields an empty `CardOCRResult` and settles a distinct `.emptyRawResult` UI state.
- `CardOCRProcessor` is a plain `actor` (the native async Vision API provides its own execution pipeline; unlike camera/crop, no DispatchSerialQueue is needed). `RecognizedTextObservation` never crosses the actor boundary — only Sendable project values leave it. NOT `@unchecked Sendable`, NOT `nonisolated(unsafe)`, NOT `Task.detached`.

### ViewModel integration — separate state family + generation guard

- New `ScanViewModel.RecognitionState` family: `inactive / processing(CardCropResult) / rawTextAvailable(CardOCRResult) / emptyRawResult(CardOCRResult) / failed(OCRError)` with `var isActive`. Deliberately NOT merged into the camera `State` or the S04 `CardRegionState` families: raw recognition starts only after P04 confirm, and retake returns to the scanner.
- Crop → OCR auto-wiring: there is no separate "start recognition" action. `confirmCrop()` awaits perspective correction and chains `beginRecognition(result)`; the DEBUG `.confirmed` crop fixture chains identically. While recognition runs, `cardRegion` stays `.confirmed(crop)` UNDERNEATH — the two families are independent (so the confirmed crop is never rolled back by OCR success/empty/failure).
- Stale-result guard: each `beginRecognition` captures a monotonic `recognitionGeneration`; `retake()` and `scannerDidDisappear()` increment it. A late result whose generation differs is discarded without touching UI state. Disappear invalidates an in-flight request but intentionally RETAINS an already-finished result.
- **Pre-Accept fix made during this increment (found by the gated workflow test):** `confirmCrop()` previously held `isCropInFlight` across the OCR await (a single `defer`), which made the recognition screen's 重拍 permanently un-tappable — contradicting the frozen design (retake is available in every recognition state and OCR has its own generation guard). The freeze now wraps perspective CORRECTION ONLY: set before `performCropConfirmation`, reset immediately after; OCR runs outside it. Double-confirm protection is unchanged (second tap still rejected while a correction runs; afterwards `.confirmed` has no draft so the guard rejects). All Increment 5 confirm/retake freeze tests still pass.
- Injection seam: `CardOCRProcessing` with a default `CardOCRProcessor()`; tests and DEBUG UI fixtures inject fakes.

### Transitional raw recognition UI (IMPLEMENTATION surface — Reference fidelity NOT ESTABLISHED)

The CamCard raw-text screen was NOT externally exposed/observed (spec/reference-tests.md T07). `RawRecognitionView` is therefore a minimal TRANSITIONAL IMPLEMENTATION surface, never a CamCard Reference page. Four states, full-screen overlay with priority over the lingering `.confirmed` crop screen (`ScanEntryView` ZStack): `.processing` (crop image + spinner "正在识别…"; no faked animation), `.rawTextAvailable` (image top ~36% + "原始识别文本" + ScrollView of `Text(rawText)` with system text SELECTION enabled — no TextField, never editable), `.emptyRawResult` ("未识别到文字" + explanation, no fabricated fields, no auto-return), `.failed` ("识别失败"). The ONLY action in every state is 重拍 (`scan-recognition-retake`) → existing P04 retake path (discards crop + recognition, restarts preview). No Save, no Repository, no P06/P07 navigation, no structured fields.

### DEBUG fixtures

`-SimCamCardOCR {success|empty|failure}` → DEBUG-only `DebugOCRProcessor` actor. Success returns 4 FIXED lines (`张伟` / `产品总监 | Product Director` / `+86 138 0013 8000` / `wei.zhang@zhiyuntech.com`, confidence 1.0) WITHOUT Vision; empty returns zero lines; failure throws `OCRError.recognitionFailed`. Entire surface `#if DEBUG`.

### Real Vision results (actual run, no fixture) — dataset detect→crop→OCR smoke

`OCRPipelineDatasetSmokeTests` runs the full REAL chain (`CardCropProcessor.prepare → perspectiveCorrect → CardOCRProcessor.recognize`) on in-repo dataset images (`#filePath`, no fixtures). Tests deliberately normalize for comparison (lowercase + strip whitespace) but the production contract does NOT normalize. Actual observed raw output:

- **card-001-standard-bilingual** — 10 lines: `上海智云科技有限公司` / `Shanghai Zhiyun Tech Co., Ltd.` / `张伟` / `Wei Zhang` / `产品总监 |Product Director` / `手机 Mobile：+86 138 0013 8000` / `电话 Tel： +86 21 5555 1234` / `邮稍 Email: wei.zhang@zhiyuntech.com` / `网址 Web：www.zhiyuntech.com` / `地址 Address：上海市浦东新区世纪大道100号 200120`. Note Vision MISREAD 邮箱 as "邮稍" with language correction OFF — preserved as-is; concrete evidence for the correction-off decision. Test anchors: contains 张伟; digit-only stream contains 13800138000; compact stream contains zhiyuntech.
- **card-004** — raw name line `张 伟` (Vision INSERTED a space — preserved; the test's whitespace normalization absorbs it) and `+86 138 0013 8000`. Anchors: 张伟 / 13800138000.
- **card-013-english-bio-photographed** — `Morningside` / `Secure Systems` / `Kevin Park` / `Solutions Architect` / `Mobile: +1 (646) 555-0113` / `Office: +1 (212) 555-0199` / `Web: www.mss-secure.com` / `Address: 305 Madison Ave, New York, NY 10165`. Anchors: compact contains kevin / park / mss-secure; digits contain 5550113.
- **Ground-truth discrepancy corrected:** prior working notes claimed card-013 depicted "Daniel Wu / stonepinebio.com". The ACTUAL image content is Kevin Park / Morningside Secure Systems / mss-secure.com / +1 (646) 555-0113. Tests anchor on the image's real content; the stale note was wrong.

Processor-level real-Vision tests (`CardOCRProcessorTests`): configuration contract (level/languages/detect/correction=false/no customWords — structure asserted without freezing Vision internals beyond these setters); rawText verbatim newline join; real recognition of a CoreText-rendered bilingual PNG (anchors 13800138000 / wei.zhang@zhiyuntech.com, test-only lowercase/whitespace normalization); textless white PNG → EMPTY result, no throw; invalid bytes → `.recognitionFailed`. (CoreText draws in native bottom-left coordinates on a fresh CGBitmapContext — no UIKit-style context flip, which would double-flip and garble glyphs.)

### Builds and tests (actual reruns)

- Debug build: PASS.
- Release build: PASS (`SWIFT_ACTIVE_COMPILATION_CONDITIONS` empty — the only definition is `DEBUG $(inherited)` on the Debug config; Release does not override). Release binary strings: ZERO matches for `SimCamCardOCR`, `DebugOCRProcessor`, `SimCamCardCrop`, `DebugCropProcessor`, `SimCamCardCamera`, `DebugCameraSessionController`; production `CardOCRProcessor`/`OCRConfiguration` and the `scan-recognition-*` identifiers DO ship.
- Unit tests: **160/160 PASS** (was 147; +13 = 5 CardOCRProcessorTests + 3 dataset OCR smoke + 5 ScanViewModel T07 workflow tests: auto-start processing→rawText with crop staying `.confirmed`, empty→`.emptyRawResult`, failure→`.failed(.recognitionFailed)`, retake-during-processing stale discard, scanner-disappear stale discard; the two stale tests use deterministic continuation gates with bounded `Task.yield()` waits — no sleep).
- UI tests: target total **23** (was 21; +2 new fixture tests; the Increment 5 confirm test was adapted 1:1 to the new auto-flow). Full sequential simulator run: 22/23 passed; the single failure was the PRE-EXISTING `testDeniedShowsStableFallbackWithoutSessionUI` timing out in the shared `closeScanner` existence wait under abnormal simulator load (a foreign QA simulator was booted on the machine; suite ran 857s vs ~90s normal; xcodebuild logged a 60s simulator-boot timeout). That path has no OCR involvement. Isolated rerun on a quiet simulator of the denied test + all three T07 tests: **4/4 PASS in 89.6s** — characterized as environmental flake, not a code regression. All T07 assertions passed in BOTH runs.
  - `testRawOCRSuccessFixtureShowsPreservedRawText`: root + raw text present; label contains 张伟 / +86 138 0013 8000 / wei.zhang@zhiyuntech.com verbatim; no 保存; 重拍 returns to `scan-camera-preview`.
  - `testRawOCREmptyFixtureShowsEmptyState`: `scan-recognition-empty` + "未识别到文字"; no raw-text block; not the failed id; no 保存; 重拍 returns.
  - `testCropConfirmFlowsIntoRawRecognitionWithoutHandles` (adapted Increment 5 test): confirm now lands on the recognition screen; all four handles and the editing boundary absent; 重拍 recovers.
- Validation screenshots (fixture-driven; manually opened and visually verified by AI — NOT human visual comparison): `ai/validation/2026-10-01-increment6-raw-ocr-fixture.png` (corrected synthetic card + 4 preserved lines), `ai/validation/2026-10-01-increment6-empty-ocr-fixture.png` (empty state). Fixture UI ≠ real Vision; real recognition is covered by the processor/dataset tests above.

### Boundary / concurrency audit

- No `@unchecked Sendable`, no `nonisolated(unsafe)`, no `Task.detached` (grep matches are explanatory comments only).
- No Vision types in ViewModel/View: `RecognizedTextObservation`/`RecognizeTextRequest` confined to `SimCamCard/OCR/` (the only other `import Vision` files are the pre-existing Detection services). `UIImage(data:)` in RawRecognitionView is a display adapter only.
- Model / Repository / spec / dataset / MockBusinessCards.swift / CardCropProcessor / CardRegionGeometry / AspectFitCoordinateMapper / project.pbxproj: unchanged. `BusinessCard.rawOCRText` (Week 2 optional, default nil) is NOT written by this increment — raw text lives only in `CardOCRResult`; the only `rawOCRText:` references remain pre-existing nil mocks.
- New files auto-included via filesystem-synchronized groups; no pbxproj edits. `git status` shows no `ai/prompts/_local/` path.

### Traceability

- T04 capture mechanics: PASS automated; capture → Crop: PASS; capture → OCR processing: PASS automated (auto-chain after confirm); structured capture → Recognition/Edit: NOT IMPLEMENTED (Week 4); T04 overall: PARTIAL.
- T05 import mechanics: PASS; import → Crop: PASS; import → OCR: same shared auto-chain; structured Recognition/Edit: NOT IMPLEMENTED; T05 overall: PARTIAL.
- T07 Swift-native Vision text request on the upright PNG: PASS automated (real Vision, processor tests).
- T07 cropped image → OCR: PASS automated (dataset smoke, real chain).
- T07 raw observation lines preserved verbatim (top-1, order kept, correction off): PASS automated; real-data caveats (邮稍 / 张 伟) recorded above.
- T07 raw text presented for copy (selection, not editing): PASS fixture-driven UI; Reference raw-text page NOT OBSERVED → Reference fidelity NOT APPLICABLE / NOT ESTABLISHED; this is explicitly a transitional implementation surface.
- T07 overall: **PASS (functional, automated)** on manually verified image↔GT-consistent cards (card-001, card-004, card-016); card-013's OCR smoke is BLOCKED by a broader pre-existing frozen dataset image/GT integrity issue (card-005, card-013, card-014 confirmed mismatched); dataset NOT modified; physical-device camera→EXIF→crop→OCR chain still PENDING real hardware; native PhotosPicker real-asset path still NOT INDEPENDENTLY VERIFIED.
- S05: processing state IMPLEMENTED; raw OCR transport (`processing` / raw / empty / failed foundation) IMPLEMENTED. Frozen structured states `structuredResultAvailable` / `missingFields` / `multiplePhoneFields` / `manualEditing`: NOT IMPLEMENTED (Week 4). `nonCardEmptyResult`: only the empty-RAW foundation exists — NOT the frozen structured behavior; must not be claimed as S05 acceptance. Cancelled/error path: IMPLEMENTED per actual behavior (`.failed` + 重拍).

### Human Decision

Accepted — 2026-10-02 (human review).

AI did not commit, merge or tag. Increment 7 not entered. Recommended commit message when accepted: `feat(ocr): 实现名片原始文本识别`.

## 2026-10-02 — Increment 6 Pre-Accept Correction (dataset integrity + actor reentrancy)

Baseline: 68d242c. This section amends Increment 6 before Accept; no commit made.

### Broader frozen dataset image/GT integrity issue

A broader pre-existing frozen dataset image/GT integrity issue was discovered during Increment 6. Confirmed mismatches include card-005, card-013 and card-014. Increment 6 did not modify dataset or ground truth.

**Manual re-verification of the primary four sources** (dataset/cards/card-013-english-bio-photographed.png, dataset/cards/card-014-missing-email-security.png, dataset/ground-truth/card-013.json, dataset/ground-truth/card-014.json):

| Source | Identity observed |
|---|---|
| card-013 PNG | Kevin Park / Morningside Secure Systems / +1 (646) 555-0113 |
| card-014 PNG | 何嘉怡 Jiayi He / 广州澜图文旅发展有限公司 (Chinese card) |
| card-013 GT | Daniel Wu / Stonepine BioSystems / +44 7700 900245 |
| card-014 GT | Kevin Park / Morningside Secure Systems / +1 (646) 555-0113 |

Additionally verified during replacement-candidate screening: **card-005 PNG shows 王敏 Min Wang / 星澜智能制造有限公司 (the card-010 GT identity), not the card-005 GT (Olivia Chen / North Harbor Analytics).** card-013's PNG contains the identity card-014's GT describes. This is a PRE-EXISTING FROZEN DATASET INTEGRITY ISSUE, not an OCR defect. The dataset was NOT modified; Kevin Park is NOT adopted as new card-013 ground truth.

**OCR functional smoke accounting** (only manually verified image↔GT-consistent cards count as real functional validation):

- card-001 standard bilingual: PASS
- card-004 minimal name+mobile: PASS
- card-016 English software engineer: PASS (replacement; PNG ↔ GT manually confirmed consistent)
- card-013 English bio: **DISABLED / BLOCKED BY FROZEN DATASET INTEGRITY ISSUE** (frozen image and GT do not correspond)

card-013's disabled placeholder documents the mismatch in `OCRPipelineDatasetSmokeTests`; card-001 and card-004 smokes remain unchanged. The dataset was NOT modified; spec/* untouched.

### Swift actor reentrancy correction

**CardOCRProcessor actor comment fixed:** Removed the false claim that "actor serializes access to at most one active recognition." The actor isolates processor state and keeps Vision types behind the boundary, but Swift actors are reentrant across await points — actor isolation alone does NOT prevent two `perform` calls from overlapping.

### Recognition Task ownership (calibrated wording)

**ScanViewModel owns at most one current recognition Task** (never Task.detached):

- Starting a new recognition cancels and supersedes the previously owned Task (`beginRecognition`: `recognitionTask?.cancel(); recognitionTask = nil`, increments generation, spawns new `recognitionTask = Task { ... }`).
- `retake`: increments generation, cancels task, nils it, sets `recognition = .inactive`.
- `scannerDidDisappear`: increments generation, cancels task, nils it (does NOT clear a settled result).
- The Task body captures its generation; all state writes are guarded by `generation == self.recognitionGeneration`.

**Responsibilities (calibrated):**
- recognitionGeneration guarantees that stale completion from an older recognition cannot mutate the current workflow state.
- Task cancellation does not establish that an already-running Vision request aborts immediately; underlying early-abort behavior remains framework-dependent.
- No semaphore / blocking queue added; existing retake / scannerDidDisappear cancellation and new-recognition-supersedes-old semantics unchanged.

### Stale A → new B deterministic test

Added `staleACannotOverwriteNewerB` to ScanViewModelTests:

1. OCR A starts (gated) → `.processing`, enteredCount=1.
2. Retake → cancels A, invalidates generation, recognition = .inactive.
3. Release A's gate → A completes but is discarded (state stays .inactive).
4. New capture → crop → confirm → OCR B starts on the SAME view model (same FakeOCRProcessor instance, enteredCount now 2).
5. Release B's gate → B completes → `.rawTextAvailable` with B's rawText.

Assertions: A cannot resurrect recognition; B owns final state; A entered once, B entered once. No sleep; deterministic via gates + bounded Task.yield.

### Updated test totals

Swift Testing actual runner output: **162 discovered; 161 executed; 161 PASS; 1 disabled/skipped**.

- **Baseline unit:** 147/147 PASS (unchanged from pre-Increment-6).
- **OCR processor unit:** 5/5 PASS (config contract / rawText verbatim / real Vision on rendered PNG / empty non-throwing / invalid bytes).
- **OCR dataset functional smoke:** 3/3 PASS (card-001 / card-004 / card-016); 1 disabled / BLOCKED (card-013 frozen dataset image/GT mismatch).
- **ScanViewModel T07 workflow:** 6/6 PASS (auto-start processing→rawText / empty→.emptyRawResult / failure→.failed / retake stale discard / disappear stale discard / stale A→B supersede).
- **Total accounting:** 147 + 5 + 3 + 6 = **161 executed and passing**; 1 disabled card-013 placeholder = **162 discovered**.

**UI tests:** 23 total scheme tests; T07 3-test regression (success/empty/confirm-flow) PASS (94.971s).

**Release build:** PASS; binary strings zero matches for SimCamCardOCR / DebugOCRProcessor / SimCamCardCrop / DebugCropProcessor / SimCamCardCamera / DebugCameraSessionController.

**Concurrency audit:** zero @unchecked Sendable / nonisolated(unsafe) / Task.detached; Vision types confined to SimCamCard/OCR/ (Detection files are pre-existing).

**Scope audit:** dataset/*, spec/*, Model/*, Repository/*, MockBusinessCards.swift, CardCropProcessor, CardRegionGeometry, AspectFitCoordinateMapper, project.pbxproj unchanged; no ai/prompts/_local/.

### card-016 real Vision output (new smoke card)

card-016-en-software-engineer.png → full chain (detect → perspectiveCorrect → OCR) → 7 lines:
`Michael Chen / Senior Software Engineer / CloudMatrix Inc. / +1 415 555 0199 / mchen@cloudmatrix.com / www.cloudmatrix.com / 500 Terry A Francois Blvd, San Francisco, CA 94158, USA`

Anchors verified: michael, chen, cloudmatrix, 14155550199 (digit-only).

### Human Decision

Accepted — 2026-10-02 (human review).

AI did not commit, merge or tag. Increment 7 not entered.

## 2026-10-02 — Week 3 Increment 7 Integration / Regression + Week 3 Freeze

Baseline: b0404e2 (`feat(ocr): 实现名片原始文本识别`). Scope = integration/regression only; production freeze maintained.

### Integration matrix

| # | Scenario | Result |
|---|----------|--------|
| A | Camera authorized | PASS (fixture-driven automated) |
| B | Camera denied | PASS (fixture-driven automated) |
| C | Camera request → allowed | PASS (fixture-driven automated) |
| D | Camera request → denied | PASS (fixture-driven automated) |
| E | Photo import success | PASS (fixture-driven automated) |
| F | Photo import cancel | PASS (fixture-driven automated) |
| G | Photo import load failure | PASS (unit tested) |
| H | live cardDetected | PASS (fixture-driven automated) |
| I | live cardNotDetected | PASS (fixture-driven automated) |
| J | camera capture → Crop | PASS (fixture-driven automated) |
| K | photo import → Crop | PASS (fixture-driven automated) |
| L | autoDetected Crop | PASS (fixture-driven automated) |
| M | manualAdjusting Crop | PASS (fixture-driven automated) |
| N | Crop confirm | PASS (fixture-driven automated) |
| O | Crop retake | PASS (fixture-driven automated) |
| P | Crop → raw OCR success | PASS (fixture-driven automated) |
| Q | Crop → raw OCR empty | PASS (fixture-driven automated) |
| R | Crop → raw OCR failure | PASS (fixture-driven automated) |
| S | recognition retake → Scanner | PASS (fixture-driven automated) |
| T | scanner exit while active | PASS (unit tested: disappearInvalidatesInFlightRecognition) |

**Explicit non-claims:** All UI integration results are fixture-driven. Real AVFoundation camera capture, native PhotosPicker runtime, and physical-device verification are NOT INDEPENDENTLY VERIFIED.

### New integration tests added

1. **testCameraWorkflowRunsThroughCropAndRawOCRThenRetakes** — full camera pipeline: authorized → preview → capture → Crop → confirm → Raw OCR → retake → preview → close. Fixture-driven.
2. **testPhotoImportWorkflowRunsThroughCropAndRawOCR** — photo import pipeline: authorized → 相册 → imported image → Crop → confirm → Raw OCR → retake → scanner. Fixture-driven.
3. **testOCRFailureShowsStableRecoveryAndRetake** — OCR failure recovery: Crop confirm → recognition failed → no raw text → no Save → 重拍 → scanner. Fixture-driven.

### Debug build

**PASS** — 0 compile errors, 0 Swift concurrency diagnostics. Xcode 27 / iOS 27.0 SDK / Swift 6.4 language mode 6.

### Release build

**PASS** — SWIFT_ACTIVE_COMPILATION_CONDITIONS empty for Release.

### Unit accounting

Swift Testing actual runner output: **162 discovered; 161 executed; 161 PASS; 1 disabled/skipped**.

- Baseline unit: 147/147 PASS (unchanged).
- OCR processor unit: 5/5 PASS.
- OCR dataset functional smoke: 3/3 PASS (card-001 / card-004 / card-016); 1 disabled / BLOCKED (card-013 frozen dataset image/GT mismatch).
- ScanViewModel T07 workflow: 6/6 PASS (auto-start processing→rawText / empty→.emptyRawResult / failure→.failed / retake stale discard / disappear stale discard / stale A→B supersede).

### UI accounting

**26 UI tests total; 26/26 PASS in one full run** (418.948s, fixed UDID 5B32D815-5F37-4EE0-825C-85DE864E0B02, sequential).

- Increment 6 baseline: 23 tests.
- Increment 7 added: 3 integration tests (camera E2E / photo-import E2E / OCR failure recovery).
- Previously flaky `testDeniedShowsStableFallbackWithoutSessionUI`: PASS in this clean run.

### Dataset smoke

- card-001 standard bilingual: PASS (real Vision).
- card-004 minimal name+mobile: PASS (real Vision).
- card-016 English software engineer: PASS (real Vision; PNG ↔ GT manually verified consistent).
- card-013 English bio: **DISABLED / BLOCKED BY FROZEN DATASET INTEGRITY ISSUE** (frozen image and GT do not correspond; dataset NOT modified).

### Fixture isolation audit

Release binary strings: **0 matches** for SimCamCardCamera / DebugCameraSessionController / SimCamCardPhotoImport / SimCamCardDetection / DebugVideoFrameProcessor / SimCamCardCrop / DebugCropProcessor / SimCamCardOCR / DebugOCRProcessor.

Production symbols present as expected: CameraSessionController (3), CardCropProcessor (2), CardOCRProcessor (2), OCRConfiguration (1).

### Architecture audit

- View → presentation + user intent only.
- ScanViewModel → workflow ownership (@MainActor).
- CameraSessionController → AVFoundation session (custom serial executor).
- VideoFrameProcessor / CardRegionDetector → live Vision rectangle (dedicated detection queue).
- CardCropProcessor → still decode/orientation/perspective correction (dedicated isolation).
- CardOCRProcessor → raw text Vision (actor).
- **No Vision types in SwiftUI View.** Detection files (VideoFrameProcessor, CardRegionDetector) legitimately use Vision for rectangle detection; OCR confined to SimCamCard/OCR/.
- **No AVCaptureSession logic in View.**
- **No UIImage source-of-truth in processor** (Data-based).
- **No Repository save from ScanViewModel.**
- **No BusinessCard creation in OCR/Crop.**

### Concurrency audit

- **Zero** `@unchecked Sendable` / `nonisolated(unsafe)` / `Task.detached` in production code.
- `recognitionGeneration` stale guard: ACTIVE.
- `recognitionTask` ownership: IMPLEMENTED (ScanViewModel owns at most one current recognition Task).
- Task cancellation does not claim guaranteed immediate termination of an already-running Vision request; underlying Vision early-abort behavior remains framework-dependent.

### State-family ownership audit

Four state families remain independent:
- S02 camera state (permissionUnknown/permissionDenied/preview/cardNotDetected/cardDetected/captured/cancelled)
- S03 photoImport state (idle/pickerPresented/imageSelected/cancelled)
- S04 cardRegion state (inactive/autoDetected/manualAdjusting/confirmed/retakeRequested)
- raw RecognitionState (inactive/processing/rawTextAvailable/emptyRawResult/failed)

No cross-contamination observed. Full path: preview → captured/imageSelected → crop → confirmed → recognition processing → raw/empty/failed. Retake path: recognition/crop → retakeRequested → preview.

### Shared still pipeline audit

Camera capture and Photo Import both enter the same pipeline:
`CapturedPhoto → CardCropProcessor.prepare → CropDraft → perspectiveCorrect → CardCropResult → CardOCRProcessor`

No duplicate camera/import OCR pipelines exist.

### Original / processed image audit

- `CapturedPhoto.data` = original source bytes (never overwritten).
- `CardCropResult.processedImageData` = upright perspective-corrected PNG.
- OCR **ONLY consumes processedImageData**; original image is never OCR'd.

### Raw OCR audit

Raw observations → top-1 candidate → surrounding trim only → OCRLine[] → newline-joined rawText.

**Forbidden and confirmed absent:** phone normalization, email correction, field classification, semantic reorder, structured extraction.

### Scope diff audit

Production code changes: 0.

Increment 7 working-tree artifacts:
- SimCamCardUITests/ScanCameraUITests.swift
- ai/changes.md
- ai/validation/2026-10-02-increment7-camera-to-raw-ocr.png
- ai/validation/2026-10-02-increment7-import-to-raw-ocr.png

dataset/*, spec/*, Model/*, Repository/*, MockBusinessCards.swift, CardCropProcessor, CardRegionGeometry, AspectFitCoordinateMapper, project.pbxproj unchanged. No ai/prompts/_local/.

### Frozen spec/data audit

- spec/*: UNCHANGED
- dataset/*: UNCHANGED
- Model/*: UNCHANGED
- Repository/*: UNCHANGED
- MockBusinessCards.swift: UNCHANGED

### Reference traceability

#### T03 Camera Permission
- allowed: PASS fixture-driven automated
- denied: PASS fixture-driven automated
- notDetermined → granted: PASS fixture-driven automated
- notDetermined → denied: PASS fixture-driven automated
- real iOS system camera permission dialog: NOT INDEPENDENTLY VERIFIED / no physical device
- **T03 overall: PARTIAL**

#### T04 Capture
- capture mechanics: PASS fixture/automated
- capture → still image → Crop: PASS
- Crop → perspective correction: PASS
- Crop → Raw OCR: PASS
- structured Recognition/Edit: NOT IMPLEMENTED
- physical camera: NOT INDEPENDENTLY VERIFIED
- **T04 overall: PARTIAL**

#### T05 Photo Import
- photo import presentation/state: PASS automated
- fixture selected image → Crop: PASS
- Crop → Raw OCR: PASS
- cancel: PASS
- load failure: PASS
- native PhotosPicker real selection: NOT INDEPENDENTLY VERIFIED
- structured Recognition/Edit: NOT IMPLEMENTED
- **T05 overall: PARTIAL**

#### T06 Boundary Detection
- live detection orchestration: PASS automated
- fixture overlay: PASS
- real dataset still rectangle detection: PASS
- Crop autoDetected: PASS
- manual adjustment: PASS
- confirm: PASS
- perspective correction: PASS
- physical live camera detection: NOT INDEPENDENTLY VERIFIED
- **T06 overall: PARTIAL**

#### T07 Raw OCR
- Swift-native Vision request: PASS real automated
- processed crop → OCR: PASS
- raw lines preserved: PASS
- rawText preserved: PASS
- empty result: PASS
- failure separated from empty: PASS
- verified dataset OCR: card-001 PASS, card-004 PASS, card-016 PASS
- card-013: BLOCKED / disabled for OCR identity validation
- raw-text Reference UI: NOT OBSERVED
- physical camera → crop → OCR: NOT INDEPENDENTLY VERIFIED
- **T07 functional requirement: PASS**

### S02 Camera/Scanner state coverage

- permissionUnknown: IMPLEMENTED
- permissionDenied: IMPLEMENTED
- preview: IMPLEMENTED
- cardNotDetected: IMPLEMENTED
- cardDetected: IMPLEMENTED
- captured: IMPLEMENTED
- cancelled: implementation/navigation coverage

### S03 Photo Import state coverage

- pickerPresented: IMPLEMENTED
- imageSelected: IMPLEMENTED
- cancelled: IMPLEMENTED
- photoPermissionRequired / photoPermissionDenied: NOT EXPLICITLY IMPLEMENTED (system PhotosPicker owns access semantics)

### S04 Card Region state coverage

- autoDetected: IMPLEMENTED
- manualAdjusting: IMPLEMENTED
- confirmed: IMPLEMENTED
- retakeRequested: IMPLEMENTED

### S05 Recognition state coverage

- processing: IMPLEMENTED
- raw OCR transport: IMPLEMENTED
- structuredResultAvailable: NOT IMPLEMENTED
- nonCardEmptyResult: NOT FULLY IMPLEMENTED (only raw-OCR foundation exists)
- missingFields: NOT IMPLEMENTED
- multiplePhoneFields: NOT IMPLEMENTED
- manualEditing: NOT IMPLEMENTED
- cancelled: 按当前 raw OCR recovery 行为记录

### Known limitations (Week 3 freeze)

1. No physical iPhone verification.
2. Real AVFoundation camera capture pending physical device.
3. Real live-camera rectangle alignment pending physical device.
4. Native PhotosPicker real-asset runtime not independently verified.
5. RawRecognitionView is transitional, not reference P05.
6. Structured extraction T08+ not implemented.
7. Confirmed pre-existing frozen dataset image/GT mismatches:
   - card-005
   - card-013
   - card-014

   card-013 OCR identity validation: DISABLED / BLOCKED.

   Dataset was not modified during Week 3.

   A complete 34-card image ↔ GT integrity audit is required
   after Week 3 freeze and before Week 4 T08–T11 structured-extraction
   validation.

### Week 3 freeze readiness criteria

| Criterion | Status |
|-----------|--------|
| Debug PASS | ✅ |
| Release PASS | ✅ |
| all executed unit tests PASS | ✅ (161/161) |
| exact skipped count documented | ✅ (1 disabled) |
| full UI suite clean PASS in one stable run | ✅ (26/26) |
| camera fixture E2E PASS | ✅ |
| photo-import fixture E2E PASS | ✅ |
| OCR failure recovery PASS | ✅ |
| real Crop/OCR dataset smoke PASS on valid cases | ✅ (card-001/004/016) |
| Release fixture isolation PASS | ✅ |
| concurrency audit PASS | ✅ |
| architecture audit PASS | ✅ |
| scope audit PASS | ✅ |
| no unintended production changes | ✅ |
| no frozen spec/data changes | ✅ |

**READY FOR WEEK 3 FREEZE**

### Recommended commit/merge/tag (for human decision)

**Increment 7 commit:**
```text
test(week3): 完成扫描与OCR集成回归
```

**Merge to main (after Accept):**
```bash
git switch main
git pull --ff-only
git merge --no-ff week3/camera-ocr -m "merge: 完成Week 3相机裁剪与OCR链路"
git push
```

**Tag (after merge + human verification):**
```text
week3-camera-ocr-baseline
```

### Human Decision

Accepted — 2026-10-02 (human review).

---

## Week 4 Increment 1 — Structured Extraction Core (2026-10-02)

### Baseline / scope

```text
baseline: e68f7c1 (tag: dataset-integrity-baseline), branch week4/structured-recognition
scope: CardOCRResult → deterministic local structured extraction → StructuredRecognitionResult
T08/T09/T10 parser core; T11 manual editing NOT implemented; no UI integration
```

### Architecture

New pipeline intermediate layer `SimCamCard/Recognition/` (NOT a Domain Model — no id,
no image references, no tags/notes, no persistence):

- `StructuredCardFields` — `name/company/jobTitle: String?`, `phones: [PhoneNumber]`
  (reuses the frozen domain `PhoneNumber.Kind` = mobile/office/fax/other; single phone
  source of truth, kind-filtered accessor only), `emails: [String]`, `website: String?`,
  `address: String?`, `unclassifiedText: [String]`. No nameLatin/companyLatin/department/
  languageProfile — frozen Domain unchanged; latin counterparts stay unclassified evidence.
- `StructuredRecognitionResult` — carries the unchanged `CardOCRResult` + fields; full
  traceability StructuredRecognitionResult → CardOCRResult → CardCropResult → CapturedPhoto.
- `CardFieldExtractor` / `CardFieldExtracting` — synchronous, pure, deterministic value-type
  parser (no suspension points, so the protocol is intentionally not async). Same input
  always yields the same output, including deterministic positional phone UUIDs.

### Parser strategy

Two phases over preserved raw lines:

1. **Phase A high-confidence typed fields**: email token regex (label-independent, so an OCR
   mis-read label like 邮稍 does not block a legal email token); website only via
   `www.`/`http://`/`https://` tokens with email ranges masked (bare domains never accepted);
   phone lines via bilingual label families (手机/移动/Mobile/Cell, 电话/座机/Tel/Phone/Office,
   传真/Fax; one-letter labels M:/T:/F: require a colon) plus an unlabelled pass; labelled
   address with deterministic continuation-line joining.
2. **Phase B semantic fields from remaining lines only**: company via frozen §18 suffix/
   keyword sets (native form preferred; `Solutions` deliberately excluded — it collides with
   the real title "Solutions Architect"), job title via §19 keyword sets (bilingual
   `中文 | English` line preserved), name from the last remaining candidates (2–4 CJK chars
   preferred, latin "Given Family" fallback; inline "何嘉怡 Jiayi He" → canonical CJK prefix,
   full line kept as evidence).

Value contract: internal normalized copies are used only for classification; returned values
preserve OCR case/punctuation/phone formatting; labels and surrounding whitespace removed.
Email exact-duplicates removed case-insensitively (first spelling kept); phones dedupe on
(kind, digit string); encounter order preserved; no first/last-wins collapse.

**Unlabeled phone classification:**

```text
- A phone with a reliable Mobile / Tel / Fax label is classified by
  that label.

- A generic unlabeled phone falls back to `.other`.

- A narrowly recognized explicit +86 Chinese mobile-number format is
  classified as `.mobile`.

This exception exists because the frozen card-004 reference contains an
unlabelled +86 mobile number while its Ground Truth semantics are
mobile.

This is a deterministic numbering-format heuristic, not dataset-ID
lookup and not inference from previously seen cards.
```

Test coverage retained for both branches: a generic unlabeled phone → `.other`, and
card-004's `+86 138 0013 8000` format → `.mobile`.

### Real Vision → structured smoke evidence (PNG → crop → OCR → extract)

- **card-001 (T08):** name `张伟`, company `上海智云科技有限公司`, title
  `产品总监 |Product Director`, mobile `+86 138 0013 8000`, office `+86 21 5555 1234`,
  email `wei.zhang@zhiyuntech.com`, website `www.zhiyuntech.com`, address
  `上海市浦东新区世纪大道100号 200120`; unclassified = EN company + `Wei Zhang`.
- **card-002 (T09):** website **nil** (email `lina.li@zhiyuntech.com` present, no URL token —
  never derived from email domain); name `李娜`, company `上海智云科技有限公司`,
  mobile `+86 139 1234 5678`, office `+86 21 6888 2468`, address extracted.
- **card-003 (T10):** three phones classified independently — mobile `+86 136 8888 1024`,
  office `+86 21 5666 7788`, fax `+86 21 5666 7799`; name `陈晨`; website/email/address ok.
  Note Vision split the bilingual title (`商务拓展经理丨` + separate `Business Development
  Manager`); parser honestly keeps the CN line as title and EN line unclassified.
- **card-004 (minimal):** name `张 伟` (Vision-inserted space preserved verbatim), exactly one
  phone `.mobile` `+86 138 0013 8000` (format rule), company/jobTitle/website/address nil,
  emails empty.

### T-status

```text
T08 structured extraction parser core: PASS (fixture + real card-001 smoke)
T09 missing-field parser core: PASS (real card-002 website nil; no email→website fabrication)
T10 multi-phone/fax parser core: PASS (real card-003 mobile/office/fax all correct)
T08/T09/T10 full reference workflow: PARTIAL (P05 structured Recognition UI, RecognitionState
    structuredResultAvailable, T11 manual correction, save/repository still not implemented)
T11 manual correction: NOT IMPLEMENTED (Week 4 later increment)
S05: processing + raw OCR transport already implemented; structuredResultAvailable /
    nonCardEmptyResult UI / missingFields / multiplePhoneFields UI / manualEditing still NOT
    IMPLEMENTED — this increment builds their data foundation (empty OCR → empty fields proven)
```

### Verification

```text
Debug build: PASS
Release build: PASS (generic iOS Simulator destination, /tmp/w4i1-dd-release)
Unit: 187 discovered / 187 executed / 187 PASS / 0 disabled
  (baseline 162 + 21 CardFieldExtractor fixture tests incl. 17b card-004 format rule
   + 4 real-pipeline StructuredExtractionDatasetSmokeTests card-001..004)
UI: 26/26 PASS, one sequential run, iPhone 18 Pro id 5B32D815-5F37-4EE0-825C-85DE864E0B02,
    parallel testing disabled (no UI/DEBUG fixture added this increment)
```

### Audits

```text
dataset/* diff: empty (read-only in tests)
spec/* diff: empty
SimCamCard/Model (incl. BusinessCard) diff: empty
SimCamCard/Repository diff: empty
ScanViewModel diff: empty
RawRecognitionView diff: empty
project.pbxproj diff: empty (filesystem-synchronized groups)
scope: only new SimCamCard/Recognition/ (3 files) + SimCamCardTests/Recognition/ (2 files)
       + this changes.md
concurrency: no @unchecked Sendable, no nonisolated(unsafe), no Task.detached;
             parser is a nonisolated pure value type, no Vision type leaks past OCR boundary;
             no network/LLM/cloud/randomness, no dataset-ID knowledge in production
raw OCR preservation: StructuredRecognitionResult.ocrResult == input asserted; rawText never
                      mutated/regenerated; Vision mis-reads never corrected by parser
```

### Known limitations

1. Structured parser is deterministic heuristic extraction, not semantic AI; it can fail on
   layouts/labels outside the keyword sets.
2. Real OCR errors propagate into extraction (e.g. `邮稍`, split bilingual titles, inserted
   spaces) — parser classifies, it does not correct OCR.
3. nameLatin / companyLatin are not frozen Domain fields; they survive only as
   `unclassifiedText` evidence.
4. P05 structured Recognition/Edit UI is not implemented (Increment 2 target).
5. T11 manual correction is not implemented (Increment 3 target).
6. No BusinessCard creation / save / repository integration yet; RecognitionState is
   unchanged (raw-only family).
7. Unlabelled Chinese mobile auto-classification is a deliberately narrow
   numbering-format heuristic (documented under Parser strategy), not a general
   number-type guesser; it has been reviewed and accepted as-is for this increment.
8. Structured extraction currently assigns deterministic synthetic `PhoneNumber`
   IDs so repeated extraction results remain semantically stable and `Equatable`.
   These IDs belong only to the structured intermediate result. A later
   final-record / `BusinessCard` creation step must not treat these positional
   synthetic IDs as persisted domain identity; persisted `PhoneNumber` values
   must receive final domain-appropriate identifiers when the corrected record is
   materialized. This increment performs no `BusinessCard` creation and no
   Repository save, so this is not a current blocker.

### Human Decision

Accepted — 2026-10-02 (human review)

## Week 4 Increment 2 — Structured State Integration + P05 (2026-10-02)

### Baseline / scope

```text
baseline: fc64e3d, branch week4/structured-recognition
scope: OCR → Structured Extraction → S05 structured state → P05 structured
       recognition form (read-only)
NO manual editing / NO T11 / NO Save / NO BusinessCard creation /
NO Repository write / NO P06
```

### State transition design

`RecognitionState` (S05) replaced the raw-only family:

```text
before: inactive / processing / rawTextAvailable / emptyRawResult / failed
after:  inactive / processing / structuredResultAvailable /
        nonCardEmptyResult / missingFields / multiplePhoneFields / failed
```

- `rawTextAvailable` / `emptyRawResult` deleted. Raw OCR is NOT dropped:
  every settled state carries `StructuredRecognitionResult`, which embeds the
  unchanged `CardOCRResult` (full chain result → OCR → crop → capture).
- The transitional raw-text page is removed: `RawRecognitionView.swift` →
  `git mv` → `RecognitionView.swift`; no `scan-recognition-raw-text` block.
- Retake/reset from any settled state returns to the Scanner preview;
  `recognitionGeneration` still discards stale async completions; OCR failure
  maps to `failed(OCRError)` with stable recovery (unchanged contract).

### Structured classification priority (fixed, deterministic)

```text
1. nonCardEmptyResult      — no canonical contact field at all
2. missingFields           — some present, but ≥1 canonical category missing
3. multiplePhoneFields     — none missing, and mobile+office+fax all present
4. structuredResultAvailable — otherwise complete
```

nonCardEmptyResult behavior: a textless/non-card image yields a legitimate
empty structured result rendered as an empty P05 form — NOT an OCR failure
and NOT the `failed` state.

### CardFieldExtractor injection

`ScanViewModel` composes `CardFieldExtracting` (protocol) alongside the
existing `CardOCRProcessing`; production wires `CardFieldExtractor()`, tests
and DEBUG fixtures inject fakes. After OCR succeeds, extraction runs on the
preserved raw lines and the settled state is classified by the fixed priority
above. One in-flight recognition per ScanViewModel; new recognition cancels
and supersedes the previous one (generation-guarded).

### P05 structured recognition form (read-only)

- `RecognitionView` (ZStack black, `scan-recognition-form`): one shared
  `formContent` for all four settled structured states; fixed-order rows
  姓名/手机/工作电话/工作传真/其他电话/工作邮箱/公司/职位/首页/公司地址.
  Row-existence policy is deliberately narrow:
  * **website** — the ONLY scalar row whose existence is data-driven:
    the row exists only when website != nil (Reference card-b evidence).
  * **phones / emails** — one row per actual array element (unchanged).
  * **name / company / jobTitle / address** — fixed structural rows always
    present; a nil value renders an empty-but-present row. Their
    missing-row behavior is NOT claimed until dedicated Reference
    evidence exists.
- **Reference recheck (2026-10-03, post tech-review):** re-opening only
  `REF-recognition-03-card-b-top.png` / `REF-recognition-04-card-b-bottom.png`
  resolved the earlier contradictory notes. card-b's form rows are
  姓名/手机/工作电话/工作邮箱/公司/职位(+latin pair)/公司地址 — the 首页 row is
  **entirely absent (ROW ABSENT, answer A)**, not present-empty.
  card-002 `website == nil` → no 首页 row. No fabrication is possible:
  no inferred URL, no "N/A", no "未识别". The earlier note
  "card-b missing website: 首页 row remains visible with an empty value" was
  wrong; the authoritative Reference behavior is **row omitted entirely**.
  **Narrowing correction (2026-10-03):** the omission rule is scoped to
  website only — card-b evidence must NOT be generalized to name/company/
  jobTitle/address. Those scalar rows are fixed structural rows whose
  nil values render empty rows; their missing-row presentation remains
  deliberately unclaimed until corresponding Reference evidence exists.
  nonCardEmptyResult retains the conservative structure (fixed scalar rows
  present-empty; website/phone/email rows absent); T20 full empty-card
  visual fidelity remains PARTIAL / pending dedicated evidence.
- Read-only boundary: no editing controls, no 保存 button, no navigation to
  any edit page; only 重拍 (`scan-recognition-retake`).
- Accessibility IDs: `scan-field-mobile-N` / `scan-field-office-N` /
  `scan-field-fax-N` / `scan-field-other-phone-N` / `scan-field-email-N`.
  N is a **per-kind index** (each kind counts from 0 in stored order).
  Verification caught and fixed a real defect where the global phones-array
  index was used (card-001 office would surface as `scan-field-office-1`),
  breaking the per-kind contract the UI tests assert; parser output was
  independently triple-verified correct and was not the cause.
- P05 reference evidence used: the six Week-3 reference recognition shots
  plus the edit reference reviewed at increment start; layout follows the
  reference label→value column form.
- Raw OCR preservation: asserted by tests — the settled state's embedded
  `ocrResult` is identical to the OCR output; nothing mutates/regenerates
  rawText.

### Verification

```text
Debug build: PASS
Release build: PASS (generic/platform=iOS, /tmp/w4i2-dd-release, CODE_SIGNING_ALLOWED=NO)
Unit: 199 discovered / 199 executed / 199 PASS / 0 disabled
      (baseline 187 + 12 ScanViewModel structured-state tests)
UI: 28/28 PASS, one sequential run,
    iPhone 18 Pro id 5B32D815-5F37-4EE0-825C-85DE864E0B02,
    -parallel-testing-enabled NO
    (baseline 26 + new missing + multiple structured UI tests)
Dataset smoke (real Vision): Crop 0.371s / OCR 2.429s /
    Structured extraction 3.057s — all PASS (card-001..004)

Post-Review Reference recheck (2026-10-03):
- targeted T09 test (renamed testStructuredMissingFieldFixtureOmitsWebsiteRow)
  + nonCardEmptyResult test: PASS (2/2)
- full UI suite rerun after the row-omission narrowing correction:
  28/28 PASS / 0 failed (ScanCameraUITests 19/19)
- Debug build: PASS, Release build: PASS
- Release DEBUG fixture isolation rechecked: 8/8 ABSENT
- unit tests / dataset smoke NOT rerun: no parser / state-machine / dataset
  / ViewModel logic changed (presentation-only fix in RecognitionView).
- missing-field PNG unchanged (card-b UI unaffected by the narrowing).
```

### Release fixture isolation

Release binary strings check — all ABSENT (re-verified after the rebuild):

```text
SimCamCardOCR, DebugOCRProcessor, DebugCameraEnvironment,
SimCamCardCamera, SimCamCardDetection, SimCamCardCrop,
SimCamCardPhotoImport, DebugCameraFakes
```

### Audits

```text
dataset/* diff: empty
spec/* diff: empty
SimCamCard/Model/BusinessCard.swift diff: empty
SimCamCard/Repository diff: empty
SimCamCard/Recognition (core) diff: empty (frozen Increment 1 files untouched)
project.pbxproj diff: empty

logical scope:
  production/test logical changes:
    - DebugCameraFakes.swift
    - RecognitionView.swift (rename from RawRecognitionView.swift)
    - ScanEntryView.swift
    - ScanViewModel.swift
    - ScanViewModelTests.swift
    - ScanCameraUITests.swift
  documentation:
    - ai/changes.md
  evidence:
    - 3 PNGs under ai/validation/

concurrency: no @unchecked Sendable, no nonisolated(unsafe), no Task.detached;
             extractor is a nonisolated pure value type injected by protocol;
             recognition stays generation-guarded on @MainActor ScanViewModel
```

### Screenshots produced (fixture-driven; NOT real camera, NOT real Vision)

```text
ai/validation/2026-10-02-w4i2-structured-recognition.png (card-001 full form)
ai/validation/2026-10-02-w4i2-missing-field.png          (card-002 首页 row omitted)
ai/validation/2026-10-02-w4i2-multiple-phones.png        (card-003 手机/工作电话/工作传真)
```

### T-status

```text
T08 structured state + read-only field presentation: PASS
T09 missing-field state + demonstrated website omission: PASS
    (website == nil → 首页 row omitted entirely, per Reference card-b;
     no fabricated website / no N/A / no 未识别)
T10 multi-phone state + read-only field presentation: PASS

P05 full Reference fidelity: PARTIAL
Reason: manual editing and Save are intentionally deferred.
The Reference surface (名片全能王) includes 重新拍摄 + 编辑名片 + 保存;
Increment 2 delivers read-only recognition presentation + 重拍 only.

Only behavior directly supported by current missing-field Reference
evidence is asserted for fidelity. Website omission is confirmed by
card-b. Other scalar-field missing-row behavior remains deliberately
unclaimed until corresponding Reference evidence exists.

T08/T09/T10 full workflow: PARTIAL (T11 manual correction, Save, final record
    not implemented)
T11: NOT IMPLEMENTED
Save: NOT IMPLEMENTED
T20 empty-result visual fidelity: PARTIAL
    (nonCardEmptyResult retains conservative fixed structural rows;
     empty-card full fidelity pending dedicated Reference evidence)
```

### Known limitations

1. P05 fields are read-only in Increment 2.
2. No manual correction yet.
3. No Save / BusinessCard / Repository write.
4. Raw OCR remains preserved in state but is no longer exposed through the
   old transitional raw-text page.
5. UI tests use DEBUG fixtures; real camera/native picker claims remain
   unchanged (still NOT INDEPENDENTLY VERIFIED).
6. Parser remains deterministic heuristic extraction (Increment 1 limits
   unchanged); OCR errors propagate, no correction.

### Human Decision

Accepted — 2026-10-03 (human review)

---

## Week 4 Increment 3 — T11 Manual Editing

Baseline: `77dd1cd` feat(recognition): 集成结构化识别表单 (branch
`week4/structured-recognition`), clean tree. Increment 3 delivers the
corrected intermediate state ONLY — no Save, no BusinessCard
materialization, no Repository involvement.

### Three-layer separation (core invariant)

```text
1. Raw OCR           StructuredRecognitionResult.ocrResult
                     (CardOCRResult.lines + rawText) — never rewritten
2. Structured result StructuredRecognitionResult.fields — never mutated
3. Corrected draft   RecognitionDraft editable strings — this increment
```

`RecognitionDraft` keeps `let source: StructuredRecognitionResult`, so the
traceability chain always exists:

```text
draft → source → original structured fields
                → ocrResult.rawText / OCRLine[]
                → ocrResult.cropResult (original + processed image)
```

### RecognitionDraft design

NEW `SimCamCard/Recognition/RecognitionDraft.swift`

```swift
nonisolated struct RecognitionDraft: Sendable, Equatable {
    struct PhoneField: Identifiable, Sendable, Equatable {
        let id: Int          // stable edit-UI row identity (array position)
        let sourceID: UUID   // structured intermediate PhoneNumber.id
        let kind: PhoneNumber.Kind   // preserved, not editable this increment
        var value: String
    }
    struct EmailField: Identifiable, Sendable, Equatable {
        let id: Int
        var value: String
    }
    let source: StructuredRecognitionResult
    var name / company / jobTitle / website / address: String  // nil → ""
    var phones: [PhoneField]
    var emails: [EmailField]
}
```

- Structured `String?` → editable `String` (nil → "").
- `correctedFields: StructuredCardFields`: surrounding whitespace/newlines
  trimmed; blank scalar → nil; blank phone/email row → dropped from
  collection; phone kind preserved; phone rebuilt with `id: sourceID`;
  `unclassifiedText` carried through unchanged. Non-empty user content is
  preserved verbatim — no semantic correction (no phone reformatting, no
  email lower-casing).
- `hasChanges` = `correctedFields != source.fields`.
- Identity semantics stay INTERMEDIATE: `PhoneField.id` is edit-UI row
  identity; `sourceID` keeps the structured PhoneNumber.id; persisted
  domain identity is reprocessed in the later Save increment.

### manualEditing state (frozen S05)

`ScanViewModel.RecognitionState` gains
`case manualEditing(RecognitionDraft)` (included in `isActive`).
Intents: `beginManualEditing()`, `updateDraftName/Company/JobTitle/
Website/Address(_:)`, `updateDraftPhone(id:value:)`,
`updateDraftEmail(id:value:)`; all mutations funnel through one private
`mutateDraft` guard that acts only in `.manualEditing`. The View never
owns a second copy — SwiftUI Bindings route get/set through the
ViewModel intents.

`beginManualEditing()` accepted from the four settled states
(structuredResultAvailable / missingFields / multiplePhoneFields /
nonCardEmptyResult); stable no-op when already editing (draft kept);
ignored in inactive/processing/failed.

### Editing interaction (based on REF-edit evidence)

- Read-only P05 gains a trailing 编辑 entry (`scan-recognition-edit`)
  next to 重拍. Increment-2 read-only presentation and all its
  identifiers remain unchanged.
- manualEditing reuses the SAME layout, row order, metrics and
  data-driven row policy; value regions switch from Text to TextField;
  hidden marker `scan-recognition-manual-editing`.
- Tapping a row edits in place; native caret/tint; focused non-empty row
  shows the trailing gray × clear button (accessibilityLabel 清除) per
  REF-edit-02. Autocorrection / autocapitalization disabled.
- Editable existing fields: name, company, jobTitle, all existing phone
  values (kind kept), all existing email values, website (only when the
  source form had the row), address. No "add field" rows (out of scope).
- 重拍 in manualEditing discards the draft and returns to the scanner
  preview (unit + UI covered). Reference 保存/取消: Save is explicitly
  out of scope; discard maps to the existing 重拍 affordance.
- Edit identifiers: `scan-edit-name/company/job-title/website/address`,
  `scan-edit-mobile-0 / office-0 / fax-0 / other-phone-0` (per-kind
  index matching the read-only rows), `scan-edit-email-<id>`.

### Fixed T11 scenario (deterministic success fixture = card-001)

```text
name    张伟                 → 张伟 修正
company 上海智云科技有限公司  → 上海智云科技
mobile  +86 138 0013 8000   → +86 138 0013 8001
```

After correction: draft holds the new values;
`draft.source.fields` still holds 张伟 / 上海智云科技有限公司 /
+86 138 0013 8000; `draft.source.ocrResult.rawText` String content
remains unchanged. Unedited rows (office, email, website, address,
jobTitle) remain unchanged.

### Raw OCR preservation

Unit/model tests verify that the original StructuredRecognitionResult
and draft.source.ocrResult.rawText remain unchanged after manual edits.

UI tests separately verify that corrected values remain visible and
that unedited structured fields remain stable.

(No byte-level comparison is claimed; preservation is asserted on the
raw OCR String content and the structured source value.)

### Tests

```text
Unit: 238/238 PASS (baseline 199 + RecognitionDraftTests 21 + T11 VM 18),
      0 disabled / 0 skipped — Swift Testing, iOS Simulator (iPhone 18 Pro).
      Coverage: 4 settled-state entries into manualEditing; init
      preservation; name/company/phone-kind/email-surgical edits; blank
      scalar→nil; blank phone/email dropped; source result unchanged;
      raw OCR unchanged; hasChanges false→true; retake discards draft;
      nonCardEmpty entry; begin-twice stable no-op; intents ignored
      outside manualEditing; draft mapping/nil→""/order/Equatable/Sendable.
UI:   30/30 PASS (baseline 28 + 2):
      testManualCorrectionUpdatesRecognitionDraft
      testManualEditingRetakeReturnsToScannerPreview
      CJK typed via XCUITest typeText after the × clear; corrected values
      re-asserted through the TextField values; original strings asserted
      gone from the form.
Debug build:   PASS
Release build: PASS (generic/platform=iOS, /tmp/w4i3-release,
               CODE_SIGNING_ALLOWED=NO)
Release DEBUG fixture isolation: 8/8 ABSENT
  SimCamCardOCR / DebugOCRProcessor / DebugCameraEnvironment /
  SimCamCardCamera / SimCamCardDetection / SimCamCardCrop /
  SimCamCardPhotoImport / DebugCameraFakes → 0 string matches.
  (Short ASCII identifiers ≤15 bytes, e.g. scan-edit-name, are inlined
   by the Swift compiler as immediates and therefore do not appear as
   contiguous cstring bytes; this is normal release codegen, not a
   functional gate.)
```

### Scope audit

```text
NEW      SimCamCard/Recognition/RecognitionDraft.swift
NEW      SimCamCardTests/Recognition/RecognitionDraftTests.swift
MODIFIED SimCamCard/ViewModel/ScanViewModel.swift
MODIFIED SimCamCard/View/Scan/RecognitionView.swift
MODIFIED SimCamCardTests/ViewModel/ScanViewModelTests.swift
MODIFIED SimCamCardUITests/ScanCameraUITests.swift
EVIDENCE ai/validation/2026-10-03-w4i3-before-edit.png
         ai/validation/2026-10-03-w4i3-after-edit.png
DOC      ai/changes.md (this section)

Empty diff (verified): dataset/, spec/,
  SimCamCard/Model/BusinessCard.swift, SimCamCard/Repository/,
  SimCamCard.xcodeproj/project.pbxproj,
  SimCamCard/Recognition/StructuredCardFields.swift,
  SimCamCard/Recognition/CardFieldExtractor.swift
```

New files are picked up by the existing
`PBXFileSystemSynchronizedRootGroup`; project.pbxproj untouched.

### Screenshots produced (fixture-driven; NOT real camera, NOT real Vision)

```text
ai/validation/2026-10-03-w4i3-before-edit.png
    read-only P05 (重拍 + 编辑), original extracted values
ai/validation/2026-10-03-w4i3-after-edit.png
    manualEditing form, 张伟 修正 / +86 138 0013 8001 with caret + × /
    上海智云科技; unedited rows unchanged
```

### T-status

```text
T08: PASS
T09: PASS
T10: PASS

T11 manual correction:
PASS

P05 full reference fidelity:
PARTIAL

Save:
NOT IMPLEMENTED

BusinessCard materialization:
NOT IMPLEMENTED
```

T11 PASS 依据:

```text
- RecognitionDraft separates source and corrected values
- manualEditing is owned by ScanViewModel
- name/company/phone corrections verified in UI
- source StructuredRecognitionResult preserved
- raw OCR preserved by unit/model tests
- retake discards draft
- correctedFields available as intermediate result
```

P05 full fidelity 继续 PARTIAL，因为当前尚未实现:

```text
- Save
- dedicated Cancel behavior
- adding new missing fields
- adding/removing phone/email rows
- full Reference Edit Card workflow
```

### Known limitations

1. Corrections stop at the corrected intermediate draft; nothing is
   persisted and no final BusinessCard exists yet.
2. No Save / 取消 affordance; discarding edits is only possible via
   重拍 (which also restarts the camera). Editing an already-saved card
   is out of scope.
3. Phone kinds are not editable; adding/removing/reordering phone or
   email rows and adding brand-new missing scalar fields are later
   increments (T11 covers correction of recognized existing fields).
4. Website row visibility while editing remains tied to the SOURCE form
   (present rows can be corrected/cleared; absent rows cannot be added).
5. correctedFields trims surrounding whitespace only; no value
   validation or semantic repair by design.
6. UI evidence is DEBUG-fixture-driven; real camera and real Vision OCR
   remain NOT INDEPENDENTLY VERIFIED. Native iOS callout/magnifier
   system chrome is not asserted.
7. Unit-test simulator runs required `CoreSimulator` service reset once
   during this increment (stale DTServiceHub "bless" failure after a
   hung earlier run); final results above are from clean reruns.

### Human Decision

Accepted — 2026-10-03 (human review)

---

## Week 4 Increment 4

Baseline: `ee633e1` (`feat(recognition): 实现名片识别结果人工修正`, branch
`week4/structured-recognition`).

Scope: T12 Save — final BusinessCard materialization + image asset storage +
repository save + P06 Save Result + Card Holder / Detail closure.

```text
RecognitionDraft.correctedFields
→ persist original + processed image assets (real bytes)
→ real image references on the card
→ final BusinessCard (BusinessCardMaterializer)
→ BusinessCardRepository.save()
→ SaveState.saveSucceeded (S06, separate state family)
→ P06 Save Result
→ 完成 → Card Holder reload → saved card row
→ saved card Detail
```

### Calibration (post technical review, same baseline ee633e1)

Three directed calibrations applied on top of the reviewed主体实现:

1. Direct save: `saveDraft()` (manualEditing-only) → `saveCurrentCard()`
   resolving a draft from ANY settled recognition state — a complete
   result no longer requires Edit before Save.
2. S05/S06 boundary: `saveSucceeded` removed from `RecognitionState`;
   new separate `SaveState` family (idle / saving / saveSucceeded).
   P06 ownership = `saveState.saveSucceeded` over the intact S05
   content.
3. Materialization extracted to `BusinessCardMaterializer` (pure
   deterministic mapping; fresh final phone UUIDs; injected refs +
   timestamp), and the read-only P05 top bar now offers 编辑 AND 保存
   together (manualEditing keeps 重拍 + 保存).

Kept unchanged: ImageAssetStore / InMemoryImageAssetStore, real image
bytes, P06 composition, Holder immediate refresh + real thumbnail,
Detail corrected fields, shared Repository / ImageAssetStore instances.

Second-round constraints (same review, same baseline):

4. Duplicate-save guard: `saveCurrentCard()` entry is exactly
   `guard saveState == .idle, !isSaveInFlight, let cardRepository,
   let imageStore else { return }` — after `.saveSucceeded` the settled
   S05 state stays as-is, so without the `saveState == .idle` clause a
   second tap WOULD re-enter; the clause makes it a no-op (regression
   test unit T12 9: repository contains exactly one new card).
5. Materializer fully deterministic: it performs NO implicit
   `UUID()` / `Date()` calls. The orchestration layer allocates the
   fresh final phone IDs (`corrected.phones.map { _ in UUID() }`) and
   injects them; the materializer signature takes `cardID`,
   `finalPhoneIDs: [UUID]`, `timestamp: Date` and precondition-checks
   1:1 alignment. Fixed-UUID tests verify same complete inputs → same
   BusinessCard.
6. `SaveState.saving` has real behavior coverage: a gated
   `GatedImageAssetStore` double suspends the first image save, and the
   test observes idle → (isSaveInFlight true, .saving, nothing
   persisted) → release → .saveSucceeded (isSaveInFlight false,
   repository + both assets present). All three SaveState cases are now
   covered.

### ImageAssetStore (new abstraction)

- `SimCamCard/Repository/ImageAssetStore.swift`:
  `nonisolated protocol ImageAssetStore: Sendable`
  (`save(reference:data:)` idempotent replace + `data(for:) -> Data?`),
  `actor InMemoryImageAssetStore`. Mirrors the BusinessCardRepository
  design: ViewModels/Views depend on the protocol, never a concrete store.
- The frozen Domain Model keeps REQUIRED String reference tokens
  (`originalImageReference` / `processedImageReference`) — never UIImage /
  Data; this store is the bridge between those tokens and the real bytes
  (`CardCropResult.original.data` + `processedImageData`).
- In-memory only this increment. On-disk persistence (T18, spec/data-model.md
  §Persistence rule) is introduced behind the same abstraction later —
  after relaunch the saved card is NOT retained (explicitly out of scope).

### ScanViewModel T12 save path

- NEW separate `SaveState` state family — `idle / saving /
  saveSucceeded(BusinessCard)` with `private(set) var saveState`.
  `saveSucceeded` was REMOVED from `RecognitionState`, which again
  expresses ONLY S05 (inactive / processing / structuredResultAvailable
  / nonCardEmptyResult / missingFields / multiplePhoneFields /
  manualEditing / failed). P06 screen ownership comes from
  `saveState.saveSucceeded` and takes priority over the S05 content,
  which stays intact underneath until 拍下一张 discards the workflow.
  No `.failed` case exists — the InMemory stores expose no failure API.
- New optional dependencies `cardRepository` / `imageStore`, injected from
  the App composition root (`SimCamCardApp` builds ONE shared
  `InMemoryBusinessCardRepository` + `InMemoryImageAssetStore` and passes
  them App → CardHolderView → ScanEntryView → ScanViewModel, DEBUG fixture
  path included). Optional so capture/crop/OCR/edit stay usable without
  persistence; only `saveCurrentCard()` requires both.
- `saveCurrentCard()` (renamed from `saveDraft()`): saves the CURRENT
  result — directly from ANY settled recognition state
  (structuredResultAvailable / missingFields / multiplePhoneFields /
  nonCardEmptyResult) WITHOUT requiring Edit first, or from
  manualEditing using the corrected draft. Chain: resolve the
  intermediate RecognitionDraft (edited buffer, or a fresh draft
  projected verbatim from the settled result — no fabrication) →
  persist original + processed image bytes FIRST so the references
  always resolve → materialize via `BusinessCardMaterializer` →
  `repository.save(card)` → settle `saveState = .saveSucceeded(card)`.
  No-ops: non-settled state, missing dependencies, `isSaveInFlight`
  (double tap), `saveState != .idle` (a settled save blocks a second
  save until 拍下一张 resets it).
- `captureNextAfterSave()`: 拍下一张 delegates to the shared retake path
  (recognition → inactive, crop → reset, scanner → preview; the saved
  card stays persisted), then resets `saveState → .idle`.
- `imageData(for:)`: View-layer read seam back to the injected store
  (P06 thumbnail). Nil store / unknown reference → nil → neutral slot,
  never a fabricated image.

### BusinessCardMaterializer (new, T12 calibration)

`SimCamCard/Recognition/BusinessCardMaterializer.swift` — pure
deterministic final-domain mapping, no I/O / state / clock and NO
implicit `UUID()` / `Date()` calls:

```text
RecognitionDraft + cardID + image references + timestamp +
finalPhoneIDs: [UUID]
    → BusinessCard
```

- Corrected-field projection via `draft.correctedFields` (blank scalars
  → nil, blank phone/email rows dropped, kinds preserved).
- Phone identity rule: the final record inherits ONLY kind + value;
  final IDs are the caller-injected `finalPhoneIDs` aligned by index
  (precondition: count == corrected phones). The orchestration layer
  allocates the fresh domain UUIDs; the draft's edit-row ids and the
  structured intermediate PhoneNumber.ids never leak into the persisted
  record.
- Determinism: identical complete inputs produce identical
  BusinessCards (fixed-UUID test).
- `rawOCRText` = original `draft.source.ocrResult.rawText`, untouched.
- `createdAt == updatedAt == timestamp` (injected).
- ScanViewModel keeps ONLY orchestration (resolve draft → allocate
  final IDs → save images → materialize → repository.save → SaveState).

### P06 Save Result (minimal fidelity, REF-save-01)

`RecognitionView.saveSucceededContent` (`scan-save-success`):

```text
✓名片保存成功 (centered title) + 完成 (top-right, scan-save-done,
    @Environment(\.dismiss) → pop Scanner → Holder)
summary strip (scan-save-summary): real processed-image thumbnail
    (scan-save-thumbnail, resolved via imageData(for:) from the card's
    persisted reference — proves references are real) + name
    (scan-save-name) + jobTitle + company
拍下一张 (bottom white capsule, scan-save-next → captureNextAfterSave)
```

Spec-excluded Reference elements NOT built (spec/page-inventory.md P06):
分组/备注/提醒/保存失败 action grid, VIP invite banner, 企业简介, 交换名片.

### Card Holder / Detail closure

- `CardHolderView.onAppear` reloads (`viewModel.loadCards()`) so 完成
  popping back immediately lists the saved card (T12 "new card immediately
  appears in holder").
- `BusinessCardRow(card:imageStore:)`: optional store → renders the card's
  REAL processed-image thumbnail (64×40, REF-card-holder-02-after-save.png
  has a thumbnail). No store / unresolved reference (Week 2 seed fixtures,
  Previews) → text-only row, no placeholder image (previous "no fabricated
  thumbnail" decision preserved for non-real assets).
- `CardDetailView` unchanged: REF-detail-01-collapsed header uses a surname
  avatar circle (previously documented fidelity gap), NOT the card image;
  T13 = structured fields visible, already satisfied. Tapping the saved
  row opens Detail with corrected name + unedited fields intact.

### Accessibility IDs (new)

```text
scan-recognition-save   保存 (read-only settled P05 alongside 编辑 AND
                        manualEditing top bar; disabled while
                        isSaveInFlight)
scan-save-success       P06 root marker
scan-save-done          完成
scan-save-next          拍下一张
scan-save-summary       summary strip
scan-save-thumbnail     strip thumbnail
scan-save-name          strip corrected name
card-row-thumbnail      holder row real thumbnail (only when resolved)
```

### Verification

```text
Debug build: PASS
Unit:
262 / 262 PASS
24 suites
0 failed
0 disabled
0 skipped
Swift Testing runner reports 262 total tests.
261 quoted display-name test lines were observed,
plus the existing unquoted template example() test.
UI: 33/33 PASS, 0 failed, one sequential run,
    iPhone 18 Pro id 5B32D815-5F37-4EE0-825C-85DE864E0B02,
    -parallel-testing-enabled NO
    (baseline 30 + testSaveFlowMaterializesCardIntoHolderAndDetail
     + testCaptureNextAfterSaveReturnsToFreshScanner
     + testStructuredResultCanSaveWithoutEditing)
Release build: PASS
Release DEBUG fixture isolation: 8/8 ABSENT
    (SimCamCardOCR, DebugOCRProcessor, DebugCameraEnvironment,
     SimCamCardCamera, SimCamCardDetection, SimCamCardCrop,
     SimCamCardPhotoImport, DebugCameraFakes)
Release production id present: scan-recognition-save (1)
```

Calibration iteration note: the first post-calibration full UI run had
3 failures — two OBSOLETE pre-calibration assertions ("no Save in the
P05 read-only increment" on the success/empty fixtures, exactly the
behavior this calibration introduces) plus the new direct-save test
missing its scan-crop-confirm tap. All three were fixed (assertions
inverted to require 保存 alongside 编辑; confirm tap added); the three
tests passed in isolation (28s / 26s / 18s) and the final full UI
number above is one clean sequential run with zero failures. No
disabled / skipped tests anywhere.

### Screenshots produced (fixture-driven; NOT real camera, NOT real Vision)

```text
ai/validation/2026-10-03-w4i4-p06-save-success.png
    P06: ✓名片保存成功 + 完成 + summary strip (real thumbnail,
    张伟 修正 / 产品总监 | Product Director / 上海智云科技有限公司)
    + 拍下一张 capsule; excluded items absent
ai/validation/2026-10-03-w4i4-holder-after-save.png
    名片夹 with the saved card row (real thumbnail + corrected name)
ai/validation/2026-10-03-w4i4-detail-saved-card.png
    Detail: corrected name 张伟 修正 + unedited structured fields
    (phones / email / website / address)
ai/validation/2026-10-03-w4i4-direct-save-ready.png
    read-only P05 top bar with 重拍 | 编辑 | 保存 all present
    (direct-save entry point; calibration evidence)
```

### T-status

```text
T08: PASS
T09: PASS
T10: PASS

T11 corrected value reaches final BusinessCard:
PASS (manualEditing draft → saveCurrentCard → corrected values on the
      final record; raw OCR + structured source untouched)

T12 Save:
PASS
- direct save without edit (all four settled states resolvable;
  structuredResultAvailable + missingFields covered by dedicated unit
  tests, structuredResultAvailable by a dedicated UI test)
- corrected save after manual edit

T13 saved card Detail:
PASS (corrected fields visible; holder-resolved full BusinessCard,
      no second fetch)

T18 persistence across relaunch:
NOT IMPLEMENTED (in-memory repository + image store this increment;
                 disk persistence behind the same abstractions later)

P06 required-scope fidelity:
PASS (✓名片保存成功 / 完成 / real-thumbnail summary strip / 拍下一张)

P06 full Reference surface:
PARTIAL (分组/备注/提醒/保存失败 grid, VIP invite, 企业简介, 交换名片
         are spec-excluded)
```

T12 PASS 依据:

```text
- corrected draft materializes into a final BusinessCard (unit T12 1;
  BusinessCardMaterializerTests cover the pure mapping directly)
- original + processed image assets persisted byte-exact under real
  references (unit T12 2, UI P06/holder thumbnails render real bytes)
- rawOCRText preserved on the saved card (unit T12 3 + materializer
  test)
- blank corrections projected (nil/dropped) (unit T12 4 + materializer
  test)
- complete structured result saves DIRECTLY without Edit (unit T12 6)
- missingFields result saves directly WITHOUT fabrication (unit T12 7)
- final phone identities are FRESH domain UUIDs — kind + value
  inherited, intermediate ids never leak (unit T12 8 covers the
  ViewModel-allocated ids; materializer tests cover injected fixed ids
  + same-inputs/same-output determinism)
- no-dependency / non-settled saves are no-ops (unit T12 5)
- exactly-once settle: saveState blocks a second save until 拍下一张
  (unit T12 9; a second saveCurrentCard() at .saveSucceeded is a no-op
  and the repository holds exactly one new card)
- idle → saving → saveSucceeded transition with isSaveInFlight toggling
  true-then-false, gated at the image store (unit T12 11)
- materializer determinism: same complete inputs → same BusinessCard;
  final IDs are injected, never implicitly generated (BusinessCard-
  MaterializerTests, fixed UUIDs)
- read-only P05 offers 编辑 AND 保存 together (updated
  testStructuredRecognitionSuccessShowsP05Fields /
  testStructuredEmptyFixtureShowsEmptyP05WithoutFailure + new
  testStructuredResultCanSaveWithoutEditing)
- P06 → 完成 → holder immediately lists the saved card (UI tests 1/3)
- holder row → saved card Detail shows corrected fields (UI test 1)
- 拍下一张 → saveState idle + fresh scanner; card stays saved (unit
  T12 10, UI test 2)
```

### Known limitations

1. Persistence is in-memory: a full quit + relaunch loses saved cards and
   image assets (T18 deferred behind the same Repository/ImageAssetStore
   abstractions).
2. Holder rows show real thumbnails only for cards saved this session;
   Week 2 seed fixtures / Previews stay text-only (no fabricated images).
3. Detail header keeps the documented fidelity gaps (avatar circle, card
   image strip, action grid, grouping/notes/export rows) — unchanged.
4. P06 is minimal fidelity by scope decision; the summary strip is not
   tappable (Detail is reached via the Holder after 完成).
5. UI evidence is DEBUG-fixture-driven; real camera, real Vision OCR and
   physical-device save remain NOT INDEPENDENTLY VERIFIED.

### Audits

```text
dataset/* diff: empty
spec/* diff: empty
evidence/* diff: empty
SimCamCard/Model/BusinessCard.swift diff: empty
SimCamCard/Repository/BusinessCardRepository.swift diff: empty
SimCamCard/Repository/InMemoryBusinessCardRepository.swift diff: empty
project.pbxproj diff: empty (PBXFileSystemSynchronizedRootGroup picks up
    the four new Swift files automatically)

logical scope:
  production:
    - SimCamCard/Repository/ImageAssetStore.swift (NEW)
    - SimCamCard/Recognition/BusinessCardMaterializer.swift (NEW)
    - SimCamCard/ViewModel/ScanViewModel.swift
    - SimCamCard/View/Scan/RecognitionView.swift
    - SimCamCard/View/Scan/ScanEntryView.swift
    - SimCamCard/View/CardHolder/CardHolderView.swift
    - SimCamCard/View/CardHolder/BusinessCardRow.swift
    - SimCamCard/App/SimCamCardApp.swift
    - SimCamCard/Camera/Debug/DebugCameraFakes.swift (DEBUG-only)
  tests:
    - SimCamCardTests/Repository/InMemoryImageAssetStoreTests.swift (NEW)
    - SimCamCardTests/Recognition/BusinessCardMaterializerTests.swift (NEW)
    - SimCamCardTests/ViewModel/ScanViewModelTests.swift
    - SimCamCardUITests/ScanCameraUITests.swift
  documentation:
    - ai/changes.md
  evidence:
    - 4 PNGs under ai/validation/

untracked files (sole source of truth: `git status --short`,
2026-10-03 final run): 4 Swift + 4 PNG = 8
    Swift: ImageAssetStore.swift, BusinessCardMaterializer.swift,
           InMemoryImageAssetStoreTests.swift,
           BusinessCardMaterializerTests.swift
    PNG:   w4i4-p06-save-success / w4i4-holder-after-save /
           w4i4-detail-saved-card / w4i4-direct-save-ready

concurrency: ImageAssetStore read seam is protocol + async; the in-memory
    store is an actor (no @unchecked Sendable, no nonisolated(unsafe),
    no Task.detached); isSaveInFlight is MainActor-owned UI state.
```

### Human Decision

Human Decision:
Accepted — 2026-10-04 (human review)

---

## Week 4 Increment 5 — Existing-Card Editing

### Baseline

```text
branch: week4/structured-recognition
HEAD:   a54560b (feat(scan): 完成名片保存与结果闭环)
working tree at start: clean
regression baseline: Unit 262/262 PASS · UI 33/33 PASS ·
  Debug PASS · Release PASS · Release fixture isolation 8/8 ABSENT
```

### Reference observations（frozen evidence，未改动）

- `REF-detail-03-after-edit-expanded.png` — 编辑入口 = 动作条最右侧的青色圆形
  铅笔图标「编辑」（在「电话 / 地址 / 备注」之后）；保存返回后仍停留在同一名片详情，
  头部立即显示「张伟 / 高级产品总监 | Senior Product Director /
  上海智云科技有限公司」，展开区公司块内职位同样为更正后的标题。
- `REF-edit-01-before-change.png` — 编辑页标题「编辑名片」；左上「取消」、
  右上青色「保存」；顶部为名片图像条。表单顺序：姓名 → 手机（+8613800138000）→
  工作电话（+862155551234）→ 添加电话 → 工作邮箱（wel.zhang@zhiyuntech.com）→
  添加邮箱 → 公司 → 部门 → 职位（产品总监 | Product Director）→ 英文公司/部门行。
- `REF-edit-02-after-title-change.png` — 职位行已改为
  「高级产品总监 | Senior Product Director」，聚焦态右侧有内联 × 清除；
  下方顺序为 首页（www.zhiyuntech.com）→ 公司地址
  （中国 上海市 浦东新区世纪大道 100号 200120）。
- Reference 中存在但冻结领域模型没有对应字段、本 Increment 不伪造的内容：
  部门、英文双语公司/部门行、添加电话/邮箱/URL/地址/公司信息/更多信息/背面、
  按公司排序行、电话/地址快捷动作、收藏星/更多、未分组/备注（T16）、
  向对方递名片/分享名片/存入通讯录。
- T14 固定更正：`产品总监 | Product Director` →
  `高级产品总监 | Senior Product Director`。
- 实现形态：编辑表单以 sheet 呈现（Brief §33 允许的 Detail 下最小实现），
  复刻 Reference 的页标题、取消/保存位置、字段顺序与聚焦 × 清除；
  表单字段集严格等于冻结 BusinessCard 的可编辑字段：
  姓名 → 手机/工作电话/工作邮箱 → 公司 → 职位 → 首页 → 公司地址。

### BusinessCardEditDraft 设计（新增 `SimCamCard/Edit/BusinessCardEditDraft.swift`）

- `nonisolated struct BusinessCardEditDraft: Sendable, Equatable`，
  `let source: BusinessCard` + 7 组可编辑字段（name/company/jobTitle/
  phones/emails/website/address）。
- 与 `RecognitionDraft` 刻意分离：`RecognitionDraft.source =
  StructuredRecognitionResult`；已保存卡重编不应伪造 CardOCRResult /
  CardCropResult / StructuredRecognitionResult，`BusinessCardEditDraft.source`
  就是已保存的 BusinessCard aggregate 本身。
- `PhoneField { let id: UUID; var kind; var value }` 是 Identifiable 行；
  `id` 直接取自已保存的 `PhoneNumber.id`。
- 初始化映射：scalar `nil → ""`；邮箱数组原样；手机行保留 id+kind+value。
- `func updatedCard(timestamp: Date) -> BusinessCard` 为纯 deterministic
  projection（时钟由编排方注入，内部不调用 `Date()`/`UUID()`）。
- Blank normalization 与 RecognitionDraft 一致：trim 首尾空白；空 scalar →
  nil；空手机/邮箱行省略；不生成任何占位内容。
- `var hasChanges: Bool`：用 `source.updatedAt` 作时间戳投影后比较 7 组可编辑
  值；`updatedAt` 与所有非编辑元数据不计入变更检测；纯空白编辑视为无变更。

### Aggregate 身份语义（与 Increment 4 的区别不混用）

- Increment 4（新扫描 → 新卡）：final `PhoneNumber.id` 是全新 domain UUID，
  因为诞生的是新 aggregate。
- Increment 5（已保存卡编辑）：是同一 BusinessCard aggregate 的原地修改 ——
  `updatedCard` 保留 `source.id`；每个已存在手机行保留原 `PhoneNumber.id`，
  仅 value（及投影后的 kind）来自 draft。

### 元数据保持（单测逐项证明）

```text
BusinessCard.id            保持
originalImageReference     保持
processedImageReference    保持
rawOCRText                 保持（nil 仍为 nil）
createdAt                  保持
tags / notes               保持
updatedAt                  = saveEdits() 注入的新时间戳（必然推进）
```

ImageAssetStore 本 Increment 未修改：image refs 不变 → 既有资产继续有效。

### CardDetailViewModel 编辑状态机（修改 ViewModel/CardDetailViewModel.swift）

- 由完全 read-only 变为持有必需依赖：
  `private let repository: any BusinessCardRepository`；
  production 导航必须传 shared repository（Previews / 无仓库上下文回退到
  用当前卡种子化的隔离 InMemory 仓储）。
- `enum EditState: Equatable { viewing / editing(draft) / saving(draft) }`，
  独立于展示用的 `card` 值（对应扫描侧 RecognitionState/SaveState 的职责分离）。
- `beginEditing()`：viewing → 以当前 card 建 draft；重复进入保持当前 draft。
- intents：`updateName/updateCompany/updateJobTitle/updateWebsite/updateAddress/
  updatePhone(id:value:)/updateEmail(index:value:)`，全部只改 draft；
  非 editing 态（含 saving）与未知 id/index 一律忽略。View 不持有第二份
  editable card，Binding 全部经 ViewModel intent。
- `cancelEditing()`：丢弃 draft → viewing；展示卡与 repository 均不变。
- `saveEdits() async`：editing(draft) → `draft.updatedCard(timestamp: Date())`
  → `await repository.save(updated)`（same-UUID save = replace，无重复）→
  `self.card = updated` → viewing；saving 中重入忽略。

### Repository 替换语义与三层刷新

- 依赖既有契约：同一 UUID 的 `save(_:)` 替换实体，仓储 before count =
  after count = N，不产生第二张卡。
- Detail 即时刷新：saveEdits 成功后 ViewModel.card 即更正后的值，保存后仍在
  Detail，新职位立即可见（T14 核心闭环，不需要先回 Holder）。
- Holder 刷新：返回时走既有 `.onAppear → loadCards()`，从同一 shared
  repository 重载；不直接改 CardHolderViewModel.cards[index]。
- production 组合根 `SimCamCardApp` 的 shared InMemoryBusinessCardRepository
  经 CardHolderView 透传给 CardDetailViewModel（App 入口本 Increment 无改动；
  透传链在 Increment 4 已建立，本 Increment 只是接到 Detail）。

### View 改动

- `View/CardDetail/CardDetailView.swift`（修改）：动作条加入 Reference 同款
  青色圆形铅笔「编辑」入口，稳定 identifier `card-detail-edit`；
  sheet 绑定 `editState`。
- `View/CardDetail/CardEditView.swift`（新增）：`编辑名片` 表单 sheet，
  左上 `card-edit-cancel`（取消）、右上 `card-edit-save`（保存），
  职位字段 identifier `card-edit-job-title`；其余字段 `card-edit-name /
  card-edit-company / card-edit-mobile-* / card-edit-office-* /
  card-edit-email-* / card-edit-website / card-edit-address`；
  聚焦字段显示「清除」按钮复刻 Reference 的 × affordance。
- `View/CardHolder/CardHolderView.swift`（修改）：导航构造 Detail 时透传
  shared repository。

### T14 验证结果

- Unit（Swift Testing，runner 权威行）：
  `✔ Test run with 289 tests in 25 suites passed after 7.897 seconds.`
  即 262 → **289/289 PASS**（新增 27：BusinessCardEditDraftTests 19 个
  全新文件 + CardDetailViewModelTests 新增 8 个 T14 用例），25 suites，
  0 failures / 0 disabled / 0 skipped。
  覆盖：BusinessCard→Draft 映射、nil scalar→""、手机 id/kind 保持、
  职位更正投影、trim/blank→nil、空手机/邮箱省略、卡 id 保持、
  图像引用保持、rawOCR 保持（含 nil）、createdAt 保持 + updatedAt 用注入
  时间戳、tags/notes 保持、source 不被修改、hasChanges 三类；
  ViewModel 侧覆盖建 draft/重入、只改 draft、非 editing 忽略、
  cancel 不动仓储、save 同 id 替换且 Detail 即时刷新、身份/元数据/手机 id
  保持 + updatedAt 推进、blank 持久化、saving 外 no-op。
- UI（XCTest，runner 权威行）：
  `Executed 35 tests, with 0 failures (0 unexpected) in 661.711 seconds`
  → **35/35 PASS**（33 → 35；`** TEST EXECUTE SUCCEEDED **`），
  0 disabled / 0 skipped。
  - `testExistingCardTitleEditPersistsToDetail`（29.3s）：fixture
    populated → card 001 Detail 原标题断言 → 编辑表单 → 经
    `card-edit-job-title` 替换为「高级产品总监 | Senior Product Director」
    → 保存 → 同页 Detail 立即显示新标题、旧标题消失、两行手机 id/值仍在 →
    返回 Holder，同一 `card-row-…001` 的副标题已是新标题、旧副标题消失；
    card 002 / card 004 行仍在（无重复卡回归）。
  - `testExistingCardEditCancelDiscardsChanges`（26.8s）：改职位后取消 →
    Detail 保持原标题，仓储无变化。
- Debug：**TEST BUILD SUCCEEDED**（build-for-testing；289 Unit + 35 UI
  均在该 Debug 测试构建上执行通过）。
- Release：**BUILD SUCCEEDED**（`-configuration Release
  CODE_SIGNING_ALLOWED=NO`，0 errors；Release
  `SWIFT_ACTIVE_COMPILATION_CONDITIONS` 无 DEBUG）。
- Release fixture isolation（strings 扫描 Release app binary）：
  **8/8 ABSENT** — `SimCamCardOCR / DebugOCRProcessor /
  DebugCameraEnvironment / SimCamCardCamera / SimCamCardDetection /
  SimCamCardCrop / SimCamCardPhotoImport / DebugCameraFakes` 各 0 匹配。

### Evidence（fixture-driven，非真实相机/OCR 证据）

```text
ai/validation/2026-10-04-w4i5-existing-edit-before.png  (Detail 原标题)
ai/validation/2026-10-04-w4i5-existing-edit-form.png    (编辑名片表单)
ai/validation/2026-10-04-w4i5-existing-edit-after.png   (Detail 更正后标题)
```

均从全量 UI 运行的 .xcresult 中以 XCTAttachment（.keepAlways）导出；
人工目检确认：before=「产品总监 | Product Director」、form=职位行原值与
取消/保存布局、after=「高级产品总监 | Senior Product Director」且两条电话、
邮箱、首页、公司地址完好。与冻结 `REF-*` 证据分离，未覆盖任何 Reference。

### Audits

```text
dataset/* diff: empty
spec/* diff: empty
evidence/* diff: empty
SimCamCard/Model/BusinessCard.swift diff: empty
SimCamCard/Repository/BusinessCardRepository.swift diff: empty
SimCamCard/Repository/InMemoryBusinessCardRepository.swift diff: empty
SimCamCard/Repository/ImageAssetStore.swift diff: empty
RecognitionDraft / BusinessCardMaterializer / CardFieldExtractor diff: empty
SimCamCard/App/SimCamCardApp.swift diff: empty (透传链 Increment 4 已建立)
project.pbxproj diff: empty (PBXFileSystemSynchronizedRootGroup
    自动纳入 3 个新 Swift 文件)

logical scope:
  production (5):
    - SimCamCard/Edit/BusinessCardEditDraft.swift (NEW)
    - SimCamCard/View/CardDetail/CardEditView.swift (NEW)
    - SimCamCard/ViewModel/CardDetailViewModel.swift (MODIFIED)
    - SimCamCard/View/CardDetail/CardDetailView.swift (MODIFIED)
    - SimCamCard/View/CardHolder/CardHolderView.swift (MODIFIED)
  tests (3):
    - SimCamCardTests/Edit/BusinessCardEditDraftTests.swift (NEW, 19 tests)
    - SimCamCardTests/ViewModel/CardDetailViewModelTests.swift (MODIFIED, +8)
    - SimCamCardUITests/CardDetailUITests.swift (MODIFIED, +2)
  documentation:
    - ai/changes.md
  evidence:
    - 3 PNGs under ai/validation/

`git status --short`（2026-10-04 final run，唯一权威）:
  6 tracked modified, 6 untracked entries = 12 working-tree paths
  untracked physical files: 3 Swift + 3 PNG
```

### T-status

```text
T11 structured scan:        PASS (prior increments)
T12 manual correction:      PASS
T13 detail:                 PASS
T14 existing-card edit:     PASS  ← this Increment
T15 search:                 not this Increment
T16 group:                  not this Increment
T17 delete:                 not this Increment
T18 persistence across relaunch: NOT IMPLEMENTED
    （T16 Group / P10 Notes 尚未完整实现；待业务数据稳定后再把
      BusinessCardRepository / ImageAssetStore 换成 disk-backed，
      避免重复迁移）
```

### Final fidelity statement

```text
T14 existing-card edit behavioral acceptance:
PASS

P07 / Edit Card full Reference fidelity:
PARTIAL
```

PARTIAL rationale:

```text
The T14 persisted-edit workflow is complete, but the full
Reference Edit Card / Detail surface contains additional UI and
domain concepts outside this increment, including department
rows, additional company-information blocks, add-phone/email/URL/
address affordances, full Detail quick-action surface and other
deferred features.
```

T-status remains:

```text
T11 PASS
T12 PASS
T13 PASS
T14 PASS

T15 not this Increment
T16 not this Increment
T17 not this Increment
T18 NOT IMPLEMENTED
```

Verification results preserved (not re-run for this review):

```text
Unit:
289 / 289 PASS
25 suites
0 failed
0 disabled
0 skipped

UI:
35 / 35 PASS

Debug:
TEST BUILD SUCCEEDED

Release:
BUILD SUCCEEDED

Release DEBUG fixture isolation:
8 / 8 ABSENT
```

Known deferred item (not an Increment 5 blocker): the temporary
isolated-repository fallback in `CardHolderView` Detail construction is
left as-is and will be revisited during persistence/composition cleanup.

### Human Decision

Human Decision:
Accepted — 2026-10-04 (human review)

---

## Week 4 Increment 6 — T15 Search

### Baseline

```text
branch: week4/structured-recognition
HEAD:   46e0783 (feat(card): 实现已保存名片编辑 — Increment 5 accepted)
working tree at start: clean
regression baseline: Unit 289/289 PASS · UI 35/35 PASS ·
  Debug TEST BUILD SUCCEEDED · Release BUILD SUCCEEDED ·
  Release fixture isolation 8/8 ABSENT
```

### Reference observations（frozen evidence，未改动）

- `REF-card-holder-02-after-save.png`：Holder 顶部为圆角搜索条，放大镜 +
  占位文字「请输入姓名/公司/职位搜索」，右侧另有 + 入口；点击搜索条进入
  独立搜索页（不是列表内联搜索）。
- `REF-search-01-by-name.png`（query=张伟）：独立 P08 页面 —— 顶部自定义
  栏：返回 `<` chevron、放大镜+可编辑文本+字段内 × 清除；分段控件
  综合/名片 1/企业；结果区标题「名片夹名片 1」+「浏览模式」；结果行复用
  名片行（缩略图 + 张伟 + 命中的第二行）。
- `REF-search-02-by-company.png`（query=智云）：同结构，结果区
  「名片夹名片 1」，命中行第二行为公司并高亮命中词。
- Reference 中本 Increment 不复刻的表面：分段控件（综合/名片/企业，企业无
  冻结领域对应）、浏览模式、名片缩略图大图、命中词蓝色高亮、异步
  「正在加载……」（内存快照搜索是同步的）。视觉采用 App 既有浅色体系做
  结构复刻，非像素级复制 → P08 全 Reference fidelity 视为 PARTIAL
  （T15 行为 acceptance 为 PASS）。
- spec 复核：page-inventory P08「Search cards by supported fields,
  Detail / Back」；state-inventory S01 `searching`（query active）；
  reference-tests T15 黑盒直接证据仅 name/company，最终实现还必须支持
  jobTitle/phone/email。

### Search architecture

```text
SimCamCard/Search/BusinessCardSearchMatcher.swift (NEW)
  nonisolated struct BusinessCardSearchMatcher: Sendable
  func matches(card: BusinessCard, query: String) -> Bool
```

- 纯 deterministic、无副作用：不访问 repository、不修改 BusinessCard、
  不持有 query；调用方（CardHolderViewModel）拥有 query 与投影。
- trim query；空/纯空白 → 匹配全部（清空即恢复完整列表，无第二条代码路径）。
- name / company / jobTitle / 每个 email：`range(of:options:.caseInsensitive)`
  大小写不敏感子串；nil 字段永不制造命中。
- phones：存储值与 query 都归一化为 ASCII 数字后做子串匹配，每个号码独立
  参与。
- `BusinessCard.swift` 未改动；无新增 Domain 字段。

### Phone normalization

```text
"+86 138 0013 8000" → digits → "8613800138000"
query "13800138000"（纯数字）           → 命中
query "+86 138 0013 8000"（格式化）     → 同样命中
query "55551234"（第二部座机子串）      → 命中
```

### CardHolder state ownership（S01 empty/populated/searching）

- `CardHolderViewModel` 继续是 repository snapshot（`cards`）的唯一 owner；
  新增 `var searchQuery: String`（View 直接 Binding，View 不持第二份）、
  派生 `var isSearching: Bool`（trim 后非空）、
  派生 `var visibleCards: [BusinessCard]`（非搜索 = cards；搜索 =
  cards.filter(matcher)，保持快照成员与顺序，不重新排序）。
- 搜索是纯 presentation filter：不修改 `cards` / repository / BusinessCard
  （单测在多轮搜索后断言快照值相等、仓储内容不变）。
- `clearSearch()`：× 与返回共用；未引入大型状态 enum（empty/populated/
  searching 全部由 cards + searchQuery + visibleCards 派生）；
  `groupFiltered` 留给 Increment 7，未来组合为
  snapshot → group filter → search filter，无需重写 matcher。

### View / navigation

- `AppRoute` 新增 `case search`（AppRoute.swift）；Holder
  （CardHolderView）顶部以 safeAreaInset 加入 Reference 同款圆角搜索条
  入口（`card-holder-search-entry`，占位文字完全照搬），点击 push P08；
  Holder 列表始终渲染完整 `cards` 快照。
- `SimCamCard/View/Search/CardSearchView.swift`（NEW）：自定义顶栏
  （返回 chevron `card-search-back` + 胶囊搜索框；TextField
  `card-holder-search` 自动聚焦、禁用自动大写/纠错；非空时显示 ×
  `card-holder-search-clear`）；结果 Section header「名片夹名片 N」；
  结果行复用 `BusinessCardRow` + `NavigationLink(value: .cardDetail(id))`，
  由 Holder 既有的 navigationDestination 解析 —— 没有第二套 Detail 导航，
  行 identifier 继续是 `card-row-<UUID>`。
- 搜索 active 且 0 命中 → `ContentUnavailableView.search`，稳定
  identifier `card-holder-search-empty`，与 Holder 无卡的
  `card-holder-empty` 语义严格分开。
- 返回语义：自定义 chevron 先 clearSearch 再 dismiss；从结果 push Detail
  再返回时不重置 query（不在 onDisappear 重置，避免 Detail 往返清空）；
  × 在页内恢复完整快照。

### 各字段结果（populated fixture：card001 张伟/智云/Product Director/
### +86 138 0013 8000/wei.zhang；card002 李娜/智云/Marketing/139…；
### card004 张伟 minimal）

```text
name     "张伟"             → {001, 004}
company  "智云"             → {001, 002}
jobTitle "Product Director" → {001}
phone    "13800138000"      → {001, 004}（存储为 "+86 138 0013 8000"）
email    "wei.zhang"        → {001}
no-result "查无此名片…"      → card-holder-search-empty，0 行
```

- no-result：专用空态，非 holder 空态。
- clear：× 后同页恢复全部 3 张；再返回 Holder，3 张全部在位。
- Detail navigation：name 用例点 card001 → 名片详情显示张伟并返回仍保留
  query；company 用例点 card002 → 名片详情显示李娜。全部按
  card-row-<UUID> membership 断言，不依赖行位置/节点总数。

### Verification

- Unit（Swift Testing，runner 权威行）：
  `✔ Test run with 314 tests in 26 suites passed after 7.609 seconds.`
  289 → **314/314 PASS**（新增 25：BusinessCardSearchMatcherTests 15 +
  CardHolderViewModelTests T15 段 10），0 failed / 0 disabled / 0 skipped。
  覆盖：空/纯空白 query、name 精确/部分、company、jobTitle、电话纯数字/
  格式化/多号码、email 部分/多邮箱、Latin 大小写不敏感、非命中、nil 字段
  不伪造、trim；VM 侧覆盖初始态、五字段搜索、零命中、清空恢复、快照与仓储
  不被修改、reload 后新值自然参与搜索。
- UI（XCTest，runner 权威行）：
  `Executed 38 tests, with 0 failures (0 unexpected) in 659.839 seconds`
  → **38/38 PASS**（35 → 38；`** TEST EXECUTE SUCCEEDED **`），
  0 disabled / 0 skipped。
  - `testSearchByNameOpensExpectedCard`（19.6s）
  - `testSearchByCompanyReturnsExpectedCard`（17.1s）
  - `testSearchAcrossJobTitlePhoneEmailNoResultAndClear`（20.6s，
    单 launch 连续覆盖 jobTitle/phone/email/no-result/clear/back）
- Debug：**TEST BUILD SUCCEEDED**（314 Unit + 38 UI 均在该测试构建执行）。
- Release：**BUILD SUCCEEDED**（`-configuration Release
  CODE_SIGNING_ALLOWED=NO`，0 errors）。
- Release DEBUG fixture isolation（Release app binary strings）：
  **8/8 ABSENT** — SimCamCardOCR / DebugOCRProcessor /
  DebugCameraEnvironment / SimCamCardCamera / SimCamCardDetection /
  SimCamCardCrop / SimCamCardPhotoImport / DebugCameraFakes 各 0 匹配。

### Evidence（fixture-driven，非真实相机/OCR 证据）

```text
ai/validation/2026-10-04-w4i6-search-name.png     (query 张伟 → 名片夹名片 2)
ai/validation/2026-10-04-w4i6-search-company.png  (query 智云 → 名片夹名片 2)
```

从全量 UI 运行的 .xcresult 以 XCTAttachment（.keepAlways）导出；人工目检：
name 图为张伟全卡 + 张伟 minimal 两行；company 图为张伟 + 李娜两行；
顶栏 chevron/放大镜/query/× 与「名片夹名片 2」分区清晰。与冻结 REF-*
证据分离，未覆盖任何 Reference。

### Audits

```text
dataset/* diff: empty
spec/* diff: empty
evidence/* diff: empty
SimCamCard/Model/BusinessCard.swift diff: empty
SimCamCard/Repository/* diff: empty
SimCamCard/Repository/ImageAssetStore.swift diff: empty
SimCamCard/Recognition/* diff: empty
SimCamCard/Edit/BusinessCardEditDraft.swift diff: empty
SimCamCard/App/SimCamCardApp.swift diff: empty
project.pbxproj diff: empty (PBXFileSystemSynchronizedRootGroup
    自动纳入 2 个新 Swift 源文件 + 1 个新测试文件)

logical scope:
  production (5):
    - SimCamCard/Search/BusinessCardSearchMatcher.swift (NEW)
    - SimCamCard/View/Search/CardSearchView.swift (NEW)
    - SimCamCard/App/AppRoute.swift (MODIFIED, +case search)
    - SimCamCard/ViewModel/CardHolderViewModel.swift (MODIFIED)
    - SimCamCard/View/CardHolder/CardHolderView.swift (MODIFIED)
  tests (3):
    - SimCamCardTests/Search/BusinessCardSearchMatcherTests.swift (NEW, 15)
    - SimCamCardTests/ViewModel/CardHolderViewModelTests.swift (MODIFIED, +10)
    - SimCamCardUITests/CardSearchUITests.swift (NEW, 3)
  documentation:
    - ai/changes.md
  evidence:
    - 2 PNGs under ai/validation/

`git status --short`（2026-10-04 final run，唯一权威）:
  5 tracked modified, 6 untracked entries = 11 working-tree paths
  untracked physical files: 4 Swift + 2 PNG
  4 new Swift:
    - SimCamCard/Search/BusinessCardSearchMatcher.swift
    - SimCamCard/View/Search/CardSearchView.swift
    - SimCamCardTests/Search/BusinessCardSearchMatcherTests.swift
    - SimCamCardUITests/CardSearchUITests.swift
  2 PNG:
    - ai/validation/2026-10-04-w4i6-search-name.png
    - ai/validation/2026-10-04-w4i6-search-company.png
  （AppRoute 为新增路由的最小必要改动；未触碰组合根与持久化接缝。
   Increment 5 记录的 CardHolderView temporary repository fallback
   仍按评审结论保留，留待 persistence/composition cleanup。）
```

### T-status

```text
T11 structured scan:        PASS
T12 manual correction:      PASS
T13 detail:                 PASS
T14 existing-card edit:     PASS
T15 search:                 PASS  ← this Increment
T16 group:                  not this Increment
T17 delete:                 not this Increment
T18 persistence across relaunch: NOT IMPLEMENTED
```

### Final fidelity statement

```text
T15 Search behavioral acceptance:
PASS

P08 full Reference fidelity:
PARTIAL
```

PARTIAL rationale:

```text
Reference-specific segmented 综合/名片/企业 surface,
browse-mode affordance, match highlighting and other non-core
search presentation details are not fully replicated.
```

T-status remains:

```text
T11 PASS
T12 PASS
T13 PASS
T14 PASS

T15 Search behavioral acceptance:
PASS

P08 full Reference fidelity:
PARTIAL

T16:
not this Increment

T17:
not this Increment

T18:
NOT IMPLEMENTED
```

Verification results preserved (not re-run for this review):

```text
Unit:
314 / 314 PASS
26 suites
0 failed
0 disabled
0 skipped

UI:
38 / 38 PASS

Debug:
TEST BUILD SUCCEEDED

Release:
BUILD SUCCEEDED

Release fixture isolation:
8 / 8 ABSENT
```

### Human Decision

Human Decision:
Accepted — 2026-10-04 (human review)

## Week 4 Increment 7 — T16 Group/Tag (2026-10-04)

### Baseline

```text
branch: week4/structured-recognition
HEAD:   194a6c3 (feat(search): 实现名片多字段搜索 — Increment 6 accepted)
working tree at start: 6 tracked modified carried from this Increment
regression baseline: Unit 314/314 PASS · UI 38/38 PASS ·
  Debug TEST BUILD SUCCEEDED · Release BUILD SUCCEEDED ·
  Release fixture isolation 8/8 ABSENT
```

### Reference observations（frozen evidence，未改动）

- `REF-group-01-select-card.png`：选卡页 —— 顶部「已选 N 张」计数，
  每张名片一行带勾选（已选实心蓝勾 / 未选空心圆），底部蓝色主按钮
  「添加到分组 (N)」，右上「取消」。
- `REF-group-02-create-dialog.png`（深色 macOS 版）：底层是全屏
  「添加到分组」选择页 —— 顶栏 取消 / 添加到分组 / 确认；分组名搜索框；
  「+ 新建分组」入口；「未分组」分区带勾选；「你可能会用到的分组」预设
  标签 VIP / 客户 / 供应商 / 合作伙伴 / 同行。其上叠加「新建分组」小对话框：
  单行输入框（带 × 清空）+ 完成 / 取消。
- `REF-group-03-assigned.png` / `REF-group-04-list.png`：分组管理列表
  —— 顶部「+ 新建分组」入口，其下「我的分组」分区，每行显示分组名 +
  成员数，右侧删除控件与 chevron。
- `REF-group-05-filtered-list.png`：点击某个分组后回到名片夹，仅显示该组
  名片；顶部出现分组筛选条（文件夹图标 + 组名 + 计数 + × 清除）。
- `REF-group-06-delete-confirmation.png`：删除确认对话框「删除分组」，
  文案明示删除后分组不可恢复、名片保留，按钮 取消 / 确认删除（红色）。
- `REF-group-07-after-delete-empty.png`：删除最后一个分组后列表回到空态
  「你还未创建分组」。
- spec 复核：page-inventory P09「Group Management — Create/assign/view
  card groups → Group list / filtered list」；state-inventory S07
  `ungrouped / selectingCards / creatingGroup / assigned / groupFiltered /
  groupDeleted`；reference-tests T16 冻结工作流「Create → Assign → View
  by Group/Tag → Delete Group/Tag。Deleting a group removes the group
  while the business cards remain in the Card Holder.」

### Domain model（复用，未新增字段）

```text
SimCamCard/Model/CardTag.swift（Week 2 既有，未改动）
  nonisolated struct CardTag: Identifiable, Sendable, Hashable
    let id: UUID
    var name: String
SimCamCard/Model/BusinessCard.swift（未改动）
  var tags: [CardTag]   // "card → assigned groups"
```

- 未给 BusinessCard 增加任何字段；分组能力完全建立在既有 `tags` 之上。

### 双存储模型：分组目录 vs 名片 tags

T16 需要「即使最后一张名片被移出，分组本身仍然存在」（空分组是合法的，
见 REF-group-04 与 S07 `ungrouped`）。单一 `BusinessCard.tags` 无法表达
空分组，因此引入独立的分组目录仓储，与名片仓储并列、同样走构造注入：

```text
SimCamCard/Repository/CardGroupRepository.swift (NEW)
  nonisolated protocol CardGroupRepository: Sendable
    func allGroups() async -> [CardTag]
    func group(id: UUID) async -> CardTag?
    func save(_ group: CardTag) async      // 同 id = replace
    func delete(id: UUID) async            // 缺席 = 安全 no-op

SimCamCard/Repository/InMemoryCardGroupRepository.swift (NEW)
  actor InMemoryCardGroupRepository: CardGroupRepository
    private var groups: [UUID: CardTag]
```

- 与 `BusinessCardRepository` / `InMemoryBusinessCardRepository` 完全同构：
  protocol `nonisolated` + 全 async；可变状态只存在于 actor 内，按 UUID
  字典串行化；无 mutable class、无锁、无 `@unchecked Sendable`。
- 语义：`BusinessCard.tags` 表示「名片 → 所属分组」；
  `CardGroupRepository` 表示「用户定义过的全部分组」。删除分组时两边都
  更新，但名片本体永不删除。

### CardHolderViewModel — 唯一状态所有者（S07）

- 新增注入：构造器新增 `groupRepository: any CardGroupRepository`
  （`let`，组合根注入；与既有 `repository` 并列）。`loadHolderData()`
  同时 `loadCards()` + `loadGroups()`。
- 持有的状态：`groups: [CardTag]`（`private(set)`，仓储快照）、
  `selectedGroupID: UUID?`（S01/S07 `groupFiltered`）、
  瞬态 `groupCardSelection: Set<UUID>` 与 `pendingGroupName: String`。
  View（GroupManagementView）不持任何 cards/groups/selection 的副本。
- 派生投影（兑现 Increment 6 预留的组合点，无第二条数据路径）：

```text
visibleCards = cards 快照
   → groupFilteredCards（selectedGroupID 命中 card.tags[id]，无选中 = 全量）
   → BusinessCardSearchMatcher（trim query，空 = 全量）
cardCount(in:) = cards 快照中 tags 含该组 id 的数量（无独立计数存储）
```

- `createGroup(named:)`：trim 后空名 → 返回 nil（不建组）；否则
  ① groupRepository.save(新 CardTag) ② 把**同一个 CardTag 值**追加到每张
  选中卡 `card.tags`（同 id 去重），经 `repository.save(card)` 写回，
  更新 `updatedAt` ③ reload cards + groups ④ 清空瞬态选择/输入。
- `deleteGroup(id:)`：① groupRepository.delete ② 从**所有携带该 tag 的
  名片**上移除该 tag 并逐张 `repository.save`（名片本身保留）③ reload
  两个快照 ④ 若被删组正是当前筛选组则清空筛选。
- `selectGroup / clearGroupFilter / beginGroupSelection /
  toggleGroupCardSelection / clearGroupCardSelection` 均为 ViewModel 上的
  纯状态变更；分组计数、筛选、搜索全部由快照派生（无大型状态 enum）。

### View / navigation（P09）

- `AppRoute` 新增 `case .groups`；Holder 顶部 toolbar 新增文件夹入口
  `card-holder-groups`（`NavigationLink(value: .groups)`，label「分组」），
  由 Holder 既有 `navigationDestination` 统一解析到
  `GroupManagementView` —— 没有第二套导航、没有并行 Bool/sheet 状态。
- `SimCamCard/View/Group/GroupManagementView.swift`（NEW）：共享 Holder
  的同一个 `CardHolderViewModel`（分组目录、选择、筛选状态同源），仅持有
  本地 UI phase（`groupList` / `selectingCards`）与两个 alert 的呈现态。
  - groupList 阶段：「+ 新建分组」入口（identifier `group-create`）、
    「我的分组」分区（行 `group-row-<uuid>`：组名 + `(N)`，点击 =
    selectGroup + dismiss 回 Holder 进入筛选；红色 `minus.circle.fill`
    删除按钮 `group-delete-<uuid>`）、空态 `group-empty`「你还未创建分组」。
  - selectingCards 阶段：「已选 N 张」计数、复用 `BusinessCardRow` 的
    勾选行 `group-card-select-<uuid>`、右上「取消」
    （`group-selection-cancel`）、底部「添加到分组 (N)」主按钮（空选禁用）。
  - 两个原生 SwiftUI `.alert`：「新建分组」（TextField 占位
    「请输入分组名称」+ 取消 / 完成，完成在创建后从选卡阶段回到列表）；
    「删除分组」（完整保留提示文案 + 取消 / 确认删除 destructive）。
- Holder 筛选态（S01 `groupFiltered`）：当 `selectedGroupID != nil`，
  列表渲染 `groupFilteredCards`，并以 `.safeAreaInset(edge: .top)` 显示
  筛选条 `group-filter-active`（文件夹 + 组名 + `(N)` + × 清除
  `group-filter-clear` / label「清除分组筛选」）。× 恢复完整快照；
  行 identifier 继续是 `card-row-<UUID>`，与搜索/详情完全兼容。
- `SimCamCardApp` 组合根构造 `InMemoryCardGroupRepository()` 并注入
  ViewModel；`CardSearchView` 预览仅随新构造器签名更新（无行为变化）。

### T16 冻结工作流验证（fixture-driven，membership only）

- Create：空态 → 新建分组 → 勾选 card001（已选 1 张）→ 添加到分组 →
  「新建分组」对话框输入「客户」→ 完成；列表出现「我的分组 / 客户 (1)」。
- Assign：同一张 CardTag（同 UUID）写入分组目录与 card001.tags；多卡同组、
  重复分配去重、空名拒绝由单元测试覆盖。
- View filtered：点「客户」行回到名片夹，筛选条出现，仅 card001 可见；
  card002 / card004 在筛选列表中缺席（按 `card-row-<UUID>` 成员关系断言，
  不依赖行位置）。
- 与搜索组合：筛选可再叠加搜索（单元测试 `t16GroupPlusSearchCompose`）。
- Delete group / cards preserved：删除 → 红色确认对话框 → 确认删除 →
  目录空态；返回名片夹 card001 / card002 / card004 三张全部仍在。
  「删除被筛选中的分组自动清筛选」由单元测试覆盖。

### Verification

- Unit（Swift Testing，runner 权威行，串行，iPhone 18 Pro / iOS 27）：
  `✔ Test run with 337 tests in 27 suites passed after 8.879 seconds.`
  314 → **337/337 PASS**（+23：InMemoryCardGroupRepositoryTests 9 +
  CardHolderViewModelTests T16 段 14），0 failed / 0 disabled / 0 skipped，
  26 → 27 suites。
  - 仓储 9：初始空 / 初始种子 / insert / 同 id replace / 异 id 共存 /
    id 查询 / 删除存在 / 删除缺席 no-op / 空分组独立于名片存在。
  - VM 14：loadGroups、创建并分配、多卡同组同 id、分配去重、
    分配保持其余元数据、cardCount 派生、selectGroup 筛选、清筛选、
    分组+搜索组合、删除移除目录、删除后名片保留、删除当前筛选组清筛选、
    空白组名拒绝、选卡 toggle。
  - 权威日志：`/tmp/w4i7-unit2.log`。
- UI（XCTest，runner 权威行，**串行**
  `-parallel-testing-enabled NO`，iPhone 18 Pro / iOS 27）：
  `Executed 40 tests, with 0 failures (0 unexpected) in 696.760 seconds`
  → **40/40 PASS**（38 → 40；`** TEST SUCCEEDED **`），0 disabled /
  0 skipped。
  - `CardGroupUITests.testGroupFullFlow`（34.3s）
  - `CardGroupUITests.testGroupDeleteFlow`（36.4s）
  - 全量串行（应设备高压要求，全程未开并行）；38 个既有用例零回归。
  - 权威日志：`/tmp/w4i7-ui-full.log`；bundle `/tmp/w4i7-ui-full.xcresult`。
- Debug：**TEST BUILD SUCCEEDED**（337 Unit + 40 UI 均在该测试构建执行）。
- Release：**BUILD SUCCEEDED**（`-configuration Release
  CODE_SIGNING_ALLOWED=NO`，0 errors，日志 `/tmp/w4i7-release.log`）。
  该验证在本 Increment 生产代码冻结点完成；其后仅更新 UI 测试文件
  （SimCamCardUITests target），app 生产 target 输入未再变化。
- Release DEBUG fixture isolation（Release app binary strings）：
  **8/8 ABSENT** — SimCamCardOCR / DebugOCRProcessor /
  DebugCameraEnvironment / SimCamCardCamera / SimCamCardDetection /
  SimCamCardCrop / SimCamCardPhotoImport / DebugCameraFakes 各 0 匹配。

### UI 测试工程注记（XCTest ↔ SwiftUI bridge）

本 Increment 新增的两条 bridge 行为已通过失败快照实证并固化到测试注释：

1. SwiftUI `.alert`（bridge 到 UIAlertController）中的 **TextField 不导出
   自定义 accessibilityIdentifier**（`group-name-field` 全树 0 匹配），但
   其 placeholderValue 正常导出；故用
   `app.alerts["新建分组"].textFields.firstMatch` + 占位文本断言定位。
2. alert **Button 的 identifier 会导出，但在 bridge 层可能落在多个节点上**，
   直接 `alert.buttons["..."]` tap 触发单匹配错误；改用
   `.matching(identifier:).firstMatch`。
3. 给「内含交互 Button 的容器 HStack」挂 `.accessibilityIdentifier` 时，
   该容器 id 会污染内部 Button 的 bridge 节点（失败归档 plist 实证：× 按钮
   elementType=9(Button)、label「清除分组筛选」完好，但 identifier 显示为
   容器的 `group-filter-active`，`group-filter-clear` 全树 0 匹配；同条 HStack
   内两个静态文本节点也被挂了容器 id）。因此筛选条 × 以无障碍 label
   「清除分组筛选」为首选查询，identifier / banner 右端坐标为兜底。
   （生产视觉与行为未为此改动；仅测试定位方式适配。）

### Evidence（fixture-driven，非真实相机/OCR 证据）

```text
ai/validation/2026-10-04-w4i7-group-selecting.png      (选卡页：已选 1 张，card001 勾选)
ai/validation/2026-10-04-w4i7-group-created.png        (我的分组：客户 (1))
ai/validation/2026-10-04-w4i7-group-filtered.png       (筛选条 客户(1)，仅 card001)
ai/validation/2026-10-04-w4i7-group-delete-confirm.png (删除分组确认对话框)
ai/validation/2026-10-04-w4i7-group-after-delete.png   (删除后空态：你还未创建分组)
```

从全量串行 UI 运行的 .xcresult 以 XCTAttachment（.keepAlways）导出；人工
目检：选卡页 3 行仅 card001 实心蓝勾；分组列表「客户 (1)」+ 红色删除控件；
筛选页 banner 与单卡；删除对话框文案与红色确认键；删除后空态图标与文案。
与冻结 REF-* 证据分离，未覆盖任何 Reference。

### Audits

```text
dataset/* diff: empty
spec/* diff: empty
evidence/* diff: empty
SimCamCard/Model/BusinessCard.swift diff: empty
SimCamCard/Model/CardTag.swift diff: empty
SimCamCard/Recognition/* diff: empty
project.pbxproj diff: empty (PBXFileSystemSynchronizedRootGroup
    自动纳入新 Swift 源文件与新测试文件)

logical scope:
  production (7):
    - SimCamCard/Repository/CardGroupRepository.swift (NEW)
    - SimCamCard/Repository/InMemoryCardGroupRepository.swift (NEW)
    - SimCamCard/View/Group/GroupManagementView.swift (NEW)
    - SimCamCard/App/AppRoute.swift (MODIFIED, +case groups)
    - SimCamCard/App/SimCamCardApp.swift (MODIFIED, 注入 groupRepository)
    - SimCamCard/View/CardHolder/CardHolderView.swift (MODIFIED, 入口+筛选态)
    - SimCamCard/ViewModel/CardHolderViewModel.swift (MODIFIED, S07 状态/投影)
  incidental (1, preview-only):
    - SimCamCard/View/Search/CardSearchView.swift (预览随构造器签名更新)
  tests (3):
    - SimCamCardTests/Repository/InMemoryCardGroupRepositoryTests.swift (NEW, 9)
    - SimCamCardTests/ViewModel/CardHolderViewModelTests.swift (MODIFIED, +14)
    - SimCamCardUITests/CardGroupUITests.swift (NEW, 2)
  documentation:
    - ai/changes.md
  evidence:
    - 5 PNGs under ai/validation/

`git status --short`（2026-10-04 final run，唯一权威）:
  6 tracked modified, 11 untracked entries
  untracked physical files: 5 Swift + 1 View/Group directory + 5 PNG
  5 new Swift:
    - SimCamCard/Repository/CardGroupRepository.swift
    - SimCamCard/Repository/InMemoryCardGroupRepository.swift
    - SimCamCard/View/Group/GroupManagementView.swift
    - SimCamCardTests/Repository/InMemoryCardGroupRepositoryTests.swift
    - SimCamCardUITests/CardGroupUITests.swift
  5 PNG:
    - ai/validation/2026-10-04-w4i7-group-selecting.png
    - ai/validation/2026-10-04-w4i7-group-created.png
    - ai/validation/2026-10-04-w4i7-group-filtered.png
    - ai/validation/2026-10-04-w4i7-group-delete-confirm.png
    - ai/validation/2026-10-04-w4i7-group-after-delete.png
  （未触碰 Domain 字段、识别栈、持久化接缝与冻结参考；分组目录经构造注入，
   Increment 5 记录的 CardHolderView temporary repository fallback
   仍按评审结论保留，留待 persistence/composition cleanup。）
```

### T-status

```text
T11 structured scan:        PASS
T12 manual correction:      PASS
T13 detail:                 PASS
T14 existing-card edit:     PASS
T15 search:                 PASS
T16 group/tag:              PASS  ← this Increment
T17 delete:                 not this Increment
T18 persistence across relaunch: NOT IMPLEMENTED
```

### Final fidelity statement

```text
T16 Group/Tag behavioral acceptance:
PASS

P09 full Reference fidelity:
PARTIAL
```

PARTIAL rationale:

```text
冻结的 T16 行为工作流（Create → Assign → View filtered → Delete group,
cards remain in the Card Holder）全部由自动化覆盖并 PASS。以下 REF-group-02
的表面未复刻：
  - 「添加到分组」全屏选择页（分组名搜索框、右上角确认、未分组分区勾选）；
  - 「你可能会用到的分组」预设标签 VIP/客户/供应商/合作伙伴/同行；
  - 把名片加入「已存在分组」的多选路径（当前支持新建组并一次性分配；
    点已有组行是筛选而非向其追加成员）；
  - 新建分组输入框内的 × 清空；
  - Reference 为深色 macOS 体系，本实现为 iOS 浅色体系，做结构复刻而非
    像素级复制。
空分组在目录中独立存在、删除分组保留名片这两条关键领域语义均已实现。
```

T-status remains:

```text
T11 PASS
T12 PASS
T13 PASS
T14 PASS
T15 PASS

T16 Group/Tag behavioral acceptance:
PASS

P09 full Reference fidelity:
PARTIAL

T17:
not this Increment

T18:
NOT IMPLEMENTED
```

Verification results:

```text
Unit:
337 / 337 PASS
27 suites
0 failed
0 disabled
0 skipped

UI:
40 / 40 PASS（serial, -parallel-testing-enabled NO）

Debug:
TEST BUILD SUCCEEDED

Release:
BUILD SUCCEEDED

Release fixture isolation:
8 / 8 ABSENT
```

### Human Decision

Human Decision:
Accepted — 2026-10-04 (human review)

## Week 4 Increment 8 — T17 Delete (2026-10-04)

- Baseline commit: `b5d4dd1`（Increment 7「feat(group): 实现名片分组管理」，
  已 accepted + pushed；开工时 `git switch week4/structured-recognition` /
  `git pull --ff-only`（Already up to date）/ `git status` clean）。
- Regression baseline：Unit 337/337（27 suites）、UI 40/40、Debug PASS、
  Release PASS、fixture isolation 8/8 ABSENT。
- 本 Increment 结束：**未 commit、未 push**，等待 human review。

### Reference observations（frozen evidence，未改动）

逐张核对 REF-detail-04 / REF-delete-01 / REF-card-holder-01-empty，文案以
Reference 为准：

- **More entry location**：名片详情（P07）顶栏右上角 `•••`（ellipsis），
  位于收藏星 ☆ 同侧 trailing（星标本 Increment 不实现）。稳定 identifier
  `card-detail-more`。
- **More-actions surface**：点击 ••• 弹出 Reference 底部操作面板（网格图标：
  保存到通讯录 / 编辑 / 邀请使用名片全能王 / 分组 / 备注 / 提醒 / 删除 + 取消）。
  本 Increment 仅渲染真实可用的 **删除** 一项，其余为死按钮不做。
- **Delete row wording**：垃圾桶图标 + 文案「删除」（destructive）。
  identifier `card-detail-delete`。
- **Confirmation title**：「提示」。
- **Confirmation message**：「删除未同步名片将无法恢复，请确认是否要删除？」
- **destructive / cancel button wording**：右侧红色「删除名片」
  （identifier `card-delete-confirm`）；左侧中性「取消」
  （identifier `card-delete-cancel`）。
- **confirm destination**：确认 → repository delete(id:) → Holder reload
  （loadHolderData：cards + groups）→ Detail dismiss → 名片夹中该卡消失；
  删除最后一张 → 名片夹回到空态（`card-holder-empty`，名片 (0张)），
  扫描入口（+）仍可用。
- **cancel result**：取消确认框 → Detail 保持在前台，名片姓名仍显示，
  repository 中该卡完全不变。
- spec 复核：page-inventory P07 actions 含 Delete；state-inventory
  S06 `deleted`；S01 删除后列表即时更新、删最后一张回空态；
  reference-tests T17「Confirmation precedes delete; card disappears
  afterward.」

### DeleteState 设计（独立于 EditState）

`CardDetailViewModel` 在现有 `EditState { viewing / editing(draft) /
saving(draft) }` 之外新增**独立**的删除状态族，二者正交，互不污染：

```swift
enum DeleteState: Equatable {
    case idle
    case confirming
    case deleting
    case deleted
}
private(set) var deleteState: DeleteState = .idle
```

Intents（`SimCamCard/ViewModel/CardDetailViewModel.swift`）：

- `requestDelete()`：仅当 `editState == .viewing && deleteState == .idle`
  才进入 `.confirming`；editing / saving / deleting / deleted 全部 no-op。
- `cancelDelete()`：仅 `.confirming → .idle`；显示中的 card 与 repository
  完全不变；其它状态 no-op。
- `@discardableResult func confirmDelete() async -> Bool`：仅 `.confirming`
  可执行：`.confirming → .deleting → await repository.delete(id: card.id)
  → .deleted`，返回 `true`；任何非 `.confirming` 调用是稳定 no-op，返回
  `false`（重复 confirm 不会二次删除、也不会离开 `.deleted`）。
- 当前 repository 不抛错，**不制造**假的 failed state；没有新增
  deleted flag / soft-delete / DTO / tombstone。

### More-actions entry / confirmation 行为（CardDetailView）

- 新增 `@Environment(\.dismiss)` 与由 Holder 注入的
  `let onDeleted: @MainActor () async -> Void`（production 传真实回调；
  仅两个 #Preview 传 no-op `{}`）。
- 导航栏 trailing 新增 native `•••`（`Image(systemName: "ellipsis")`，
  accessibilityLabel「更多操作」，identifier `card-detail-more`）。
- 点击呈现 SwiftUI native `.confirmationDialog("更多操作", …)`，**本
  Increment 只渲染一个真实可用动作**：destructive「删除」（trash，
  identifier `card-detail-delete`），外加系统「取消」。不做保存通讯录 /
  分组 / 备注 / 提醒 / 邀请等死按钮。
- 「删除」→ `viewModel.requestDelete()` 并呈现 native `.alert("提示")`：
  message 严格等于「删除未同步名片将无法恢复，请确认是否要删除？」；
  - 取消（role `.cancel`，identifier `card-delete-cancel`）→
    `viewModel.cancelDelete()`，Detail 与卡完全不变。
  - 删除名片（role `.destructive`，红色，identifier
    `card-delete-confirm`）→
    ```swift
    Task {
        if await viewModel.confirmDelete() {
            await onDeleted()
            dismiss()
        }
    }
    ```
  - 顺序严格为 **repository delete → Holder onDeleted reload → Detail
    dismiss**，不先 dismiss 再赌 onAppear。

### 显式 Holder reload（CardHolderView wiring）

`navigationDestination(.cardDetail)` 构造 `CardDetailView` 时继续传同一
`BusinessCardRepository`，并新增：

```swift
onDeleted: { await viewModel.loadHolderData() }
```

`loadHolderData()` 顺序 reload cards + groups。删除确认返回后，pop 完成时
Holder 已持有最新 snapshot：普通列表、group cardCount、当前活动 group
filter、以及之后的 Search（不再命中已删卡）全部即时正确，不依赖
onAppear 时序。

### Cancel 语义

取消确认框：alert 关闭、`deleteState → .idle`、`editState` 仍 `.viewing`，
头部姓名仍在；返回 Holder 后 card001 行仍存在、空态不出现。单元测试
`t17CancelPreservesCardAndRepository` 与 UI
`testDeleteCancelLeavesCardUnchanged` 双重固化；另验证「请求/取消删除」
不干扰 T14 编辑保存链路（`t17DoesNotDisturbEditWorkflow`）。

### 分组卡删除语义（group catalog 独立）

删除 `BusinessCard` 仅让该 aggregate 从 `BusinessCardRepository` 消失；
**不触碰 `CardGroupRepository`**。例：客户 group 仅含 card001，删除
card001 后，group「客户」仍在 catalog 中、`cardCount == 0`，活动中的该
group filter 解析为空集而非悬挂卡。由
`t17DeleteLastCardOfGroupKeepsGroupAtZero` 断言（含 groupRepo
`allGroups()` 仍含该 tag）。`ImageAssetStore` 本 Increment 未改；持久化
资产回收留待 T18 disk-persistence 统一设计。

### 测试变更

- 单元（Swift Testing，DEBUG fixture 段）：
  - `CardDetailViewModelTests` 新增 **11** 个 T17 用例：初始 idle；
    request→confirming；editing 中 request 被忽略；deleted 后 request
    被忽略；cancel→idle；cancel 卡/repository 完全不变；confirm 删除同
    UUID 且到 deleted；非 confirming confirm 返回 false（idle 与取消后两
    种）；重复 confirm 稳定停留 deleted 且不二次删除；删一卡保全其它卡；
    删除请求/取消不破坏 T14 编辑保存。
  - `CardHolderViewModelTests` 新增 **2** 个 T17 用例：repository 删除后
    `loadHolderData()` 的 cards snapshot 不再含该 id 且 Search 不再命中；
    删除某 group 唯一卡后 catalog group 保留、cardCount 0、活动 filter
    为空、groupRepo 仍含该 group。
- UI（XCTest）：新增 `SimCamCardUITests/CardDeleteUITests.swift`
  （`-SimCamCardFixture single`，仅 card001；全程 waitForExistence /
  waitForNonExistence，无 sleep；`-parallel-testing-enabled NO`）：
  - `testDeleteConfirmedRemovesCardAndReturnsEmptyHolder`：••• → 删除 →
    「提示」确认（断言标题/逐字 message/两按钮）→ 删除名片 → Detail 消失
    → Holder 中 card001 行缺席 → `card-holder-empty` +「名片 (0张)」→
    `scan-entry` 仍在。
  - `testDeleteCancelLeavesCardUnchanged`：确认框 → 取消 → alert 消失、
    Detail 与「张伟」仍在 → 返回 Holder，card001 仍存在、空态不出现。
  - 查询遵循 Increment 7 bridge 经验：alert/dialog Button 用
    `.matching(identifier:).firstMatch`，中文 label 兜底；helper 均
    `@MainActor`。

### Verification results

```text
Unit:
350 / 350 PASS
27 suites
0 failed
0 disabled
0 skipped

UI:
42 / 42 PASS（serial, -parallel-testing-enabled NO；新增 2 条删除用例）
0 failed
0 disabled
0 skipped

Debug:
BUILD SUCCEEDED

Release:
BUILD SUCCEEDED

Release fixture isolation:
8 / 8 ABSENT
（SimCamCardOCR / DebugOCRProcessor / DebugCameraEnvironment /
 SimCamCardCamera / SimCamCardDetection / SimCamCardCrop /
 SimCamCardPhotoImport / DebugCameraFakes 各 0 匹配，strings 扫描
 Release-iphonesimulator/SimCamCard.app/SimCamCard）

日志：
/tmp/w4i8-unit.log   /tmp/w4i8-ui.log
/tmp/w4i8-debug.log  /tmp/w4i8-release.log
xcresult：
/tmp/w4i8-unit.xcresult  /tmp/w4i8-ui.xcresult
设备：iPhone 18 Pro / iOS 27.0（platform=iOS Simulator,name=iPhone 18 Pro）
```

### Evidence（fixture-driven，非真实数据）

```text
ai/validation/2026-10-04-w4i8-delete-confirmation.png  「提示」确认框（逐字文案/取消/红色删除名片）
ai/validation/2026-10-04-w4i8-holder-after-delete.png  删除后空态：名片 (0张)，扫描 + 与分组入口仍在
ai/validation/2026-10-04-w4i8-more-actions.png         ••• native 更多操作面板（仅红色「删除」）
```

均从全量串行 UI 运行的 `/tmp/w4i8-ui.xcresult` 以 XCTAttachment
（.keepAlways）导出（`xcresulttool export attachments` + activities
name/uuid 映射），已逐一打开核对内容。

### Scope audit（冻结面保持无 diff）

保持无 diff（最终 `git status --short` / `git diff --name-status` 复核）：

```text
dataset/*        spec/*        evidence/*
BusinessCard.swift        PhoneNumber.swift        CardTag.swift
CardNote.swift
BusinessCardRepository.swift
InMemoryBusinessCardRepository.swift
ImageAssetStore.swift
Recognition/*   Edit/*   Search/*   Group Repository 实现
（CardGroupRepository / InMemoryCardGroupRepository）
project.pbxproj（新文件经 PBXFileSystemSynchronizedRootGroup 自动纳入）
```

实际变更面：

```text
M  SimCamCard/ViewModel/CardDetailViewModel.swift
M  SimCamCard/View/CardDetail/CardDetailView.swift
M  SimCamCard/View/CardHolder/CardHolderView.swift
M  SimCamCardTests/ViewModel/CardDetailViewModelTests.swift
M  SimCamCardTests/ViewModel/CardHolderViewModelTests.swift
M  ai/changes.md
A  SimCamCardUITests/CardDeleteUITests.swift
A  ai/validation/2026-10-04-w4i8-delete-confirmation.png
A  ai/validation/2026-10-04-w4i8-holder-after-delete.png
A  ai/validation/2026-10-04-w4i8-more-actions.png
```

### T17 behavioral acceptance

```text
T17 behavioral acceptance: PASS
P07 / More Actions full Reference fidelity: PARTIAL
```

- T17 冻结行为完整实现：More → Delete → confirmation → Cancel / Confirm →
  repository delete → Holder reload → card disappears。
- 删除确认框的 title/message/buttons 与 REF-delete-01 一致。
- 删除最后一张名片后 Holder 进入 0 张空态，scan entry 仍可用。
- 当前 ••• 使用原生 SwiftUI confirmationDialog，只呈现当前真正可用的 Delete。
- iOS 27 实际呈现为锚定 ••• 的 native popover；Reference
  REF-detail-04-more-actions 为底部九宫格 more-actions sheet。
- Reference 中保存通讯录/编辑/分组/备注/提醒等其它 action 不属于本
  Increment，不为了视觉完整度制造 dead controls。
- 因此 T17 required behavior = PASS；当前 P07 More Actions full
  Reference surface fidelity = PARTIAL。
- 后续随着 Notes / Export 等真实功能实现，再统一做 final fidelity sweep。

### T-status

```text
T11 PASS
T12 PASS
T13 PASS
T14 PASS
T15 PASS
T16 PASS
T17 PASS

T18 Persistence:
NOT IMPLEMENTED
```

### Human Decision

Human Decision:
Accepted — 2026-10-04 (human review)

---

## Week 4 Increment 9 — T18 Persistence

### Baseline

```text
分支：week4/structured-recognition
Baseline HEAD：6649434（feat(delete): 实现名片删除流程 = W4I8 T17，已 push）
基线回归：Unit 350/350（27 suites）、UI 42/42、Debug PASS、Release PASS、
fixture isolation 8/8 ABSENT
设备：iPhone 18 Pro / iOS 27.0（platform=iOS Simulator,name=iPhone 18 Pro）
```

### Reference 观察（Reference first，本 Increment 未开始编码前完成）

- `evidence/screenshots/REF-persistence-01-after-relaunch.png`：
  完整杀掉 App 后重新启动，进入「名片详情」，名片仍在：
  - 头部：张伟 / 高级产品总监 | Senior Product Director /
    上海智云科技有限公司；
  - 头部摘要条：+8613800138000、中国 上海市 浦东新区世纪大道 100 号 200120；
  - 分组行：未分组；备注行：备注：2026-09-28 拍名片保存；
  - 展开字段：+86 138 0013 8000（手机）、+86 2155551234（工作电话）、
    wel.zhang@zhiyuntech.com（工作邮箱）、地址、公司（中/英两行）、
    www.zhiyuntech.com（首页）。
- spec/reference-tests.md T18：「After a full quit and relaunch,
  the saved card and retained edited data remain available. The
  termination action itself has no useful screenshot; the post-relaunch
  state is preserved as evidence.」必须保留：original image、processed
  image、corrected fields、group/tag、notes。
- spec/state-inventory.md S10：`savedBeforeQuit` /
  `restoredAfterRelaunch`，同一组 5 项保留清单。
- P10 Notes UI 本 Increment 不实现：Reference 中的备注行不作为新 UI
  交付；`CardNote` 的持久化往返由仓储单元测试证明。

### 架构映射（frozen Domain/protocol 不改动）

```text
BusinessCard / PhoneNumber / CardTag / CardNote（frozen，不加 Codable）
        │  纯 deterministic 映射（init(_:) / func businessCard()）
        ▼
BusinessCardSnapshot / PhoneNumberSnapshot / PhoneKindSnapshot /
CardTagSnapshot / CardNoteSnapshot（Persistence 层私有 Codable DTO）
        │  JSONEncoder/Decoder（Date = timeIntervalSinceReferenceDate
        │  Double，无损 Domain round-trip；不用 ISO8601 文本以免截断
        │  亚毫秒精度）
        ▼
cards.json / groups.json（schemaVersion = 1）
images/<base64url(reference)>.asset（原始字节，atomic write）

BusinessCardRepository（frozen protocol）
  └─ actor FileBusinessCardRepository（新实例即重新读盘 = T18 证据）
CardGroupRepository（frozen protocol）
  └─ actor FileCardGroupRepository（groups.json 是独立权威 catalog）
ImageAssetStore（frozen protocol，不加删除 API；孤儿资源本轮不 GC）
  └─ actor FileImageAssetStore（base64url 文件名，slash/unicode 安全）
```

- 新目录 `SimCamCard/Persistence/` 与
  `SimCamCardTests/Persistence/` 均经
  `PBXFileSystemSynchronizedRootGroup` 自动纳入；
  **不修改 project.pbxproj**。
- 所有 File 仓储为 `actor`（Swift 6 并发：无 mutable class、无锁、
  无 @unchecked Sendable）。
- 变更流程：读快照 → 构造 next 数组 → 编码 → 建父目录 →
  `Data.write(to:options:.atomic)` → 成功后才提交内存缓存；
  绝不先截断再写。

### 磁盘布局

```text
生产：
<Application Support>/SimCamCard/v1/
  cards.json    BusinessCardStoreDocument { schemaVersion:1, cards:[…] }
  groups.json   CardGroupStoreDocument   { schemaVersion:1, groups:[…] }
  images/       <base64url(reference)>.asset（同一 reference 覆盖）

DEBUG persistent-test（绝不与生产 v1 重叠）：
<Application Support>/SimCamCard/uitests/<sanitized-namespace>/
  cards.json / groups.json / images/
```

### DEBUG launch contract（Release 整体编译移除）

```text
-SimCamCardStorage ephemeral
    → 三个 InMemory 实现；-SimCamCardFixture 仅在此模式 seed
      （mock 数据永不写入生产磁盘）
-SimCamCardStorage persistent-test
    + -SimCamCardStorageNamespace <name>
    + -SimCamCardResetStorage <true|false>（仅 true 的那次启动 wipe）
    → 独立命名空间下的 File*；第二次启动必须带 false
无参数 DEBUG 手动启动 / Release：
    → 真实生产持久化（dev/Release parity），Release 无任何测试 hook
```

### 实现清单

```text
生产代码（新增，Persistence/ 经 PBXFileSystemSynchronizedRootGroup 自动纳入）：
A  SimCamCard/Persistence/PersistencePaths.swift
   - rootDirectory/cardsFile/groupsFile/imagesDirectory
   - production（SimCamCard/v1）与 persistentTest（SimCamCard/uitests/<ns>）布局
A  SimCamCard/Persistence/PersistenceSnapshots.swift
   - BusinessCardStoreDocument / CardGroupStoreDocument（schemaVersion=1）
   - BusinessCardSnapshot / PhoneNumberSnapshot / PhoneKindSnapshot /
     CardTagSnapshot / CardNoteSnapshot（持久化专用 Codable，Domain 不 Codable）
   - PhoneKind 双向 exhaustive switch（未知 raw 在 Codable 边界失败，不静默 .other）
   - PersistenceJSON：Date 以 timeIntervalSinceReferenceDate Double
     持久化（IEEE 754 位级精确往返；ISO8601 文本会截断亚毫秒精度）、
     sortedKeys/prettyPrinted/withoutEscapingSlashes
A  SimCamCard/Persistence/FileBusinessCardRepository.swift
   - actor；init 读盘，缺文件=空；save 同 id replace；delete 缺省 no-op
   - next→encode→建目录→.atomic write→成功后提交内存
A  SimCamCard/Persistence/FileCardGroupRepository.swift
   - actor；groups.json 独立权威 catalog；空分组独立持久化
A  SimCamCard/Persistence/FileImageAssetStore.swift
   - actor；Base64URL 文件名（+/= 转义，.asset 后缀，injective 无碰撞）
   - atomic、懒建目录、缺资源 nil；本轮不做孤儿 GC（协议不加删除 API）
A  SimCamCard/Persistence/RuntimeStorageConfiguration.swift（#if DEBUG 整体）
   - 解析 -SimCamCardStorage ephemeral|persistent-test、
     -SimCamCardStorageNamespace（白名单消毒）、-SimCamCardResetStorage
M  SimCamCard/App/SimCamCardApp.swift
   - 存储属性升级为 any BusinessCardRepository / any CardGroupRepository /
     any ImageAssetStore；File/InMemory 具体类型不泄漏到 View/ViewModel
   - DEBUG：ephemeral=InMemory+fixture seed；persistent(-test)=共享 root 的 File*
   - Release：恒为生产 File*，测试 hook 零编译

测试代码：
A  SimCamCardTests/Persistence/PersistenceTestSupport.swift（临时目录 + max-info card）
A  SimCamCardTests/Persistence/PersistenceSnapshotTests.swift
A  SimCamCardTests/Persistence/FileBusinessCardRepositoryTests.swift
A  SimCamCardTests/Persistence/FileCardGroupRepositoryTests.swift
A  SimCamCardTests/Persistence/FileImageAssetStoreTests.swift
A  SimCamCardTests/Persistence/RuntimeStorageConfigurationTests.swift（#if DEBUG）
A  SimCamCardUITests/UITestAppFactory.swift（launchEphemeral/launchPersistent）
A  SimCamCardUITests/CardPersistenceUITests.swift
   （w4i9-t18-persistence：写入→terminate(.notRunning)→reset:false 重启）
M  现有 10 个 UI 测试文件全部改经 UITestAppFactory（ephemeral），
   fixture/camera/detection/crop/ocr 参数原样透传，产品行为零改动
```

### 提交前校准（Date 无损 round-trip，仅编码格式，UI/Domain/协议/schema 均未动）

```text
变更：PersistenceJSON 的 Date 编解码由 ISO8601 文本（毫秒精度截断）
  改为 date.timeIntervalSinceReferenceDate JSON Double
  （decode = Date(timeIntervalSinceReferenceDate:)）——
  Date 即 IEEE 754 Double，原值位级精确往返。
测试：fixture 三处日期改为互不相同的非毫秒对齐亚毫秒值
  （123_456_789.123_456_7 / 765_432_109.246_813_5 / 987_654_321.135_792_4，
  timeIntervalSinceReferenceDate）；
  原 ISO8601 毫秒往返测试重写为 subMillisecondDatesSurviveJSON
  （Domain→Snapshot→JSON→decode→Domain 全链路，断言 restored == original
  及 createdAt/updatedAt/notes[0].createdAt 三处精确相等，无 round/tolerance，
  另以 JSONSerialization 钉住 JSON 数值表示）；
  新增 dateCodecBitExactForArbitraryDoubles（含负区间与远未来区间）。
  schemaVersion 仍为 1；无已提交生产 v1 数据，无需 migration。
  三张 T18 UI evidence 不重生成（可见 UI 行为未变）。
```

### Verification results

```text
设备：iPhone 18 Pro / iOS 27.0；UI 全程串行（-parallel-testing-enabled NO）。
主验证轮（编码格式变更前）：
Unit：PASS — 383 tests in 32 suites, 0 failures
  （基线 350/27，本 Increment +33 tests、+5 suites）
  bundle /tmp/w4i9-unit.xcresult；log /tmp/w4i9-unit.log
UI：PASS — Executed 43 tests, 0 failures (0 unexpected) in 782.171s
  （基线 42/42 + 新增 CardPersistenceUITests 1 个，= 43/43）
  bundle /tmp/w4i9-ui.xcresult；log /tmp/w4i9-ui.log
校准回归轮（Date Double 编码后，最终门控）：
Unit：PASS — 384 tests in 32 suites, 0 failures（>383 达标，+1 编解码位级测试）
  bundle /tmp/w4i9c-unit2.xcresult；log /tmp/w4i9c-unit2.log
UI：PASS — Executed 43 tests, 0 failures (0 unexpected) in 970.923s
  bundle /tmp/w4i9c-ui.xcresult；log /tmp/w4i9c-ui.log
  （CardPersistenceUITests passed 71.991s）
  措辞校准：UI terminate/relaunch proves persisted numeric Date
  documents can be decoded by a fresh app process. Exact
  sub-millisecond Date round-trip is proven by persistence unit tests.
Debug build：** BUILD SUCCEEDED **（exit 0，/tmp/w4i9c-debug.log）
Release build：** BUILD SUCCEEDED **（exit 0，/tmp/w4i9c-release.log）

Release fixture isolation（Release-iphonesimulator/SimCamCard.app/SimCamCard,
7.4MB 静态主二进制，bundle 内无 dylib；strings -a | grep -c，8/8 ABSENT）：
  SimCamCardOCR 0 / DebugOCRProcessor 0 / DebugCameraEnvironment 0 /
  SimCamCardCamera 0 / SimCamCardDetection 0 / SimCamCardCrop 0 /
  SimCamCardPhotoImport 0 / DebugCameraFakes 0
Release storage hooks N/N ABSENT（3/3，同一二进制）：
  SimCamCardStorage 0 / SimCamCardStorageNamespace 0 / SimCamCardResetStorage 0
阳性对照（DEBUG 代码位于 SimCamCard.debug.dylib，12MB；
  主可执行仅 89KB 为 ENABLE_DEBUG_DYLIB 启动桩，故对照扫描 dylib）：
  SimCamCardOCR=2、SimCamCardStorage=4、SimCamCardStorageNamespace=2、
  SimCamCardResetStorage=2 —— 证明扫描方法有效，hook 仅 DEBUG 编译。
生产持久化代码已静态链入 Release（BusinessCard=26、PersistencePaths=2、
  FileBusinessCardRepository=4 命中）。

磁盘旁证（校准回归轮成功运行后命名空间
  <App Support>/SimCamCard/uitests/w4i9-t18-persistence/）：
  cards.json（schemaVersion 1；1 张张伟；jobTitle=
  高级产品总监 | Senior Product Director；tags=[{id,name=客户}]；
  createdAt/updatedAt 为 JSON 数值
  （如 812817699.697366）—— Double 格式落盘实证）；
  groups.json（schemaVersion 1；独立 catalog 含 客户，group id 与
  card tags[0].id 一致）；images/ 下 2 个 .asset（原始+处理后）。
  容器内无 v1 目录 —— 测试数据绝不接触生产路径。
```

### Evidence（fixture-driven persistent-test evidence）

```text
全部为 terminate(.notRunning) 后第二次启动（reset:false，全新 App/仓储实例）
截图；从 /tmp/w4i9-ui.xcresult 按附件名导出，已逐张人工核对：
ai/validation/2026-10-04-w4i9-persistence-holder-after-relaunch.png
  名片夹：张伟 / 高级产品总监 | Senior Product Director ·
  上海智云科技有限公司（修正后职位在重启后保留）。
ai/validation/2026-10-04-w4i9-persistence-detail-after-relaunch.png
  名片详情：张伟 + 修正后职位 + 公司；手机 +86 138 0013 8000、
  工作电话 +86 21 5555 1234、邮箱 wei.zhang@zhiyuntech.com、
  首页 www.zhiyuntech.com、公司地址 —— 五字段全保留。
ai/validation/2026-10-04-w4i9-persistence-group-after-relaunch.png
  分组管理：我的分组 → 客户 (1)（独立 catalog + 成员计数跨重启保留；
  测试随后点入并断言 group-filter-active、张伟行与 card-row-thumbnail
  均存在 —— 图像资源同路径恢复，自动断言通过）。
自动化证据（非截图）：File*Repository 单元测试对临时目录的写入/
  重新读盘往返；上述容器内 cards.json / groups.json / images/*.asset。
人工证据：上面 3 张重启后 PNG（已查看核对）。
```

### Scope audit（冻结面保持无 diff）

```text
git status --short（最终）

已跟踪文件被修改（14 个，git diff --name-status 全部为 M）：
  生产（3，仅装配根与 DEBUG 预览支撑）：
    M SimCamCard/App/SimCamCardApp.swift
    M SimCamCard/View/PreviewSupport/MockBusinessCards.swift
    M SimCamCard/View/PreviewSupport/SimCamCardFixture.swift
  UI 测试（10，仅迁移到 UITestAppFactory 启动契约）：
    M SimCamCardUITests/CardDeleteUITests.swift
    M SimCamCardUITests/CardDetailUITests.swift
    M SimCamCardUITests/CardGroupUITests.swift
    M SimCamCardUITests/CardHolderEmptyUITests.swift
    M SimCamCardUITests/CardHolderPopulatedUITests.swift
    M SimCamCardUITests/CardSearchUITests.swift
    M SimCamCardUITests/ScanCameraUITests.swift
    M SimCamCardUITests/ScanEntryUITests.swift
    M SimCamCardUITests/SimCamCardUITests.swift
    M SimCamCardUITests/Week2IntegrationUITests.swift
    M ai/changes.md
未跟踪新增（17 个）：
    SimCamCard/Persistence/PersistencePaths.swift
    SimCamCard/Persistence/PersistenceSnapshots.swift
    SimCamCard/Persistence/FileBusinessCardRepository.swift
    SimCamCard/Persistence/FileCardGroupRepository.swift
    SimCamCard/Persistence/FileImageAssetStore.swift
    SimCamCard/Persistence/RuntimeStorageConfiguration.swift（#if DEBUG）
    SimCamCardTests/Persistence/PersistenceTestSupport.swift
    SimCamCardTests/Persistence/PersistenceSnapshotTests.swift
    SimCamCardTests/Persistence/FileBusinessCardRepositoryTests.swift
    SimCamCardTests/Persistence/FileCardGroupRepositoryTests.swift
    SimCamCardTests/Persistence/FileImageAssetStoreTests.swift
    SimCamCardTests/Persistence/RuntimeStorageConfigurationTests.swift
    SimCamCardUITests/UITestAppFactory.swift
    SimCamCardUITests/CardPersistenceUITests.swift
    ai/validation/2026-10-04-w4i9-persistence-holder-after-relaunch.png
    ai/validation/2026-10-04-w4i9-persistence-detail-after-relaunch.png
    ai/validation/2026-10-04-w4i9-persistence-group-after-relaunch.png

冻结面（git diff --quiet 逐个确认 CLEAN，无任何 diff）：
  spec/、dataset/、evidence/；
  SimCamCard/Model/{BusinessCard,PhoneNumber,CardTag,CardNote}.swift；
  BusinessCardRepository / CardGroupRepository / ImageAssetStore 三协议；
  Recognition/、Edit/（含 BusinessCardEditDraft）、Search/
  （含 BusinessCardSearchMatcher）；SimCamCard.xcodeproj/project.pbxproj
  （3 个 PBXFileSystemSynchronizedRootGroup 自动纳入新目录）。
未 commit、未 push。
```

### T18 behavioral acceptance

```text
T18 Persistence：PASS
  端到端（CardPersistenceUITests.testSavedCardEditAndGroupSurvive
  FullTerminateAndRelaunch，43/43 之一）：扫描 OCR → 保存名片 →
  编辑职位（产品总监 | Product Director →
  高级产品总监 | Senior Product Director）→ 新建分组「客户」并加入 →
  terminate(.notRunning) 完整杀掉 → reset:false 重新启动（全新 App/
  File*Repository 实例，init 即重新读盘）→ 名片夹行、名片详情全字段、
  分组 catalog 客户 (1)、组过滤下的名片行与缩略图全部恢复。
  保留项覆盖 S10 五项：original image / processed image
  （images/ 2 个 .asset，引用不变即同名覆盖恢复）、corrected fields
  （修正后职位）、group/tag（groups.json 独立 catalog +
  card.tags 同 id）、notes（BusinessCard.notes 经
  FileBusinessCardRepository 往返单元测试覆盖）。
  首跑曾因中文 IME 软键盘吞掉「新建分组」弹窗的首次确认点击失败；
  根因是测试交互时序（失败时刻 AX 层级显示弹窗仍在、createGroup
  未执行、磁盘无 groups.json），产品代码无缺陷。修复仅在测试侧：
  对输入框发回车提交 IME → 重新解析并点击 完成 →
  waitForNonExistence 显式确认弹窗关闭（含一次保护性重试）。
  复测单测 83.17s 通过，随后全量 UI 43/43 通过。
P10 Notes UI：NOT IMPLEMENTED（Reference 备注行不作为新 UI 交付；
  BusinessCard.notes / CardNote 持久化由仓储单元测试覆盖）
T19 Export：NOT IMPLEMENTED
```

### T-status

```text
T11 PASS
T12 PASS
T13 PASS
T14 PASS
T15 PASS
T16 PASS
T17 PASS
T18 Persistence：PASS（Unit 384/32（校准后 >383）；UI 43/43；Debug/Release PASS；
  Release fixture hooks 8/8 + storage hooks 3/3 ABSENT；
  P10 Notes UI / T19 Export NOT IMPLEMENTED）
```

### Human Decision

Human Decision:
Accepted — 2026-10-04 (human review)

## Week 4 Increment 10 — P10 Notes

### Baseline

```text
分支：week4/structured-recognition
Baseline HEAD：e8af2b4（feat(persistence): 实现名片本地持久化，已 push）
working tree clean；git pull --ff-only = Already up to date。
基线回归：Unit 384/384（32 suites）、UI 43/43、Debug PASS、Release PASS、
fixture isolation 8/8 ABSENT、storage-hook isolation 3/3 ABSENT。
设备：iPhone 18 Pro / iOS 27.0（platform=iOS Simulator,name=iPhone 18 Pro）。
```

### Reference 观察（Reference first，编码前完成）

亲自查看 evidence/screenshots/REF-notes-01-page.png，并复查
REF-detail-01-collapsed.png / REF-detail-04-more-actions.png：

- **页面性质**：独立 push 页面。导航栏居中标题「备注」，左上 < 返回
  chevron（Back → Detail），不是 alert/sheet。
- **历史行视觉结构（页面内唯一一条）**：
  - 第一行：左侧粗体标题「名片保存」，右侧同一行时间戳
    「2026-09-28 22:52」；
  - 第二行：灰色「来源：拍名片保存」。
  - 这是 Reference App 在拍名片保存时生成的**系统记录型条目**
    （带标题 + 来源类型），不是用户自由文本备注。冻结 Domain
    CardNote 只有 { id, text, createdAt }，无法也不应伪造
    noteTitle/noteType；本 Increment 历史行只渲染 text + createdAt。
- **Add Note 入口**：页面底部一条通栏亮蓝色圆角按钮
  「+ 新增备注」——是页面级底部按钮，不是导航栏 + 号。
- **Add Note 编辑器呈现：Reference 未捕获**（state-inventory S08
  明确：addingNote entry observed; saved custom note not yet
  captured）。编辑器形态、placeholder、保存/取消按钮属于
  SimCamCard completion behavior，不声称 Reference pixel fidelity。
- **空历史态：Reference 无证据**。使用中性文案「暂无备注」
  （identifier card-notes-empty），记录为 completion behavior。
- **时间戳格式**（REF 唯一可见事实）：`yyyy-MM-dd HH:mm`
  （2026-09-28 22:52，无秒）。
- **历史排序**：Reference 仅一条，无法证明排序规则；保持 Domain
  notes 数组现有顺序（新 note append 到末尾），不擅自按 createdAt
  reverse —— fidelity ambiguity。
- **Detail 入口（REF-detail-01）**：头部 action strip 四个圆形按钮
  电话(蓝)/地址(琥珀)/备注(绿色圆底白色文档线条图标)/编辑(青底铅笔)。
  本 Increment 只把「备注」做成真实功能（card-detail-notes，SF Symbol
  note.text 最接近 REF 图标，绿色为近似值）；电话/地址仍是不渲染的
  deferred 项，不造死按钮。REF 中另有一条内联行
  「备注: 2026-09-28 拍名片保存」带 chevron —— 该内联摘要依赖系统
  保存记录语义（标题/来源），本 Increment 不实现，记录为 fidelity
  difference（两个 Notes entry 按计划为 strip + More Actions）。
- **More Actions 入口（REF-detail-04）**：底部 action grid 第二行含
  分组/备注/提醒/删除，第一行含 保存到通讯录/编辑/邀请使用名片全能王。
  当前 confirmationDialog 只有删除；现新增「备注」
  （card-detail-more-notes）与删除并列。保存到通讯录留 T19；
  分组/提醒/邀请 无完整 live path，不渲染。
- **S08 解释边界**：historyVisible / addingNote 两态有 Reference 依据；
  「自定义备注保存后的样式」Reference 未捕获，可工作的 Add Note 保存
  是 assignment core-behavior completion，不是未观察到的 Reference 事实。

### 冻结面（本 Increment 无 diff）

```text
Domain：BusinessCard.swift / CardNote.swift / PhoneNumber.swift /
  CardTag.swift 不动；CardNote 不加 Codable、不加 title/type/status/
  updatedAt/HTML/attachment。
Persistence：BusinessCardRepository 协议、FileBusinessCardRepository、
  PersistenceSnapshots/PersistencePaths、schemaVersion=1 全部不动。
  Notes 保存只走 repository.save(updatedCard) 既有能力。
不新增第二个 owning ViewModel；不使用/改造 BusinessCardEditDraft。
spec/ dataset/ evidence/ project.pbxproj 无 diff。
```

### NoteState 设计与状态所有权

- CardDetailViewModel 内新增**第三个独立状态族** NoteState
  （historyVisible / addingNote(String) / saving(String)），与
  EditState、DeleteState 并列；不新增 ViewModel、不新增聚合类型、
  不经 BusinessCardEditDraft。
- 唯一事实源：`private(set) var card: BusinessCard`；`var notes:
  [CardNote] { card.notes }` 只是投影。CardNotesView 不持有
  [CardNote] 副本，不持有 repository，草稿 String 也只存在
  noteState 关联值里，经 updateNoteDraft(_:) 进出。
- 保存语义：trim → 构造 CardNote（注入式 id/createdAt 默认值，测试可
  固定）→ `private nonisolated static func appending(note:to:updatedAt:)`
  纯函数生成同 id 新聚合（其余字段逐项原样搬运，notes = old + [note]，
  updatedAt = 保存时刻）→ 既有 `repository.save(updatedCard)` 同 id
  replace → `self.card = updated` → historyVisible。历史行立即出现。
- 取消：仅 `.addingNote → .historyVisible`，丢弃草稿，card/repository
  不动；`.saving` 中取消为 no-op。空白 trim 草稿留在 .addingNote
  （View 层 Save 同时禁用，双保险）。
- 互斥：beginAddingNote 要求 historyVisible + viewing + idle；
  beginEditing / requestDelete 在 note 工作流激活时 stable no-op；
  saving 窗口内 cancel/draft/edit/delete/重入 save 全部忽略。
  gate actor 单测确定性地观测了 saving 窗口。
- 排序：保持 Domain notes 数组顺序（追加在末尾），不按时间翻转
  （Reference 仅一条，无法证明规则）。

### 实现清单

```text
SimCamCard/ViewModel/CardDetailViewModel.swift（M）
  - NoteState 枚举、noteState、notes 投影
  - beginAddingNote / updateNoteDraft / cancelAddingNote / saveNote
  - appending(note:to:updatedAt:) 纯函数
  - beginEditing / requestDelete 增加 noteState 互斥守卫
SimCamCard/View/CardDetail/CardNotesView.swift（新增）
  - push 页面 card-notes，标题「备注」；card-notes-history
  - 行 card-note-<uuid>：text + yyyy-MM-dd HH:mm
  - 空态 card-notes-empty「暂无备注」（无 REF 证据，completion）
  - 底部蓝色通栏 card-notes-add「+ 新增备注」
  - 同页编辑器 card-note-editor
    （TextEditor，多行，placeholder 为 completion）
  - card-note-cancel / card-note-save（trim 非空才可点，
    saving 时禁用全部控件并显示 ProgressView）
  - 所有状态 marker（card-notes / card-notes-history）挂在无子节点的
    背景/overlay 层，避免 SwiftUI 容器 accessibilityIdentifier 向子
    Button 传播覆盖子控件自身 id（同 ScanEntryView 记录的坑）
SimCamCard/View/CardDetail/CardDetailView.swift（M）
  - action strip 绿色 note.text「备注」card-detail-notes（3rd slot）
  - more-actions dialog 新增 card-detail-more-notes
  - @State showNotes + navigationDestination(isPresented:) push
  - strip 两个 Button 显式 .buttonStyle(.plain)：修复一个真实缺陷——
    List 同一行内多个默认（.automatic）样式 Button 会各自退化为整行
    action，一次 tap 同时触发「备注」push 与「编辑」sheet（P10 首轮
    UI 回归 5 个失败的共同根因，经临时探针 record='notes;edit;' 证实）
SimCamCardTests/ViewModel/CardDetailViewModelTests.swift（M，+8 tests）
SimCamCardUITests/CardNotesUITests.swift（新增，3 tests）
SimCamCardUITests/CardPersistenceUITests.swift（M）
  - 重命名 testSavedCardEditGroupAndNoteSurviveFullTerminateAndRelaunch
  - launch1 终止前真实走 Detail→Notes→新增「跟进客户」
  - launch2 Detail→Notes 断言备注存在 + w4i10-note-after-relaunch
```

### Verification results

```text
设备：iPhone 18 Pro / iOS 27.0，全部 xcodebuild 串行
（-parallel-testing-enabled NO）。

Unit：392 tests / 32 suites 全部 PASS，exit 0
（/tmp/w4i10-unit2.xcresult，含 P10 新增 8 例）。
Final authoritative full UI gate: 46 / 46 PASS，
0 failures，0 unexpected（/tmp/w4i10-ui5.xcresult，1130.6s）。
Earlier diagnostic runs exposed:
  - SwiftUI List-row dual Button action
  - transient confirmationDialog AX timing
Both were resolved before the final clean gate.
CardNotesUITests additionally passed: 9 / 9 across 3 repeated
iterations（-test-iterations 3，/tmp/w4i10-notes3.xcresult）。
Debug build（iphonesimulator）：PASS，0 error。
Release build（iphonesimulator）：PASS，0 error。
Fixture isolation（Release 主二进制 7,996,944B，无 dylib）：
  SimCamCardOCR/DebugOCRProcessor/DebugCameraEnvironment/
  SimCamCardCamera/SimCamCardDetection/SimCamCardCrop/
  SimCamCardPhotoImport/DebugCameraFakes = 0/0/0/0/0/0/0/0（8/8 ABSENT）
Storage hooks：SimCamCardStorage/SimCamCardStorageNamespace/
  SimCamCardResetStorage = 0/0/0（3/3 ABSENT）
Debug 阳性对照（SimCamCard.debug.dylib）：上述 11 个符号全部 >0，
扫描机制有效。

回归中发现并修复的真实产品缺陷（非测试问题）：
  Detail action strip 是 List 同一行内两个默认样式 Button；
  .automatic 样式在 List row 中使每个 Button 退化为整行 action，
  一次点击同时执行「备注」与「编辑」两个闭包（临时跨页记录探针实测
  record='notes;edit;'）。现象：点备注 push 备注页的同时编辑 sheet
  盖在上面，导致 card-notes-add 命中点 {-1,-1} 不可点；点编辑保存/
  取消后落到备注页而非详情页——首轮 UI 5 个失败同源。修复：两个
  Button 显式 .buttonStyle(.plain)，修复后探针实测
  点备注 record='notes;'（仅备注页）、点编辑 record='edit;'
  （仅 sheet）。
```

### Evidence

```text
以下 3 张均由 /tmp/w4i10-ui5.xcresult 导出并逐张人工核对，
全部 fixture-driven（populated fixture / w4i9-t18-persistence
ephemeral namespace），非手工摆拍：

ai/validation/2026-10-05-w4i10-notes-history.png
  备注 push 页：居中标题「备注」+ 左上 chevron；空态卡片
  「暂无备注」；底部亮蓝通栏「+ 新增备注」。页面/标题/返回/
  蓝色入口与 REF-notes-01 同构（REF 首条为系统记录行，本图为空态）。
ai/validation/2026-10-05-w4i10-note-added.png
  新增并保存「跟进客户」后历史立即出现该行，caption 时间戳
  2026-10-05 03:40（yyyy-MM-dd HH:mm），空态消失。
ai/validation/2026-10-05-w4i10-note-after-relaunch.png
  terminate app → 重新启动（状态栏 03:42）→ Detail→备注，
  「跟进客户」仍在（时间戳 03:41 为第一次启动保存时刻），
  证明 FileBusinessCardRepository 跨进程持久化。
```

### Scope audit

```text
git diff --name-status（tracked，5 个）：
M  SimCamCard/View/CardDetail/CardDetailView.swift
M  SimCamCard/ViewModel/CardDetailViewModel.swift
M  SimCamCardTests/ViewModel/CardDetailViewModelTests.swift
M  SimCamCardUITests/CardPersistenceUITests.swift
M  ai/changes.md
Untracked（5 个）：
?? SimCamCard/View/CardDetail/CardNotesView.swift
?? SimCamCardUITests/CardNotesUITests.swift
?? ai/validation/2026-10-05-w4i10-notes-history.png
?? ai/validation/2026-10-05-w4i10-note-added.png
?? ai/validation/2026-10-05-w4i10-note-after-relaunch.png

冻结面 git status 复查全部 CLEAN：
SimCamCard/Model、SimCamCard/Persistence、SimCamCard/Repository、
SimCamCard/Recognition、SimCamCard/Edit、SimCamCard/Search、
spec/、dataset/、evidence/、SimCamCard.xcodeproj
（PBXFileSystemSynchronizedRootGroup 自动收纳新增文件）。
无第二个 ViewModel、无第二份 [CardNote] 副本、无第二个 draft
String；备注保存只经 BusinessCard → repository.save(updatedCard)。
调试期临时探针文件（DiagTEMP.swift / DiagnosticTEMPUITests.swift）
已全部删除，产物中无 DIAG 残留符号。
未 commit、未 push、未创建分支。
```

### P10 behavioral acceptance

```text
P10 required-scope behavior：PASS
  - Detail→备注 push（action strip 与 more-actions 两个入口等价）。
  - 空历史显示「暂无备注」；新增→输入→保存→行立即进入历史；
    时间戳 yyyy-MM-dd HH:mm。
  - 取消不落库（重开仍为空）；纯空白保存被拒（trim 守卫 + 按钮禁用）。
  - 离开/重开备注仍在（同一 BusinessCard 聚合，无 View 副本）。
  - terminate app → 重新启动后备注仍在（真实 E2E，T18 升级）。
  - 备注/编辑/删除三状态族互斥有单测与 UI 覆盖。
P10 full Reference fidelity：PARTIAL（按计划记录的差距，非缺陷）
  一致：push 页形态、居中「备注」标题、plain back chevron、
    历史行 text+时间戳同行、底部亮蓝「+ 新增备注」通栏按钮。
  差距：
    1) REF 首条是系统记录型「名片保存 / 来源：拍名片保存」，
       冻结 CardNote{id,text,createdAt} 无 title/type，不仿造；
    2) Add-note 编辑器 REF 未捕获（S08 completion behavior）；
    3) 空历史态 REF 无证据（completion behavior）；
    4) Detail 内联备注摘要行「备注: 2026-09-28 拍名片保存」
       依赖系统记录语义，本 Increment 不实现；
    5) 历史排序保持数组 append 顺序，REF 仅一条无法证明规则。
T19 Contact Export：NOT IMPLEMENTED
T20 Final sweep：NOT IMPLEMENTED
```

### T-status

```text
T11–T18 PASS（全量 46 UI + 392 Unit 回归）
P10 Notes required behavior：PASS（Reference fidelity PARTIAL，差距如上）
T19 Contact Export：NOT IMPLEMENTED
T20 Final exception/fidelity sweep：NOT IMPLEMENTED
额外修复：action strip 同行双 Button 的 List-row action 误触发缺陷
（见 Verification results），T14 编辑入口因此也更健壮。
```

### Human Decision

Human Decision:
Accepted — 2026-10-05 (human review)

---

## Week 4 Increment 11 — T19 Contact Export

### Baseline

```text
branch: week4/structured-recognition
HEAD: 68c10ca71d5c62390056699b714ea94b8ad37142
      feat(notes): 实现名片备注管理
working tree: clean（git pull --ff-only: Already up to date）

Regression baseline (W4I10 accepted):
Unit 392/392 PASS，32 suites
UI 46/46 PASS，0 failures，0 unexpected
Debug PASS / Release PASS
Release fixture isolation 8/8 ABSENT
Release storage-hook isolation 3/3 ABSENT
```

### Reference first — REF-export-01..05 + REF-detail-01/04

```text
REF 环境：参考 App「名片全能王」(CamCard_zh_lite.app) 运行在
macOS / Mac Catalyst 风格环境（窗口红绿灯、Contacts for Mac）。
我们的目标是 iOS 27 真机/模拟器，因此只抽取行为与字段语义，不复制
macOS 专有的账号选择器等控件。

REF-export-01-contacts-permission.png
  - 触发：名片详情（张伟卡）。
  - 弹框是【系统】通讯录授权弹窗（带 Contacts 图标+手掌 badge），
    不是 App 自绘框。
    标题：允许"CamCard_zh_lite.app"访问你的联系人?
    正文：我们需要获取您的通讯录权限读取导入通讯录联系人信息以及
          将名片信息保存到通讯录
    按钮：不允许 / 允许
  - 底层 Detail 底部栏可见：左下「存入通讯录」卡片图标按钮，
    中间「向对方递名片」，右侧绿色「分享名片」。

REF-export-02-permission-denied.png
  - 一个标题为「保存到通讯录」的模态页面：左上「取消」，居中标题，
    无右上确认按钮。
  - 灰色说明行：无法保存名片到通讯录
  - 白色可点行：点击设置通讯录权限（→ 系统 Settings）
  - 即 denied state 有独立 UI 面（不是 toast），提供 Settings 跳转
    和取消。

REF-export-03-contact-destination.png
  - 同一个「保存到通讯录」模态（取消 / 右上确认），内容是
    【系统 Contacts 账号/目的地选择器】：多个 iPad 分组/账号行
    （单选 radio，一行已勾选）+ Mac 行。
  - 结论：这是参考环境（macOS Contacts 多账号：iCloud/Google/
    On My Mac 等）的系统目的地选择页，属于 verification-only
    evidence，不是参考 App 自己的页面。
  - iOS 只有单一默认 Contacts 账号，CNContactStore+CNSaveRequest
    直接写入默认账号，不呈现该选择器；本 Increment 不制造对应页面。

REF-export-04-contacts-app-summary.png（陈晨卡，即 card-003 形态）
  系统 Contacts App 中新建联系人可见：
  - 姓名：陈晨（完整名作为联系人显示名，单一字段呈现）
  - 职位+公司连排：商务拓展经理 Business Development Manager·
    上海智云科技有限公司 Shanghai Zhiyun Tech Co., Ltd.
  - 手机  +86 136 8888 1024
  - 工作  +86 (21) 5666 7788
  - 工作传真 +86 (21) 5666 7799
  - 工作  chen.chen@zhiyuntech.com
  - 工作  地址（下沿露出：中国/上海市/徐汇区漕溪北路398号/200030）

REF-export-05-contacts-app-fields.png（继续向下滚动）
  - 三条电话 label：手机 / 工作 / 工作传真（值与 04 一致）
  - email label：工作
  - 地址 label：工作；多行：中国 / 上海市 / 徐汇区漕溪北路398号 /
    200030（参考 App 把结构化地址分行；Domain 只有单 String）
  - 第二个「工作」地址块露出残字（参考数据自身异常，不采纳）
  - 主页：http://www.zhiyuntech.com  ← website 确实被保存
  - 备注：空块
  - 系统行：共享联系人 / 屏蔽联系人

REF-detail-01-collapsed.png
  - 底部栏左下确有「存入通讯录」独立入口（通讯录+人像图标）。

REF-detail-04-more-actions.png
  - 底部••• 网格第一行第一格：保存到通讯录（绿色通讯录图标）；
    同行：编辑、邀请使用名片全能王；
    第二行：分组 / 备注 / 提醒 / 删除。
  - 展开态字段小字 label 旁证：手机 / 工作电话 / 工作邮箱 /
    公司地址。

P11/S09/T19 解读：
  - P11 = App + System：权限由系统弹；denied 是 App 内结果面；
    成功目的地是系统 Contacts（无独立 App 页面）。
  - S09 四态：contactsPermissionUnknown / Denied / Allowed /
    exportSucceeded；requesting/exporting/failed 为运行期瞬态。
  - T19 frozen acceptance：name/company/jobTitle/phone/email/
    address 六组字段进入系统 Contact；多电话多邮箱不丢失；
    缺失字段不伪造。
  - website 观察（REF-05 主页）：记录为 Reference observation，
    本 Increment 不映射（frozen T19 不含 website；§3 明确禁止
    擅自扩大）。
  - email/地址 label「工作」：REF 明确可见，但 frozen spec T19
    只要求 value survive、未要求 label；按计划 §10 的保守原则，
    email 不凭空声称 work/home，使用 CNLabelOther；地址同样使用
    CNLabelOther。REF label 差异记为 fidelity gap。
  - name：不拆中文姓名，完整字符串放入单个 CN 姓名属性
    （givenName 承载完整串，Contact 显示名即完整姓名）。
```

### Export entry / UI 面规划

```text
入口（两处，同一 workflow）：
  1) Detail ••• more-actions：新增「保存到通讯录」
     id=card-detail-more-export（置于备注之前，对齐 REF 网格首位）
  2) Detail 底部：「存入通讯录」底部按钮
     id=card-detail-export（对齐 REF-detail-01 底部栏左下入口；
     递名片/分享不属于本 App，不造）
结果面（App 内）：
  - requestingPermission/exporting：按钮内 ProgressView + 禁用，
    不新增页面。
  - permissionDenied：alert，id=contact-export-denied
    标题「无法保存名片到通讯录」（对齐 REF-02 文案），
    「点击设置通讯录权限」→ UIApplication.openSettingsURLString
    （REF-02 明确有 Settings 入口），「取消」回到 idle。
  - exportSucceeded：alert「已保存到通讯录」，单个「好」。
  - exportFailed：alert「保存到通讯录失败」+「好」。
```

### Architecture

```text
SimCamCard/Export/（新增，随 PBXFileSystemSynchronizedRootGroup 自动入 target）
  ContactExporting.swift     — ContactAuthorizationState /
                               ContactExportReceipt / ContactExporting
  ContactExportPayload.swift — Payload + ContactExportPhone（Sendable）
  BusinessCardContactMapper.swift — 纯函数 BusinessCard→Payload
  SystemContactMapper.swift  — 纯函数 Payload→CNMutableContact
  SystemContactExporter.swift— actor，CNContactStore + CNSaveRequest
  Debug/DebugContactExporter.swift — #if DEBUG 可编程 fake
  Debug/ContactExportLaunchMode.swift — #if DEBUG -SimCamCardContactExportMode

权限状态映射：
  notDetermined → notDetermined
  denied/restricted/@unknown → denied
  authorized/limited → allowed（limited 不当 error）
电话 label：
  mobile→CNLabelPhoneNumberMobile；office→CNLabelWork；
  fax→CNLabelPhoneNumberWorkFax；other→CNLabelOther
email：全部 CNLabelOther（Domain 无 email kind，见上）
地址：完整单 String → CNMutablePostalAddress.street（不拆城市/邮编），
      label CNLabelOther
姓名：完整 name → CNMutableContact.givenName 单一属性
```

### Verification results

```text
环境：iPhone 18 Pro / iOS 27.0 模拟器（UDID 5B32D815-…），
串行 xcodebuild（-parallel-testing-enabled NO）。

Unit（SimCamCardTests）：
  423/423 PASS，34 suites（基线 392 + T19 新增 31）
  新增分布：
    BusinessCardContactMapperTests 10（全字段/最小/全 nil/
      website 与 tag/note/OCR 排除/幂等确定性）
    SystemContactMapperTests 11（CNMutableContact 逐字段精确断言：
      givenName 单属性、organizationName、jobTitle、三电话 label、
      email CNLabelOther、postalAddress.street 全串 CNLabelOther；
      SystemContactExporter.map 五种 CNAuthorizationStatus 映射）
    CardDetailViewModelTests T19 块 10（allowed/denied/
      allowOnRequest/denyOnRequest/failure 五脚本、双击只写一次、
      与编辑/删除/备注互斥、终态 dismiss 回 idle 不重写、
      卡片与仓储零变更）

UI（SimCamCardUITests）：
  53/53 PASS，0 failures，0 unexpected（基线 46 + 新增 7）
  日志：/tmp/w4i11-ui-full.log（1121.5s）
  bundle：/tmp/w4i11-ui-full.xcresult
  新增 CardContactExportUITests：
    A fake allowed + more 入口(card-detail-more-export) → 成功 alert
    B fake allow-on-request + 底部入口(card-detail-export) → 成功
      （两个入口同一 workflow 的双入口证明）
    C fake deny-on-request → denied 面（设置/取消齐全，
      不出现成功面；取消后再点仍 denied，零写入）
    D fake denied → 直接 denied 面，无请求 prompt
    E fake failure → 失败面，「好」可关闭
    F System01 真实系统授权（resetAuthorizationStatus →
      真实系统面 → 允许 → 真实 CNSaveRequest 成功）
    G System02 预授权真实 CNContactStore.execute 成功

真实系统集成（非 fake，关键证据）：
  - iOS 27 模拟器真实流程呈现的是系统联系人共享管理面
    「你要如何共享联系人？」全屏页面（不是传统双按钮 alert）：
    选择联系人 / 共享所有 N 位联系人，由系统进程承载
    （SpringBoard AX 树的普通 Window 内，非 Alert 节点）。
    测试对该管理面与经典 alert 两种形态都做了处理。
  - On this iOS 27 simulator, the real Contacts flow presented
    the system contact-sharing management surface
    “你要如何共享联系人？”. The run did not separately instrument
    and record the exact CNAuthorizationStatus at that moment,
    so no broader simctl-grant-equals-limited claim is made.
    （测试运行前用过 simctl privacy grant/reset contacts 协调，
    但未在呈现管理面的时刻单独记录精确的
    CNAuthorizationStatus；点「共享所有 N 位联系人」后，
    挂起的真实写入继续完成。）
  - 真实写入后系统联系人数量 6 → 7（6 个模拟器种子联系人 +
    张伟），并打开系统 Contacts（com.apple.MobileAddressBook）
    人工核对张伟详情（见 evidence w4i11-contacts-fields.png）。
  - real hard-denied TCC path was not obtained reliably on this
    iOS 27 simulator（simctl privacy revoke contacts 后真实写入
    仍成功，未稳定复现 hard-denied）；denied 业务行为由
    unit tests + deterministic UI fake 证明
    （ScriptedContactExporter 五脚本、CNAuthorizationStatus
    状态映射单测、UI C/D 用例）。

构建：
  Debug build PASS（/tmp/w4i11-debug-build.log）
  Release -sdk iphonesimulator build PASS
  （/tmp/w4i11-release-build.log）
  两配置产物 Info.plist 均含
  NSContactsUsageDescription=需要访问通讯录以保存名片联系人。

Release isolation（主二进制 8,312,016B，Release-iphonesimulator）：
  fixture 8 符号 0/0/0/0/0/0/0/0（8/8 ABSENT）
  storage 3 符号 0/0/0（3/3 ABSENT）
  T19 新增 2 符号 SimCamCardContactExportMode /
    DebugContactExporter = 0/0（2/2 ABSENT）
  合计 13/13 ABSENT。
Debug 阳性对照（新鲜构建 SimCamCard.debug.dylib 6,382,088B）：
  上述 13 个符号全部 >0（其中新符号 1/2），扫描机制有效。
```

### Evidence

```text
全部从真实测试运行的 xcresult 导出（XCTAttachment.keepAlways，
非手工摆拍），存入 ai/validation/。provenance 逐张标注：

2026-10-05-w4i11-contact-permission.png
  PROVENANCE: REAL iOS system Contacts permission/sharing surface
  来源：System01（/tmp/w4i11-sys01.xcresult）。
  系统全屏联系人共享管理面「你要如何共享联系人？」，可见
  「选择联系人」「共享所有7位联系人」与系统通讯录头像墙
  （含已被前序真实写入保存的张伟头像）——真实系统权限/共享面，
  非 App 自绘、非 Debug fake。

2026-10-05-w4i11-contact-export-success.png
  PROVENANCE: REAL SystemContactExporter + real CNSaveRequest success
  来源：System02（/tmp/w4i11-sys02c.xcresult）。
  真实 CNContactStore.execute(CNSaveRequest) 成功后 App 呈现
  alert「已保存到通讯录 / 联系人已保存到系统通讯录。」+「好」。
  背景 Detail 可见名片含「首页 www.zhiyuntech.com」行，
  而系统联系人详情无 URL 行（website 排除的反向佐证）。

2026-10-05-w4i11-contacts-fields.png
  PROVENANCE: REAL Contacts.app verification
  来源：真实写入后打开系统 Contacts App
  （com.apple.MobileAddressBook）的张伟详情页
  （/tmp/w4i11-verify2.xcresult，一次性 scratch 测试取证后
  已删除，无残留文件）。逐字段核对：
    张伟（完整姓名单字段）
    产品总监 | Product Director · 上海智云科技有限公司
      （jobTitle · organizationName 连排）
    手机 +86 138 0013 8000（CNLabelPhoneNumberMobile）
    工作 +86 (21) 5555 1234（CNLabelWork）
    其他 wei.zhang@zhiyuntech.com（CNLabelOther）
    其他 上海市浦东新区世纪大道100号 200120
      （完整地址单串在 street，CNLabelOther）
    无 URL 行、备注为空；无 tag/note/OCR/图片。

2026-10-05-w4i11-contact-denied.png
  PROVENANCE: DEBUG scripted denied-state UI evidence
  来源：DEBUG-only DebugContactExporter 的 deny-on-request
  脚本（UI C，/tmp/w4i11-uifake3.xcresult），不是真实 TCC
  hard-denied 截图。
  明确：real hard-denied TCC path was not obtained reliably on
  this iOS 27 simulator；denied 业务行为由 unit tests +
  deterministic UI fake 证明，App 自绘结果面（S09 Denied 态在
  两种授权来源下 UI 完全一致）：标题「无法保存名片到通讯录」、
  「点击设置通讯录权限」、「取消」，对齐 REF-export-02 文案
  与结构（页面 vs alert 的 surface 差异见 P11 PARTIAL）。
```

### Scope audit

```text
git diff --name-status（tracked，8 个）：
M  SimCamCard.xcodeproj/project.pbxproj
M  SimCamCard/App/SimCamCardApp.swift
M  SimCamCard/View/CardDetail/CardDetailView.swift
M  SimCamCard/View/CardDetail/CardNotesView.swift（仅 #Preview 构造注入）
M  SimCamCard/View/CardHolder/CardHolderView.swift
M  SimCamCard/ViewModel/CardDetailViewModel.swift
M  SimCamCardTests/ViewModel/CardDetailViewModelTests.swift
M  ai/changes.md
Untracked（新增）：
?? SimCamCard/Export/（7 文件：
     ContactExportPayload.swift / ContactExporting.swift /
     BusinessCardContactMapper.swift / SystemContactMapper.swift /
     SystemContactExporter.swift /
     Debug/ContactExportLaunchMode.swift /
     Debug/DebugContactExporter.swift）
?? SimCamCardTests/Export/（2 文件：
     BusinessCardContactMapperTests.swift /
     SystemContactMapperTests.swift）
?? SimCamCardUITests/CardContactExportUITests.swift
?? ai/validation/2026-10-05-w4i11-contact-permission.png
?? ai/validation/2026-10-05-w4i11-contact-export-success.png
?? ai/validation/2026-10-05-w4i11-contact-denied.png
?? ai/validation/2026-10-05-w4i11-contacts-fields.png

冻结面 git status 复查全部 CLEAN：
SimCamCard/Model（BusinessCard/PhoneNumber/CardTag/CardNote
  无 CNContact、无 Codable、无 contactIdentifier/exported 标记）、
SimCamCard/Persistence、SimCamCard/Repository（schemaVersion=1
  未动）、SimCamCard/Recognition、SimCamCard/Edit、SimCamCard/Search、
spec/、dataset/、evidence/。
导出是外部副作用：BusinessCard 不新增任何持久化状态，
写入系统通讯录只经 SystemContactExporter.export 一次。
取证用一次性 scratch UI 测试已删除，工作树无 Scratch 残留。
未 commit、未 push、未创建分支。
```

### pbxproj audit

```text
git diff SimCamCard.xcodeproj/project.pbxproj 仅两行新增
（Debug 与 Release app target 各一，均在 NSCamera 行之后）：
+ INFOPLIST_KEY_NSContactsUsageDescription =
+   "需要访问通讯录以保存名片联系人。";
无 build phase、framework、文件 membership 变更
（新文件由 PBXFileSystemSynchronizedRootGroup 自动入 target；
Contacts.framework 由 import Contacts 自动链接）。
两配置构建产物 Info.plist 已实测含该 key。
```

### T19 behavioral acceptance

```text
T19 behavioral acceptance: PASS

frozen T19 六类字段全部正确导出（真实系统联系人 + Unit 双重证明）：
1. name    PASS 完整姓名入 CNMutableContact 单一姓名属性
              （givenName 承载全串），不拆分中文名；系统联系人
              显示名即「张伟」。
2. company PASS organizationName=上海智云科技有限公司。
3. jobTitle PASS jobTitle=产品总监 | Product Director；
              系统联系人头部连排「职位 · 公司」。
4. phones  PASS 全部电话逐条保留，label 按 Domain PhoneNumber.Kind：
              mobile→手机(CNLabelPhoneNumberMobile)
              office→工作(CNLabelWork)
              fax→工作传真(CNLabelPhoneNumberWorkFax)
              other→其他(CNLabelOther)
              multiple phones 有 Unit 覆盖（真实卡 001 两部
              手机+工作系统核对一致；三电话含传真由
              SystemContactMapperTests 精确断言）。
              号码原样保留，不做破坏性归一化（系统自身加 +86 间距
              格式化属系统展示行为）。
5. emails  PASS 全部邮箱逐条 CNLabeledValue 保留（multiple emails
              有 Unit 双值断言；真实卡 001 单邮箱
              wei.zhang@zhiyuntech.com 系统可见）。
6. address PASS 地址完整单串入 CNMutablePostalAddress.street，
              不拆城市/省份/邮编、不补造 country；系统联系人完整显示
              「上海市浦东新区世纪大道100号 200120」。

missing optional fields：最小卡（仅姓名+手机）映射单测证明
company/jobTitle/emails/address 全部 nil，不伪造；空 payload
全 nil 安全。
real CNContactStore / CNSaveRequest：已成功（System02）。
real Contacts.app：exported values 已人工核对
（w4i11-contacts-fields.png）。
冻结排除项：website（REF-05 主页）、tags、notes、OCR 图片均不映射，
有专门排除单测；真实系统联系人详情确认无 URL 行、备注为空。
互斥与状态机：requestingPermission/exporting 期间底部按钮
ProgressView+禁用；编辑/删除/备注入口与导出互斥（双向单测）；
双击仅一次系统写入（GatedContactExporter 计数断言）。
denied/cancel/dismiss：取消关闭结果面回 idle 可重试；
「点击设置通讯录权限」跳系统 Settings（UI 断言按钮存在）。
失败面：写入抛错 → exportFailed + 卡片/仓储零变更 + 尝试计数=1、
成功计数=0。
```

### P11 full Reference fidelity

```text
P11 full Reference fidelity: PARTIAL

说明：以下是「实现 vs Reference 完整表面」的差异清单，不是 T19
failure。T19 frozen required behavior 已全部满足并判定 PASS；
PARTIAL 仅表示与参考 App（CamCard_zh_lite，macOS / Mac Catalyst
环境）的完整 surface 仍有差异，且其中包含平台自身差异。

frozen T19 要求且已验证为真：
  - 六类字段 name / company / jobTitle / phones / emails /
    address 全部正确导出；
  - multiple phones / multiple emails / missing optional fields
    已有 Unit 覆盖；
  - real CNContactStore / CNSaveRequest 已成功；
  - real Contacts.app 已验证 exported values。

full Reference surface 的差异（PARTIAL 原因）：
  diff-1 REF-export-02 的 denied 是一个独立的「保存到通讯录」
         页面（左上取消 + 居中标题 + 设置行）；当前实现使用
         native SwiftUI alert 呈现同一 denied 信息与动作
         （标题/设置跳转/取消一致，承载 surface 不同）。
  diff-2 REF-export-03 有 destination/account selector
         （macOS Contacts 多账号选择器）；iOS 27 当前系统流程
         没有对应的 App-controlled surface，故未实现该选择页。
  diff-3 REF 中 email / address label = 工作；当前按 frozen
         Domain（无 email/address kind）保守映射为「其他」
         （CNLabelOther），不伪造语义标签。
  diff-4 REF-export-05 观察到 website（主页）被保存；
         frozen T19 acceptance 不要求 website，当前故意未导出。
  diff-5 Reference 运行于 macOS / Mac Catalyst，其系统 Contacts
         UI 与 iOS 27 system Contacts UI 本身存在平台差异
         （含上述账号选择器、地址多行排版等），不全部可迁移。
```

### T-status

```text
T11–T18 PASS（全量回归未受影响：Unit 423/423、UI 53/53）
P10 Notes: PASS
T19 Contact Export: PASS
  六类 frozen 字段真实系统写入并人工核对；五授权/失败脚本 +
  真实系统权限/共享面 + 真实 CNSaveRequest 全覆盖。
P11 full Reference fidelity: PARTIAL（5 项 surface 差异见上；
  这些差异不构成 T19 failure）。
T20 Final sweep: NOT IMPLEMENTED
```

### T20 note (non-blocking, carried forward)

```text
Real Contacts integration mutates the simulator Contacts store
and repeated runs can create duplicate exported fixture contacts.
本次 W4I11 验证中已观察到种子联系人数量随真实写入变化
（6 → 7，张伟）；重复执行 System01/System02 会继续追加同名
联系人。
At T20:
  - either keep real Contacts validation as targeted integration
    （保留为定点集成测试，不进入每次全量门禁），
  - or clean up the created test contact after validation
    （验证后按 receipt.systemIdentifier 删除本次创建的联系人）。
Do not broaden W4I11 for this now（本 Increment 不为此扩大范围）。
```

### Human Decision

Human Decision:
Accepted — 2026-10-05 (human review)

---

## Week 4 Increment 12 — T20 Exception Handling + Final Acceptance Sweep

Baseline: branch `week4/structured-recognition`, HEAD `5ec0803`
（feat(contacts): 实现名片通讯录导出），tree clean。基线门禁：
Unit 423/423 PASS（34 suites）、UI 53/53 PASS（0 failures / 0
unexpected）、Debug build PASS、Release build PASS、Release hook
isolation 13/13 ABSENT + fresh Debug 13/13 PRESENT。T01–T19
behavioral acceptance PASS；T20 NOT IMPLEMENTED。

### T20 Exception Matrix（先审计，后改码）

列：Spec source / Existing implementation / Existing automated proof /
Missing proof / Behavior status / Reference fidelity status。

| ID | 场景 | Spec source | 现有实现 | 现有自动化证据 | 缺失证据 | Behavior | Ref fidelity |
|---|---|---|---|---|---|---|---|
| E01 | 相机已拒绝 | S02 permissionDenied；T03；REF-permission-01 | ScanViewModel denied→permissionFallback（scan-permission-denied），无 session/无快门，✕=scan-close dismiss | UI ScanCameraUITests.testDeniedShowsStableFallbackWithoutSessionUI；Unit ScanViewModelTests denied/restricted 用例 | 无 | PASS | 自定义 denied fallback（frozen REF 仅记录系统弹窗，无自绘拒绝页）→ deferred cosmetic surface |
| E02 | unknown→拒绝 | S02；T03 | notDetermined→requestVideoAccess→denied | UI testNotDeterminedDeniedResolvesToFallback（+close→Holder）；Unit | 无 | PASS | 同上（系统弹窗本身不模拟） |
| E03 | Scanner 取消/返回 | P02 exits=Back；T02 | scan-close→dismiss；onDisappear stop session + invalidate recognition | UI testCloseReturnsToCardHolderWithStateUnchanged、Week2 nav skeleton | 无 | PASS | PASS（✕ 与 REF X 同义） |
| E04 | 相册取消 | S03 cancelled；T05 | handleImportCancel：flag 清除→restartPreview→photoImport=.idle（终态顺序保证），无 crop/OCR/draft | UI testPhotoImportCancelReturnsToPreview（DEBUG cancel fixture）；Unit import-cancel 顺序用例 | 真实系统 PhotosPicker 取消（不稳定，按 §8 分列） | PASS（fixture）；系统 picker 取消 NOT INDEPENDENTLY VERIFIED | fixture 级 PASS |
| E05 | Crop 取消/返回 | S04 retakeRequested；P04 exits | CardCropView 取消=scan-crop-retake→retake()：generation+1、cancel task、清 crop/import、restart preview | UI testCaptureShowsCapturedPhotoFixture（retake→preview）；Unit retake 系列 3 例（含 import、inactive no-op） | 无 | PASS | PASS |
| E06 | 识别失败 | S05 failed；T20 §10 | OCRError→.failed；failedContent 有重拍；无 Save | UI testOCRFailureShowsStableRecoveryAndRetake；Unit failedRecognitionSettlesFailed | failed 页只有重拍、无直接取消出口（§10 要求 Retake/Cancel）→ **最小修复：失败页加取消→Holder** | 修复后 PASS | 失败页为 minimal fallback（无 REF 失败页截图）→ deferred surface |
| E07 | 非卡片/零文本 | t20-negative-001-expected.json；S05 nonCardEmptyResult；REF-exception-02 | 零行/零结构化字段→.nonCardEmptyResult→P05 空表单、无失败弹窗、可重拍 | UI testStructuredEmptyFixtureShowsEmptyP05WithoutFailure；Unit emptyRecognitionSettlesEmptyResult、#5/#6 | **空表单保存按钮当前可点 → 可存出全空卡（§4「Save 成功产生假卡」禁止、§27-B「cannot fabricate/save」）→ 最小修复：VM guard + Save disabled；旧 UI 断言同步翻转** | 修复后 PASS | REF 保存按钮可见但 CamCard 空结果点按行为未观测；保留按钮但禁用，差异如实分类 deferred surface |
| E08 | 极简名片 card004 | REF-exception-01；data-model missing-field 规则 | extractor：bare +86 1[3-9]…→.mobile；nil 字段不伪造；固定标量行保留空行 | Unit card004 真实 Vision smoke、VM #4、Materializer、card004 Detail UI；OCR fixture 无 minimal 模式 | recognition 全链路 UI 组合（fixture 级）→ 新增 OCRFixtureMode.minimal（复用 -SimCamCardOCR hook，无新 hook 字符串）+ composite C | PASS | 手机展示格式 REF 为 +8613800138000 连写、我方为分段（cosmetic，记录） |
| E09 | 识别后手动编辑取消 | S05 manualEditing；T11 | retake() 丢弃 draft；source StructuredRecognitionResult/raw OCR 不可变 | UI testManualEditingRetakeReturnsToScannerPreview、testManualCorrectionUpdatesRecognitionDraft；Unit T11 11/12/15、extra | 无 | PASS | PASS |
| E10 | 已有卡片编辑取消 | T14 | cancelEditing 仅 .editing 有效；card/repo 不变 | UI testExistingCardEditCancelDiscardsChanges；Unit T14 cancel | updatedAt 断言已含于 Unit | PASS | PASS |
| E11 | 删除取消 | T17 | cancelDelete：confirming→idle | UI testDeleteCancelLeavesCardUnchanged；Unit T17 cancel 系列 | 无 | PASS | PASS |
| E12 | 建组取消/删组保卡 | T16 | 建组 alert 取消仅清 pendingGroupName；选择页取消 clearGroupCardSelection；createGroup 仅在完成时调用；删组删 tag 保卡（Unit） | Unit T16 全套（含 delete keeps cards）；UI testGroupFullFlow/testGroupDeleteFlow | 建组流程输入后取消→catalog/tags 不变的直接 UI 证据缺 → 补 1 个 targeted UI | 补证后 PASS | PASS |
| E13 | 备注取消 | P10；S08 | cancelAddingNote 仅 .addingNote 有效；draft 不留存 | UI testAddNoteCancelPersistsNothing；Unit P10 cancel/re-entry | 无 | PASS | PASS |
| E14 | 搜索清空/返回/组过滤 | T15；T16 | 空结果 ContentUnavailableView；×=clearSearch；返回先 clear 再 pop；组过滤独立保留 | UI testSearchAcrossJobTitlePhoneEmailNoResultAndClear；Unit T15 空/clear/不变异 + T16 group+search compose | 无 | PASS | PARTIAL（综合/名片/企业 segmented 等排除面） |
| E15 | 通讯录权限拒绝 | S09；T19 | denied→permissionDenied surface，零 export 调用 | UI testFakeAlreadyDenied…/testFakeDenyOnRequest…；Unit T19 deny 系列 | 无（真实系统弹窗为 W4I11 System01 targeted） | PASS | PARTIAL（denied 承载页差异 diff-1） |
| E16 | 通讯录导出失败 | T19 | exportFailed；card/repo/updatedAt 不变；dismiss→idle | UI testFakeFailureShowsFailureSurface；Unit T19 failure/double/dismiss | 无 | PASS | PASS（alert 承载差异同 diff-1） |
| E17 | 持久化首启缺文件 | T20 §20 | absent JSON→空 store、不建文件；images 目录惰性创建 | Unit FileBusinessCardRepositoryTests「absent file」、FileCardGroupRepositoryTests、FileImageAssetStoreTests lazy dir | 无 | PASS | N/A 内部机制 |
| E18 | 删除缺失 UUID 稳定 no-op | T20 §20 | repo.delete 缺席 id 安全 no-op；缺图引用→nil | Unit「absent delete is a safe no-op」（card + group）、「missing reference reads nil」 | 无 | PASS | N/A |
| E19 | 搜索无结果空状态 | T15 | card-holder-search-empty 独立空态 | 同 E14 | 无 | PASS | PARTIAL（排除面同上） |
| E20 | 重入/连击单副作用 | T20 §21 | capture/crop/save/editSave/delete/note/export 全有 guard（isCaptureInFlight/isCropInFlight/isSaveInFlight/EditState.saving/DeleteState.deleting/NoteState.saving/exportBlocksOtherWorkflows） | Unit doubleConfirm、T12 9/11、T14 save no-op、T17 re-entrant、P10 .saving、T19 double-write；UI 保存链路 | 空结果保存 guard（并入 E07 修复） | 修复后 PASS | N/A |

审计结论：只有两处真正 behavioral mismatch 需要最小修复——

1. E07：nonCardEmptyResult 可保存出全空 BusinessCard（违反 §4/§27-B）。
2. E06：识别失败页缺直接 Cancel 出口（§10 要求 Retake/Cancel）。

另有一处 fixture 能力缺口（E08 全链路 minimal UI）与一处 UI 证据缺口
（E12 建组取消）。stale async（§11）已有 3 个定向 Unit（retake /
disappear / A-B 两代），只审计不重复造。

（修复记录、测试与门禁结果在本章节后续小节追加。）

### 实际修复（仅两处 behavioral fix + 一处 fixture 能力）

1. **E07 空结果不可保存（`ScanViewModel.swift`）**
   - 新增 `var canSaveCurrentCard: Bool`：inactive/processing/failed
     恒 false；settled 态检查 `result.fields`；manualEditing 检查
     `draft.correctedFields`；判定经私有静态
     `hasAnyCanonicalField(_:)`（name/company/jobTitle/任一 phone/
     任一 email/website/address 任一非空）。
   - `saveCurrentCard()` 在 draft 解析之后、任何存储副作用之前加
     `guard Self.hasAnyCanonicalField(draft.correctedFields) else { return }`
     —— VM 级不变量，不依赖 View。
   - `RecognitionView.swift` P05 顶栏保存：
     `.disabled(viewModel.isSaveInFlight || !viewModel.canSaveCurrentCard)`。
     保存按钮仍可见（对齐 REF-exception-02），但零字段时禁用。
2. **E06 识别失败双出口（`RecognitionView.swift`）**
   - `failedContent` 改为 HStack：`取消`（id
     `scan-recognition-cancel`）→ Holder `dismiss()`；`重拍`（id
     `scan-recognition-retake`，行为不变）。失败页无 Save。
3. **E08 minimal fixture（`DebugCameraFakes.swift`）**
   - DEBUG `OCRFixtureMode` 新增 `.minimal`：两行
     `张伟` / `+86 138 0013 8000`（bare +86 自动判 mobile）。
   - 复用既有 `-SimCamCardOCR` launch hook，**未引入任何新 hook
     字符串**，Release 隔离清单仍为 13 个。

Frozen Domain、repository 协议、persistence schema、spec/*、
dataset/*、evidence/*、project.pbxproj 全部零改动。

### 新增自动化证据

**UI（XCTest，SimCamCardUITests）**

- 新文件 `ExceptionHandlingUITests.swift`（3 例，全部 fixture
  驱动、非真机非真实 Vision）：
  - `testCompositeBNonCardEmptyCannotSaveThenCancel`：empty fixture
    → P05 空表单、`scan-recognition-empty`、无 failed 弹窗；保存
    按钮存在但 `isEnabled == false`，点按无 P06；无
    未命名/网站/手机/email 捏造；重拍→✕→空 Holder 无任何
    card-row。
  - `testCompositeCMinimalCardShowsOnlyExistingFields`：minimal
    全链路 → missingFields；仅 姓名=张伟、手机-0=
    `+86 138 0013 8000`；无 office/fax/email/website 行；
    company/title 结构行保留为空值；保存按钮 enabled（真实字段
    可存）；重拍丢弃后 Holder 仍空。
  - `testOCRFailureCancelReturnsDirectlyToHolder`：failure →
    失败页同时有取消/重拍、无保存；取消后 scan-entry-view 移除、
    直达名片夹、无残留失败面。
- `CardGroupUITests.swift` 新增
  `testCreateGroupCancelLeavesCatalogAndCardsUnchanged`（E12）：
  选择页工具栏取消 → 回列表仍 group-empty；再次进入选卡→alert
  输入「临时客户」→alert 取消（返回选卡阶段，不建组）→工具栏
  取消 → group-empty、无「临时客户」、回 Holder 无筛选横幅、
  3 张卡全在。
- `ScanCameraUITests.swift`
  - 翻转旧断言
    `testStructuredEmptyFixtureShowsEmptyP05WithoutFailure`：保存
    按钮存在但 disabled、点按 no-op（原为「保存不存在」的错误
    预期）。
  - denied 用例加挂 `w4i12-camera-denied` keepAlways 附件。

**Unit（Swift Testing，SimCamCardTests）**

- `ScanViewModelTests.swift` 新增 T20 E07 三例：
  - empty 结果：`canSaveCurrentCard == false`；save 后 idle、
    repo 零卡、image store 零资产、状态保持 nonCardEmptyResult；
  - manualEditing 清空全部字段 → 不可保存/空操作；补一个真实
    姓名后恢复可保存且存出仅含 name 的卡；
  - failed 识别不可保存、saveState 保持 idle。
- 新文件 `Recognition/StructuredGroundTruthRegressionTests.swift`
  （§28/§29，5 个 @Test）：见下节。

### §28 34-card GT-level 结构化回归（诚实层级标注）

`StructuredGroundTruthRegressionTests` 从 `dataset/ground-truth/
card-001..034.json` 读取冻结 GT，按 GT 字段合成「完美识别器应输出
的 OCR token 行」（typed 字段用双语标签，语义字段裸行），直喂纯
函数 `CardFieldExtractor`，再逐字段对比 GT。**层级明确：这是
GT-level 结构化回归，不是真实 Vision OCR；禁止表述为 34 张真实
Vision 全部识别成功。** 真实 Vision 层仍为 cards 001–004 anchor
smoke + 定向真实管线门禁。

首轮诚实运行结果（已把 2 个语义层偏差钉入测试内
`knownSemanticExceptions` 注册表并附原因，类型层零容忍）：

```text
LEVEL: GT-derived synthetic OCR lines → CardFieldExtractor (NOT Vision)
total business cards: 34
typed-layer exact (mobile/office/fax/email/website/address): 34/34
full exact (typed + name/company/title): 32/34
missing-field false positives (fabrications): 0
multi-phone cards correct: 23/23
pinned semantic parser exceptions: 2
  card-019 jobTitle マネージャー — 片假名职称，无 CJK/拉丁关键词
  card-030 jobTitle "UX Researcher" — Researcher 不在拉丁职称表
independent exception fixtures: 1（t20-negative-001；不计入 34）
```

§29：测试同时解码
`dataset/exception-samples/t20-negative-001-expected.json`
（observedBehavior：无失败弹窗、进入编辑页、structuredContactFields
=empty、可返回/重拍），并断言零 OCR 行 → extractor 零规范字段。
34 张 business card 与 1 个 exception fixture 独立计数。未修改 GT。

注意：§28/§29 是 GT-derived synthetic OCR lines → 纯 extractor 的
parser 层回归，它证明「零 OCR 行 → 零规范字段」，但**不是**实际
PNG 经过真实 Vision 的 proof，禁止据此声称 actual-PNG proof。

### Human Review proof blocker 闭合：实际 non-card PNG 真实 Vision 集成（targeted, scratch 已删）

针对 human review 指出的唯一 proof blocker，新增一个**临时**
scratch test（`SimCamCardTests/ScratchT20NegativeVisionTests.swift`，
env `TEST_RUNNER_SCRATCH_T20_RUN=1` 门控，默认全量套件 skip；targeted
跑完后文件已删除，**不进入** 431 确定性基线，不留在仓库）。

直接复用真实 dataset smoke pipeline，加载冻结真实文件
`dataset/exception-samples/t20-negative-001-non-card.png`，实际执行：

```text
PNG Data → CapturedPhoto(photoLibrary)
→ CardCropProcessor.prepare（真实 Vision 矩形检测）
→ CardCropProcessor.perspectiveCorrect（Core Image 透视校正 upright PNG）
→ CardOCRProcessor.recognize（真实 Swift-native Vision OCR）
→ CardFieldExtractor.extract（确定性解析）
```

Targeted run 实测输出（2026-10-09 执行，门禁基线日期仍为 2026-10-07）：

```text
wasDetected=false
  （Vision 在该风景照中未检测到卡片边界；未据此 fail，
    按 production no-detection 语义走 inset fallback region
    0.06–0.94，non-card 本就可能没有 card boundary）
sourcePixelSize=725x597
processedPixelSize=638x526
ocrLineCount=0
ocrRawText=（空）
canonical.name=nil
canonical.company=nil
canonical.jobTitle=nil
canonical.phones=[]
canonical.emails=[]
canonical.website=nil
canonical.address=nil
unclassifiedText=[]
VERDICT: PASS — zero canonical fields
```

- 关键断言全部满足：name/company/jobTitle == nil、phones/emails
  为空、website/address == nil。
- 未要求 raw OCR text 必须为空：本次 Vision 恰好读到 0 行；即便
  Vision 从噪声读到非空 raw text，只要 canonical 字段全空，仍满足
  冻结 `structuredContactFields = "empty"`。
- 无任何 canonical false positive；未修改 expected.json、未修改
  任何 production Swift / Domain / Persistence / Repository 契约。

Targeted 结果留档：

```text
xcresult：/tmp/w4i12-scratch.xcresult
命令：TEST_RUNNER_SCRATCH_T20_RUN=1 xcodebuild test \
  -only-testing:SimCamCardTests/ScratchT20NegativeVisionTests \
  -parallel-testing-enabled NO \
  -derivedDataPath /tmp/w4i12-scratch-derived \
  -resultBundlePath /tmp/w4i12-scratch.xcresult
结果：1/1 passed（1.219s），TEST SUCCEEDED
scratch 文件：targeted PASS 后已删除（git status 无此文件）
```

T20 frozen negative fixture proof 的两层分层（缺一不可、不可互相
替代）：

```text
层 1 — deterministic DEBUG empty fixture
  空 OCR fixture → 真实 ScanViewModel/P05 UI
  → nonCardEmptyResult → Save 可见但 disabled + 点按 no-op
  + retake/cancel 出口（UI composite B；Unit E07 1/2/3）。
  证明：状态映射 + save guard。

层 2 — 冻结实际 non-card PNG targeted 真实 Vision 集成（本节）
  真实 t20-negative-001-non-card.png → 真实 crop/Vision OCR/extractor
  → zero canonical fields。
  证明：实际图片经真实 pipeline 后不产生任何规范字段。

两层合起来才构成 T20 frozen negative fixture proof。
§28/§29 synthetic empty-lines 回归是独立 parser 层，不充作
actual-PNG proof。
```

### W4I12 门禁结果（2026-10-07 重跑）

```text
Unit（全量 SimCamCardTests，iOS 27 sim，禁并行）：
  431/431 PASS，35 suites，0 failures / 0 unexpected
  （/tmp/w4i12-unit.log，/tmp/w4i12-unit.xcresult）
  基线 423 + E07 3 + GT 回归 5 = 431。
UI deterministic（全量 SimCamCardUITests，skip System01/System02）：
  55/55 PASS，0 failures / 0 unexpected，1037.7s
  （/tmp/w4i12-ui.log，/tmp/w4i12-ui.xcresult）
  = 确定性基线 51 + 本增量新增 4（Exception 3 + 建组取消 1）。
  XCTest 函数总数 57（另 2 个为有状态真实 Contacts System01/02，
  按 §30/§31 单列，不在本次确定性套件内重跑）。
Debug build：PASS（/tmp/w4i12-debug-build.log，新鲜
  -derivedDataPath /tmp/w4i12-dd-debug）
Release build：PASS（/tmp/w4i12-release-build.log，
  /tmp/w4i12-dd，主二进制 8,383,408B）
Release hook isolation（strings -a 主二进制，13 个符号）：
  8 fixture 0/0/0/0/0/0/0/0；3 storage 0/0/0；2 export 0/0
  → 13/13 ABSENT。
Fresh Debug 阳性对照（SimCamCard.debug.dylib 13,525,888B）：
  13/13 全部 >0（2/4/2/2/2/2/2/2/4/2/2/2/4），扫描机制有效。
  .minimal 复用 -SimCamCardOCR，无第 14 个符号。
```

### Evidence（全部从真实 xcresult 附件导出，无摆拍）

```text
ai/validation/2026-10-07-w4i12-camera-denied.png
  来源：testDeniedShowsStableFallbackWithoutSessionUI
  （/tmp/w4i12-ui.xcresult）。相机 denied fixture：自绘稳定
  fallback「无法访问相机」+ 设置指引，无快门/相册入口，✕ 可关。
ai/validation/2026-10-07-w4i12-non-card-empty-result.png
  来源：testCompositeBNonCardEmptyCannotSaveThenCancel。非卡片
  空结果进入 P05 空表单（姓名/公司/职位/地址全空值行，无手机/
  email/网站行），顶部「保存」可见但 disabled（UI 测试断言
  isEnabled==false 且点按无 P06），无失败弹窗。
ai/validation/2026-10-07-w4i12-minimal-card.png
  来源：testCompositeCMinimalCardShowsOnlyExistingFields。
  全链路 minimal fixture：仅 张伟 + 手机 +86 138 0013 8000；
  公司/职位/地址空值；无 email/website；保存 enabled。
ai/validation/2026-10-07-w4i12-recognition-failure.png
  来源：testOCRFailureCancelReturnsDirectlyToHolder。识别失败
  fallback：警示图标 +「识别失败」+「取消」「重拍」双出口，
  无保存。
```

### T20 终态

```text
Behavioral Reference Tests：T01–T20 20/20 PASS（P07/P08/P09/P10/
  P11 的 fidelity PARTIAL 为既有分类差异，非本增量行为缺口，
  详见 ai/final-reference-audit.md）。
Dataset：34/34 在册；typed 34/34、full-exact 32/34、捏造 0、
  multi-phone 23/23；1 个独立 exception fixture。
冻结面：Model/Repository 契约/Persistence schema/spec/dataset/
  evidence/pbxproj 全部 no-diff。
真机：无物理 iPhone，不做真机声称（camera/Vision 均为模拟器
  fixture/框架层；Contacts 真实系统写入口径沿用 W4I11）。
遗留（如实保留，不扩大）：orphan image GC 未实现；repository
  协议 non-throwing（磁盘写失败=known limitation）；corrupt JSON
  恢复未建；系统 PhotosPicker 真实取消手势未独立验证（platform
  validation gap，非已验证）；card-019/030 职称两个解析器已知
  偏差（GT-level，已钉档）。

Human review 收尾（2026-10-09，仅处理 1 个 proof blocker + 文档归档
  校准，未扩大业务功能）：
- Proof blocker 已闭合：实际 t20-negative-001-non-card.png targeted
  真实 Vision 集成 PASS（zero canonical fields，见上节，
  /tmp/w4i12-scratch.xcresult）；scratch 文件已删除。
- T20 behavioral acceptance：PASS；T01–T20：20/20 PASS。
- Proof layering 明确：层 1 deterministic DEBUG empty fixture →
  UI/nonCardEmptyResult/save guard；层 2 冻结实际 non-card PNG
  targeted 真实 Vision 集成 → zero canonical fields。synthetic
  empty-lines 回归不充作 actual-PNG proof。
- P05：required behavior PASS；full Reference fidelity PARTIAL
  （REF-exception-02 只观察到保存 affordance，未观察空结果点按保存
  的行为；Save visible-but-disabled 是 SimCamCard 为满足冻结 T20
  no-empty-card 的有意实现，不声称为 Reference 已观察）。
- T05：Photo Import behavioral mechanics PASS；native system
  PhotosPicker cancel gesture NOT independently verified（platform
  validation gap）。
- Evidence 归档日期校准：4 张 w4i12 PNG 2026-10-05 → 2026-10-07
  （仅重命名，未重新生成截图；实际 full gates 日期 2026-10-07）。
- 闭合 blocker 未修改任何 production Swift / permanent test /
  Domain / Persistence / Repository 契约，故按 human review 范围不
  重跑 55 个 UI；仅 targeted actual-PNG integration + 文档/重命名。
Human Decision: Accepted — 2026-10-09 (human review)
  T20 behavioral acceptance: PASS
  T01–T20: 20 / 20 PASS
  Full Reference fidelity: PARTIAL (documented non-blocking differences)
Submission readiness: READY FOR FINAL DELIVERY PREPARATION
未 commit / push / merge / tag（等待 human 确认最终提交范围与时机）。
```
