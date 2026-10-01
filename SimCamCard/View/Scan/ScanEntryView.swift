//
//  ScanEntryView.swift
//  SimCamCard
//
//  P02 Scanner (Week 2 Increment 6 static shell; Week 3 Increment 1
//  camera permission + real live preview; Week 3 Increment 2 adds
//  T04 single still capture → S02 captured; Week 3 Increment 3 adds
//  T05 system photo import → S03 pickerPresented/imageSelected).
//
//  Spec sources:
//   - spec/page-inventory.md P02 Scanner (Camera preview and card
//     detection; exits: Capture, Photo Import, Back)
//   - spec/state-inventory.md S02 permissionUnknown / permissionDenied
//     / preview
//   - spec/reference-tests.md T02 Enter Scanner, T03 Camera Permission
//     ("Allow/deny must produce defined states; denial path must not
//     crash."); T04 Capture remains a later boundary.
//   - Evidence: REF-scanner-01-initial.png (scanner chrome),
//     REF-permission-01-camera.png (native system permission dialog —
//     presented by iOS, NEVER replicated by the app).
//   - REF-scanner-02-card-detected.png is a later-state boundary
//     reference ONLY; detection UI is deliberately not built here.
//
//  State rendering:
//   - permissionUnknown → Week 2 static shell (black viewport, aiming
//     frame, guidance tip) while the NATIVE system dialog is shown by
//     iOS. No custom permission dialog.
//   - preview           → real AVCaptureVideoPreviewLayer feed with the
//     same Week 2 evidence-driven overlays on top.
//   - permissionDenied  → minimal functional fallback (no crash, no
//     session); Reference fidelity not established — frozen evidence
//     shows the native dialog only, not a custom denied page.
//   - cameraUnavailable → minimal functional fallback for hardware/
//     configuration failure with permission already granted (e.g.
//     simulator). Infrastructure state, not an S02 permission state.
//
//  Still NOT implemented (later increments):
//   - Card Detection, Crop, OCR/Vision, recognition navigation, saving
//     (T04 capture → recognition and T05 import → recognition are out
//     of scope; only the capture/import mechanics exist).
//
//  Concurrency: the permission provider and this ViewModel stay
//  MainActor-isolated; the camera session lifecycle runs on the
//  CameraSessionController actor's dedicated serial executor (never
//  the main thread). Lifecycle is driven by `.task` / `.onDisappear`.
//

import SwiftUI
import PhotosUI

struct ScanEntryView: View {

    /// Pops back to the Card Holder using the system NavigationStack
    /// navigation path (no custom navigation state).
    @Environment(\.dismiss) private var dismiss

    /// UI-facing S02 state owner. Default composition uses the real
    /// AVFoundation providers; DEBUG UI tests may inject fakes via the
    /// `-SimCamCardCamera` launch argument, and previews/tests may pass
    /// an explicit ViewModel.
    @State private var viewModel: ScanViewModel

    /// The selected `PhotosPickerItem`. Bound to the system
    /// `PhotosPicker`. Never stored long-term — its data is loaded into
    /// stable `Data` and handed to the ViewModel immediately.
    @State private var selectedItem: PhotosPickerItem?

    /// Tracks whether the user made a selection (so the picker's
    /// dismissal can be distinguished from a cancel).
    @State private var didSelectItem = false

