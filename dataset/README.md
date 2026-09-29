# Dataset

Week 1 SDD baseline is frozen.

## Business-card dataset

- 34 synthetic business-card samples in `cards/`, named `card-001-*.png` through `card-034-*.png`.
- 34 Ground Truth JSON files in `ground-truth/`, named `card-001.json` through `card-034.json`. Each card ID has a matching image and Ground Truth record.
- `card-index-005-034.csv` — consolidated index for the back 30 cards (`card-005` through `card-034`).
- `ground-truth-005-034.jsonl` — consolidated Ground Truth for the back 30 cards.
- `card-001` through `card-004` also retain individual JSON files (as do `card-005` through `card-034`).

## Exception samples

`exception-samples/` holds T20 non-card fixtures. These are valid test inputs but are **not** business cards and are **not** counted toward the 34-card business-card dataset.

- `t20-negative-001-non-card.png` — valid landscape photo used to verify T20 empty-recognition-result behavior.
- `t20-negative-001-expected.json` — expected reference behavior.

## Recommended coverage categories (already represented in the frozen set)

- Chinese-only;
- English-only;
- bilingual;
- vertical layout;
- unusual/special layout;
- multiple phone numbers;
- multiple emails;
- missing fields;
- low image quality;
- dark/light backgrounds;
- shadows;
- perspective distortion;
- partial edge occlusion;
- complex logos/backgrounds.

Use synthetic or fictional personal information only.

## OCR result recording

For every card, preserve separately:

- raw OCR output;
- structured parser output;
- manually corrected final result;
- field-level Ground Truth;
- error notes.

## Immutability

After the Week 1 baseline is frozen, card images, Ground Truth business fields, and exception fixtures must not be silently modified. Any real correction must be recorded as an explicit dataset revision.
