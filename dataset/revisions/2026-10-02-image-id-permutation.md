# Dataset Revision — 2026-10-02 — Image-ID Permutation Correction

## Reason

Phase A integrity audit (ai/dataset-integrity-audit.md) found eight card images assigned to incorrect card IDs. The image bytes themselves are correct; only the path-to-content mapping was scrambled.

## Reference

- Phase A audit: `ai/dataset-integrity-audit.md`
- Phase A commit: `df334f5` (audit/dataset-integrity branch)

## Affected IDs

8 cards in the 005–014 range form a closed permutation.

## Permutation Applied

| Old PNG (before) | Visible Identity | New Canonical Path | Source SHA-256 |
|-----------------|------------------|-------------------|----------------|
| card-006-minimal-designer.png | Olivia Chen / North Harbor Analytics | card-005-english-analytics.png | `ec734e1756d7826d...` |
| card-009-bilingual-tourism.png | Emma Xu / Green Aurora Studio | card-006-minimal-designer.png | `f9298eecdc7b0df4...` |
| card-014-missing-email-security.png | 何嘉怡 / 广州澜图文旅 | card-009-bilingual-tourism.png | `7154c2df779d88c0...` |
| card-005-english-analytics.png | 王敏 / 星澜智能制造 | card-010-standard-bilingual-manufacturing.png | `f18ba5c9e1bd26ff...` |
| card-012-chinese-only-education.png | 孙悦 / 宁波启辰精工 | card-011-bilingual-multi-phone-fax.png | `eaeec5e7412a5d0f...` |
| card-010-standard-bilingual-manufacturing.png | 周婷 / 成都云桥教育 | card-012-chinese-only-education.png | `0a9bdb2e4eeae044...` |
| card-011-bilingual-multi-phone-fax.png | Daniel Wu / Stonepine BioSystems | card-013-english-bio-photographed.png | `f0f44db66d07e180...` |
| card-013-english-bio-photographed.png | Kevin Park / Morningside Secure Systems | card-014-missing-email-security.png | `3a306922915bed3c...` |

## Metadata

- Individual ground-truth JSON: **unchanged**
- card-index-005-034.csv: **unchanged**
- ground-truth-005-034.jsonl: **unchanged**

## Hash Conservation

- Before multiset size: 34
- After multiset size: 34
- Unique hashes: 34 (no duplicates)
- Multiset conserved: **YES**
- No image was regenerated or recompressed
- The original 34-image byte set is preserved exactly

## Method

Lossless rotation via temporary directory:
1. All 8 affected images copied to temporary directory
2. Each canonical path overwritten with correct source image
3. Hash conservation verified immediately after

---

This revision corrects a pre-existing image-ID permutation. No Ground Truth business fields were changed. No image was regenerated or recompressed. The original 34-image byte set is preserved exactly.
