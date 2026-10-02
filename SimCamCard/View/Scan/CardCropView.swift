//
//  CardCropView.swift
//  SimCamCard
//
//  P04 Crop / Boundary Adjust (Week 3 Increment 5).
//
//  Spec source: spec/page-inventory.md P04
//  ("Confirm/adjust detected card region; exits: Done, Cancel/Retake"),
//  spec/state-inventory.md S04 autoDetected / manualAdjusting /
//  confirmed / retakeRequested.
//  Evidence: REF-crop-01-manual-adjust.png.
//
//  Evidence observations (actual screenshot):
//   - top bar: plain white "取消" top-left, plain blue "完成"
//     top-right; no back chevron, no icon buttons (no "重拍" text is
//     visible — the retake action is the "取消" button)
//   - full-bleed black background
//   - complete image shown centered (aspect fit; letterboxed)
//   - thin bright-blue quadrilateral stroke, NO dim/mask fill inside
//     or outside the boundary
//   - four bright-blue filled circular corner handles (draggable)
//   - four dark slate-gray edge-midpoint dots, centered on each edge:
//     OBSERVED IN REFERENCE and rendered for black-box visual
//     replication. PRESENTATION ONLY (allowsHitTesting(false)) — the
//     Reference does not establish midpoint-drag semantics, so no
//     edge interaction is implemented (interaction: NOT ESTABLISHED).
//   - while a perspective correction is in flight the confirm/retake
//     buttons are disabled and corner handles reject hit testing;
//     no new loading UI is introduced, the Reference UI is preserved
//   - no guidance text, no magnifier, no animation evidence
//
//  Presentation only: no Vision, no Core Image, no processing decode —
//  UIImage(data:) is used solely as the display adapter. Gestures
//  emit intents to the ViewModel, which owns the (always valid) draft.
//

import SwiftUI

struct CardCropView: View {

    /// MainActor @Observable owner; passed in from ScanEntryView (the
    /// Observation framework tracks the same instance directly).
    let viewModel: ScanViewModel

    /// Boundary/handle blue, matched to the REF-crop-01 stroke.
    private static let boundaryBlue = Color(red: 0.0, green: 0.62, blue: 1.0)
    private static let handleDiameter: CGFloat = 16
    private static let boundaryLineWidth: CGFloat = 1.5
    /// Edge-midpoint dot, sampled from REF-crop-01: dark slate gray
    /// (~RGB 69/69/78) centered on the blue edge.
    private static let midpointGray = Color(red: 0.27, green: 0.27, blue: 0.31)
    private static let midpointDiameter: CGFloat = 15

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .accessibilityElement()
                .accessibilityIdentifier("scan-crop-view")

