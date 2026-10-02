//
//  CameraPreviewView.swift
//  SimCamCard
//
//  SwiftUI bridge for AVCaptureVideoPreviewLayer (Week 3 Increment 1 —
//  S02 live preview; Week 3 Increment 4 — preview rotation contract).
//
//  This is a PRESENTATION ADAPTER only:
//   - Renders the AVCaptureSession owned by the CameraSessionController
//     actor (which alone configures/starts/stops it on its serial
//     executor).
//   - videoGravity = .resizeAspectFill.
//   - Owns ONE preview-side AVCaptureDevice.RotationCoordinator
//     (device: rear camera, read-only from the already-configured
//     stable session; previewLayer: this view's layer) and applies
//     videoRotationAngleForHorizonLevelPreview to the preview
//     connection only.
//  It does NOT own or start/stop the session, request permission,
//  capture photos, run detection, or mutate session topology /
//  photo-output / video-data-output connections. All of that belongs
//  to ScanViewModel / CameraSessionController.
//
//  Isolation boundary: the current SDK exposes AVCaptureSession as
//  non-Sendable for this Swift 6 build, so the display-only reference
//  from the session actor to this MainActor view is bridged by
//  `@preconcurrency import AVFoundation` — a narrow
//  compatibility/interoperability bridge that only relaxes
//  compile-time diagnostics; it does NOT by itself guarantee thread
//  safety. Safety relies on the ownership contract: all session
//  mutation runs on the CameraSessionController actor's serial
//  executor; this view only attaches the session to the preview layer
//  for presentation and rotates the PREVIEW connection. NOT
//  `@unchecked Sendable`, NOT `nonisolated(unsafe)`.
//

import SwiftUI
@preconcurrency import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {

    /// Session owned by the CameraSessionController actor (display
    /// only here; the actor alone configures/starts/stops it on its
    /// serial executor).
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        view.attachPreviewRotationCoordinator(session: session)
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        // The session instance is stable for the Scanner's lifetime;
        // re-bind defensively in case SwiftUI re-invokes update.
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }

    /// Plain UIView whose backing layer IS the video preview layer.
    /// Also owns the preview-side RotationCoordinator: preview rotation
    /// is presentation-only work and therefore lives here, not in the
    /// session actor.
    final class PreviewContainerView: UIView {

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // Safe: layerClass guarantees the concrete layer type.
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }

        private var previewRotationCoordinator: AVCaptureDevice.RotationCoordinator?
        private var previewRotationObservation: NSKeyValueObservation?

        /// Builds the preview RotationCoordinator from the rear camera
        /// device of the ALREADY-CONFIGURED session (read-only access;
        /// no topology mutation). Safe to call multiple times — the
        /// coordinator is created once.
        func attachPreviewRotationCoordinator(session: AVCaptureSession) {
            guard previewRotationCoordinator == nil else { return }
            guard let device = session.inputs
                .compactMap({ ($0 as? AVCaptureDeviceInput)?.device })
                .first(where: { $0.position == .back })
            else { return }

            let coordinator = AVCaptureDevice.RotationCoordinator(
                device: device, previewLayer: previewLayer
            )
            previewRotationCoordinator = coordinator
            applyPreviewRotation(coordinator.videoRotationAngleForHorizonLevelPreview)
            previewRotationObservation = coordinator.observe(
                \.videoRotationAngleForHorizonLevelPreview,
                options: [.new]
            ) { [weak self] _, change in
                guard let angle = change.newValue else { return }
                // RotationCoordinator preview callbacks are delivered on
                // the main queue; the preview-layer connection is UIKit
                // presentation state owned here.
                Task { @MainActor [weak self] in
                    self?.applyPreviewRotation(angle)
                }
            }
        }

        private func applyPreviewRotation(_ angle: CGFloat) {
            guard let connection = previewLayer.connection,
                  connection.isVideoRotationAngleSupported(angle)
            else { return }
            connection.videoRotationAngle = angle
        }
    }
}
