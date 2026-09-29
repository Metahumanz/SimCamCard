# SimCamCard

SimCamCard is a Specification-Driven Development (SDD) project that black-box replicates the instructor-defined CamCard 8.63.1 feature slice:

**Business Card Digitization and Contact Management**

## Current stage

- **Week 1: Frozen** — SDD baseline (specification, evidence, dataset, test suite) is frozen.
- **Next: Week 2** — Architecture + UI + Data Model.

No implementation of OCR, camera, persistence, repository, ViewModel, or new UI has been done yet.

## Bounded scope

Included: Card Holder / list / empty state, scan entry, camera preview + permission flow, photo-library import, card region detection, manual crop / perspective correction, OCR, raw OCR preservation, structured field extraction, manual verification / correction, save, detail view, edit, delete, search, groups/tags, notes, local persistence, export to system Contacts or VCF, and required exception paths.

Excluded: user registration / membership, subscription / payment / VIP, advertising, cloud sync, multi-device sync, team card libraries, CRM/Salesforce sync, enterprise org/permissions, digital business-card design, QR-based exchange, email signatures / virtual backgrounds, AI business intelligence / company analysis, meeting recording / summarization, sales pipeline, enterprise-data enrichment, nearby-contact maps.

Observed-but-excluded CamCard UI does not become an implementation requirement.

## Repository structure

```
SimCamCard/
├── assignment/              # immutable instructor source — do not modify
├── spec.md                  # top-level SDD specification
├── spec/                    # derived SDD baseline (environment, inventories, data model, tests)
├── evidence/                # immutable black-box observation evidence + manifest
├── dataset/                 # frozen 34-card dataset + Ground Truth + T20 exception fixture
├── ai/                      # AI collaboration rules, change log, prompt templates
├── SDD-README.md            # SDD work entry point and workflow
├── SimCamCard.xcodeproj     # Xcode project
├── SimCamCard/              # SwiftUI app source
├── SimCamCardTests/         # unit tests
└── SimCamCardUITests/       # UI tests
```

## Reference environment (frozen)

- App: CamCard / 名片全能王 8.63.1, Simplified Chinese, logged out, free / non-member
- Observation platform: Apple Silicon Mac (M2), macOS 27.0, CamCard running in iPhone/iPad-compatible mode
- Xcode 27.0; Swift compiler/toolchain 6.4; Swift language mode (`SWIFT_VERSION`) 5.0
- iOS deployment target 27.0
- Primary simulator: iPhone 18 Pro, iOS 27.0

See `spec/reference-environment.md` for details and the physical-iPhone verification caveat.

## SDD workflow

```
Specification → Architecture → Implementation → Test → Difference Analysis → Revision → Regression
```

When implementation conflicts with a frozen specification, fix the implementation, not the specification.

## Dataset summary

- 34 synthetic business-card samples (`card-001` … `card-034`) in `dataset/cards/`
- 34 Ground Truth JSON records in `dataset/ground-truth/`
- 1 separate non-card T20 exception fixture in `dataset/exception-samples/` (not counted in the 34)
- `card-index-005-034.csv` and `ground-truth-005-034.jsonl` are consolidated indices for the back 30 cards

## Reference test suite (T01–T20)

| ID | Scenario |
|---|---|
| T01 | First Launch / Empty Holder |
| T02 | Enter Scanner |
| T03 | Camera Permission |
| T04 | Capture |
| T05 | Photo Import |
| T06 | Boundary Detection |
| T07 | OCR Raw Text |
| T08 | Structured Extraction |
| T09 | Missing Field |
| T10 | Multiple Phones |
| T11 | Manual Correction |
| T12 | Save |
| T13 | Detail |
| T14 | Edit |
| T15 | Search |
| T16 | Tag / Group |
| T17 | Delete |
| T18 | Persistence |
| T19 | Export |
| T20 | Exception Handling |

See `spec/reference-tests.md` for status, expected behavior, and evidence references.

## AI collaboration rule

The assignment forbids one-prompt generation of the entire application. Use AI incrementally:

1. Provide only the relevant specification/test context.
2. Define the exact component to modify.
3. State interfaces/architecture that must not change.
4. Require unit/UI tests.
5. Run the full relevant regression suite after changes.
6. Record what the AI changed and what a human verified.

See `ai/README.md` and `ai/changes.md`.

## Development prerequisites

- macOS 27.0
- Xcode 27.0
- Swift compiler/toolchain 6.4 (bundled with Xcode 27.0)
- iOS 27.0 deployment target
- iPhone 18 Pro simulator (primary)

## Source of truth

- `assignment/` is the immutable instructor source.
- `spec/` and `spec.md` are the derived SDD baseline.
- `evidence/` is immutable black-box observation.
- `dataset/` is the frozen test data.
