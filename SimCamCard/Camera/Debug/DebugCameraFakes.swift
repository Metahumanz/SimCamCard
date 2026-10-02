//
//  DebugCameraFakes.swift
//  SimCamCard
//
//  DEBUG-only deterministic camera dependency injection for UI tests
//  and SwiftUI previews (Week 3 Increment 1).
//
//  Contract (mirrors SimCamCardFixture for card fixtures):
//   - Compiled OUT of Release builds entirely (#if DEBUG).
//   - Normal DEBUG launch without the argument: nil → production real
//     AVFoundation dependencies are used.
//   - `-SimCamCardCamera <mode>` opt-in (DEBUG UI tests only):
//       authorized            → status pre-authorized; fake session
//                               drives S02 preview UI without hardware
//       denied                → pre-denied; permissionDenied UI
//       restricted            → restricted; permissionDenied UI
//       notDeterminedGranted  → undetermined, the (fake) request
//                               resolves granted → preview
//       notDeterminedDenied   → undetermined, the (fake) request
//                               resolves denied → permissionDenied
//
//  This is fixture-driven UI STATE verification only. It is NOT real
//  camera hardware, NOT the native permission dialog and NOT live-frame
//  verification; the fake session is an empty, never-started-by-hardware
//  AVCaptureSession used only to host the preview layer container.
//

#if DEBUG

@preconcurrency import AVFoundation
import CoreGraphics
import ImageIO

// MARK: - Fake authorization provider

@MainActor
final class DebugCameraAuthorizationProvider: CameraAuthorizationProviding {

    private var current: CameraAuthorizationStatus
    private let grantOnRequest: Bool

    /// Number of times requestVideoAccess() was invoked — tests assert
    /// that denied/restricted/already-authorized statuses never re-prompt.
    private(set) var requestCount = 0

    init(initialStatus: CameraAuthorizationStatus, grantOnRequest: Bool = false) {
        self.current = initialStatus
        self.grantOnRequest = grantOnRequest
    }

    func videoAuthorizationStatus() -> CameraAuthorizationStatus {
        current
    }

    func requestVideoAccess() async -> Bool {
        requestCount += 1
        // Emulate the native outcome: status changes to the resolved
        // authorization so a subsequent inspection reflects the answer.
        current = grantOnRequest ? .authorized : .denied
        return grantOnRequest
    }
}

// MARK: - Fake session controller

/// DEBUG-only detection fixture for T06 overlay UI regression.
/// `detected` yields one deterministic CardRegion; `notdetected`
/// yields nil. Fixture detection is NOT real Vision detection; Release
/// never contains this path.
enum DetectionFixtureMode: String {
    case detected
    case notdetected
}

