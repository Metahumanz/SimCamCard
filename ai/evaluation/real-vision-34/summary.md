# Real Vision OCR Evaluation — 34 frozen cards

Generated: 2026-10-15

Engine: real production pipeline (`CapturedPhoto → CardCropProcessor.prepare → perspectiveCorrect → CardOCRProcessor.recognize → CardFieldExtractor.extract`) over the 34 unmodified frozen PNGs in `dataset/cards/`. No GT-derived synthetic OCR lines are used in this report.

## 1. Image pipeline (detection / crop / OCR)

- Cards evaluated: **34**
- Real Vision rectangle detection accepted: **19**; production inset fallback: **15** (of which **14** are sub-gate tiny quads rejected by `minimumDetectedArea`; genuine no-detection fallbacks: **1**)
- Pipeline errors: **0**
- Total OCR lines returned by Vision: **316**
- Cards with zero OCR lines: **0**

## 2. Region-detector false positives — root-cause separation

A diagnostic, **unscored** pass OCRs the full upright image (identity region, same EXIF orientation) to separate detector/crop failures from Vision OCR recognition failures.

Correct crops cover 0.47–0.93 normalized area; the bad lock-ons observed in the pre-gate baseline cover 0.007–0.024 and sit on a small decorative element near the top-left corner (near-identical coordinates across the shared-template cards card-025–card-034). `CardRegionGeometry.minimumDetectedArea` (0.05) sits between the two populations with >10× margin and now gates auto-acceptance: a geometrically valid but smaller quad is routed to the inset fallback instead of being accepted.

- Pre-gate baseline: Vision auto-accepted **14** tiny quads (< 5% area): card-012, card-017, card-020, card-021, card-025, card-026, card-027, card-028, card-029, card-030, card-031, card-032, card-033, card-034. All 14 produced zero OCR lines from the warped patch; **2** of them (card-012, card-029) also fell below the `minimumNormalizedArea` floor (0.01) and `perspectiveCorrect` threw `invalidRegion`.
- Current gated run: **0** tiny quads auto-accepted, **0** pipeline errors, **0** zero-OCR-line cards. Every sub-gate detection now falls back and OCRs the full card (§9 per-card deltas).

Of the **69** non-matching present-field cells:

- **4** are detector/crop-rooted: the GT anchor is absent from the warped OCR but present in full-image OCR (across 4 cards: card-020, card-022, card-028, card-029).
- **10** are OCR-recognition-rooted: the anchor is in neither the warped nor the full-image OCR text.
- **55** are extractor-rooted: the anchor reached the warped raw text but was misclassified, mistyped or dropped by the deterministic parser.

Note: the application flow offers manual corner adjustment (P04) before confirm; this harness models the auto-accept path (user confirms the detected boundary). The numbers above bound the damage of accepting a false detection without adjustment.

## 3. Field-level results (vs frozen Ground Truth)

Denominators: **present** = GT field non-null; **absent** = GT field null. Match counts strict `M` plus bilingual native-side `N`. `OCR coverage` = share of present fields whose raw OCR text contains the GT anchor. `Extractor conditional` = match share among present fields whose raw OCR anchor was found (isolates parser behavior from OCR).

| Field | GT present | Match | Present-field accuracy | GT absent | Strict canonical absence | Alt exact | Alt partial | Genuine fab | OCR coverage | Extractor conditional |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| name | 34 | 28 | 82.4% | 0 | 0 | 0 | 0 | 0 | 100.0% | 82.4% |
| company | 20 | 15 | 75.0% | 14 | 5 | 7 | 2 | 0 | 90.0% | 83.3% |
| jobTitle | 33 | 28 | 84.8% | 1 | 1 | 0 | 0 | 0 | 90.9% | 93.3% |
| address | 31 | 11 | 35.5% | 3 | 3 | 0 | 0 | 0 | 74.2% | 47.8% |
| mobile | 32 | 19 | 59.4% | 2 | 2 | 0 | 0 | 0 | 100.0% | 59.4% |
| office | 23 | 8 | 34.8% | 11 | 11 | 0 | 0 | 0 | 100.0% | 34.8% |
| fax | 4 | 2 | 50.0% | 30 | 30 | 0 | 0 | 0 | 100.0% | 50.0% |
| email | 31 | 29 | 93.5% | 3 | 3 | 0 | 0 | 0 | 96.8% | 96.7% |
| website | 25 | 24 | 96.0% | 9 | 9 | 0 | 0 | 0 | 100.0% | 96.0% |
| **TOTAL (micro)** | **233** | **164** | **70.4%** | **73** | **64** | **7** | **2** | **0** | **94.0%** | **74.9%** |

