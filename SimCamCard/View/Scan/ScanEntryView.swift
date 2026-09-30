//
//  ScanEntryView.swift
//  SimCamCard
//
//  P02 Scanner — static UI shell (Week 2 Increment 6).
//
//  Spec sources:
//   - spec/page-inventory.md P02 Scanner (Camera preview and card
//     detection; exits: Capture, Photo Import, Back)
//   - spec/state-inventory.md S02 Camera / Scanner
//   - spec/reference-tests.md T02 Enter Scanner
//     ("Scan entry opens scanner/camera UI.")
//   - Evidence: evidence/screenshots/REF-scanner-01-initial.png
//     (sole primary visual basis for the initial state)
//   - REF-scanner-02-card-detected.png is a later-state boundary
//     reference ONLY; the blue detection frame / live camera feed /
//     "发现名片，点击拍摄" tip are deliberately NOT built here.
//
//  What this is:
//   - A static, evidence-driven scanner page the user can navigate to
//     and back from (Holder → Scan → Back → Holder).
//
//  What this is NOT (Week 3+ concerns):
//   - No AVFoundation / AVCaptureSession / live preview layer.
//   - No camera or photo-library permission requests.
//   - No PhotosPicker / PHPicker import.
//   - No shutter capture, detection, crop, OCR/Vision, saving.
//   - No mode switching, more menu or batch review behavior.
//   - No Domain draft model and no fabricated captured image.
//
//  The black viewport is a pure SwiftUI background + stroked shape; it
//  never pretends to show a real camera feed. No developer placeholder
//  text is shown anywhere ("Coming soon" etc. are prohibited).
//
//  There is intentionally NO ScanEntryViewModel: this increment has no
//  camera / capture / permission / business state. Only the close
//  control has real behavior (system NavigationStack pop via dismiss()).
//
//  UI evidence → View element mapping (REF-scanner-01-initial.png):
//   - macOS window chrome / traffic lights / title "名片全能王"
//       → host-owned, NOT replicated (iOS status bar / home indicator
//         remain system-owned)
//   - Close "✕" (top leading)        → scan-close; real dismiss() back
//   - Segmented 基础识别 / AI高精度识别 → static visual shell (no switch)
//   - "•••" more (top trailing)      → static visual only (no menu)
//   - Black viewport + white rounded aiming frame
//                                    → Color.black + RoundedRectangle stroke
//   - Tip "请将镜头靠近名片"          → static user-guidance text from
//                                      the frozen Reference (not a dev
//                                      placeholder)
//   - Mode tabs 连续拍摄/多张拍摄/单张拍摄(selected)/二维码
//                                    → static visual shell
//   - 相册 (bottom leading)          → scan-photo-import; empty action
//                                      (NO PhotosPicker; T05 deferred)
//   - Shutter (bottom center)        → scan-capture; empty action (no
//                                      capture/recognition/repository
//                                      change; T04 deferred)
//   - Batch stack glyph + badge "5"  → glyph shown statically; the "5"
//                                      badge is OMITTED on purpose: the
//                                      shell has zero captured images, so
//                                      the number would be fabricated
//                                      state
//

import SwiftUI

struct ScanEntryView: View {

    /// Pops back to the Card Holder using the system NavigationStack
    /// navigation path (no custom navigation state).
    @Environment(\.dismiss) private var dismiss

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
                viewportSection
                modeTabs
                controlBar
            }
        }
        // The whole page is a dark full-screen surface in the Reference;
        // force dark appearance so host-owned status bar content stays
        // legible without any custom status-bar handling.
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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

            // Static Reference chrome; the more menu has no Week 2
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
    /// switching has no backing state or behavior in the Week 2 shell.
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
                // Static aiming guide: thin white rounded frame over the
                // black viewport. The interior stays black — there is no
                // live camera feed and no fake captured imagery.
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white, lineWidth: 1)
                    .aspectRatio(Self.viewportAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .top) {
                        guidanceTip
                            .padding(.top, 12)
                    }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
    }

    // MARK: - Capture mode tabs

    /// Static capture-mode tab row. 单张拍摄 is presented as selected
    /// (bold white + blue indicator), exactly as in the initial
    /// Reference. Tabs are not interactive in the Week 2 shell.
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
            // Photo-library entry — visual shell only. Tapping performs
            // no action: no PhotosPicker, no photo permission (T05/T03
            // deferred).
            Button {
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

            // Shutter — visual shell only. Tapping does not capture,
            // navigate, create a BusinessCard or mutate the Repository
            // (T04 capture workflow deferred).
            Button {
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(.white)
                        .frame(width: 62, height: 62)
                }
            }
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

// MARK: - SwiftUI Preview

#Preview("Scanner Shell") {
    NavigationStack {
        ScanEntryView()
    }
}

#endif
