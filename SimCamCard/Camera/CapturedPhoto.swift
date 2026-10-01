//
//  CapturedPhoto.swift
//  SimCamCard
//
//  Camera pipeline transport value (Week 3 Increment 2 — T04 still
//  capture).
//
//  This is a CAMERA PIPELINE TRANSPORT VALUE, not a Domain Model:
//  it carries the raw bytes of one still capture from the camera
//  service to the Scanner UI state, and onward (in later increments)
//  to the Detection/Crop/OCR pipeline.
//
//  Deliberately minimal — do NOT add OCR text, detected rectangles,
//  structured fields, BusinessCard IDs, tags or notes here.
//
//  The source of truth is the raw `Data` (the AVFoundation
//  fileDataRepresentation, including its EXIF orientation metadata —
//  orientation is NEVER stripped). UIImage/UIImageView may appear
//  only as transient View-layer rendering adapters; they are never
//  stored in this value, the ViewModel or the Domain.
//

import Foundation

/// Origin of the bytes carried by a `CapturedPhoto`. Both camera
/// capture and photo-library import feed the SAME downstream
/// Detection/Crop input contract (Increment 4+); the source tag only
/// records where the bytes came from and must not be used to maintain
/// two parallel pipeline input structures.
nonisolated enum ImageSource: Sendable, Equatable {
    /// Bytes produced by a camera still capture (`AVCapturePhoto`).
    case camera
    /// Bytes loaded from a user-selected photo library asset
    /// (`PhotosPicker` selected-photo path).
    case photoLibrary
}

/// One image entering the scanner pipeline.
///
/// This is the unified transport value for BOTH camera capture
/// (Increment 2) and photo-library import (Increment 3): both paths
/// converge here so Increment 4's Detection/Crop consumes a single
/// input type. It is NOT a Domain Model — no OCR text, detected
/// rectangles, structured fields, BusinessCard IDs, tags or notes.
///
/// The source of truth is the raw `Data`. For camera captures this is
/// `AVCapturePhoto.fileDataRepresentation()` (EXIF orientation
/// metadata preserved, never stripped). For photo imports this is the
/// bytes loaded from the selected `PhotosPickerItem` (original bytes
/// preserved where possible).
nonisolated struct CapturedPhoto: Sendable, Equatable {

    /// Raw image bytes. Source of truth; never mutated, never stripped
    /// of orientation metadata.
    let data: Data

    /// Capture/import timestamp (pipeline bookkeeping only; not user
    /// data).
    let capturedAt: Date

    /// Where the bytes came from. Camera path defaults to `.camera`;
    /// photo-import path sets `.photoLibrary`.
    let source: ImageSource

    init(data: Data, capturedAt: Date = Date(), source: ImageSource = .camera) {
        self.data = data
        self.capturedAt = capturedAt
        self.source = source
    }
}