GT-absent denominator (**73** cells) is split into four mutually exclusive buckets; the definition is **identical** for the before and the after run (see §9). Both `Strict canonical absence` and `Genuine fabrication` are comparable across runs — they measure different kinds of problems (a GT-absent field staying absent vs. a GT-absent field being filled with an unsupported value). `Alt partial` is an overlap, **not** an exact match, and is never folded into exact.

Card-level fully-matching (all 9 fields): **9/34**
…of which at least one field is a bilingual native-side match (`N`): 5

## 4. Error-type totals (306 field rows)

| errorType | count | meaning |
|---|---:|---|
| match | 155 | GT present, exact/anchor match |
| match_native_partial | 9 | GT present, native side matched; full bilingual line not contained |
| accepted_alternate_language | 9 | GT canonical absent; observed value matches GT Latin variant (e.g. companyLatin when company is null) |
| ocr_miss | 14 | GT present; raw OCR text lacks the GT anchor |
| extraction_miss | 19 | raw OCR contains the anchor but the parser did not classify it |
| wrong_value | 6 | raw OCR has the anchor but the observed field value differs |
| kind_misclassification | 30 | phone digits found but classified under the wrong kind |
| fabrication | 0 | GT absent, value present, no alternate-language match (genuine fabrication) |
| correct_absent | 64 | GT absent; no value produced |

### 4.1 GT-absent cells — four mutually exclusive buckets (after run)

Derived in the host assembler from the observed value and the frozen GT `companyLatin`; the harness `accepted_alternate_language` label is not used as-is because it conflates exact and partial overlaps.

| bucket | count | share of 73 absent cells | meaning |
|---|---:|---:|---|
| `canonical_absent` | 64 | 87.7% | Strict canonical absence |
| `alternate_exact` | 7 | 9.6% | Alternate-language exact match |
| `alternate_partial` | 2 | 2.7% | Alternate-language partial match |
| `fabrication` | 0 | 0.0% | Genuine fabrication |

Alternate-language rows (canonical GT `company` is null; observed value compared against frozen GT `companyLatin`). A PARTIAL row is **not** an exact alternate-language match:

| card | observed value | GT companyLatin | kind |
|---|---|---|---|
| card-006 | Green Aurora Studio | Green Aurora Studio | EXACT |
| card-013 | BioSystems | Stonepine BioSystems | PARTIAL |
| card-014 | Secure Systems | Morningside Secure Systems | PARTIAL |
| card-016 | CloudMatrix Inc. | CloudMatrix Inc. | EXACT |
| card-018 | Nexa Studio | Nexa Studio | EXACT |
| card-021 | GlobalTech GmbH | GlobalTech GmbH | EXACT |
| card-025 | Atelier Lumen SAS | Atelier Lumen SAS | EXACT |
| card-030 | Cobalto Studio | Cobalto Studio | EXACT |
| card-032 | Meridian Health Labs | Meridian Health Labs | EXACT |

## 5. Layer separation

1. **Detection / crop layer** — the Phase 1 dominant defect (auto-accepted tiny-quad lock-on, 14 cards) is closed by the `minimumDetectedArea` gate: every former lock-on now falls back and OCRs the card. The residual 4/69 crop-rooted present-field misses come from accepted/fallback crops that pass the area gate yet still clip the GT anchor (see §7).
2. **OCR recognition layer** — Vision raw text vs GT anchor on the production warped image: 94.0% coverage over 233 present fields (219/233). 10 missed anchors are absent even from full-image OCR; those are Vision recognition limitations, not parser or crop defects.
3. **Structured extraction layer** — given the anchor reached raw text, the deterministic extractor classified correctly 164/219 (74.9%). The residual 55 are extraction/kind/wrong-value errors.
4. **No-fabrication (behavioral) layer** — across 73 GT-absent cells the four buckets are strict canonical absence **64**, alternate-language exact **7**, alternate-language partial **2**, genuine fabrication **0**. Strict canonical absence (87.7%) and genuine fabrication (0) are both cross-run comparable, measuring different kinds of problems; partial overlaps are **not** counted as exact alternate-language matches. All 9 alternate-language rows are `company` values whose canonical GT `company` is null while GT `companyLatin` is populated — the parser recognized a real GT field under a different language key, not a fabricated value. Genuine fabrication is 0: no absent field received a value lacking any GT alternate-language overlap.
5. **Reference behavior layer** — CamCard black-box comparisons are reported separately in the delivery gap list; this report makes no CamCard accuracy claim beyond the actually observed cards.