/// Actor fake mirroring the production serialization/idempotency
/// contract (configure once / start many / stop many) without any
/// hardware dependency. Being an actor, its counters and guards are
/// serialized exactly like the real service's serial executor.
actor DebugCameraSessionController: CameraSessionControlling {

    /// An empty session: valid for hosting a preview layer, never
    /// connected to real capture hardware.
    nonisolated let session = AVCaptureSession()

    private(set) var configureCount = 0
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var captureCount = 0

    /// When non-nil, `configureIfNeeded()` throws this error to emulate
    /// hardware/configuration failure with permission already granted.
    private let configureError: CameraSessionError?

    /// Optional T06 detection fixture driving `makeDetectionEvents()`.
    private let detectionFixture: DetectionFixtureMode?

    init(
        configureError: CameraSessionError? = nil,
        detectionFixture: DetectionFixtureMode? = nil
    ) {
        self.configureError = configureError
        self.detectionFixture = detectionFixture
    }

    func configureIfNeeded() async throws {
        guard configureCount == 0 else { return } // configure-once
        configureCount += 1
        if let configureError {
            throw configureError
        }
    }

    func start() async throws {
        startCount += 1
        // Deliberately does NOT call session.startRunning(): no hardware
        // dependency, no simulator audio/camera side effects. Never
        // throws in UI fixtures (start-failure injection is covered by
        // the unit-test fake).
    }

    func stop() async {
        stopCount += 1
    }

    /// Deterministic T04 fixture capture: returns a fixed, VALID tiny
    /// PNG (4×4 green pixels) so the captured-state UI can decode and
    /// display it. Never arbitrary bytes, never nil. The same bytes on
    /// every call — fully deterministic for UI tests.
    func capturePhoto() async throws -> CapturedPhoto {
        captureCount += 1
        return CapturedPhoto(data: DebugCameraSessionController.fixtureImageData)
    }

    /// Deterministic T06 fixture stream. `detected` delivers one fixed
    /// quadrilateral; `notdetected` delivers nil; no fixture delivers
    /// an empty stream (the ViewModel's initial cardNotDetected stands).
    func makeDetectionEvents() async -> AsyncStream<CardRegion?> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            switch detectionFixture {
            case .detected:
                continuation.yield(Self.fixtureCardRegion)
            case .notdetected:
                continuation.yield(nil)
            case nil:
                break
            }
        }
    }

    /// Fixed detected quadrilateral for the T06 overlay fixture:
    /// centered card-like region in a 1920×1080 source frame.
    nonisolated static let fixtureCardRegion = CardRegion(
        topLeft: NormalizedPoint(x: 0.22, y: 0.30),
        topRight: NormalizedPoint(x: 0.78, y: 0.30),
        bottomRight: NormalizedPoint(x: 0.78, y: 0.72),
        bottomLeft: NormalizedPoint(x: 0.22, y: 0.72),
        sourcePixelWidth: 1920,
        sourcePixelHeight: 1080
    )

    /// Fixed 4×4 green PNG (71 bytes). Valid image data required because
    /// the captured presentation decodes it with UIImage(data:).
    nonisolated static let fixtureImageData: Data = Data([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x08, 0x06, 0x00, 0x00, 0x00, 0xA9, 0xF1, 0x9E,
        0x7E, 0x00, 0x00, 0x00, 0x0E, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0xF8, 0x8F, 0x06,
        0x19, 0x18, 0x00, 0x57, 0xBC, 0x07, 0xF9, 0xA7, 0xB4, 0x03, 0xCB, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ])
}

// MARK: - Launch-argument environment

enum DebugCameraEnvironment {

    static let launchArgument = "-SimCamCardCamera"
    static let photoImportArgument = "-SimCamCardPhotoImport"
    static let detectionArgument = "-SimCamCardDetection"
    static let cropArgument = "-SimCamCardCrop"
    static let ocrArgument = "-SimCamCardOCR"

    enum Mode: String {
        case authorized
        case denied
        case restricted
        case notDeterminedGranted = "notdeterminedgranted"
        case notDeterminedDenied = "notdetermineddenied"
    }

    /// Returns a fixture-configured ScanViewModel when the launch
    /// requests one; nil for normal launches (real AVFoundation path).
    /// Also honors `-SimCamCardPhotoImport <imported|cancel|loadfailure>`
    /// to deterministically drive the photo-import path without the
    /// real system PhotosPicker (T05 fixture-driven UI regression), and
    /// `-SimCamCardOCR <success|empty|failure>` to drive post-confirm
    /// raw recognition without real Vision (T07 fixture regression).
    static func makeViewModelIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> ScanViewModel? {
        guard let index = arguments.firstIndex(of: launchArgument),
              index + 1 < arguments.count,
              let mode = Mode(rawValue: arguments[index + 1].lowercased())
        else {
            return nil
        }

        let authorization: DebugCameraAuthorizationProvider
        switch mode {
        case .authorized:
            authorization = DebugCameraAuthorizationProvider(initialStatus: .authorized)
        case .denied:
            authorization = DebugCameraAuthorizationProvider(initialStatus: .denied)
        case .restricted:
            authorization = DebugCameraAuthorizationProvider(initialStatus: .restricted)
        case .notDeterminedGranted:
            authorization = DebugCameraAuthorizationProvider(
                initialStatus: .notDetermined, grantOnRequest: true
            )
        case .notDeterminedDenied:
            authorization = DebugCameraAuthorizationProvider(
                initialStatus: .notDetermined, grantOnRequest: false
            )
        }

        let photoImportFixture = parsePhotoImportFixture(arguments: arguments)
        let detectionFixture = parseDetectionFixture(arguments: arguments)
        let cropFixture = parseCropFixture(arguments: arguments)
        let ocrFixture = parseOCRFixture(arguments: arguments)

        return ScanViewModel(
            authorization: authorization,
            sessionController: DebugCameraSessionController(
                detectionFixture: detectionFixture
            ),
            photoImportFixture: photoImportFixture,
            cropProcessor: cropFixture == nil ? nil : DebugCropProcessor(),
            ocrProcessor: ocrFixture.map { DebugOCRProcessor(mode: $0) },
            cropFixture: cropFixture
        )
    }

