//
//  SimCamCardApp.swift
//  SimCamCard
//
//  App composition root.
//
//  Responsibilities:
//   1. Construct the storage triple behind the frozen repository
//      protocols. T18 production runtime uses disk-backed File
//      repositories (Application Support/SimCamCard/v1); DEBUG UI
//      tests select ephemeral in-memory stores or an isolated
//      persistent-test namespace via -SimCamCardStorage. Only the
//      protocol existentials ever leave the composition root — the
//      File/InMemory concrete types do NOT leak into Views/ViewModels.
//   2. Construct the CardHolderViewModel with the repositories
//      injected.
//   3. Host the NavigationStack root and present CardHolderView.
//   4. Trigger initial card loading via `.task`.
//
//  Spec sources:
//   - spec/page-inventory.md P01 Card Holder
//   - spec/state-inventory.md S01 empty, S10 Persistence
//   - spec/reference-tests.md T01 Empty Card Holder, T18 Persistence
//

import SwiftUI

@main
struct SimCamCardApp: App {

    /// The shared card repository, owned by the composition root for the
    /// app's lifetime. Injected into BOTH the Card Holder (read) and the
    /// Scanner (T12 save) so a card saved after recognition appears in
    /// the same store the Holder lists.
    private let cardRepository: any BusinessCardRepository

    /// The shared group catalog repository (T16). App-lifetime ownership;
    /// injected into the Card Holder ViewModel alongside the card repo.
    private let groupRepository: any CardGroupRepository

    /// The shared image asset store (T12 original/processed bytes; T18
    /// also survives terminate/relaunch).
    private let imageStore: any ImageAssetStore

    /// The shared T19 contact-export service (real CNContactStore backed
    /// in production; DEBUG launch arguments may substitute a scripted
    /// fake). App-lifetime singleton shared through the Holder into each
    /// CardDetailViewModel.
    private let contactExporter: any ContactExporting

    /// Holds the Card Holder ViewModel for the app's lifetime. `@State`
    /// (not `@StateObject`) is the standard holder for `@Observable`.
    @State private var viewModel: CardHolderViewModel

    #if DEBUG
    /// Final Delivery Phase 1.1 calibration: DEBUG-only openURL recorder
    /// installed ONLY when `-SimCamCardCaptureOpenURL 1` is present.
    /// Compiled out of Release entirely.
    @State private var debugURLCapture = DebugURLCapture()
    #endif

    /// Wires the storage triple selected for this launch and injects it
    /// into the Card Holder ViewModel.
    init() {
        let stores = Self.makeStores()
        self.cardRepository = stores.cardRepository
        self.groupRepository = stores.groupRepository
        self.imageStore = stores.imageStore
        self.contactExporter = Self.makeContactExporter()
        _viewModel = State(initialValue: CardHolderViewModel(
            repository: stores.cardRepository,
            groupRepository: stores.groupRepository
        ))
    }

    var body: some Scene {
        WindowGroup {
            appRoot
        }
    }

    /// The NavigationStack root, plus the DEBUG openURL capture seam when
    /// (and only when) the capture launch argument is present.
    @ViewBuilder
    private var appRoot: some View {
        #if DEBUG
        if DebugOpenURLCaptureLaunchMode.isEnabled() {
            baseRoot.debugOpenURLCapture(debugURLCapture)
        } else {
            baseRoot
        }
        #else
        baseRoot
        #endif
    }

    private var baseRoot: some View {
        NavigationStack {
            CardHolderView(
                viewModel: viewModel,
                cardRepository: cardRepository,
                imageStore: imageStore,
                contactExporter: contactExporter
            )
        }
        .task {
            await viewModel.loadHolderData()
        }
    }

    // MARK: - Storage composition

    /// One resolved set of stores. Existentials only: the View layer
    /// cannot see the concrete File/InMemory types.
    private struct StorageTriple {
        let cardRepository: any BusinessCardRepository
        let groupRepository: any CardGroupRepository
        let imageStore: any ImageAssetStore
    }

    /// Disk-backed triple sharing one PersistencePaths root (cards.json,
    /// groups.json and images/ live together).
    private static func fileStores(paths: PersistencePaths) -> StorageTriple {
        StorageTriple(
            cardRepository: FileBusinessCardRepository(paths: paths),
            groupRepository: FileCardGroupRepository(paths: paths),
            imageStore: FileImageAssetStore(paths: paths)
        )
    }

    #if DEBUG
    /// DEBUG: honor the -SimCamCardStorage launch contract
    /// (ephemeral / persistent-test / absent → real persistence).
    private static func makeStores() -> StorageTriple {
        switch RuntimeStorageConfiguration.resolve() {
        case .ephemeral(let seedCards):
            // Fixture cards seed the in-memory repository ONLY; mock
            // data is never written into persistent storage.
            return StorageTriple(
                cardRepository: InMemoryBusinessCardRepository(initialCards: seedCards),
                groupRepository: InMemoryCardGroupRepository(),
                imageStore: InMemoryImageAssetStore()
            )
        case .persistent(let paths):
            return fileStores(paths: paths)
        }
    }
    #else
    /// Release: always real persistent storage; no test hooks exist in
    /// this binary (RuntimeStorageConfiguration is compiled out).
    private static func makeStores() -> StorageTriple {
        let appSupport = PersistencePaths.defaultApplicationSupportDirectory()
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return fileStores(paths: .production(applicationSupportDirectory: appSupport))
    }
    #endif

    // MARK: - Contact export composition

    #if DEBUG
    /// DEBUG: honor the -SimCamCardContactExportMode launch contract
    /// (scripted fake / system exporter; absent → real SystemContact-
    /// Exporter for manual-launch parity).
    private static func makeContactExporter() -> any ContactExporting {
        ContactExportLaunchMode.makeExporter()
    }
    #else
    /// Release: always the real system Contacts exporter; no debug hooks
    /// or fake types exist in this binary.
    private static func makeContactExporter() -> any ContactExporting {
        SystemContactExporter()
    }
    #endif
}