## 6. Per-card matrix

M = match (strict contains); N = native-side match (bilingual GT, full line not contained); L = accepted alternate-language EXACT match (GT canonical absent, observed equals GT Latin variant); P = alternate-language PARTIAL match (observed and GT Latin variant overlap, not equal) — not an exact match; O = OCR miss (raw OCR lacks GT anchor); E = extraction miss (raw OCR has anchor, parser did not classify); W = wrong value (anchor in raw OCR, observed value differs); K = phone kind misclassification (digits found, wrong kind); F = genuine fabrication (GT absent, value present, no Latin variant overlap); A = canonical absence (GT absent, no value produced).

| card | detected | area | OCR lines | full-img lines | name | company | jobTitle | mobile | office | fax | email | website | address |
|---|---|---:|---:|---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| card-001 | yes | 0.620 | 10 | 10 | M | M | M | M | M | M | A | M | M |
| card-002 | yes | 0.623 | 9 | 9 | M | M | N | M | M | M | A | M | A |
| card-003 | yes | 0.622 | 12 | 12 | M | M | N | M | M | M | M | M | M |
| card-004 | yes | 0.467 | 2 | 2 | M | A | A | A | M | A | A | A | A |
| card-005 | yes | 0.753 | 14 | 13 | W | A | M | M | K | K | A | M | M |
| card-006 | yes | 0.791 | 5 | 5 | M | L | M | A | M | A | A | M | A |
| card-007 | yes | 0.756 | 9 | 9 | M | M | N | M | M | M | A | M | A |
| card-008 | yes | 0.753 | 11 | 11 | M | M | N | M | M | M | M | M | M |
| card-009 | yes | 0.745 | 11 | 12 | M | M | N | M | M | M | A | M | M |
| card-010 | yes | 0.756 | 12 | 12 | M | M | M | M | M | K | A | M | M |
| card-011 | yes | 0.656 | 14 | 13 | M | M | N | M | M | K | K | M | A |
| card-012 | fallback | 0.774 | 8 | 8 | M | M | M | M | M | M | A | M | W |
| card-013 | yes | 0.751 | 14 | 14 | M | P | M | E | K | K | A | M | M |
| card-014 | yes | 0.772 | 8 | 8 | M | P | M | M | M | M | A | A | M |
| card-015 | yes | 0.931 | 9 | 9 | M | M | M | O | M | A | A | M | A |
| card-016 | yes | 0.934 | 9 | 9 | M | L | M | O | K | A | A | M | M |
| card-017 | fallback | 0.774 | 10 | 9 | M | M | M | O | M | K | A | M | A |
| card-018 | yes | 0.919 | 10 | 12 | M | L | M | O | K | A | A | M | M |
| card-019 | yes | 0.931 | 9 | 9 | M | W | E | E | K | A | A | M | M |
| card-020 | fallback | 0.774 | 11 | 10 | M | O | M | E | M | K | A | M | A |
| card-021 | fallback | 0.774 | 9 | 9 | E | L | M | O | K | A | A | M | M |
| card-022 | fallback | 0.774 | 10 | 11 | W | O | O | O | M | A | A | O | M |
| card-023 | yes | 0.913 | 9 | 9 | M | A | M | O | K | A | A | M | M |
| card-024 | yes | 0.759 | 9 | 12 | M | M | M | E | M | K | A | M | M |
| card-025 | fallback | 0.774 | 8 | 8 | E | L | M | E | K | K | A | M | M |
| card-026 | fallback | 0.774 | 10 | 10 | W | E | O | E | K | K | A | M | M |
| card-027 | fallback | 0.774 | 11 | 11 | M | W | N | E | K | K | K | M | M |
| card-028 | fallback | 0.774 | 9 | 8 | M | M | O | E | M | K | A | A | M |
| card-029 | fallback | 0.774 | 8 | 8 | M | A | M | O | K | K | A | M | M |
| card-030 | fallback | 0.774 | 5 | 5 | M | L | E | A | A | A | A | M | M |
| card-031 | fallback | 0.774 | 10 | 10 | M | M | N | E | M | K | A | M | M |
| card-032 | fallback | 0.774 | 8 | 8 | M | L | M | E | K | K | A | E | M |
| card-033 | fallback | 0.774 | 8 | 8 | E | A | N | E | K | K | A | M | M |
| card-034 | fallback | 0.774 | 5 | 5 | M | M | M | E | A | A | A | M | A |

