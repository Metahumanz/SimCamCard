# Reference Environment

Status: Draft — fill remaining TODO values before freezing Week 1.

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
- Swift version: 6.4
- Deployment target: iOS 27.0
- Primary simulator: iPhone 18 pro iOS 27.0

## Dataset

- Current baseline: 3 synthetic business cards
- Required final size: approximately 30–50
- Cards: `dataset/cards/`
- Ground Truth: `dataset/ground-truth/`

## Reference Test Suite

- `spec/reference-tests.md`

Once these environment values are frozen, later changes must be recorded explicitly rather than silently replacing the baseline.
