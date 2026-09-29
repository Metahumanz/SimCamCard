# Dataset

Current Week 1 baseline contains three synthetic cards.

| ID | Purpose | Key condition |
|---|---|---|
| card-001 | Standard baseline | Full bilingual card |
| card-002 | Missing field | No website |
| card-003 | Phone classification | Mobile + office + fax |

Ground Truth lives in `ground-truth/`.

## Important

These three cards are not the final evaluation dataset. Expand to approximately 30–50 cards before freezing the final dataset.

Recommended categories:

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

Use synthetic or fictional personal information.

## OCR result recording

For every card, preserve separately:

- raw OCR output;
- structured parser output;
- manually corrected final result;
- field-level Ground Truth;
- error notes.
