# Reference Environment

Status: Frozen — Week 1 reference environment baseline.

## Reference Application

- App: CamCard / 名片全能王
- Reference version: 8.63.1
- App language: Simplified Chinese
- Account state: Logged out
- Feature tier: Free / non-member behavior used where possible
- Observation date: 2026-09-28

## Observation Platform

- Hardware: Apple Silicon Mac (M2)
- Execution mode: iPhone/iPad-compatible CamCard app running on macOS
- macOS version: 27.0
- Window orientation/layout used for evidence: Portrait-like app window

### Important limitation

This environment is sufficient for black-box observation of application-owned pages and workflows, but macOS-hosted system permission dialogs/photo picker are not authoritative iPhone visual references.

For final iOS-specific verification, use a physical iPhone if available for:

- camera behavior;
- iOS camera/photo/contacts permission presentation;
- safe areas and keyboard behavior;
- native Contacts export;
- external phone/mail/web actions.

## SimCamCard Development Environment

- Project path: `~/codework/SimCamCard`
- Platform: iOS
- UI framework: SwiftUI
- Architecture: MVVM
- Xcode version: 27.0
- Swift compiler / toolchain version: 6.4 (Apple Swift version 6.4, swiftlang-6.4.0.34.1)
- Swift language mode (`SWIFT_VERSION` build setting): 6.0
- Deployment target: iOS 27.0
- Primary simulator: iPhone 18 Pro, iOS 27.0

Note: the Swift compiler/toolchain version (6.4) and the Swift language mode (`SWIFT_VERSION = 6.0` in `SimCamCard.xcodeproj/project.pbxproj`) are distinct concepts. The compiler ships as part of Xcode 27.0; the project language mode is configured per-target via the `SWIFT_VERSION` build setting. The project has migrated from Swift 5 to Swift 6 language mode — App, Tests, and UI Tests in both Debug and Release use `SWIFT_VERSION = 6.0` (see `ai/changes.md`). No application source behavior was changed by the migration.

## Dataset

- Frozen baseline: 34 synthetic business-card samples, `card-001` through `card-034`
- 34 Ground Truth records (`card-001.json` through `card-034.json`)
- 1 separate non-card T20 exception fixture in `dataset/exception-samples/` (not counted as a business-card sample)
- Cards: `dataset/cards/`
- Ground Truth: `dataset/ground-truth/`

## Reference Test Suite

- `spec/reference-tests.md`

Once these environment values are frozen, later changes must be recorded explicitly rather than silently replacing the baseline.
