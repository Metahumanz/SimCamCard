# Data Model Specification

This document defines the required domain data, not the final Swift implementation.

## BusinessCard

Minimum required logical fields:

| Field | Type | Required | Source |
|---|---|---:|---|
| id | stable identifier | Yes | System |
| originalImage | image reference | Yes | Capture/Import |
| processedImage | image reference | Yes | Crop/Correction |
| rawOCRText | text | Yes after OCR | OCR |
| name | text? | No | OCR / User |
| company | text? | No | OCR / User |
| jobTitle | text? | No | OCR / User |
| mobile | text? | No | OCR / User |
| phone | text? | No | OCR / User |
| fax | text? | No | OCR / User |
| email | text? | No | OCR / User |
| website | text? | No | OCR / User |
| address | text? | No | OCR / User |
| tags | collection | No | User |
| notes | collection | No | User |
| createdAt | date/time | Yes | System |
| updatedAt | date/time | Yes | System |

## Multi-value observation

CamCard can display more than one semantically similar field, for example:

- Chinese company name + English company name;
- mobile + office phone + fax;
- potentially multiple email addresses.

Therefore the implementation should not hard-code the assumption that every semantic category can only ever have one value.

A practical Week 2 design can expose canonical fields required by the assignment while keeping an extensible internal structure, for example:

- `phones[]` with kind = mobile / office / fax / other;
- `emails[]`;
- `organizations[]`.

The UI may select the first or user-confirmed value as the canonical assignment field.

## OCR Pipeline Data

The following intermediate artifacts must be retained:

1. Original image
2. Processed/corrected image
3. Raw OCR text
4. Structured extraction result
5. User-corrected final record

Do not overwrite raw OCR output with corrected user data.

## Missing-field rule

If a value does not appear on the source card and cannot be reliably determined, store `nil` / empty rather than generating a plausible value.

Card 002 is the fixed baseline for this rule: it contains no website.

## Persistence rule

After app termination and relaunch, the following must still exist:

- images;
- manually corrected fields;
- tags/groups;
- notes.
