# Observation Index

Naming rule:

`REF-<area>-<sequence>-<state>.png`

All copied screenshots are evidence only. A screenshot does not automatically mean the feature is in scope; the specification decides scope.

## Kept evidence

### Card Holder
- `REF-card-holder-01-empty.png` — empty state; also supports delete-result behavior.
- `REF-card-holder-02-after-save.png` — card appears immediately after save.

### Scanner / Permissions / Import
- `REF-scanner-01-initial.png`
- `REF-permission-01-camera.png`
- `REF-permission-02-photo-library.png`
- `REF-scanner-02-card-detected.png`
- `REF-import-01-photo-picker.png`

### Crop
- `REF-crop-01-manual-adjust.png`

### Recognition / OCR structure
- `REF-recognition-01-card-a-top.png`
- `REF-recognition-02-card-a-bottom.png`
- `REF-recognition-03-card-b-top.png`
- `REF-recognition-04-card-b-bottom.png`
- `REF-recognition-05-card-c-top.png`
- `REF-recognition-06-card-c-bottom.png`

### Manual edit / Save
- `REF-edit-01-before-change.png`
- `REF-edit-02-after-title-change.png`
- `REF-save-01-success.png`

### Detail
- `REF-detail-01-collapsed.png`
- `REF-detail-02-phone-picker.png`
- `REF-detail-03-after-edit-expanded.png`
- `REF-detail-04-more-actions.png`

### Search
- `REF-search-01-by-name.png`
- `REF-search-02-by-company.png`

### Groups / Tags
- `REF-group-01-select-card.png`
- `REF-group-02-create-dialog.png`
- `REF-group-03-assigned.png`
- `REF-group-04-list.png`
- `REF-group-05-filtered-list.png`
- `REF-group-06-delete-confirmation.png`
- `REF-group-07-after-delete-empty.png`

### Notes
- `REF-notes-01-page.png`

### Persistence
- `REF-persistence-01-after-relaunch.png` — post-relaunch state; user confirmed the app was fully quit and reopened before this verification.

### Export / Contacts
- `REF-export-01-contacts-permission.png`
- `REF-export-02-permission-denied.png`
- `REF-export-03-contact-destination.png`
- `REF-export-04-contacts-app-summary.png`
- `REF-export-05-contacts-app-fields.png`

### Delete
- `REF-delete-01-confirmation.png`

## Intentionally excluded screenshots

The following observation categories were not copied into the final evidence set because they are redundant or clearly outside the assignment core:

- privacy/user-agreement onboarding;
- promotional Home page banners and VIP entry points;
- plus-menu functions unrelated to the required business-card flow;
- multi-shot feature announcement/tutorial;
- online company-match suggestions and enterprise enrichment;
- “add more information” optional-field popup when equivalent field behavior is already captured;
- nearby-contact map/location screens;
- card-list sorting/bulk-management UI not required by the reference test suite;
- duplicate tutorial overlays;
- redundant photo-picker screenshots;
- standalone “Add Card” page containing out-of-scope import/contact/radar options.

If the instructor later explicitly adds one of these to the required scope, restore/re-observe it and add a new evidence file rather than silently changing this baseline.

### Exception Handling
- `REF-exception-01-minimal-card-empty-fields.png` — only name + mobile recognized; all absent fields remain empty.
- `REF-exception-02-non-card-empty-result.png` — valid non-card image reaches Edit Card with empty recognition result; no fabricated contact data.
