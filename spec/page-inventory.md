# Page Inventory

Only pages relevant to the required feature slice are listed as implementation targets.

| ID | Page | Ownership | Purpose | Main exits | Evidence |
|---|---|---|---|---|---|
| P01 | Card Holder | App | List/empty state/search/scan entry | Scanner, Detail, Search, Groups | `REF-card-holder-*` |
| P02 | Scanner | App | Camera preview and card detection | Capture, Photo Import, Back | `REF-scanner-*` |
| P03 | Photo Picker | System | Import card image | Return selected image / Cancel | `REF-import-01-photo-picker.png` |
| P04 | Crop / Boundary Adjust | App | Confirm/adjust detected card region | Done, Cancel/Retake | `REF-crop-01-manual-adjust.png` |
| P05 | Recognition / Edit Card | App | Show extracted fields and allow correction | Save, Retake, Cancel | `REF-recognition-*`, `REF-edit-*` |
| P06 | Save Result | App | Confirm successful save and next action | Done / continue | `REF-save-01-success.png` |
| P07 | Card Detail | App | View structured data and card actions | Edit, Group, Note, Delete, Export | `REF-detail-*` |
| P08 | Search Results | App | Search cards by supported fields | Detail / Back | `REF-search-*` |
| P09 | Group Management | App | Create/assign/view card groups | Group list / filtered list | `REF-group-*` |
| P10 | Notes | App | View/add notes/history | Detail / Add note | `REF-notes-01-page.png` |
| P11 | Contact Export | App + System | Save card as system contact or export VCF | Permission / success / cancel | `REF-export-*` |

## Explicitly observed but excluded from core implementation

- Promotional Home content
- Digital business card
- Enterprise verification
- VIP/subscription services
- Enterprise-information enrichment and online company matching
- Nearby-contacts map
- Radar exchange
- CRM/business-intelligence functionality
- Multi-card capture enhancements beyond the required single-card workflow

These may appear in CamCard but are not part of the required bounded feature slice.
