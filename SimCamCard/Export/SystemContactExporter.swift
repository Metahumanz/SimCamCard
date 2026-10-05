//
//  SystemContactExporter.swift
//  SimCamCard
//
//  Week 4 Increment 11 — T19 Contact Export.
//
//  Production ContactExporting implementation backed by the real
//  CNContactStore. Created ONCE at the App composition root and shared
//  through the Card Holder into CardDetailViewModel; Views/ViewModels
//  never construct a CNContactStore.
//
//  Permission:
//   - authorizationState() maps CNAuthorizationStatus to the app-level
//     ContactAuthorizationState without prompting.
//   - requestAccess() uses the modern async request API and presents the
//     genuine iOS system permission alert (the app never fakes it).
//     denied/restricted/throw/@unknown all map to .denied; .limited is
//     usable access → .allowed.
//
//  Save:
//   payload → SystemContactMapper → CNMutableContact → CNSaveRequest
//   (added to the default container) → CNContactStore.execute.
//   Contacts errors are propagated to the caller (never swallowed);
//   the BusinessCard aggregate / card repository are not touched.
//

import Contacts
import Foundation

actor SystemContactExporter: ContactExporting {

    /// The shared store. CNContactStore is not Sendable; the actor
    /// provides isolation for all access.
    private let store = CNContactStore()

    init() {}

    // MARK: - Authorization

    func authorizationState() async -> ContactAuthorizationState {
        Self.map(CNContactStore.authorizationStatus(for: .contacts))
    }

    func requestAccess() async -> ContactAuthorizationState {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .allowed : .denied
        } catch {
            // System error / denial — do not fabricate access.
            return .denied
        }
    }

    /// CNAuthorizationStatus → app-level mapping.
    static func map(_ status: CNAuthorizationStatus) -> ContactAuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        case .authorized, .limited:
            // .limited means the user granted Contacts access (possibly
            // with limited visibility): fully sufficient to ADD a contact.
            return .allowed
        @unknown default:
            return .denied
        }
    }

    // MARK: - Save

    func export(_ payload: ContactExportPayload) async throws -> ContactExportReceipt {
        let contact = SystemContactMapper.makeContact(from: payload)
        let saveRequest = CNSaveRequest()
        // nil container → the system default Contacts account (the iOS
        // equivalent of REF-export-03's macOS account picker, which is
        // not presented on iPhone).
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        try store.execute(saveRequest)

        let identifier = contact.identifier
        return ContactExportReceipt(
            systemIdentifier: identifier.isEmpty ? nil : identifier
        )
    }
}
