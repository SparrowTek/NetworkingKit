//
//  CharacterSetTests.swift
//  NetworkingKitTests
//

import Foundation
import Testing
@testable import NetworkingKit

@Suite("RFC 3986 query character set")
struct CharacterSetTests {
    @Test("Reserved delimiters are excluded so they get percent-escaped")
    func reservedDelimitersAreExcluded() {
        for scalar in ":#[]@!$&'()*+,;=".unicodeScalars {
            #expect(!CharacterSet.urlQueryAllowedRFC3986.contains(scalar), "\(scalar) should be escaped")
        }
    }

    @Test("Question mark, slash, and unreserved characters pass through")
    func allowedCharactersPassThrough() {
        for scalar in "?/abcXYZ019-._~".unicodeScalars {
            #expect(CharacterSet.urlQueryAllowedRFC3986.contains(scalar), "\(scalar) should not be escaped")
        }
    }
}
