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
| T16 | Tag / Group | Observed | Create group, assign card, view filtered group, then delete the group without deleting the cards. | `REF-group-*` |
| T17 | Delete | Observed | Confirmation precedes delete; card disappears afterward. | `REF-delete-01-confirmation.png`, `REF-card-holder-01-empty.png` |
| T18 | Persistence | Observed | After a full quit and relaunch, the saved card and retained edited data remain available. The termination action itself has no useful screenshot; the post-relaunch state is preserved as evidence. | `REF-persistence-01-after-relaunch.png` |
| T19 | Export | Observed | Saving to system Contacts succeeds and the exported contact contains the recognized name/company/title/phone/email/address fields. | `REF-export-*` |
| T20 | Exception Handling | Observed for key negative inputs | Permission denial is observed. A minimal card preserves only present fields. A valid non-card image enters the edit-card screen with an empty recognition result rather than fabricating contact data. Explicit cancel/retake/back paths remain covered by the normal navigation specification and should be regression-tested. | `REF-exception-*`, permission evidence |

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

Deletion is observed: deleting a group removes the group while the business cards remain in the Card Holder.

### T18 Persistence

Observed through a full quit and relaunch. The app reopened with the saved card and retained edited/grouped data still available. There is no meaningful screenshot of the kill action itself; the authoritative evidence is the post-relaunch state plus the recorded human observation.

The SimCamCard acceptance test must preserve:
- original image;
- processed image;
- corrected fields;
- group/tag;
- notes.

### T19 Export

Reference behavior is now observed for saving to system Contacts.

Evidence verifies successful contact creation and visible exported fields. The SimCamCard test must verify mapping for:
- name;
- company;
- job title;
- phone;
- email;
- address.

### T20 Exceptions

Observed fixed negative samples:

1. **Card 004 — Minimal card**
   - Source contains only name + mobile.
   - CamCard extracts only those two fields.
   - Company, title, email, website, address, etc. remain empty.
   - SimCamCard must not fabricate missing data.

2. **Negative 001 — Non-card image**
   - Input is a valid landscape photo, not a business card.
   - CamCard 8.63.1 does **not** show a dedicated recognition-failure error in the observed path.
   - It enters the Edit Card screen with an empty recognition result.
   - SimCamCard must preserve this reference behavior unless the instructor's final test suite specifies a different error state.

Permission denial is also already observed.

Continue to regression-test:
- explicit cancel;
- back navigation;
- retake;
- denial recovery;
- exit midway through the workflow.
