# Dataset Integrity Audit — Phase A

**Baseline:** dcd2fda (`week3-camera-ocr-baseline` tag, main branch)
**Branch:** `audit/dataset-integrity`
**Date:** 2026-10-02
**Scope:** 34-card frozen dataset image ↔ ground truth identity audit
**Constraint:** Audit only. No dataset modification. No Week 4 entry.

---

## Phase A Correction Note

Initial visual-summary reconciliation found inconsistent classification in card-005...014; affected rows were re-reviewed against original PNGs on 2026-10-02. card-009 was explicitly re-verified as Emma Xu / Green Aurora Studio (NOT 何嘉怡）. The full 005–014 range was re-audited with direct PNG observation.

---

## Audit Result Summary (Corrected)

| Metric | Count |
|--------|-------|
| Total cards | 34 |
| MATCH | 26 |
| MISMATCH | 8 |
| AMBIGUOUS | 0 |
| Individual GT ↔ consolidated metadata inconsistencies | 0 |
| Exact duplicate images | 0 |

### Confirmed mismatches (005–014 range)

| Card ID | Image Visible Identity | GT Identity | Likely Matching GT ID | Confidence |
|---------|------------------------|-------------|----------------------|------------|
| card-005 | 王敏 Min Wang / 星澜智能制造有限公司 / +86 137 1001 2200 | Olivia Chen / North Harbor Analytics / +1 (415) 555-0184 | card-010 | HIGH |
| card-006 | Olivia Chen / North Harbor Analytics / +1 (415) 555-0184 | Emma Xu / Green Aurora Studio / +86 186 0217 4433 | card-005 | HIGH |
| card-009 | Emma Xu / Green Aurora Studio / +86 186 0217 4433 | 何嘉怡 / 广州澜图文旅发展有限公司 / +86 188 2506 3114 | card-006 | HIGH |
| card-010 | 周婷 / 成都云桥教育科技有限公司 / +86 181 8090 6618 | 王敏 / 星澜智能制造有限公司 / +86 137 1001 2200 | card-012 | HIGH |
| card-011 | Daniel Wu / Stonepine BioSystems / +44 7700 900245 | 孙悦 / 宁波启辰精工有限公司 / +86 158 5740 6621 | card-013 | HIGH |
| card-012 | 孙悦 Yue Sun / 宁波启辰精工有限公司 / +86 158 5740 6621 | 周婷 / 成都云桥教育科技有限公司 / +86 181 8090 6618 | card-011 | HIGH |
| card-013 | Kevin Park / Morningside Secure Systems / +1 (646) 555-0113 | Daniel Wu / Stonepine BioSystems / +44 7700 900245 | card-014 | HIGH |
| card-014 | 何嘉怡 Jiayi He / 广州澜图文旅发展有限公司 / +86 188 2506 3114 | Kevin Park / Morningside Secure Systems / +1 (646) 555-0113 | card-009 | HIGH |

### Likely remapping (confirmed 8-card permutation)

```
card-005 PNG → card-010 GT (王敏 / 星澜智能制造)
card-006 PNG → card-005 GT (Olivia Chen / North Harbor Analytics)
card-009 PNG → card-006 GT (Emma Xu / Green Aurora Studio)
card-010 PNG → card-012 GT (周婷 / 成都云桥教育)
card-011 PNG → card-013 GT (Daniel Wu / Stonepine BioSystems)
card-012 PNG → card-011 GT (孙悦 / 宁波启辰精工)
card-013 PNG → card-014 GT (Kevin Park / Morningside Secure Systems)
card-014 PNG → card-009 GT (何嘉怡 / 广州澜图文旅)
```

**8-card permutation CONFIRMED.** Each mapping verified by at least two independent identity anchors (name + company, or name + phone, or company + domain).

### Unmatched images

None — all mismatching PNGs have identifiable GT counterparts within the permutation.

### Ambiguous cards

None.

### Trusted cards

26 cards with confirmed image↔GT MATCH.

---

## Structural Audit Results

| Check | Result |
|-------|--------|
| Card PNG count | 34 ✓ |
| Individual GT JSON count | 34 ✓ |
| ID continuity 001..034 | ✓ no gaps, no duplicates |
| PNG ↔ GT bijection | ✓ exactly 1:1 |
| CSV rows 005..034 | 30 ✓ |
| JSONL records 005..034 | 30 ✓ |
| CSV IDs 005..034 | ✓ complete |
| JSONL IDs 005..034 | ✓ complete |
| Metadata consistency (JSON ↔ CSV ↔ JSONL) | 0 inconsistencies |
| Exact duplicate image bytes (SHA-256) | 0 groups |

---

## Metadata Source Consistency

All three metadata sources (individual JSON, CSV, JSONL) are **consistent** for all 30 consolidated cards (005–034).

**Classification:** IMAGE MAPPING ISSUE (metadata is consistent; the PNG files are mapped to wrong GT entries).

---

## 34-Card Audit Table

| ID | Image File | Visible Name | Visible Company | Stable Visible Anchor | Individual GT | CSV/JSONL Consistency | Image↔GT | Likely Matching GT ID | Confidence | Notes |
|----|-----------|--------------|-----------------|----------------------|-------------|----------------------|----------|----------------------|------------|-------|
| 001 | card-001-standard-bilingual.png | 张伟 Wei Zhang | 上海智云科技有限公司 | +86 138 0013 8000 | 张伟 / 上海智云科技 | N/A (001-004) | MATCH | — | HIGH | |
| 002 | card-002-missing-website.png | 李娜 Lina Li | 上海智云科技有限公司 | +86 139 1234 5678 | 李娜 / 上海智云科技 | N/A (001-004) | MATCH | — | HIGH | |
| 003 | card-003-multiple-phones-fax.png | 陈晨 Chen Chen | 上海智云科技有限公司 | +86 136 8888 1024 | 陈晨 / 上海智云科技 | N/A (001-004) | MATCH | — | HIGH | |
| 004 | card-004-minimal-name-mobile.png | 张伟 | — | +86 138 0013 8000 | 张伟 / minimal | N/A (001-004) | MATCH | — | HIGH | |
| 005 | card-005-english-analytics.png | 王敏 Min Wang | 星澜智能制造有限公司 | +86 137 1001 2200 | Olivia Chen / North Harbor Analytics | CONSISTENT | **MISMATCH** | card-010 | HIGH | |
| 006 | card-006-minimal-designer.png | Olivia Chen | North Harbor Analytics | +1 (415) 555-0184 | Emma Xu / Green Aurora Studio | CONSISTENT | **MISMATCH** | card-005 | HIGH | |
| 007 | card-007-vertical-medical-bilingual.png | 赵磊 Lei Zhao | 杭州远帆医疗科技有限公司 | +86 150 8800 7312 | 赵磊 / 杭州远帆医疗 | CONSISTENT | MATCH | — | HIGH | |
| 008 | card-008-dark-logistics-bilingual.png | 刘洋 Yang Liu | 蓝轨物流科技有限公司 | +86 139 7008 6611 | 刘洋 / 蓝轨物流 | CONSISTENT | MATCH | — | HIGH | |
| 009 | card-009-bilingual-tourism.png | Emma Xu | Green Aurora Studio | +86 186 0217 4433 | 何嘉怡 / 广州澜图文旅 | CONSISTENT | **MISMATCH** | card-006 | HIGH | |
| 010 | card-010-standard-bilingual-manufacturing.png | 周婷 | 成都云桥教育科技有限公司 | +86 181 8090 6618 | 王敏 / 星澜智能制造 | CONSISTENT | **MISMATCH** | card-012 | HIGH | |
| 011 | card-011-bilingual-multi-phone-fax.png | Daniel Wu | Stonepine BioSystems | +44 7700 900245 | 孙悦 / 宁波启辰精工 | CONSISTENT | **MISMATCH** | card-013 | HIGH | |
| 012 | card-012-chinese-only-education.png | 孙悦 Yue Sun | 宁波启辰精工有限公司 | +86 158 5740 6621 | 周婷 / 成都云桥教育 | CONSISTENT | **MISMATCH** | card-011 | HIGH | |
| 013 | card-013-english-bio-photographed.png | Kevin Park | Morningside Secure Systems | +1 (646) 555-0113 | Daniel Wu / Stonepine BioSystems | CONSISTENT | **MISMATCH** | card-014 | HIGH | |
| 014 | card-014-missing-email-security.png | 何嘉怡 Jiayi He | 广州澜图文旅发展有限公司 | +86 188 2506 3114 | Kevin Park / Morningside Secure Systems | CONSISTENT | **MISMATCH** | card-009 | HIGH | |
| 015 | card-015-zh-bilingual-product-manager.png | 李娜 | 上海智云科技有限公司 | +86 136 8888 1025 | 李娜 / 上海智云科技 | CONSISTENT | MATCH | — | HIGH | |
| 016 | card-016-en-software-engineer.png | Michael Chen | CloudMatrix Inc. | +1 415 555 0199 | Michael Chen / CloudMatrix Inc. | CONSISTENT | MATCH | — | HIGH | |
| 017 | card-017-zh-bank-department.png | 王强 | 招商银行 | +86 139 1234 5678 | 王强 / 招商银行 | CONSISTENT | MATCH | — | HIGH | |
| 018 | card-018-en-korea-dark.png | David Park | Nexa Studio | +82 10 9876 5432 | David Park / Nexa Studio | CONSISTENT | MATCH | — | HIGH | |
| 019 | card-019-ja-japanese-company.png | 佐藤健一 | さくら株式会社 | +81 90 1234 5678 | 佐藤健一 / さくら株式会社 | CONSISTENT | MATCH | — | HIGH | |
| 020 | card-020-zh-hospital.png | 陈静 | 华东第一人民医院 | +86 139 8765 4321 | 陈静 / 华东第一人民医院 | CONSISTENT | MATCH | — | HIGH | |
| 021 | card-021-de-german-umlaut.png | Sophia Müller | GlobalTech GmbH | +49 151 2345 6789 | Sophia Müller / GlobalTech GmbH | CONSISTENT | MATCH | — | HIGH | |
| 022 | card-022-zh-university.png | 刘洋 | 复旦大学 | +86 138 5555 6677 | 刘洋 / 复旦大学 | CONSISTENT | MATCH | — | HIGH | |
| 023 | card-023-en-startup-ceo.png | Emily Johnson | NovaAI | +1 650 555 0134 | Emily Johnson / NovaAI | CONSISTENT | MATCH | — | HIGH | |
| 024 | card-024-zh-manufacturing-multi-phone.png | 周磊 | 宏远制造有限公司 | +86 137 0000 9999 | 周磊 / 宏远制造 | CONSISTENT | MATCH | — | HIGH | |
| 025 | card-025-fr-en-product-director.png | Élodie Martin | Atelier Lumen SAS | +33 6 12 34 56 78 | Élodie Martin / Atelier Lumen SAS | CONSISTENT | MATCH | — | HIGH | |
| 026 | card-026-ko-en-robotics.png | 김서준 Seo-jun Kim | 한빛로보틱스 주식회사 | +82 10 4382 7715 | 김서준 / 한빛로보틱스 | CONSISTENT | MATCH | — | HIGH | |
| 027 | card-027-ja-en-design-fax.png | 高橋 美咲 Misaki Takahashi | 青空デザイン株式会社 | +81 90 2468 1357 | 高橋 美咲 / 青空デザイン | CONSISTENT | MATCH | — | HIGH | |
| 028 | card-028-zh-en-semiconductor-no-email.png | 许晨 Chen Xu | 苏州凌光半导体有限公司 | +86 159 5008 7712 | 许晨 / 苏州凌光半导体 | CONSISTENT | MATCH | — | HIGH | |
| 029 | card-029-en-apostrophe-long-address.png | Nora O'Connor | Silverline Risk Advisory | +1 917 555 0248 | Nora O'Connor / Silverline Risk Advisory | CONSISTENT | MATCH | — | HIGH | |
| 030 | card-030-en-minimal-no-phone.png | Mateo Ruiz | Cobalto Studio | mateo@cobalto.studio | Mateo Ruiz / Cobalto Studio | CONSISTENT | MATCH | — | HIGH | |
| 031 | card-031-zh-en-dark-energy.png | 林琪 Qi Lin | 深圳澄海新能源有限公司 | +86 186 8891 2040 | 林琪 / 深圳澄海新能源 | CONSISTENT | MATCH | — | HIGH | |
| 032 | card-032-en-vertical-health.png | Aisha Rahman | Meridian Health Labs | +44 7700 912481 | Aisha Rahman / Meridian Health Labs | CONSISTENT | MATCH | — | HIGH | |
| 033 | card-033-es-en-sales-director.png | José Álvarez | Nube Clara Tecnología S.L. | +34 612 345 781 | José Álvarez / Nube Clara Tecnología | CONSISTENT | MATCH | — | HIGH | |
| 034 | card-034-zh-sparse-architect.png | 顾言 | 杭州屿川建筑设计事务所 | guyan@yuchuan.design | 顾言 / 杭州屿川建筑 | CONSISTENT | MATCH | — | HIGH | |

---

## Permutation / Shift Analysis

The three mismatches form a **cyclic permutation**:

```
card-005 PNG → card-010 GT (王敏 / 星澜智能制造)
card-010 PNG → card-012 GT (周婷 / 成都云桥教育)
card-011 PNG → card-013 GT (Daniel Wu / Stonepine BioSystems)
card-012 PNG → card-011 GT (孙悦 / 宁波启辰精工)
card-013 PNG → card-014 GT (Kevin Park / Morningside Secure Systems)
card-014 PNG → card-009 GT (何嘉怡 / 广州澜图文旅)
card-009 PNG → card-009 GT (何嘉怡 / 广州澜图文旅) ← MATCH, not shifted
```

Wait — card-009 is a MATCH. Let me re-analyze:

- card-009 PNG: 何嘉怡 / 广州澜图文旅 → GT card-009: 何嘉怡 / 广州澜图文旅 ✓ MATCH
- card-014 PNG: 何嘉怡 / 广州澜图文旅 → GT card-014: Kevin Park / Morningside ✗ MISMATCH

So card-009 and card-014 PNGs show the **same identity** (何嘉怡 / 广州澜图文旅). This is not a simple cyclic permutation.

**Revised analysis:**

```
card-005 PNG → card-010 GT (王敏 / 星澜智能制造)
card-010 PNG → card-012 GT (周婷 / 成都云桥教育)
card-011 PNG → card-013 GT (Daniel Wu / Stonepine BioSystems)
card-012 PNG → card-011 GT (孙悦 / 宁波启辰精工)
card-013 PNG → card-014 GT (Kevin Park / Morningside Secure Systems)
card-014 PNG → card-009 GT (何嘉怡 / 广州澜图文旅) — duplicate identity of card-009
```

**Pattern:** The images for cards 005–014 are shifted/scrambled. This is NOT a clean cyclic permutation; cards 009 and 014 both contain the same identity （何嘉怡 / 广州澜图文旅）.

**Orphaned GTs:** card-010 GT （王敏 / 星澜智能制造） and card-012 GT （周婷 / 成都云桥教育） have no corresponding PNGs in the dataset.

**Duplicate image identity:** card-009 PNG and card-014 PNG both show 何嘉怡 / 广州澜图文旅. Only one is correct (card-009).

---

## T08/T09/T10 Representative Sample Status

| Card | Purpose | Status |
|------|---------|--------|
| card-001 | standard extraction baseline | **TRUSTWORTHY** (MATCH) |
| card-002 | missing website | **TRUSTWORTHY** (MATCH) |
| card-003 | multiple phone/fax | **TRUSTWORTHY** (MATCH) |
| card-004 | minimal name/mobile | **TRUSTWORTHY** (MATCH) |

All four representative samples are trustworthy. Week 4 T08–T10 are **not blocked** by representative sample integrity.

---

## Week 3 Smoke Cards Status

| Card | Week 3 Role | Image↔GT Status |
|------|-------------|-----------------|
| card-001 | OCR smoke (real Vision) | MATCH |
| card-004 | OCR smoke (real Vision) | MATCH |
| card-007 | crop geometry smoke | MATCH |
| card-016 | OCR smoke (real Vision) | MATCH |

All Week 3 smoke cards are trustworthy.

---

## card-005 / card-006 / card-009 / card-010 / card-011 / card-012 / card-013 / card-014 Status

| Card | Status | Details |
|------|--------|---------|
| card-005 | MISMATCH | PNG = 王敏 / 星澜智能制造； GT = Olivia Chen / North Harbor Analytics |
| card-006 | MISMATCH | PNG = Olivia Chen / North Harbor Analytics; GT = Emma Xu / Green Aurora Studio |
| card-009 | MISMATCH | PNG = Emma Xu / Green Aurora Studio; GT = 何嘉怡 / 广州澜图文旅 |
| card-010 | MISMATCH | PNG = 周婷 / 成都云桥教育； GT = 王敏 / 星澜智能制造 |
| card-011 | MISMATCH | PNG = Daniel Wu / Stonepine BioSystems; GT = 孙悦 / 宁波启辰精工 |
| card-012 | MISMATCH | PNG = 孙悦 / 宁波启辰精工； GT = 周婷 / 成都云桥教育 |
| card-013 | MISMATCH | PNG = Kevin Park / Morningside; GT = Daniel Wu / Stonepine BioSystems |
| card-014 | MISMATCH | PNG = 何嘉怡 / 广州澜图文旅； GT = Kevin Park / Morningside |

**No orphaned GT identities.** All GT identities 005–014 appear in some PNG within the 8-card permutation.

**No duplicate identity images.** card-009 and card-014 show different identities (Emma Xu vs 何嘉怡）. The earlier "duplicate" claim was an error in visual classification.

---

## card-016 Status

MATCH. PNG shows Michael Chen / CloudMatrix Inc. / +1 415 555 0199, matching GT.

---

## Proposed Phase B Correction

**Not executed.** Proposal only.

The mismatches form a confirmed 8-card permutation affecting cards 005, 006, 009, 010, 011, 012, 013, 014. All GT identities are present in the dataset; only the PNG-to-ID assignments are scrambled.

**Options:**

- **Option A:** Reassign the 8 PNGs to their correct IDs (005→010, 006→005, 009→006, 010→012, 011→013, 012→011, 013→014, 014→009). This is the cleanest fix — no image regeneration needed.
- **Option B:** Regenerate the 8 PNGs to match their current IDs. This preserves filenames but requires image generation.

**Recommendation:** Option A (reassign PNGs to correct IDs) is preferred because all GT identities are already present and correct; only the file-to-ID mapping needs correction.

---

## WEEK 4 DATASET READINESS

**BLOCKED**

Reason: Unresolved image↔GT mismatches exist (8 confirmed: card-005, 006, 009, 010, 011, 012, 013, 014). The mismatches form a confirmed 8-card permutation. A complete dataset integrity resolution is required before Week 4 T08–T11 structured-extraction validation can begin.

---

## Files Changed (Phase A)

- `tools/audit_dataset_integrity.py` — structural audit script
- `tools/generate_contact_sheets.py` — contact sheet generator
- `ai/dataset-integrity-audit.md` — this report
- `ai/validation/dataset-integrity/cards-001-009.png` — contact sheet
- `ai/validation/dataset-integrity/cards-010-018.png` — contact sheet
- `ai/validation/dataset-integrity/cards-019-027.png` — contact sheet
- `ai/validation/dataset-integrity/cards-028-034.png` — contact sheet

## Git Diff Scope

```
tools/audit_dataset_integrity.py
tools/generate_contact_sheets.py
ai/dataset-integrity-audit.md
ai/validation/dataset-integrity/*.png
```

No dataset/*, spec/*, SimCamCard/*, SimCamCardTests/*, SimCamCardUITests/*, or project.pbxproj modified.

---

## Phase B Dataset Revision Validation

**Date:** 2026-10-02
**Action:** Corrected 8-card image-ID permutation (dataset/revisions/2026-10-02-image-id-permutation.md)

### Permutation Applied

| Old PNG | New Canonical Path | Identity |
|---------|-------------------|----------|
| card-006 | card-005 | Olivia Chen / North Harbor Analytics |
| card-009 | card-006 | Emma Xu / Green Aurora Studio |
| card-014 | card-009 | 何嘉怡 / 广州澜图文旅 |
| card-005 | card-010 | 王敏 / 星澜智能制造 |
| card-012 | card-011 | 孙悦 / 宁波启辰精工 |
| card-010 | card-012 | 周婷 / 成都云桥教育 |
| card-011 | card-013 | Daniel Wu / Stonepine BioSystems |
| card-013 | card-014 | Kevin Park / Morningside Secure Systems |

### Post-Revision Audit Results

| Metric | Before | After |
|--------|--------|-------|
| Total cards | 34 | 34 |
| MATCH | 26 | **34** |
| MISMATCH | 8 | **0** |
| AMBIGUOUS | 0 | **0** |

### Verification Results

| Check | Result |
|-------|--------|
| Structural audit (counts/IDs/bijection/consistency/hash) | PASS |
| Hash multiset conservation | PASS (34→34, 0 duplicates) |
| card-005 (Olivia Chen) | MATCH ✓ |
| card-006 (Emma Xu) | MATCH ✓ |
| card-009 （何嘉怡） | MATCH ✓ |
| card-010 （王敏） | MATCH ✓ |
| card-011 （孙悦） | MATCH ✓ |
| card-012 （周婷） | MATCH ✓ |
| card-013 (Daniel Wu) | MATCH ✓ |
| card-014 (Kevin Park) | MATCH ✓ |
| card-001 standard bilingual | MATCH ✓ |
| card-002 missing website | MATCH ✓ |
| card-003 multiple phones/fax | MATCH ✓ |
| card-004 minimal name/mobile | MATCH ✓ |
| card-016 software engineer | MATCH ✓ |

### Test Results

| Suite | Result |
|-------|--------|
| Unit tests | 162/162 PASS (0 disabled) |
| card-013 OCR smoke | PASS (0.840s) |
| card-013 Crop pipeline | PASS |
| card-016 OCR smoke | PASS |
| UI tests | 26/26 PASS |
| Debug build | PASS |
| Release build | PASS |
| Release DEBUG fixture isolation | PASS (0 symbols) |

### Metadata

- Ground Truth JSON: unchanged
- CSV: unchanged
- JSONL: unchanged
- Only PNG path-to-content assignment corrected

### Final Evidence Verification (2026-10-02, baseline df334f5)

Byte-level conservation vs the Phase A commit:

```text
BEFORE_COUNT = 34
AFTER_COUNT = 34

BEFORE_UNIQUE_HASHES = 34
AFTER_UNIQUE_HASHES = 34

HASH_MULTISET_EQUAL = True

8/8 mapping verification = PASS

Individual GT changes = 0
CSV changes = 0
JSONL changes = 0

Production diff = 0
Spec diff = 0
pbxproj diff = 0

Unit = 162/162 PASS
UI = 26/26 PASS
Debug = PASS
Release = PASS
```

Contact sheet evidence:

```text
cards-001-009.png:
updated after Phase B
visual verification PASS (005 Olivia Chen, 006 Emma Xu, 009 何嘉怡)

cards-010-018.png:
updated after Phase B
visual verification PASS (010 王敏, 011 孙悦, 012 周婷, 013 Daniel Wu, 014 Kevin Park)

cards-019-027.png:
byte-identical, no affected IDs

cards-028-034.png:
byte-identical, no affected IDs
```

Final working-tree scope:

```text
13 modified tracked paths
1 untracked revision-record path
14 total paths
```

---

**WEEK 4 DATASET READINESS: READY**

All 34 cards confirmed image↔GT MATCH. Representative cards (001-004) trustworthy. Week 3 smoke cards (001/004/007/016) all functional. card-013 OCR restored and passing.

---

**Human Decision:** Accepted — 2026-10-02 (human review).