## 7. Detailed error listing (all non-match, non-correct-absent rows)

| card | field | type | GT | observed | warped anchor | full-img anchor | note |
|---|---|---|---|---|:---:|:---:|---|
| card-005 | name | wrong_value | Olivia Chen | North Harbor | yes | yes | raw OCR contains anchor but observed field value differs |
| card-005 | mobile | kind_misclassification | +1 (415) 555-0184 |  | yes | yes | digits found but classified as other instead of mobile |
| card-005 | office | kind_misclassification | +1 (415) 555-0147 |  | yes | yes | digits found but classified as other instead of office |
| card-010 | office | kind_misclassification | +86 21 6200 1188 |  | yes | yes | digits found but classified as other instead of office |
| card-011 | office | kind_misclassification | +86 574 8790 3321 |  | yes | yes | digits found but classified as other instead of office |
| card-011 | fax | kind_misclassification | +86 574 8790 3329 |  | yes | yes | digits found but classified as other instead of fax |
| card-012 | website | wrong_value | www.yqedu.cn | www.yqeau.cn | yes | yes | anchor in raw OCR, observed value differs |
| card-013 | address | extraction_miss | 14 Kingsway, London WC2B 6XF, UK |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-013 | mobile | kind_misclassification | +44 7700 900245 |  | yes | yes | digits found but classified as other instead of mobile |
| card-013 | office | kind_misclassification | +44 20 7946 1288 |  | yes | yes | digits found but classified as other instead of office |
| card-015 | address | ocr_miss | 上海市徐汇区漕溪北路398号 200030 |  | no | no | raw OCR does not contain the GT anchor |
| card-016 | address | ocr_miss | 500 Terry A Francois Blvd, San Francisco, CA 94158, USA |  | no | no | raw OCR does not contain the GT anchor |
| card-016 | mobile | kind_misclassification | +1 415 555 0199 |  | yes | yes | digits found but classified as other instead of mobile |
| card-017 | address | ocr_miss | 上海市浦东新区陆家嘴环路1088号 200120 |  | no | no | raw OCR does not contain the GT anchor |
| card-017 | office | kind_misclassification | +86 21 5555 6666 |  | yes | yes | digits found but classified as other instead of office |
| card-018 | address | ocr_miss | 12 Teheran-ro, Gangnam-gu, Seoul 06234, Korea |  | no | no | raw OCR does not contain the GT anchor |
| card-018 | mobile | kind_misclassification | +82 10 9876 5432 |  | yes | yes | digits found but classified as other instead of mobile |
| card-019 | company | wrong_value | さくら株式会社 | Sakura Co., Ltd. | yes | yes | raw OCR contains anchor but observed field value differs |
| card-019 | jobTitle | extraction_miss | マネージャー |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-019 | address | extraction_miss | 東京都千代田区丸の内1-9-1 100-0005 |  | yes | no | raw OCR contains anchor but extractor did not classify |
| card-019 | mobile | kind_misclassification | +81 90 1234 5678 |  | yes | yes | digits found but classified as other instead of mobile |
| card-020 | company | ocr_miss | 华东第一人民医院 |  | no | yes | raw OCR does not contain the GT anchor |
| card-020 | address | extraction_miss | 上海市静安区延安中路1000号 200040 |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-020 | office | kind_misclassification | +86 21 6666 8888 |  | yes | yes | digits found but classified as other instead of office |
| card-021 | name | extraction_miss | Sophia Müller |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-021 | address | ocr_miss | Musterstraße 12, 80331 München, Deutschland |  | no | no | raw OCR does not contain the GT anchor |
| card-021 | mobile | kind_misclassification | +49 151 2345 6789 |  | yes | yes | digits found but classified as other instead of mobile |
| card-022 | name | wrong_value | 刘洋 | 復旦大拳 | yes | yes | raw OCR contains anchor but observed field value differs |
| card-022 | company | ocr_miss | 复旦大学 | FUDAN UNIVERSITY | no | no | raw OCR lacks GT anchor; observed value may be OCR error |
| card-022 | jobTitle | ocr_miss | 副教授 | 刷教授 | no | no | raw OCR lacks GT anchor; observed value may be OCR error |
| card-022 | address | ocr_miss | 上海市杨浦区邯郸路220号 200433 |  | no | yes | raw OCR does not contain the GT anchor |
| card-022 | email | ocr_miss | liuyang@fudan.edu.cn | livyang@fudan.edu.cn | no | no | raw OCR lacks the GT email |
| card-023 | address | ocr_miss | 3200 Hillview Ave, Palo Alto, CA 94304, USA |  | no | no | raw OCR does not contain the GT anchor |
| card-023 | mobile | kind_misclassification | +1 650 555 0134 |  | yes | yes | digits found but classified as other instead of mobile |
| card-024 | address | extraction_miss | 上海市嘉定区嘉罗公路123号 201800 |  | yes | no | raw OCR contains anchor but extractor did not classify |
| card-024 | office | kind_misclassification | +86 21 7777 8888 |  | yes | yes | digits found but classified as other instead of office |
| card-025 | name | extraction_miss | Élodie Martin |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-025 | address | extraction_miss | 24 Rue de Lyon, 75012 Paris, France |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-025 | mobile | kind_misclassification | +33 6 12 34 56 78 |  | yes | yes | digits found but classified as other instead of mobile |
| card-025 | office | kind_misclassification | +33 1 84 80 22 10 |  | yes | yes | digits found but classified as other instead of office |
| card-026 | name | wrong_value | 김서준 | Seo-jun Kim | yes | yes | raw OCR contains anchor but observed field value differs |
| card-026 | company | extraction_miss | 한빛로보틱스 주식회사 |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-026 | jobTitle | ocr_miss | 제품전략 매니저 \| Product Strategy Manager | \|Prodct Strategy Manager | no | no | raw OCR lacks GT anchor; observed value may be OCR error |
| card-026 | address | extraction_miss | 대한민국 서울특별시 강남구 테헤란로 221, 06142 |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-026 | mobile | kind_misclassification | +82 10 4382 7715 |  | yes | yes | digits found but classified as other instead of mobile |
| card-026 | office | kind_misclassification | +82 2 6123 4400 |  | yes | yes | digits found but classified as other instead of office |
| card-027 | company | wrong_value | 青空デザイン株式会社 | Aozora Design Inc. | yes | yes | raw OCR contains anchor but observed field value differs |
| card-027 | address | extraction_miss | 東京都渋谷区神宮前4-18-7 150-0001 |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-027 | mobile | kind_misclassification | +81 90 2468 1357 |  | yes | yes | digits found but classified as other instead of mobile |
| card-027 | office | kind_misclassification | +81 3 6450 2290 |  | yes | yes | digits found but classified as other instead of office |
| card-027 | fax | kind_misclassification | +81 3 6450 2299 |  | yes | yes | digits found but classified as other instead of fax |
| card-028 | jobTitle | ocr_miss | 产品应用工程师 \| Field Application Engineer |  | no | yes | raw OCR does not contain the GT anchor |
| card-028 | address | extraction_miss | 中国 苏州市工业园区星湖街328号 215123 |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-028 | office | kind_misclassification | +86 512 6688 2046 |  | yes | yes | digits found but classified as other instead of office |
| card-029 | address | ocr_miss | 375 Lexington Avenue, Floor 18, New York, NY 10017, USA |  | no | yes | raw OCR does not contain the GT anchor |
| card-029 | mobile | kind_misclassification | +1 917 555 0248 |  | yes | yes | digits found but classified as other instead of mobile |
| card-029 | office | kind_misclassification | +1 212 555 0186 |  | yes | yes | digits found but classified as other instead of office |
| card-030 | jobTitle | extraction_miss | UX Researcher |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-031 | address | extraction_miss | 中国 深圳市南山区科苑南路2666号 518063 |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-031 | office | kind_misclassification | +86 755 8654 2033 |  | yes | yes | digits found but classified as other instead of office |
| card-032 | address | extraction_miss | 88 Great Portland Street, London W1W 7NT, UK |  | yes | no | raw OCR contains anchor but extractor did not classify |
| card-032 | mobile | kind_misclassification | +44 7700 912481 |  | yes | yes | digits found but classified as other instead of mobile |
| card-032 | office | kind_misclassification | +44 20 7946 2310 |  | yes | yes | digits found but classified as other instead of office |
| card-032 | email | extraction_miss | aisha.rahman@meridianhealthlabs.co.uk | eaisha.rahman@meridianhealthlabs.co.uk | yes | yes | raw OCR contains email but extractor missed it |
| card-033 | name | extraction_miss | José Álvarez |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-033 | address | extraction_miss | Calle de Alcalá 121, 28009 Madrid, España |  | yes | yes | raw OCR contains anchor but extractor did not classify |
| card-033 | mobile | kind_misclassification | +34 612 345 781 |  | yes | yes | digits found but classified as other instead of mobile |
| card-033 | office | kind_misclassification | +34 91 555 2480 |  | yes | yes | digits found but classified as other instead of office |
| card-034 | address | extraction_miss | 杭州市西湖区文三路90号 310012 |  | yes | yes | raw OCR contains anchor but extractor did not classify |

