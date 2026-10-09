# Final Reference Fidelity Audit (P01–P11)

Week 4 Increment 12 — final acceptance companion to
[final-acceptance.md](./final-acceptance.md).

- Baseline: `5ec080368fc7d3f4bc4595233ba5f88ffb7f577e`, branch
  `week4/structured-recognition`.
- Reference source: CamCard 8.63.1 observations frozen in
  `evidence/screenshots/REF-*.png` + `spec/{page-inventory,state-inventory,
  reference-tests,observation-index}.md`.
- Classification legend for every difference:
  - **platform** — imposed by iOS 27 / SwiftUI / system component vs the
    macOS/Mac-Catalyst or Android-era Reference surface;
  - **frozen-domain** — blocked by the frozen Domain model / repository
    contracts (Revision 8); not mechanically changed in T20;
  - **excluded** — explicitly outside the bounded feature slice
    (`spec/page-inventory.md` exclusion list);
  - **deferred cosmetic** — application-owned visual/UX surface gap that
    does not change required behavior;
  - **blocker** — a required behavior that fails; **none in this audit**.

Behavior status is the T01–T20 behavioral acceptance (see
final-acceptance.md). Fidelity status answers "how close is the surface
to the Reference screenshots". PARTIAL means behavior passes but the
surface is not pixel-identical; it is an honest, classified gap, not a
failure.

## Summary

| Page | Behavior | Full fidelity | Open real-blockers |
|---|---|---|---|
| P01 Card Holder | PASS | PARTIAL (deferred cosmetic) | 0 |
| P02 Scanner | PASS (fixture + real AVCapture session on simulator) | PARTIAL (no physical-device frames) | 0 |
| P03 Photo Picker | PASS mechanics; system-picker cancel NOT INDEPENDENTLY VERIFIED | PARTIAL (system surface) | 0 |
| P04 Crop / Boundary | PASS | PASS (functional; minor cosmetic) | 0 |
| P05 Recognition / Edit Card | PASS incl. T20 empty/minimal/failure rules | PARTIAL (deferred cosmetic) | 0 |
| P06 Save Result | PASS | PARTIAL (deferred cosmetic) | 0 |
| P07 Card Detail | PASS | PARTIAL (recorded W2I5 gaps remain) | 0 |
| P08 Search Results | PASS (name/company/title/phone/email) | PARTIAL (excluded segmented surfaces) | 0 |
| P09 Group Management | PASS incl. create-cancel evidence | PARTIAL (deferred cosmetic) | 0 |
| P10 Notes | PASS | PARTIAL (deferred cosmetic) | 0 |
| P11 Contact Export | PASS (real CNContactStore proof) | PARTIAL (diff-1..5, see below) | 0 |

No page required a code change in T20 for fidelity reasons: the two T20
behavior fixes (E06 failure Cancel, E07 empty-result save guard) were
behavioral, not visual.

## P01 — Card Holder

Required behavior: empty/populated list, scan entry, search entry, group
entry, group-filter banner, delete. All PASS with unit + deterministic UI
proof (T01/T15/T16/T17, E14/E19).

Differences vs `REF-card-holder-01/02`:

- Row chrome (avatar/thumbnail, section count header, inline three-dot
  affordance) is rendered in SwiftUI List idiom rather than the
  Reference row. — **deferred cosmetic**.
- Search is a pushed search page (`card-holder-search-entry`) rather than
  an inline always-visible search bar; behavior (all five required
  fields, empty state, clear, back-clears) is complete. — **deferred
  cosmetic**.
- Promotional/home content, subscription and enterprise entries. —
  **excluded**.

## P02 — Scanner

Required behavior: permission allow/deny/restricted states, live
preview, capture, photo-import entry, explicit back. PASS. Camera
permission denial uses a stable application fallback page
(`scan-permission-denied`) with no capture/import actions.

