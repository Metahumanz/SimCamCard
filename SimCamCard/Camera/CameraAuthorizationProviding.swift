//
//  CameraAuthorizationProviding.swift
//  SimCamCard
//
//  Minimal camera-permission abstraction for the Scanner (Week 3
//  Increment 1 — T03 Camera Permission / S02 permissionUnknown,
//  permissionDenied, preview).
//
//  The ScanViewModel depends on THIS protocol, never on the static
//  `AVCaptureDevice` API directly, so that all four authorization
//  outcomes are deterministically unit-testable with a fake:
//
//    .notDetermined → S02 permissionUnknown → request permission
//    .denied / .restricted
//                   → S02 permissionDenied (no request, no session)
//    .authorized    → configure/start preview → S02 preview
//
//  Restricted is deliberately NOT treated as authorized. An already
//  denied/restricted status must never trigger another prompt.
//
//  The native system permission dialog itself is presented by iOS when
//  `requestVideoAccess()` is first called on a .notDetermined status;
//  the app must never draw its own permission dialog replica
//  (spec/reference-tests.md T03: "System dialogs themselves must be
//  native platform dialogs, not custom replicas.").
//

import AVFoundation

/// UI-facing camera authorization outcome, independent of AVFoundation's
/// status enum so the state machine stays testable without AV types.
enum CameraAuthorizationStatus: Sendable, Equatable {
    /// User has not been asked yet (AV `.notDetermined`).
    case notDetermined
    /// User granted camera access (AV `.authorized`).
    case authorized
    /// User explicitly denied access (AV `.denied`).
    case denied
    /// Access is restricted system-wide, e.g. parental controls
    /// (AV `.restricted`). Handled the same as denied by the Scanner.
    case restricted
}

/// Reads the current video authorization status and requests access.
///
/// All conformance is `@MainActor` because the app target uses
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and the results drive
/// `@Observable` UI state directly. The AVFoundation implementation
/// performs no UI work itself.
@MainActor
protocol CameraAuthorizationProviding: AnyObject {

    /// Current video authorization status. Does not prompt.
    func videoAuthorizationStatus() -> CameraAuthorizationStatus

    /// Requests video access via the native system dialog.
    ///
    /// Must only be called when the current status is `.notDetermined`.
    /// Returns `true` when the user grants access.
    func requestVideoAccess() async -> Bool
}