## 8. Multi-phone classification (mobile / office / fax)

- mobile: present in 32 cards, correctly classified 19/32; kind misclassifications: 13 (card-005, card-013, card-016, card-018, card-019, card-021, card-023, card-025, card-026, card-027, card-029, card-032, card-033)
- office: present in 23 cards, correctly classified 8/23; kind misclassifications: 15 (card-005, card-010, card-011, card-013, card-017, card-020, card-024, card-025, card-026, card-027, card-028, card-029, card-031, card-032, card-033)
- fax: present in 4 cards, correctly classified 2/4; kind misclassifications: 2 (card-011, card-027)

## 9. Before / after — per-card effect of the area gate

Baseline: the **same** harness, dataset, Ground Truth and normalization rules; the production pipeline was measured with the `minimumDetectedArea` auto-acceptance gate removed (a temporary, fully-restored measurement-only revert). The gate is the only difference between the two runs.

### 9.1 Aggregate deltas

| metric | before (no gate) | after (gate) |
|---|---:|---:|
| detection accepted | 33 | 19 |
| inset fallback | 1 | 15 |
| pipeline errors (`invalidRegion`) | 2 | 0 |
| zero-OCR-line cards | 14 | 0 |
| total OCR lines | 196 | 316 |
| present-field match | 109/233 (46.8%) | 164/233 (70.4%) |
| fully-matching cards (9/9 cells) | 9 | 9 |

