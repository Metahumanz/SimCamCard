# SimCamCard — SDD Work Entry

SimCamCard follows Specification-Driven Development (SDD). This file is the working entry point for the repository.

## Current stage

- **Week 1: Frozen** — the Week 1 SDD baseline remains frozen; this file still documents it as the immutable starting point.
- **Phase 1.1: Accepted (human review), 2026-10-18** — baseline commit
  `de58eee81326e6728080a2816ac718520c268366` on
  `week4/structured-recognition`. The bounded feature slice is implemented and
  behaviorally accepted (T01–T20 = 20/20 PASS).
- Next: **Final Delivery Phase 2** — documentation refresh and human review only.
  No new feature increment is planned. Formal packaging and extraction
  verification occur in **Phase 3**. See `ai/delivery/delivery-package-plan.md`.

The frozen Week 1 artifacts below were not modified while progressing from
Week 2 to Phase 1.1; they remain the derived SDD baseline.

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

## Final delivery workflow (Phase 2)

Week 1 → … → Phase 1.1 each added an increment under the same loop
(Specification → Architecture → Implementation → Test → Difference Analysis
→ Revision → Regression). Phase 2A consolidates the result for submission;
it adds documentation and packaging only.

Final delivery artifacts:

- `ai/final-acceptance.md` — T01–T20 behavioral acceptance.
- `ai/final-reference-audit.md` — P01–P11 Reference-fidelity audit
  (behavioral PASS vs surface PARTIAL are separate axes).
- `ai/delivery/course-compliance-matrix.md` — assignment requirement
  ⇄ code / test / evidence traceability.
- `ai/delivery/final-gap-list.md` — open gaps and classified limitations.
- `ai/delivery/delivery-package-plan.md` — submission packaging plan.
- `ai/evaluation/real-vision-34/` — real Vision OCR evaluation over the 34
  frozen cards (`summary.md`, `environment.md`, `comparison.csv`, raw/structured
  JSONL, before/after payloads).
- `ai/changes.md` — increment-by-increment AI/human collaboration record.

Rules that continue to hold during packaging:

- `assignment/`, `spec.md`, `spec/`, `evidence/`, `dataset/`, the Domain model,
  and the Persistence schema stay frozen and unmodified.
- Historical records are appended to, not rewritten: prior audit dates, baseline
  commits, blockers, and test counts are preserved as historical facts, with any
  later update clearly marked as such.
- Test figures quoted in delivery documents carry their measured date and commit;
  they are never presented as if re-run by a later documentation change.
