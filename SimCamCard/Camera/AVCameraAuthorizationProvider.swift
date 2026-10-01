//
//  AVCameraAuthorizationProvider.swift
//  SimCamCard
//
//  Production AVFoundation implementation of CameraAuthorizationProviding.
//
//  Week 3 Increment 1 — T03 Camera Permission.
//
//  Responsibilities (and nothing more):
//   - Read `AVCaptureDevice.authorizationStatus(for: .video)`.
//   - Request access via `AVCaptureDevice.requestAccess(for: .video)`
//     when (and only when) the status is .notDetermined. The first
//     request makes iOS present the NATIVE system permission dialog
//     (usage string: INFOPLIST_KEY_NSCameraUsageDescription).
//
//  This type owns no UI state and never presents a custom dialog.
//

import AVFoundation

@MainActor
final class AVCameraAuthorizationProvider: CameraAuthorizationProviding {

    func videoAuthorizationStatus() -> CameraAuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            // Future-proof mapping: an unknown status must not silently
            // grant camera access. Treat conservatively as denied.
            return .denied
        }
    }

    func requestVideoAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