    /// Parses the optional `-SimCamCardPhotoImport` launch argument.
    /// Returns nil when absent or unrecognized.
    private static func parsePhotoImportFixture(
        arguments: [String]
    ) -> PhotoImportFixtureMode? {
        guard let index = arguments.firstIndex(of: photoImportArgument),
              index + 1 < arguments.count
        else {
            return nil
        }
        return PhotoImportFixtureMode(rawValue: arguments[index + 1].lowercased())
    }

    /// Parses the optional `-SimCamCardDetection detected|notdetected`
    /// launch argument. Returns nil when absent or unrecognized.
    private static func parseDetectionFixture(
        arguments: [String]
    ) -> DetectionFixtureMode? {
        guard let index = arguments.firstIndex(of: detectionArgument),
              index + 1 < arguments.count
        else {
            return nil
        }
        return DetectionFixtureMode(rawValue: arguments[index + 1].lowercased())
    }

    /// Parses the optional `-SimCamCardCrop auto|manual|confirmed`
    /// launch argument. Returns nil when absent or unrecognized.
    private static func parseCropFixture(
        arguments: [String]
    ) -> CropFixtureMode? {
        guard let index = arguments.firstIndex(of: cropArgument),
              index + 1 < arguments.count
        else {
            return nil
        }
        return CropFixtureMode(rawValue: arguments[index + 1].lowercased())
    }

    /// Parses the optional `-SimCamCardOCR success|empty|failure`
    /// launch argument. Returns nil when absent or unrecognized.
    private static func parseOCRFixture(
        arguments: [String]
    ) -> OCRFixtureMode? {
        guard let index = arguments.firstIndex(of: ocrArgument),
              index + 1 < arguments.count
        else {
            return nil
        }
        return OCRFixtureMode(rawValue: arguments[index + 1].lowercased())
    }
}

// MARK: - Fake crop processor (P04 fixtures)