**GT-absent cells (73 in both runs) — same four-bucket definition applied to the before and the after payload.** These are the only rows of the table whose values are guaranteed comparable, because the bucket label is re-derived host-side from the observed value and the frozen GT, not inherited from the harness:

| bucket | before (no gate) | after (gate) |
|---|---:|---:|
| `canonical_absent` | 68 | 64 |
| `alternate_exact` | 3 | 7 |
| `alternate_partial` | 2 | 2 |
| `fabrication` | 0 | 0 |
| *(denominator)* | 73 | 73 |

Reading: strict canonical absence **drops** (68 → 64) because the gate lets four more cards reach OCR, and those cards surface the unchanged `companyLatin` promotion path (alternate-language count rises). This is a **real trade-off, not a regression in safety**: genuine fabrication stays **0 → 0** and no absent cell received an unsupported value. Both strict canonical absence and genuine fabrication are comparable across runs — they measure different kinds of problems (absence correctness vs. no-fabrication); the previous report compared strict-before with relaxed-after as a single safety figure and is superseded here.

Harness raw labels before → after (not the comparable metric): `ocr_miss` 105→14; `extraction_miss` 4→19; `wrong_value` 3→6; `kind_misclassification` 12→30; `fabrication` 0→0; `accepted_alternate_language` 5→9

