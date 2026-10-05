//
//  ContactExporting.swift
//  SimCamCard
//
//  Week 4 Increment 11 — T19 Contact Export.
//
//  App-owned minimal authorization/export abstraction. The ViewModel
//  depends ONLY on this protocol — it never imports Contacts and never
//  constructs a CNContactStore. The production implementation
//  (SystemContactExporter) is injected from the App composition root;
//  DEBUG UI tests substitute a deterministic DebugContactExporter.
//
//  Spec sources:
//   - spec/page-inventory.md P11 Contact Export (App + System)
//   - spec/state-inventory.md S09 (contactsPermissionUnknown / Denied /
//     Allowed / exportSucceeded)
//   - spec/reference-tests.md T19
//

import Foundation

/// App-level Contacts authorization state, independent from the
/// Contacts framework enum so ViewModels/Views never import Contacts.
///
/// System mapping (see SystemContactExporter):
///   CNAuthorizationStatus.notDetermined → .notDetermined
///   .denied / .restricted / @unknown   → .denied
///   .authorized / .limited             → .allowed
/// `.limited` is usable access, never an error.
nonisolated enum ContactAuthorizationState: Sendable, Equatable {
    case notDetermined
    case denied
    case allowed
}

/// Minimal result of a successful CNSaveRequest. T19 does not persist a
/// contact identifier on the BusinessCard (export is an external side
/// effect); the receipt exists only so the exporter can report what the
/// system assigned.
nonisolated struct ContactExportReceipt: Sendable, Equatable {

    /// The system contact identifier when Contacts assigns one during
    /// the save; nil otherwise. Never written back to the card.
    var systemIdentifier: String?

    init(systemIdentifier: String? = nil) {
        self.systemIdentifier = systemIdentifier
    }
}

/// Authorization + write surface used by CardDetailViewModel.
nonisolated protocol ContactExporting: Sendable {

    /// Current Contacts authorization without prompting.
    func authorizationState() async -> ContactAuthorizationState

    /// Requests Contacts access (shows the SYSTEM permission prompt on
    /// `.notDetermined`). Returns the resulting state; never throws —
    /// a user denial or system error maps to `.denied`.
    func requestAccess() async -> ContactAuthorizationState

    /// Creates a real system Contact from `payload` via CNSaveRequest.
    /// Throws (without swallowing) when the Contacts write fails.
    func export(_ payload: ContactExportPayload) async throws -> ContactExportReceipt
}
