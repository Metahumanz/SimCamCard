//
//  DebugOpenURLCapture.swift
//  SimCamCard
//
//  Final Delivery Phase 1.1 calibration — DEBUG-only openURL capture seam
//  for B-01 (assignment §10: "Tap phone number; Tap email address; Tap
//  website").
//
//  Why this exists: the Simulator cannot complete a real tel:/mailto:/https
//  handoff (no Phone / Mail / Safari receiver inside the test process), so a
//  UI test can only observe "the row is tappable" — which is NOT proof that
//  the correct URL was initiated. This hook swaps the SwiftUI `openURL`
//  action at the App composition root for a recorder: it captures the exact
//  `absoluteString` handed to openURL, deliberately does NOT forward it to
//  the system (no real Phone / Mail / browser is invoked), and publishes the
//  captured value as an accessibility element the UI test reads.
//
//  Compiled ENTIRELY out of Release (#if DEBUG) and opt-in only: the
//  recorder is installed solely when the launch argument below is present,
//  so ordinary DEBUG manual launches keep exact Release parity (the real
//  openURL handoff is untouched when the flag is absent).
//
//  DEBUG launch contract:
//    -SimCamCardCaptureOpenURL 1
//        Install the recorder at the App root; row taps are captured.
//    (absent / any other value)
//        Real SwiftUI openURL; no capture, no test seam.
//
//  Isolation: like every other DEBUG hook, the type names
//  (`DebugURLCapture`, `DebugOpenURLCaptureLaunchMode`) and the argument
//  string below must be ABSENT from the Release binary (see the hook
//  isolation gate in ai/final-acceptance.md).
//
//  Honest boundary: this proves the URL the app INITIATES. The system
//  app's final takeover behavior (Phone dialing, Mail composing, Safari
//  loading) is NOT exercised here and remains unverified.
//

#if DEBUG

import Observation
import SwiftUI

/// Launch-argument gate for the DEBUG openURL recorder.
nonisolated enum DebugOpenURLCaptureLaunchMode {

    static let argument = "-SimCamCardCaptureOpenURL"

    /// True only when the flag is present with value "1".
    static func isEnabled(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        guard let index = arguments.firstIndex(of: argument),
              index + 1 < arguments.count
        else { return false }
        return arguments[index + 1] == "1"
    }
}

/// Records the most recent URL passed to SwiftUI's `openURL`.
/// Owned by the App composition root for the process lifetime.
@MainActor
@Observable
final class DebugURLCapture {

    /// `absoluteString` of the last captured URL ("" before any tap).
    private(set) var lastOpenedURL: String = ""

    func record(_ url: URL) {
        lastOpenedURL = url.absoluteString
    }
}

/// Accessibility identifier of the element that publishes
/// `DebugURLCapture.lastOpenedURL` (read by the UI test via `.label`).
nonisolated enum DebugOpenURLCaptureElement {
    static let identifier = "debug-open-url-log"
}

extension View {

    /// Installs the DEBUG openURL recorder plus its readable accessibility
    /// element. The element has no visual footprint and never intercepts
    /// hits. The recorder returns `.handled` so the captured URL is NOT
    /// forwarded to a real system app.
    func debugOpenURLCapture(_ capture: DebugURLCapture) -> some View {
        environment(\.openURL, OpenURLAction { url in
            capture.record(url)
            return .handled
        })
        .overlay(alignment: .bottom) {
            Text(capture.lastOpenedURL)
                .font(.system(size: 1))
                .foregroundStyle(.clear)
                .allowsHitTesting(false)
                .accessibilityIdentifier(DebugOpenURLCaptureElement.identifier)
        }
    }
}

#endif
