//
//  JSONParameterEncoderTests.swift
//  NetworkingKitTests
//

import Foundation
import Testing
@testable import NetworkingKit

@Suite("JSON parameter encoding")
struct JSONParameterEncoderTests {
    @Test("Dictionary parameters serialize into the body with a JSON content type")
    func parametersSerializeIntoBody() throws {
        var request = URLRequest(url: try requestURL())
        try JSONParameterEncoder().encode(urlRequest: &request, with: ["name": "perch"])

        let body = try #require(request.httpBody)
        let decoded = try JSONDecoder().decode([String: String].self, from: body)
        #expect(decoded == ["name": "perch"])
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Encodable bodies round-trip through the encoder")
    func encodableRoundTrips() throws {
        var request = URLRequest(url: try requestURL())
        try JSONParameterEncoder().encode(urlRequest: &request, with: TestBody(sender: "SP0"))

        let body = try #require(request.httpBody)
        let decoded = try JSONDecoder().decode(TestBody.self, from: body)
        #expect(decoded == TestBody(sender: "SP0"))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Raw data bodies pass through verbatim")
    func rawDataPassesThrough() throws {
        var request = URLRequest(url: try requestURL())
        let payload = Data([0x00, 0x01, 0x02])
        JSONParameterEncoder().encode(urlRequest: &request, with: payload)

        #expect(request.httpBody == payload)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("An existing Content-Type header wins over the JSON default")
    func existingContentTypeWins() throws {
        var request = URLRequest(url: try requestURL())
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        JSONParameterEncoder().encode(urlRequest: &request, with: Data([0x2A]))

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")
    }

    @Test("A throwing Encodable surfaces as encodingFailed")
    func throwingEncodableFails() throws {
        var request = URLRequest(url: try requestURL())

        do {
            try JSONParameterEncoder().encode(urlRequest: &request, with: FailingBody())
            Issue.record("Expected NetworkError.encodingFailed")
        } catch NetworkError.encodingFailed {}
    }
}