            switch viewModel.cardRegion {
            case .inactive, .retakeRequested:
                // Scanner owns the screen during the retake transient.
                Color.clear
            case .preparing:
                preparingContent
            case .autoDetected(let draft), .manualAdjusting(let draft):
                cropContent(draft)
            case .confirmed(let result):
                confirmedContent(result)
            case .failed(let error):
                failedContent(error)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Crop editing

    private func cropContent(_ draft: CropDraft) -> some View {
        VStack(spacing: 0) {
            toolbar
            GeometryReader { proxy in
                ZStack {
                    imageLayer(data: draft.source.data)

                    boundaryPath(draft: draft, size: proxy.size)
                        .stroke(
                            Self.boundaryBlue,
                            style: StrokeStyle(lineWidth: Self.boundaryLineWidth)
                        )
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("scan-crop-boundary")

                    // Reference-visible edge-midpoint dots. Derived
                    // dynamically from the current four corners (never
                    // fixed screen coordinates); presentation only.
                    ForEach(edgeMidpoints(draft: draft, size: proxy.size)) { midpoint in
                        Circle()
                            .fill(Self.midpointGray)
                            .frame(width: Self.midpointDiameter, height: Self.midpointDiameter)
                            .position(midpoint.point)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    ForEach(CardCorner.allCases, id: \.self) { corner in
                        cornerHandle(corner, draft: draft, size: proxy.size)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .coordinateSpace(name: "crop-image")
            }
        }
    }

    /// Aspect-fit image: the whole still image must be visible on P04.
    private func imageLayer(data: Data) -> some View {
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private func boundaryPath(draft: CropDraft, size: CGSize) -> Path {
        let corners = [
            draft.region.topLeft,
            draft.region.topRight,
            draft.region.bottomRight,
            draft.region.bottomLeft,
        ].map {
            AspectFitCoordinateMapper.point(
                $0,
                sourcePixelWidth: draft.sourcePixelWidth,
                sourcePixelHeight: draft.sourcePixelHeight,
                destinationSize: size
            )
        }
        return Path { path in
            guard let first = corners.first else { return }
            path.move(to: first)
            for point in corners.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
    }

    private func cornerHandle(
        _ corner: CardCorner,
        draft: CropDraft,
        size: CGSize
    ) -> some View {
        let position = AspectFitCoordinateMapper.point(
            cornerPoint(corner, of: draft.region),
            sourcePixelWidth: draft.sourcePixelWidth,
            sourcePixelHeight: draft.sourcePixelHeight,
            destinationSize: size
        )
        return Circle()
            .fill(Self.boundaryBlue)
            .frame(width: Self.handleDiameter, height: Self.handleDiameter)
            .position(position)
            // Confirmation freeze: no corner hit-testing while a
            // correction is in flight (draft/state are frozen).
            .allowsHitTesting(!viewModel.isCropInFlight)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("crop-image"))
                    .onChanged { value in
                        let normalized = AspectFitCoordinateMapper.normalized(
                            viewPoint: value.location,
                            sourcePixelWidth: draft.sourcePixelWidth,
                            sourcePixelHeight: draft.sourcePixelHeight,
                            containerSize: size
                        )
                        viewModel.moveCorner(corner, to: normalized)
                    }
            )
            .accessibilityIdentifier(corner.handleIdentifier)
    }

    /// Edge-midpoint dots in display coordinates, derived live from
    /// the current four corners (REF-crop-01 visual replication).
    /// Presentation only: these carry no interaction.
    private func edgeMidpoints(draft: CropDraft, size: CGSize) -> [EdgeMidpoint] {
        let points = [
            draft.region.topLeft,
            draft.region.topRight,
            draft.region.bottomRight,
            draft.region.bottomLeft,
        ].map {
            AspectFitCoordinateMapper.point(
                $0,
                sourcePixelWidth: draft.sourcePixelWidth,
                sourcePixelHeight: draft.sourcePixelHeight,
                destinationSize: size
            )
        }
        // Edges in boundary winding order: top, right, bottom, left.
        return [
            EdgeMidpoint(id: "top", point: Self.midpoint(points[0], points[1])),
            EdgeMidpoint(id: "right", point: Self.midpoint(points[1], points[2])),
            EdgeMidpoint(id: "bottom", point: Self.midpoint(points[2], points[3])),
            EdgeMidpoint(id: "left", point: Self.midpoint(points[3], points[0])),
        ]
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func cornerPoint(_ corner: CardCorner, of region: CardRegion) -> NormalizedPoint {
        switch corner {
        case .topLeft: region.topLeft
        case .topRight: region.topRight
        case .bottomRight: region.bottomRight
        case .bottomLeft: region.bottomLeft
        }
    }

    // MARK: - Toolbar (REF-crop-01: 取消 / 完成)

    private var toolbar: some View {
        HStack {
            Button {
                Task { await viewModel.retake() }
            } label: {
                Text("取消")
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .frame(minWidth: 56, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("scan-crop-retake")
            // Confirmation freeze: retake must not interleave with a
            // running correction (stale-result race prevention).
            .disabled(viewModel.isCropInFlight)

            Spacer()

            Button {
                Task { await viewModel.confirmCrop() }
            } label: {
                Text("完成")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Self.boundaryBlue)
                    .frame(minWidth: 56, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(viewModel.isCropInFlight)
            .accessibilityIdentifier("scan-crop-confirm")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Transient states

    /// Implementation transient while decode + still detection runs.
    /// Reference fidelity not established (the Reference shows the
    /// already-detected page only).
    private var preparingContent: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white)
            Text("正在识别名片边界…")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    /// Minimal functional transitional confirmation (§30): the actual
    /// perspective-corrected image. NO OCR loading, NO recognition
    /// fields, NO save button — P05 is not implemented.
    private func confirmedContent(_ result: CardCropResult) -> some View {
        Group {
            if let image = UIImage(data: result.processedImageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("scan-crop-confirmed-image")
    }

    /// Stable fallback for prepare/correction failure (implementation
    /// transient; no Reference page exists). The 取消 path returns to
    /// the Scanner.
    private func failedContent(_ error: CropError) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
            Text("无法处理照片")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text(message(for: error))
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.retake() }
            } label: {
                Text("返回")
                    .font(.system(size: 17))
                    .foregroundStyle(Self.boundaryBlue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .accessibilityIdentifier("scan-crop-failed-back")
        }
        .padding(.horizontal, 40)
    }

    private func message(for error: CropError) -> String {
        switch error {
        case .invalidImageData:
            "所选照片无法读取，请返回后重新拍摄或选择。"
        case .invalidRegion:
            "名片边界无效，请返回后重新调整。"
        case .correctionFailed:
            "透视校正失败，请返回后重试。"
        }
    }
}

/// Presentation-only edge-midpoint marker (no interaction semantics
/// are established by the Reference).
private struct EdgeMidpoint: Identifiable {
    let id: String
    let point: CGPoint
}
