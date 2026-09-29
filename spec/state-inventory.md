# State Inventory

## S01 Card Holder

- `empty`
  - zero saved cards
  - scan entry remains available
- `populated`
  - one or more cards shown
  - list updates immediately after save/delete
- `searching`
  - query active
- `groupFiltered`
  - cards filtered by selected group/tag

Evidence: `REF-card-holder-*`, `REF-search-*`, `REF-group-*`

## S02 Camera / Scanner

- `permissionUnknown`
- `permissionDenied`
- `preview`
- `cardNotDetected`
- `cardDetected`
- `captured`
- `cancelled`

Evidence: `REF-permission-01-camera.png`, `REF-scanner-*`

## S03 Photo Import

- `photoPermissionRequired`
- `photoPermissionDenied`
- `pickerPresented`
- `imageSelected`
- `cancelled`

Evidence: `REF-permission-02-photo-library.png`, `REF-import-01-photo-picker.png`

## S04 Card Region

- `autoDetected`
- `manualAdjusting`
- `confirmed`
- `retakeRequested`

Evidence: `REF-scanner-02-card-detected.png`, `REF-crop-01-manual-adjust.png`

## S05 Recognition

- `processing`
- `structuredResultAvailable`
- `nonCardEmptyResult` — valid non-card image produced an empty editable recognition result; no dedicated failure dialog was observed
- `missingFields` — observed with Card 004; absent fields remain empty
- `multiplePhoneFields`
- `manualEditing`
- `cancelled`

Evidence: `REF-recognition-*`, `REF-edit-*`

## S06 Saved Card

- `saveSucceeded`
- `detailCollapsed`
- `detailExpanded`
- `editing`
- `deleted`

Evidence: `REF-save-*`, `REF-detail-*`, `REF-delete-*`

## S07 Group / Tag

- `ungrouped`
- `selectingCards`
- `creatingGroup`
- `assigned`
- `groupFiltered`
- `groupDeleted`

Evidence: `REF-group-*`

## S08 Notes

- `historyVisible`
- `addingNote` — **entry observed; saved custom note not yet captured**

Evidence: `REF-notes-01-page.png`

## S09 Export

- `contactsPermissionUnknown`
- `contactsPermissionDenied`
- `contactsPermissionAllowed`
- `exportSucceeded`

Evidence: `REF-export-*`

## S10 Persistence

- `savedBeforeQuit`
- `restoredAfterRelaunch`

Required preserved state after relaunch:
- original image;
- processed image;
- corrected fields;
- group/tag;
- notes.
