# SimCamCard — SDD Work Entry

SimCamCard follows Specification-Driven Development (SDD). This file is the working entry point for the repository.

## Current stage

- **Week 1: Frozen** — Week 1 SDD baseline is frozen.
- Next stage: **Week 2 — Architecture + UI + Data Model**.

## Week 1 deliverables (frozen)

- Reference environment (`spec/reference-environment.md`)
- Page inventory (`spec/page-inventory.md`)
- State inventory (`spec/state-inventory.md`)
- Data model spec (`spec/data-model.md`)
- T01–T20 Reference Test Suite (`spec/reference-tests.md`)
- Black-box evidence (`evidence/screenshots/`, `evidence/image-manifest.md`)
- 34-card business-card dataset + 34 Ground Truth records (`dataset/`)
- T20 non-card exception fixture (`dataset/exception-samples/`)
- AI collaboration rules (`ai/README.md`, `ai/changes.md`)

## Source of truth priority

1. `assignment/` — immutable instructor source. Never modify.
2. `spec.md` and `spec/` — derived SDD baseline.
3. `evidence/screenshots/` — immutable black-box observation evidence.
4. `dataset/` — frozen test cards and Ground Truth.

## SDD workflow

```
Specification
  → Architecture
  → Implementation
  → Test
  → Difference Analysis
  → Revision
  → Regression
```

## Implementation conflict rule

When implementation behavior conflicts with a confirmed (frozen) specification, **fix the implementation, not the specification**. The frozen spec is not edited to accommodate code convenience.

## Do not

- Do not move SDD artifacts into `assignment/` — `assignment/` is the immutable instructor source.
- Do not silently edit frozen evidence, dataset images, or Ground Truth business fields.
- Do not begin Week 2 implementation work inside the Week 1 baseline freeze.
