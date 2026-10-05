//
//  ContactExportLaunchMode.swift
//  SimCamCard
//
//  Week 4 Increment 11 — DEBUG-only contact-export launch contract.
//
//  This file is compiled ENTIRELY out of Release builds (#if DEBUG).
//  Production always constructs a real SystemContactExporter; none of
//  the argument strings below (e.g. "SimCamCardContactExportMode") or
//  the DebugContactExporter type name can appear in the Release binary.
//
//  DEBUG launch contract:
//
//   -SimCamCardContactExportMode allowed
//       Authorization is pre-allowed; export succeeds without touching
//       the system store.
//   -SimCamCardContactExportMode denied
//       Authorization is already denied; requestAccess stays denied;
//       export is never attempted.
//   -SimCamCardContactExportMode allow-on-request
//       Starts notDetermined; the system prompt is faked as allowed.
//   -SimCamCardContactExportMode deny-on-request
//       Starts notDetermined; the system prompt is faked as denied.
//   -SimCamCardContactExportMode failure
//       Authorization allowed; the write throws deterministically.
//   -SimCamCardContactExportMode system
//       Forwards to the real SystemContactExporter (real permission
//       prompt + real CNSaveRequest; used by the native integration
//       validation).
//
//  No argument (normal DEBUG manual launch): real SystemContactExporter,
//  giving DEBUG manual runs exact Release parity.
//

#if DEBUG

import Foundation

nonisolated enum ContactExportLaunchMode: Sendable {

    static let argument = "-SimCamCardContactExportMode"

    case allowed
    case denied
    case allowOnRequest
    case denyOnRequest
    case failure
    case system

    /// Resolves the launch arguments to an export mode. Unknown/missing
    /// values fall back to `.system` — test scripting is opt-in only.
    static func resolve(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> ContactExportLaunchMode {
        guard let index = arguments.firstIndex(of: argument),
              index + 1 < arguments.count
        else {
            return .system
        }
        switch arguments[index + 1] {
        case "allowed": return .allowed
        case "denied": return .denied
        case "allow-on-request": return .allowOnRequest
        case "deny-on-request": return .denyOnRequest
        case "failure": return .failure
        case "system": return .system
        default: return .system
        }
    }

    /// Composition helper used by the DEBUG App root: `.system` returns
    /// the real exporter; every scripted mode returns the deterministic
    /// DEBUG fake.
    static func makeExporter(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> any ContactExporting {
        let mode = resolve(arguments: arguments)
        switch mode {
        case .system:
            return SystemContactExporter()
        case .allowed, .denied, .allowOnRequest, .denyOnRequest, .failure:
            return DebugContactExporter(mode: mode)
        }
    }
}

#endif