/// Deterministic P04 fixture processor. Preparation returns a fixed
/// VALID synthetic image + valid region (no Vision involved — real
/// still detection is covered by the dataset smoke tests). Confirm
/// delegates to a REAL CardCropProcessor so the fixture exercises the
/// actual Core Image perspective-correction + PNG pipeline on
/// deterministic input. DEBUG-only; never instantiated in Release.
actor DebugCropProcessor: CardCropProcessing {

    private let realProcessor = CardCropProcessor()

    func prepare(_ photo: CapturedPhoto) async throws -> CropPreparation {
        let synthetic = CapturedPhoto(
            data: Self.syntheticCardImageData,
            source: photo.source
        )
        let draft = CropDraft(
            source: synthetic,
            sourceOrientation: .up,
            sourcePixelWidth: Self.syntheticPixelWidth,
            sourcePixelHeight: Self.syntheticPixelHeight,
            region: Self.fixtureRegion
        )
        return CropPreparation(draft: draft, wasDetected: true)
    }

    func perspectiveCorrect(_ draft: CropDraft) async throws -> CardCropResult {
        try await realProcessor.perspectiveCorrect(draft)
    }

    nonisolated static let syntheticPixelWidth = 600
    nonisolated static let syntheticPixelHeight = 380

    /// Fixed card-like quadrilateral matching the white rectangle
    /// painted into `syntheticCardImageData`.
    nonisolated static let fixtureRegion = CardRegion(
        topLeft: NormalizedPoint(x: 0.10, y: 0.16),
        topRight: NormalizedPoint(x: 0.90, y: 0.16),
        bottomRight: NormalizedPoint(x: 0.90, y: 0.84),
        bottomLeft: NormalizedPoint(x: 0.10, y: 0.84),
        sourcePixelWidth: syntheticPixelWidth,
        sourcePixelHeight: syntheticPixelHeight
    )

    /// Deterministic card-like PNG: dark background, white inset
    /// rounded rectangle (exactly `fixtureRegion`) with a few gray
    /// lines. Built once via Core Graphics; never reads fixture
    /// arguments from production code.
    nonisolated static let syntheticCardImageData: Data = {
        let width = syntheticPixelWidth
        let height = syntheticPixelHeight
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        func setPixel(_ x: Int, _ y: Int, r: UInt8, g: UInt8, b: UInt8) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            let offset = y * bytesPerRow + x * 4
            pixels[offset] = r
            pixels[offset + 1] = g
            pixels[offset + 2] = b
            pixels[offset + 3] = 255
        }

        // Dark gray background.
        for y in 0..<height {
            for x in 0..<width {
                setPixel(x, y, r: 45, g: 45, b: 48)
            }
        }

        // White card rectangle at fixtureRegion (inset).
        let cardX0 = Int(Double(width) * 0.10)
        let cardX1 = Int(Double(width) * 0.90)
        let cardY0 = Int(Double(height) * 0.16)
        let cardY1 = Int(Double(height) * 0.84)
        for y in cardY0..<cardY1 {
            for x in cardX0..<cardX1 {
                setPixel(x, y, r: 245, g: 245, b: 247)
            }
        }
        // A few dark horizontal "text lines" so the image is not flat.
        for y in stride(from: cardY0 + 90, to: cardY1 - 40, by: 46) {
            for x in (cardX0 + 60)..<(cardX1 - 60) {
                setPixel(x, y, r: 90, g: 96, b: 110)
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            return Data()
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, "public.png" as CFString, 1, nil
        ) else {
            return Data()
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return Data() }
        return output as Data
    }()
}

// MARK: - Fake OCR processor (T07 fixtures)

/// Deterministic T07 raw-OCR fixture processor. Returns fixed
/// preserved lines WITHOUT invoking Vision — real recognition is
/// covered by CardOCRProcessorTests and the OCR dataset smoke tests.
/// Being an actor mirrors the real service's isolation contract.
/// DEBUG-only; never instantiated in Release.
actor DebugOCRProcessor: CardOCRProcessing {

    private let mode: OCRFixtureMode

    init(mode: OCRFixtureMode) {
        self.mode = mode
    }

    func recognize(_ crop: CardCropResult) async throws -> CardOCRResult {
        switch mode {
        case .success:
            // Fixed bilingual lines; punctuation, spacing, case and
            // digits preserved verbatim (T07 raw contract).
            return CardOCRResult(cropResult: crop, lines: [
                OCRLine(text: "张伟", confidence: 1.0),
                OCRLine(text: "产品总监 | Product Director", confidence: 1.0),
                OCRLine(text: "+86 138 0013 8000", confidence: 1.0),
                OCRLine(text: "wei.zhang@zhiyuntech.com", confidence: 1.0),
            ])
        case .empty:
            // A legitimate zero-text result (not a failure).
            return CardOCRResult(cropResult: crop, lines: [])
        case .failure:
            throw OCRError.recognitionFailed
        }
    }
}

extension ScanViewModel {

    /// DEBUG launch composition: fixture VM when requested, otherwise
    /// the production real-AVFoundation VM. Release builds call the
    /// real initializer directly (this extension does not exist there).
    static func configuredForDebugLaunch() -> ScanViewModel {
        DebugCameraEnvironment.makeViewModelIfRequested() ?? ScanViewModel()
    }
}

#endif
