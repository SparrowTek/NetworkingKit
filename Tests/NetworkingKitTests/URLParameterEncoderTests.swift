//
//  URLParameterEncoderTests.swift
//  NetworkingKitTests
//

import Foundation
import Testing
@testable import NetworkingKit

@Suite("URL parameter encoding")
struct URLParameterEncoderTests {
    @Test("Parameters land in the query string without claiming a Content-Type")
    func queryEncodingSetsNoContentType() throws {
        var request = URLRequest(url: try requestURL())
        try URLParameterEncoder().encode(urlRequest: &request, with: ["proof": "0"])

        #expect(request.url?.query == "proof=0")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
        #expect(request.httpBody == nil)
    }

    @Test("An existing Content-Type header is left untouched")
    func existingContentTypeSurvives() throws {
        var request = URLRequest(url: try requestURL())
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try URLParameterEncoder().encode(urlRequest: &request, with: ["proof": "0"])

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Parameters append to an existing query in sorted key order")
    func parametersMergeWithExistingQuery() throws {
        var request = URLRequest(url: try requestURL(query: "tip=latest"))
        try URLParameterEncoder().encode(urlRequest: &request, with: ["b": "2", "a": "1"])

        #expect(request.url?.query == "tip=latest&a=1&b=2")
    }

    @Test("Reserved characters are percent-escaped per RFC 3986")
    func reservedCharactersAreEscaped() throws {
        var request = URLRequest(url: try requestURL())
        try URLParameterEncoder().encode(urlRequest: &request, with: ["q": "a b&c=d+e/f?g:h[i]@j"])

        #expect(encodedQuery(of: request) == "q=a%20b%26c%3Dd%2Be/f?g%3Ah%5Bi%5D%40j")
    }

    @Test("Arrays repeat the key with escaped brackets by default")
    func arraysUseBracketsByDefault() throws {
        var request = URLRequest(url: try requestURL())
        try URLParameterEncoder().encode(urlRequest: &request, with: ["ids": ["a", "b"]])

        #expect(encodedQuery(of: request) == "ids%5B%5D=a&ids%5B%5D=b")
    }

    @Test("Array encoding can drop brackets or index them")
    func arrayEncodingVariants() throws {
        var noBrackets = URLRequest(url: try requestURL())
        try URLParameterEncoder(arrayEncoding: .noBrackets).encode(urlRequest: &noBrackets, with: ["ids": ["a", "b"]])
        #expect(encodedQuery(of: noBrackets) == "ids=a&ids=b")

        var indexed = URLRequest(url: try requestURL())
        try URLParameterEncoder(arrayEncoding: .indexInBrackets).encode(urlRequest: &indexed, with: ["ids": ["a", "b"]])
        #expect(encodedQuery(of: indexed) == "ids%5B0%5D=a&ids%5B1%5D=b")
    }

    @Test("Bools encode numerically by default and literally on request")
    func boolEncodingVariants() throws {
        var numeric = URLRequest(url: try requestURL())
        try URLParameterEncoder().encode(urlRequest: &numeric, with: ["off": false, "on": true])
        #expect(encodedQuery(of: numeric) == "off=0&on=1")

        var literal = URLRequest(url: try requestURL())
        try URLParameterEncoder(boolEncoding: .literal).encode(urlRequest: &literal, with: ["off": false, "on": true])
        #expect(encodedQuery(of: literal) == "off=false&on=true")
    }

    @Test("Numbers keep their textual representation")
    func numbersEncodeAsThemselves() throws {
        var request = URLRequest(url: try requestURL())
        try URLParameterEncoder().encode(urlRequest: &request, with: ["count": 7, "ratio": 1.5])

        #expect(encodedQuery(of: request) == "count=7&ratio=1.5")
    }

    @Test("Nested dictionaries flatten into bracketed keys")
    func nestedDictionariesFlatten() throws {
        var request = URLRequest(url: try requestURL())
        try URLParameterEncoder().encode(urlRequest: &request, with: ["filter": ["name": "perch"]])

        #expect(encodedQuery(of: request) == "filter%5Bname%5D=perch")
    }

    @Test("A custom character set controls what gets escaped")
    func customCharacterSetIsHonored() throws {
        var request = URLRequest(url: try requestURL())
        try URLParameterEncoder(characterSet: .urlQueryAllowed).encode(urlRequest: &request, with: ["q": "a+b"])

        #expect(encodedQuery(of: request) == "q=a+b")
    }

    @Test("Empty parameters leave the URL untouched")
    func emptyParametersLeaveURLUntouched() throws {
        let url = try requestURL()
        var request = URLRequest(url: url)
        try URLParameterEncoder().encode(urlRequest: &request, with: [:])

        #expect(request.url == url)
    }

    @Test("A request without a URL throws missingURL")
    func missingURLThrows() throws {
        var request = URLRequest(url: try requestURL())
        request.url = nil

        do {
            try URLParameterEncoder().encode(urlRequest: &request, with: ["proof": "0"])
            Issue.record("Expected NetworkError.missingURL")
        } catch NetworkError.missingURL {}
    }
}