- The frozen Reference for T03 only records the **native system dialog**
  (REF-permission-01/02); it contains no Reference custom denied page.
  The custom fallback is an application-owned addition that guarantees
  the "denial path must not crash" contract; no Settings button is added
  because no Reference evidence requires one here. — **deferred
  cosmetic** (surface beyond evidence), behavior PASS.
- Real AVCapture session runs on the simulator; no physical iPhone
  camera frames were captured. Live-camera visual parity on hardware is
  NOT claimed. — **platform / verification boundary** (§31, §35).

## P03 — Photo Picker

- The picker itself is the system `PhotosPicker` (P03 ownership:
  System). Imported/cancelled/load-failure outcomes are driven and
  asserted via DEBUG fixtures (E04).
- A real user-initiated cancel inside the system picker UI is NOT
  INDEPENDENTLY VERIFIED on this simulator. — **platform**, classified
  in final-acceptance T05 as targeted/fixture-level, not faked.

## P04 — Crop / Boundary Adjust

Required behavior: auto-detected boundary, handle adjustment, confirm,
retake/cancel. PASS with fixture UI + unit proof (T06, E05). Real Vision
rectangle detection on the 34-card dataset is exercised by the anchor
smoke suite.

- Handle/overlay styling is a functional SwiftUI drawing, not a pixel
  replica. — **deferred cosmetic**.
- Physical-device detection accuracy is NOT claimed. — **platform**.

## P05 — Recognition / Edit Card

Required behavior: structured form, missing-field no fabrication,
multi-phone kinds, manual correction, Save/Retake/Cancel, plus T20
rules: non-card empty result enters the form (no failure dialog) with
Save disabled; minimal card keeps only real fields and remains saveable;
OCR failure offers Retake AND Cancel. All PASS after the W4I12 fixes
(E06 `scan-recognition-cancel`, E07 VM `canSaveCurrentCard` guard +
disabled Save, E08 `.minimal` fixture/composite C).

- Fixed scalar rows (姓名/公司/职位/地址) stay visible with empty values
  instead of disappearing, and empty states use blank rows rather than
  any "未识别/N/A/Unknown" placeholder (fabrication ban, §4).
- Save affordance on an all-empty result — explicit evidence boundary:
  `REF-exception-02` observes the 保存 affordance, but the captured
  black-box evidence does NOT establish what happens when Save is
  tapped on a completely empty result. The Reference does NOT show
  Save as disabled; that state was never observed. SimCamCard
  intentionally keeps the Save affordance VISIBLE but disables it when
  zero canonical fields exist, to satisfy the frozen T20 no-empty-card
  behavior (an all-empty card can never be materialized). This is an
  application-owned behavior beyond the captured evidence, not a
  claim that Reference was observed disabling Save. — therefore
  **P05 required behavior: PASS** (frozen T20 no-empty-card rule
  asserted by unit + UI), **P05 full Reference fidelity: PARTIAL**
  (tap behavior on an all-empty result is unobserved; the disabled
  state is a deliberate conservative implementation, not a replica).
- Card-004 phone display: Reference shows the concatenated
  `+8613800138000`; the app preserves OCR spacing `+86 138 0013 8000`
  (digits identical, format preserved per parser contract). — **deferred
  cosmetic**.
- Raw OCR transitional screen is a minimal internal surface; CamCard
  never exposed its raw-text screen (T07 Partial in frozen spec). —
  documented **transitional surface**, not a Reference replica.

## P06 — Save Result

Required behavior: success confirmation, Done/continue, new card appears
in Holder. PASS (T12 direct save + corrected save, P06 UI ids). The
success illustration/styling differs from `REF-save-01` — **deferred
cosmetic**.

## P07 — Card Detail

Behavior PASS (T13/T14 + image/notes/group/delete/export entries). The
W2I5-recorded application-owned visual gaps remain honestly open and are
NOT reclassified in T20:

