//
//  ParameterEncodingTests.swift
//  NetworkingKitTests
//

import Foundation
import Testing
@testable import NetworkingKit

@Suite("Parameter encoding dispatch")
@NetworkingKitActor
struct ParameterEncodingTests {
    @Test("URL encoding fills the query and nothing else")
    func urlEncoding() throws {
        var request = URLRequest(url: try requestURL())
        try ParameterEncoding.urlEncoding(parameters: ["proof": "0"]).encode(urlRequest: &request)

        #expect(encodedQuery(of: request) == "proof=0")
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    @Test("JSON encoding writes a labeled body")
    func jsonEncoding() throws {
        var request = URLRequest(url: try requestURL())
        try ParameterEncoding.jsonEncoding(parameters: ["name": "perch"]).encode(urlRequest: &request)

        let body = try #require(request.httpBody)
        let decoded = try JSONDecoder().decode([String: String].self, from: body)
        #expect(decoded == ["name": "perch"])
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("JSON data encoding forwards the body verbatim")
    func jsonDataEncoding() throws {
        var request = URLRequest(url: try requestURL())
        let payload = Data([0xDE, 0xAD])
        try ParameterEncoding.jsonDataEncoding(data: payload).encode(urlRequest: &request)

        #expect(request.httpBody == payload)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Encodable encoding writes the encoded body")
    func jsonEncodableEncoding() throws {
        var request = URLRequest(url: try requestURL())
        try ParameterEncoding.jsonEncodableEncoding(encodable: TestBody(sender: "SP0")).encode(urlRequest: &request)

        let body = try #require(request.httpBody)
        let decoded = try JSONDecoder().decode(TestBody.self, from: body)
        #expect(decoded == TestBody(sender: "SP0"))
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Combined URL and JSON encoding labels the body as JSON")
    func urlAndJsonEncodingKeepsJSONContentType() throws {
        var request = URLRequest(url: try requestURL())
        try ParameterEncoding
            .urlAndJsonEncoding(urlParameters: ["proof": "0"], bodyParameters: ["sender": "SP0"])
            .encode(urlRequest: &request)

        #expect(encodedQuery(of: request) == "proof=0")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody != nil)
    }

    @Test("Failures inside an encoder surface as encodingFailed")
    func failuresBecomeEncodingFailed() throws {
        var request = URLRequest(url: try requestURL())

        do {
            try ParameterEncoding.jsonEncodableEncoding(encodable: FailingBody()).encode(urlRequest: &request)
            Issue.record("Expected NetworkError.encodingFailed")
        } catch NetworkError.encodingFailed {}
    }
}
