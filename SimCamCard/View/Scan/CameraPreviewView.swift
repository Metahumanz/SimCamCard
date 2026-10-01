//
//  CameraPreviewView.swift
//  SimCamCard
//
//  SwiftUI bridge for AVCaptureVideoPreviewLayer (Week 3 Increment 1 —
//  S02 live preview).
//
//  This is a PRESENTATION ADAPTER only:
//   - Renders the AVCaptureSession owned by the CameraSessionController
//     actor (which alone configures/starts/stops it on its serial
//     executor).
//   - videoGravity = .resizeAspectFill.
//  It does NOT own or start/stop the session, request permission,
//  capture photos, or run detection. All of that belongs to
//  ScanViewModel / CameraSessionController.
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
//  for presentation. NOT `@unchecked Sendable`, NOT
//  `nonisolated(unsafe)`.
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
        // Keep the camera image oriented with the device while the app
        // supports portrait; the layer derives orientation from the
        // connection.
        view.backgroundColor = .black
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
    final class PreviewContainerView: UIView {

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // Safe: layerClass guarantees the concrete layer type.
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