- surname avatar, dark header card / card-photo strip, favorite star,
  more-menu chrome, bottom action-bar styling; — **deferred cosmetic**;
- 展开/收起 distinct collapsed/expanded interaction: all multi-value
  fields are shown directly (deliberate, to satisfy the frozen
  phones[]/emails[] no-loss requirement). `detailCollapsed` as a
  distinct state stays NOT IMPLEMENTED. — **deferred cosmetic**, with
  the behavior rationale recorded in W2I5 and preserved;
- English company / 昵称 fields. — **frozen-domain** (not in Revision 8
  model) + partly **excluded**;
- tel:/mailto:/URL invocation wiring. — non-required behavior;
  **excluded** from the slice (no Reference acceptance row).

## P08 — Search Results

Required five search scopes (name, company, job title, phone, email)
PASS with unit + UI proof (T15, E14/E19), including empty-result state,
clear (×), back-navigation clearing the filter, and group+search
composition.

- 综合/个人/企业 segmented search, integrated/enterprise result sources.
  — **excluded** surfaces (enterprise matching is on the page-inventory
  exclusion list). Fidelity stays PARTIAL for these only.

## P09 — Group Management

Required workflow Create → Assign → View filtered → Delete group keeping
cards PASS, and T20 adds direct UI proof that BOTH create cancels
(selection toolbar 取消; naming-alert 取消 after typing) leave the
catalog and card tags unchanged (E12).

- List/row styling vs `REF-group-*` is SwiftUI idiom. — **deferred
  cosmetic**.
- Alert cancel returns to the card-selection phase (the Reference does
  not document an intermediate); returning to the group list uses the
  toolbar 取消. Behavior at both exits is proven. — **deferred
  cosmetic** (phase placement).

## P10 — Notes

Required behavior: add note, cancel, history, persistence after
relaunch. PASS (unit + UI, W4I10). Page chrome vs `REF-notes-01` is
simplified — **deferred cosmetic**.

## P11 — Contact Export

Behavior PASS: real `CNContactStore.execute(CNSaveRequest)` succeeded on
the iOS 27 simulator (targeted System01/System02 gates, run separately
from the deterministic suite), and the real Contacts.app verified
name / organization / title / mobile(CNLabelPhoneNumberMobile) /
work(CNLabelWork) / email(CNLabelOther) / address(CNLabelOther) mapping.
Fake permission/failure scripts + unit tests cover all denial/failure
branches (E15/E16).

Full surface remains PARTIAL with five classified differences
(unchanged from W4I11; T20 made no Domain/export changes):

- **diff-1 (deferred cosmetic / surface)**: REF-export-02 denied state is
  a standalone page; implementation is a native SwiftUI alert with the
  same title/Settings action/cancel semantics.
- **diff-2 (platform)**: REF destination/account selector belongs to the
  macOS Contacts multi-account flow; no equivalent App-controlled
  surface exists in the iOS 27 flow.
- **diff-3 (frozen-domain)**: Reference labels email/address as 工作;
  the frozen Domain has no email/address kind, so both map to
  CNLabelOther rather than fabricating a work label.
- **diff-4 (frozen-domain / requirement)**: Reference exports website
  (主页); frozen T19 acceptance lists six fields and does not require
  URL, so website is deliberately not exported (also independently
  visible in the real Contacts.app evidence).
- **diff-5 (platform)**: Reference ran on macOS/Mac Catalyst; system
  Contacts UI itself differs (account picker, multi-line address
  layout), so not every surface is portable.

## Re-review decision for T20

P07–P11 were re-reviewed against the frozen evidence. No "tiny,
obvious, low-risk" visual fix changed required behavior or removed a
classified difference: the open items are either platform/frozen-domain
constraints or explicitly deferred cosmetic surfaces, and editing them
under a stop-at-T20 sweep would broaden scope without new Reference
evidence. All PARTIAL statuses therefore remain PARTIAL, by design.
