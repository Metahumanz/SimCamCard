# Real Vision evaluation — environment & methodology

- Run date (UTC, device clock): 2026-10-15T04:45:25Z
- Xcode: 27.0
- iOS: 27.0
- Simulator: iPhone 18 Pro
- OCR engine: Vision RecognizeTextRequest (.accurate, zh-Hans+en-US, auto-detect ON, correction OFF)
- Region detector: Vision VNDetectRectanglesRequest via CardRegionDetector
- Crop: CardCropProcessor actor + CIPerspectiveCorrection
- Dataset: 34 frozen dataset PNGs, unmodified
- Ground truth: dataset/ground-truth/card-001..034.json

## Pipeline (real production components)

```
PNG Data → CapturedPhoto(source: .photoLibrary)
→ CardCropProcessor.prepare      (Vision rectangle detection;
                                  quad area < 0.05 (minimumDetectedArea)
                                  or no quad → inset fallback 0.06–0.94,
                                  wasDetected=false, NOT a failure)
→ CardCropProcessor.perspectiveCorrect (CIPerspectiveCorrection,
                                        upright PNG, .up)
→ CardOCRProcessor.recognize     (RecognizeTextRequest, .accurate,
                                  zh-Hans then en-US, auto language
                                  detection ON, correction OFF,
                                  no customWords)
→ CardFieldExtractor.extract     (deterministic local parser)
```

A second, **diagnostic-only** pass per card runs the same OCR over
the full upright image through an identity region (no detector
quad). Its output (`diag*` fields) is never scored; it exists solely
to separate detector/crop root causes from OCR recognition root
causes (see summary.md §2). The detected quad's normalized area is
recorded as `detectedRegionNormalizedArea`.

## Harness & repeatability

- Harness: `SimCamCardTests/Evaluation/RealVision34EvaluationTests.swift`
  (env-gated: skipped in the deterministic 431-test baseline).
- Run:

```sh
TEST_RUNNER_REAL_VISION_EVAL=1 xcodebuild test \
  -project SimCamCard.xcodeproj -scheme SimCamCard \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:SimCamCardTests/RealVision34EvaluationTests \
  -parallel-testing-enabled NO
python3 tools/assemble_real_vision34.py
```

Vision OCR is probabilistic: exact per-card numbers may vary slightly across OS/machine runs; the harness preserves the full raw text so every error can be traced. The frozen dataset and Ground Truth are never modified to improve scores.

## Normalization & scoring rules

- `compact(s)`: lowercase, all whitespace removed.
- `digits(s)`: all Unicode digit characters kept, others removed.
- Text fields (name/company/jobTitle/address): **strict match** = compact(GT) substring of compact(observed). A secondary **native-side match** (`N`) accepts the part before ` | ` in bilingual GT lines (e.g. `产品总监 | Product Director` → `产品总监`); it counts as a match but is reported separately.
- Phones: equality on `digits(value)`; kind must equal GT (mobile/office/fax). Digits present under another kind = `kind_misclassification`.
- Email: lowercase exact membership in the extracted email list.
- Website: core equality after lowercasing and stripping `http(s)://`, leading `www.` and trailing `/`.
- Raw-OCR anchor: same normalization applied to the full raw text; phones use digit-substring, websites the core token.
- `fullImageContainsAnchor` (CSV/§2/§7): same anchor test applied to the unscored full-image diagnostic OCR. `warped=no, full=yes` ⇒ detector/crop-rooted miss; `no/no` ⇒ OCR-recognition-rooted.

## Denominators and empty-field handling

- Each of 9 fields x 34 cards = 306 cells.
- **Present-field accuracy** = matches / cells where GT is non-null.
- **GT-absent cells (73)** are split into four mutually exclusive buckets, re-derived host-side in `tools/assemble_real_vision34.py` from the observed value and the frozen GT `companyLatin` (read-only). The **same definition** is applied to the before and the after payload so the two runs share one metric:
  1. `canonical_absent` — **strict** canonical absence correctness: GT canonical field null and no value produced. Comparable across runs; it measures whether a GT-absent field stays absent — a problem of a different kind from bucket 4 (fabrication), which is likewise comparable across runs.
  2. `alternate_exact` — GT canonical field null and the observed value **equals** the GT alternate-language variant (compact equality).
  3. `alternate_partial` — the observed value and the GT alternate-language variant merely **overlap** (one compact string contains the other and they are not equal). Example: observed `BioSystems` vs GT `Stonepine BioSystems` — marked **PARTIAL** and never counted as an exact alternate-language match.
  4. `fabrication` — observed value present with no GT alternate-language overlap (genuine fabrication).
- The harness additionally emits a coarse `accepted_alternate_language` label via bidirectional substring overlap; that label conflates buckets 2 and 3 and is **not** used for the safety metric. `comparison.csv` carries the host-derived `absenceKind` column.
- **OCR coverage** = present cells whose raw OCR contains the anchor / all present cells.
- **Extractor conditional accuracy** = matches / present cells with raw anchor present (isolates parser errors from OCR errors).
- GT `null` is the only absence signal; empty strings are treated as absent. `nameLatin` / `department` / `notes` are not scored. `companyLatin` is read only to classify GT-absent `company` cells (buckets 2/3 vs 4 above); the frozen Domain still keeps Latin counterparts in `unclassifiedText` and department is an assignment-optional field. The assembler never writes to `dataset/ground-truth/`.

## Files

- `raw-ocr.jsonl` — detection/region/normalized-area/dimensions + every OCR line with confidence + full raw text per card, plus the unscored full-image diagnostic lines/text (`diag*`).
- `structured-results.jsonl` — extracted canonical fields + unclassified text per card.
- `comparison.csv` — 306 long-format field comparison rows, including `fullImageContainsAnchor` and the host-derived `absenceKind` four-bucket label for GT-absent cells (`canonical_absent` / `alternate_exact` / `alternate_partial` / `fabrication`).
- `summary.md` — aggregates, layer separation, error analysis, and the §9 before/after comparison.
- `environment.md` — this file.
- `_eval-payload.json` — raw harness payload (kept for provenance).
- `_eval-payload-pre-gate-baseline.json` — pre-gate baseline payload (same harness/GT/normalization, area gate temporarily reverted and restored for measurement); input to summary §9.

