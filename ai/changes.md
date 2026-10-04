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