### 9.2 Per-card deltas

`mode`: det = auto-accepted quad, fb = inset fallback, ERR = pipeline error (`invalidRegion`). `lines` = primary OCR line count. `cells` = correct cells out of 9 (match incl. native-side / accepted-alternate-language / correct-absent). `changes` = per-field status transitions before→after (letters per §6 legend).

| card | mode before→after | lines before→after | cells before→after | changes |
|---|:---:|---:|---:|---|
| card-001 | det→det | 10→10 | 9→9 | — |
| card-002 | det→det | 9→9 | 9→9 | — |
| card-003 | det→det | 12→12 | 9→9 | — |
| card-004 | det→det | 2→2 | 9→9 | — |
| card-005 | det→det | 14→14 | 6→6 | — |
| card-006 | det→det | 5→5 | 9→9 | — |
| card-007 | det→det | 9→9 | 9→9 | — |
| card-008 | det→det | 11→11 | 9→9 | — |
| card-009 | det→det | 11→11 | 9→9 | — |
| card-010 | det→det | 12→12 | 8→8 | — |
| card-011 | det→det | 14→14 | 7→7 | — |
| card-012 | ERR→fb | 0→8 | 1→8 | name: O→M, company: O→M, jobTitle: O→M, address: O→M, mobile: O→M, office: O→M, email: O→M, website: O→W |
| card-013 | det→det | 14→14 | 6→6 | — |
| card-014 | det→det | 8→8 | 9→9 | — |
| card-015 | det→det | 9→9 | 8→8 | — |
| card-016 | det→det | 9→9 | 7→7 | — |
| card-017 | det→fb | 0→10 | 2→7 | name: O→M, company: O→M, jobTitle: O→M, mobile: O→M, office: O→K, email: O→M |
| card-018 | det→det | 10→10 | 7→7 | — |
| card-019 | det→det | 9→9 | 5→5 | — |
| card-020 | det→fb | 0→11 | 2→6 | name: O→M, jobTitle: O→M, address: O→E, mobile: O→M, office: O→K, email: O→M |
| card-021 | det→fb | 0→9 | 3→6 | name: O→E, company: A→L, jobTitle: O→M, mobile: O→K, email: O→M, website: O→M |
| card-022 | fb→fb | 10→10 | 4→4 | — |
| card-023 | det→det | 9→9 | 7→7 | — |
| card-024 | det→det | 9→9 | 7→7 | — |
| card-025 | det→fb | 0→8 | 2→5 | name: O→E, company: A→L, jobTitle: O→M, address: O→E, mobile: O→K, office: O→K, email: O→M, website: O→M |
| card-026 | det→fb | 0→10 | 1→3 | name: O→W, company: O→E, address: O→E, mobile: O→K, office: O→K, email: O→M, website: O→M |
| card-027 | det→fb | 0→11 | 0→4 | name: O→M, company: O→W, jobTitle: O→N, address: O→E, mobile: O→K, office: O→K, fax: O→K, email: O→M, website: O→M |
| card-028 | det→fb | 0→9 | 2→6 | name: O→M, company: O→M, address: O→E, mobile: O→M, office: O→K, website: O→M |
| card-029 | ERR→fb | 0→8 | 2→6 | name: O→M, jobTitle: O→M, mobile: O→K, office: O→K, email: O→M, website: O→M |
| card-030 | det→fb | 0→5 | 5→8 | name: O→M, company: A→L, jobTitle: O→E, email: O→M, website: O→M |
| card-031 | det→fb | 0→10 | 1→7 | name: O→M, company: O→M, jobTitle: O→N, address: O→E, mobile: O→M, office: O→K, email: O→M, website: O→M |
| card-032 | det→fb | 0→8 | 2→5 | name: O→M, company: A→L, jobTitle: O→M, address: O→E, mobile: O→K, office: O→K, email: O→E, website: O→M |
| card-033 | det→fb | 0→8 | 2→5 | name: O→E, jobTitle: O→N, address: O→E, mobile: O→K, office: O→K, email: O→M, website: O→M |
| card-034 | det→fb | 0→5 | 4→8 | name: O→M, company: O→M, jobTitle: O→M, address: O→E, email: O→M |