    init(viewModel: ScanViewModel? = nil) {
        if let viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            #if DEBUG
            _viewModel = State(initialValue: ScanViewModel.configuredForDebugLaunch())
            #else
            _viewModel = State(initialValue: ScanViewModel())
            #endif
        }
    }

    var body: some View {
        ZStack {
            // Root accessibility marker lives on the childless background
            // shape, NOT on the container that parents the controls:
            // SwiftUI propagates a container-level accessibilityIdentifier
            // down to child Buttons and overrides their own identifiers.
            // As a sibling ZStack layer the marker cannot affect them.
            Color.black
                .ignoresSafeArea()
                .accessibilityElement()
                .accessibilityIdentifier("scan-entry-view")

            VStack(spacing: 0) {
                topBar

                // Photo-import transient states take priority over the
                // camera state: a selected/imported image or an import
                // failure renders on top of the underlying scanner
                // shell.
                switch viewModel.photoImport {
                case .imageSelected(let photo):
                    imageSection(photo, identifier: "scan-imported-photo")
                case .importFailed:
                    permissionFallback(
                        systemImage: "photo.on.rectangle.angled",
                        title: "无法导入照片",
                        message: "所选照片无法读取，请重试或选择其他照片。",
                        identifier: "scan-import-failed"
                    )
                case .idle, .pickerPresented:
                    switch viewModel.state {
                    case .permissionDenied:
                        permissionFallback(
                            systemImage: "camera.slash",
                            title: "无法访问相机",
                            message: "请在系统“设置”中允许 SimCamCard 访问相机后再扫描名片。",
                            identifier: "scan-permission-denied"
                        )
                    case .cameraUnavailable:
                        permissionFallback(
                            systemImage: "camera.fill",
                            title: "相机不可用",
                            message: "当前设备无法启动相机预览。",
                            identifier: "scan-camera-unavailable"
                        )
                    case .captured(let photo):
                        imageSection(photo, identifier: "scan-captured-photo")
                    case .permissionUnknown, .preview:
                        viewportSection
                        modeTabs
                        controlBar
                    }
                }
            }
        }
        // The whole page is a dark full-screen surface in the Reference;
        // force dark appearance so host-owned status bar content stays
        // legible without any custom status-bar handling.
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(
            isPresented: Binding(
                get: { viewModel.isPickerPresented },
                set: { presented in
                    // The picker sheet was dismissed by the system.
                    // A dismissal AFTER a selection is NOT a cancel:
                    // clear only the presentation flag (prevents stale
                    // re-presentation while Data is still loading); a
                    // dismissal WITHOUT a selection is a first-class
                    // cancel (§12).
                    guard !presented else { return }
                    if didSelectItem {
                        viewModel.photoPickerDidDismissAfterSelection()
                    } else {
                        Task { await viewModel.handleImportCancel() }
                    }
                    didSelectItem = false
                }
            ),
            selection: $selectedItem,
            matching: .images,
            // Ask the system to preserve the item's current encoding
            // (avoid PhotosPicker transcoding when possible). SimCamCard
            // performs NO app-side decode/re-encode: the `Data` returned
            // by `loadTransferable` is preserved unchanged. Bit-for-bit
            // original asset identity is NOT guaranteed.
            preferredItemEncoding: .current
        )
        .onChange(of: selectedItem) { _, newItem in
            // nil is the reset value (see below) — never an event.
            guard let item = newItem else { return }
            didSelectItem = true
            Task {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       !data.isEmpty {
                        viewModel.handleSelectedImage(data)
                    } else {
                        viewModel.handleImportLoadFailure()
                    }
                } catch {
                    viewModel.handleImportLoadFailure()
                }
                // Terminal result handled — release the item so a later
                // picker session never holds the previous
                // PhotosPickerItem. Setting nil re-fires onChange,
                // which returns immediately on nil and is NOT a cancel.
                selectedItem = nil
            }
        }
        .task {
            await viewModel.scannerDidAppear()
        }
        .onDisappear {
            // stop() runs on the session service's serial executor;
            // hop off the MainActor via the ViewModel's async API.
            Task { await viewModel.scannerDidDisappear() }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("关闭")
            .accessibilityIdentifier("scan-close")

            Spacer(minLength: 0)

            recognitionModeSelector

            Spacer(minLength: 0)

            // Static Reference chrome; the more menu has no current
            // actions, so it is a non-interactive glyph (hidden from the
            // accessibility tree to avoid a fake control).
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    /// Static 基础识别 / AI 高精度识别 segmented selector.
    /// Selection is presented (基础识别) but NOT interactive: mode
    /// switching has no backing state or behavior yet.
    private var recognitionModeSelector: some View {
        HStack(spacing: 0) {
            Text("基础识别")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(.white))

            Text("AI 高精度识别")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Self.aiModeBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .padding(3)
        .frame(width: 264)
        .background(
            Capsule()
                .fill(.black)
                .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("识别模式：基础识别")
    }

    // MARK: - Viewport

    private var viewportSection: some View {
        GeometryReader { proxy in
            ZStack {
                // Live preview fills the viewport when authorized; the
                // pre-permission state stays black. No fake camera image
                // is ever shown.
                switch viewModel.state {
                case .preview:
                    CameraPreviewView(session: viewModel.cameraSession)
                        .accessibilityIdentifier("scan-camera-preview")
                case .permissionUnknown:
                    Color.clear
                case .permissionDenied, .cameraUnavailable, .captured:
                    Color.clear
                }

                // T06 detected boundary (REF-scanner-02-card-detected.png):
                // when a card is detected the cyan quadrilateral overlay
                // REPLACES the static white aiming guide, and the
                // guidance tip switches to the detected copy. When no
                // card is detected the Week 2 static guide + tip remain.
                if case .cardDetected(let region) = viewModel.cardDetection {
                    CardDetectionOverlay(region: region, containerSize: proxy.size)
                        .overlay(alignment: .top) {
                            detectedTip
                                .padding(.top, 12)
                        }
                } else {
                    // Static aiming guide + guidance tip overlay retained
                    // over BOTH the pre-permission shell and the live feed.
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white, lineWidth: 1)
                        .aspectRatio(Self.viewportAspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                        .overlay(alignment: .top) {
                            guidanceTip
                                .padding(.top, 12)
                        }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Image presentation (camera capture + photo import)

    /// Shared presentation for a selected/imported image. Used by BOTH
    /// the camera-capture path (T04, id `scan-captured-photo`) and the
    /// photo-import path (T05, id `scan-imported-photo`) — §13: reuse
    /// one image-display component rather than duplicating it.
    ///
    /// Frozen evidence has NO standalone "captured holding page" (T04
    /// flows straight into recognition in the Reference, which is a
    /// later increment), so this is deliberately minimal: the actual
    /// image bytes plus the existing top-bar close back path.
    /// Reference fidelity: functional transitional UI; reference
    /// fidelity not established.
    ///
    /// The raw Data remains the source of truth; UIImage exists only
    /// as this View-layer rendering adapter — never stored in the
    /// Domain, never persisted.
    private func imageSection(_ photo: CapturedPhoto, identifier: String) -> some View {
        Group {
            if let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // The DEBUG fixture always supplies valid image bytes;
                // a decode failure here means corrupt pipeline data —
                // show a stable fallback rather than a fake image.
                permissionFallback(
                    systemImage: "exclamationmark.triangle",
                    title: "照片不可用",
                    message: "所选的照片无法显示。",
                    identifier: identifier + "-undecodable"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    /// Minimal functional fallback for denied/unavailable states.
    /// Functional fallback only — Reference fidelity is not established:
    /// frozen evidence documents the native dialog, not a custom page.
    /// Keeps the page stable (no crash, no AVCaptureSession start) and
    /// the top-bar ✕ remains the real Back path.
    private func permissionFallback(
        systemImage: String,
        title: String,
        message: String,
        identifier: String
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    /// Frozen Reference guidance copy. This is user-facing scanner
    /// guidance observed in REF-scanner-01-initial.png, not a developer
    /// placeholder.
    private var guidanceTip: some View {
        Text("请将镜头靠近名片")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(.white.opacity(0.18))
            )
            .allowsHitTesting(false)
    }

    /// Frozen Reference detected-state copy from
    /// REF-scanner-02-card-detected.png ("发现名片，点击拍摄"). Same
    /// capsule presentation as the not-detected guidance tip.
    private var detectedTip: some View {
        Text("发现名片，点击拍摄")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(.white.opacity(0.18))
            )
            .allowsHitTesting(false)
    }

    // MARK: - Capture mode tabs

    /// Static capture-mode tab row. 单张拍摄 is presented as selected
    /// (bold white + blue indicator), exactly as in the initial
    /// Reference. Tabs are not interactive yet.
    private var modeTabs: some View {
        HStack(spacing: 28) {
            modeTab("连续拍摄", isSelected: false)
            modeTab("多张拍摄", isSelected: false)
            modeTab("单张拍摄", isSelected: true)
            modeTab("二维码", isSelected: false)
        }
        .padding(.top, 10)
        .padding(.bottom, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("拍摄模式：单张拍摄")
    }

    private func modeTab(_ title: String, isSelected: Bool) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.55))
            Capsule()
                .fill(isSelected ? Self.aiModeBlue : Color.clear)
                .frame(width: 22, height: 3)
        }
    }

    // MARK: - Bottom control bar

    private var controlBar: some View {
        HStack {
            // Photo-library entry — T05 system photo import. Tapping
            // stops the camera session and presents the system
            // `PhotosPicker` (out-of-process; no photo-library
            // permission required).
            Button {
                Task { await viewModel.beginPhotoImport() }
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                    Text("相册")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.white)
                .frame(width: 64, height: 56)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("相册")
            .accessibilityIdentifier("scan-photo-import")

            Spacer()

            // Shutter — real T04 capture action. Only reachable in
            // .preview (the control bar only renders there) and
            // disabled while a capture is in flight, so a fast double
            // tap cannot start two capture workflows.
            Button {
                Task { await viewModel.capture() }
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(.white)
                        .frame(width: 62, height: 62)
                }
                .opacity(viewModel.isCaptureInFlight ? 0.5 : 1.0)
            }
            .disabled(viewModel.isCaptureInFlight)
            .accessibilityLabel("拍摄")
            .accessibilityIdentifier("scan-capture")

            Spacer()

            // Batch-review glyph shown for Reference fidelity. The
            // Reference badge number ("5") is intentionally not rendered
            // — zero images exist in this shell, so a count would be
            // fabricated state. Non-interactive (batch review deferred).
            Image(systemName: "square.on.square")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 64, height: 56)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .padding(.top, 4)
    }

    // MARK: - Constants

    /// Reference aiming frame width/height ratio (~0.61 measured from
    /// REF-scanner-01-initial.png).
    private static let viewportAspectRatio: CGFloat = 0.61

    /// Blue used for the AI-mode text and the selected capture-tab
    /// indicator in the Reference.
    private static let aiModeBlue = Color(red: 0.36, green: 0.69, blue: 1.0)
}

#if DEBUG

// MARK: - SwiftUI Previews (DEBUG fakes only — no real camera in Canvas)

#Preview("Scanner Authorized Fixture") {
    NavigationStack {
        ScanEntryView(viewModel: ScanViewModel(
            authorization: DebugCameraAuthorizationProvider(initialStatus: .authorized),
            sessionController: DebugCameraSessionController()
        ))
    }
}

#Preview("Scanner Denied Fixture") {
    NavigationStack {
        ScanEntryView(viewModel: ScanViewModel(
            authorization: DebugCameraAuthorizationProvider(initialStatus: .denied),
            sessionController: DebugCameraSessionController()
        ))
    }
}

#endif
