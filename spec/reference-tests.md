# Reference Test Suite

Status values:
- **Observed** — reference behavior has usable evidence.
- **Partial** — some behavior observed, more reference evidence needed.
- **Pending** — not yet observed.

| ID | Scenario | Reference status | Expected behavior | Evidence |
|---|---|---|---|---|
| T01 | First Launch / Empty Holder | Observed | Empty Card Holder is shown when no cards exist. | `REF-card-holder-01-empty.png` |
| T02 | Enter Scanner | Observed | Scan entry opens scanner/camera UI. | `REF-scanner-01-initial.png` |
| T03 | Camera Permission | Partial | Allow/deny must produce defined states; denial path must not crash. | `REF-permission-01-camera.png` |
| T04 | Capture | Observed | Standard card enters recognition workflow. | `REF-scanner-02-card-detected.png` |
| T05 | Photo Import | Observed | Selecting a card image enters recognition/edit workflow. | `REF-import-01-photo-picker.png`, `REF-recognition-03-card-b-top.png` |
| T06 | Boundary Detection | Observed | Detected boundary is shown; user can manually adjust and confirm. | `REF-scanner-02-card-detected.png`, `REF-crop-01-manual-adjust.png` |
| T07 | OCR Raw Text | Partial | OCR must produce and preserve raw text. CamCard raw-text screen was not externally exposed in current observation. | Recognition evidence only |
| T08 | Structured Extraction | Observed | Name/company/title/phone/email/etc. are classified into structured fields. | `REF-recognition-01-card-a-top.png`, `REF-recognition-02-card-a-bottom.png` |
| T09 | Missing Field | Observed | Card without website must not gain a fabricated website. | `REF-recognition-03-card-b-top.png`, `REF-recognition-04-card-b-bottom.png` |
| T10 | Multiple Phones | Observed | Mobile / office / fax are classified separately. | `REF-recognition-05-card-c-top.png`, `REF-recognition-06-card-c-bottom.png` |
| T11 | Manual Correction | Observed | User-corrected value replaces extracted value in final card. | `REF-edit-01-before-change.png`, `REF-edit-02-after-title-change.png` |
| T12 | Save | Observed | Save succeeds and new card immediately appears in holder. | `REF-save-01-success.png`, `REF-card-holder-02-after-save.png` |
| T13 | Detail | Observed | Saved structured fields are visible in detail view. | `REF-detail-01-collapsed.png`, `REF-detail-03-after-edit-expanded.png` |
| T14 | Edit | Observed | Edited title is reflected in stored/detail data. | `REF-edit-02-after-title-change.png`, `REF-detail-03-after-edit-expanded.png` |
| T15 | Search | Observed for name/company | Search by name and company returns the card. Implementation must also support fields required by assignment detail spec. | `REF-search-01-by-name.png`, `REF-search-02-by-company.png` |
| T16 | Tag / Group | Partial | Create group, assign card, view filtered group. Group deletion still needs observation. | `REF-group-*` |
| T17 | Delete | Observed | Confirmation precedes delete; card disappears afterward. | `REF-delete-01-confirmation.png`, `REF-card-holder-01-empty.png` |
| T18 | Persistence | Pending | Kill app → relaunch → image/corrections/group/notes remain. | — |
| T19 | Export | Partial | At least Contacts or VCF must succeed with correct field mapping. Permission denial is observed; success is not. | `REF-export-*` |
| T20 | Exception Handling | Partial | Cancel/back/permission denial/recognition failure/empty fields must be safe and spec-compliant. Recognition failure + empty-field cases pending. | Permission evidence + normal navigation evidence |

## Additional detailed checks

### T03 Permission

Test:
- camera allowed;
- camera denied;
- photo library allowed;
- photo library denied.

System dialogs themselves must be native platform dialogs, not custom replicas.

### T15 Search

Final implementation should support:
- name;
- company;
- job title;
- phone;
- email.

Current black-box evidence directly verifies only name and company.

### T16 Groups/Tags

Required final workflow:
Create → Assign → View by Group/Tag → Delete Group/Tag.

Delete is still a reference-observation gap.

### T18 Persistence

Must preserve:
- original image;
- processed image;
- corrected fields;
- group/tag;
- notes.

### T19 Export

At least one:
- save to Contacts;
- export VCF/vCard.

Verify mapping:
- name;
- company;
- job title;
- phone;
- email;
- address.

### T20 Exceptions still to capture

- recognition failure / non-card image;
- empty-field card;
- explicit cancel/retake paths;
- permission denial recovery.
