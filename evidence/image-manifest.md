# Image Manifest

This manifest lists every image intentionally retained in the Week 1 SDD baseline.

## Evidence screenshots

- `REF-card-holder-01-empty.png`
- `REF-card-holder-02-after-save.png`

- `REF-crop-01-manual-adjust.png`

- `REF-delete-01-confirmation.png`

- `REF-detail-01-collapsed.png`
- `REF-detail-02-phone-picker.png`
- `REF-detail-03-after-edit-expanded.png`
- `REF-detail-04-more-actions.png`

- `REF-edit-01-before-change.png`
- `REF-edit-02-after-title-change.png`

- `REF-export-01-contacts-permission.png`
- `REF-export-02-permission-denied.png`
- `REF-export-03-contact-destination.png`
- `REF-export-04-contacts-app-summary.png`
- `REF-export-05-contacts-app-fields.png`

- `REF-group-01-select-card.png`
- `REF-group-02-create-dialog.png`
- `REF-group-03-assigned.png`
- `REF-group-04-list.png`
- `REF-group-05-filtered-list.png`
- `REF-group-06-delete-confirmation.png`
- `REF-group-07-after-delete-empty.png`

- `REF-import-01-photo-picker.png`

- `REF-notes-01-page.png`

- `REF-permission-01-camera.png`
- `REF-permission-02-photo-library.png`

- `REF-persistence-01-after-relaunch.png`

- `REF-recognition-01-card-a-top.png`
- `REF-recognition-02-card-a-bottom.png`
- `REF-recognition-03-card-b-top.png`
- `REF-recognition-04-card-b-bottom.png`
- `REF-recognition-05-card-c-top.png`
- `REF-recognition-06-card-c-bottom.png`

- `REF-save-01-success.png`

- `REF-scanner-01-initial.png`
- `REF-scanner-02-card-detected.png`

- `REF-search-01-by-name.png`
- `REF-search-02-by-company.png`

- `REF-exception-01-minimal-card-empty-fields.png`
- `REF-exception-02-non-card-empty-result.png`

## Dataset cards

### Baseline cards

- `card-001-standard-bilingual.png`
- `card-002-missing-website.png`
- `card-003-multiple-phones-fax.png`
- `card-004-minimal-name-mobile.png`

### Dataset expansion: card-005 to card-014

- `card-005-english-analytics.png`
- `card-006-minimal-designer.png`
- `card-007-vertical-medical-bilingual.png`
- `card-008-dark-logistics-bilingual.png`
- `card-009-bilingual-tourism.png`
- `card-010-standard-bilingual-manufacturing.png`
- `card-011-bilingual-multi-phone-fax.png`
- `card-012-chinese-only-education.png`
- `card-013-english-bio-photographed.png`
- `card-014-missing-email-security.png`

### Dataset expansion: card-015 to card-024

- `card-015-zh-bilingual-product-manager.png`
- `card-016-en-software-engineer.png`
- `card-017-zh-bank-department.png`
- `card-018-en-korea-dark.png`
- `card-019-ja-japanese-company.png`
- `card-020-zh-hospital.png`
- `card-021-de-german-umlaut.png`
- `card-022-zh-university.png`
- `card-023-en-startup-ceo.png`
- `card-024-zh-manufacturing-multi-phone.png`

### Dataset expansion: card-025 to card-034

- `card-025-fr-en-product-director.png`
- `card-026-ko-en-robotics.png`
- `card-027-ja-en-design-fax.png`
- `card-028-zh-en-semiconductor-no-email.png`
- `card-029-en-apostrophe-long-address.png`
- `card-030-en-minimal-no-phone.png`
- `card-031-zh-en-dark-energy.png`
- `card-032-en-vertical-health.png`
- `card-033-es-en-sales-director.png`
- `card-034-zh-sparse-architect.png`

## Exception-input images

These are valid test inputs but are not business cards.

- `t20-negative-001-non-card.png`
  - Purpose: T20 non-card / empty recognition-result behavior.
  - Expected reference behavior: CamCard accepts the image, enters the Edit Card screen, and produces no fabricated structured contact data.

## Manifest rules

- Evidence screenshots are immutable black-box observation evidence.
- Dataset-card filenames must remain stable after the Week 1 baseline is frozen.
- Ground Truth files must reference the corresponding card ID.
- Exception samples must not be counted as valid business-card samples.
- Supporting preview/contact-sheet images must not be included in OCR accuracy calculations.
- If an image is replaced after the dataset is frozen, the change must be recorded as an explicit dataset revision rather than silently overwriting the baseline.