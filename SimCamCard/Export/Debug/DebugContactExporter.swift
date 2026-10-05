//
//  DebugContactExporter.swift
//  SimCamCard
//
//  Week 4 Increment 11 — deterministic DEBUG-only ContactExporting
//  fake for SwiftUI Previews and UI tests. NEVER compiled into Release;
//  never touches the real CNContactStore.
//
//  The fake records every payload/access request so unit/UI tests can
//  assert call counts and payload content. Write behavior is scripted
//  by ContactExportLaunchMode; `.failure` throws DebugContactExport-
//  Error.failureSimulated without swallowing semantics.
//

#if DEBUG

import Foundation

/// Error thrown by the `.failure` scripted mode.
nonisolated enum DebugContactExportError: Error, Sendable, Equatable {
    case failureSimulated
}

actor DebugContactExporter: ContactExporting {

    private let mode: ContactExportLaunchMode

    /// Scripted CURRENT status. Starts from the mode's initial state and
    /// only changes via requestAccess().
    private var currentStatus: ContactAuthorizationState

    /// Every payload that reached the (fake) write step, in call order.
    private(set) var exportedPayloads: [ContactExportPayload] = []

    /// Number of authorization prompts presented.
    private(set) var requestAccessCallCount = 0

    init(mode: ContactExportLaunchMode) {
        self.mode = mode
        switch mode {
        case .allowed, .failure:
            self.currentStatus = .allowed
        case .denied:
            self.currentStatus = .denied
        case .allowOnRequest, .denyOnRequest:
            self.currentStatus = .notDetermined
        case .system:
            // The composition root uses SystemContactExporter for the
            // `.system` mode; defensive default only.
            self.currentStatus = .notDetermined
        }
    }

    // MARK: - Observation (tests)

    func exportCount() -> Int { exportedPayloads.count }
    func lastPayload() -> ContactExportPayload? { exportedPayloads.last }
    func status() -> ContactAuthorizationState { currentStatus }

    // MARK: - ContactExporting

    func authorizationState() async -> ContactAuthorizationState {
        currentStatus
    }

    func requestAccess() async -> ContactAuthorizationState {
        requestAccessCallCount += 1
        switch mode {
        case .allowOnRequest:
            currentStatus = .allowed
        case .denyOnRequest:
            currentStatus = .denied
        case .allowed, .failure:
            currentStatus = .allowed
        case .denied:
            currentStatus = .denied
        case .system:
            break
        }
        return currentStatus
    }

    func export(_ payload: ContactExportPayload) async throws -> ContactExportReceipt {
        switch mode {
        case .failure:
            throw DebugContactExportError.failureSimulated
        case .allowed, .allowOnRequest:
            exportedPayloads.append(payload)
            return ContactExportReceipt(
                systemIdentifier: "debug-contact-\(exportedPayloads.count)"
            )
        case .denied, .denyOnRequest:
            // Defense in depth: a denied exporter must never be written
            // through; same error category a denied real store raises.
            throw DebugContactExportError.failureSimulated
        case .system:
            throw DebugContactExportError.failureSimulated
        }
    }
}

#endif
