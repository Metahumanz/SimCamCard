//
//  PhoneNumberTests.swift
//  SimCamCardTests
//
//  Unit tests for PhoneNumber domain value.
//  Spec source: spec/data-model.md §Multi-value observation
//  ("phones[] with kind = mobile / office / fax / other").
//

import Testing
import Foundation
@testable import SimCamCard

@Suite("PhoneNumber")
struct PhoneNumberTests {

    @Test("Kind enum covers mobile / office / fax / other")
    func kindEnumCoversAllSpecKinds() throws {
        let kinds = Set(PhoneNumber.Kind.allCases.map(\.rawValue))
        #expect(kinds == ["mobile", "office", "fax", "other"])
    }

    @Test("init assigns kind and value")
    func initAssignsKindAndValue() throws {
        let phone = PhoneNumber(kind: .mobile, value: "+86 138 0013 8000")
        #expect(phone.kind == .mobile)
        #expect(phone.value == "+86 138 0013 8000")
    }

    @Test("two phones with same kind and value have different ids")
    func twoPhonesWithSameKindAndValueHaveDifferentIds() throws {
        let a = PhoneNumber(kind: .mobile, value: "123")
        let b = PhoneNumber(kind: .mobile, value: "123")
        #expect(a.id != b.id)
        #expect(a != b) // Hashable includes id; not a value-object
    }

    @Test("two phones with identical id, kind, value are equal")
    func identicalPhonesAreEqual() throws {
        let id = UUID()
        let a = PhoneNumber(id: id, kind: .office, value: "555")
        let b = PhoneNumber(id: id, kind: .office, value: "555")
        #expect(a == b)
    }

    @Test("explicit id is preserved")
    func explicitIdIsPreserved() throws {
        let id = UUID()
        let phone = PhoneNumber(id: id, kind: .fax, value: "+86 574 8790 3329")
        #expect(phone.id == id)
    }
}
