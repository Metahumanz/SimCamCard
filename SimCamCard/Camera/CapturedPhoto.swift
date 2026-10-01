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

/// One still capture from the camera pipeline.
nonisolated struct CapturedPhoto: Sendable, Equatable {

    /// Raw still-image bytes as delivered by
    /// `AVCapturePhoto.fileDataRepresentation()`, including EXIF
    /// orientation metadata. Never mutated, never stripped.
    let data: Data

    /// Capture timestamp (pipeline bookkeeping only; not user data).
    let capturedAt: Date

    init(data: Data, capturedAt: Date = Date()) {
        self.data = data
        self.capturedAt = capturedAt
    }
}
