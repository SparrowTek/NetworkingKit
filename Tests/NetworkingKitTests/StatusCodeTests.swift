//
//  StatusCodeTests.swift
//  NetworkingKitTests
//

import Testing
@testable import NetworkingKit

@Suite("Status codes")
struct StatusCodeTests {
    @Test("Known codes map to their cases", arguments: zip(
        [200, 201, 204, 301, 304, 400, 401, 403, 404, 418, 429, 500, 502, 503, 511],
        [StatusCode.ok, .created, .noContent, .movedPermanently, .notModified, .badRequest, .unauthorized,
         .forbidden, .notFound, .imATeapot, .tooManyRequests, .internalServerError, .badGateway,
         .serviceUnavailable, .networkAuthenticationRequired]
    ))
    func knownCodesMap(raw: Int, expected: StatusCode) {
        #expect(StatusCode(rawValue: raw) == expected)
    }

    @Test("Codes outside the known set have no case", arguments: [104, 209, 227, 509, 512, 599])
    func unknownCodesHaveNoCase(raw: Int) {
        #expect(StatusCode(rawValue: raw) == nil)
    }
}

@Suite("HTTP methods")
struct HTTPMethodTests {
    @Test("Raw values match their HTTP verbs")
    func rawValuesMatchVerbs() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }
}
