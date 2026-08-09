//
//  NetworkRouterTests.swift
//  NetworkingKitTests
//

import Foundation
import Testing
@testable import NetworkingKit

@Suite("Network router")
@NetworkingKitActor
struct NetworkRouterTests {
    // MARK: Request building

    @Test("Plain requests join the URL and carry a JSON content type")
    func buildsPlainRequests() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let payload: TestPayload = try await router.execute(.plain)

        #expect(payload == TestPayload(userName: "perch"))
        let request = try #require(stub.requests.first)
        #expect(request.url?.absoluteString == "https://api.example.com/status")
        #expect(request.httpMethod == "GET")
        #expect(request.timeoutInterval == 30)
        #expect(request.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("Route headers override the plain request's JSON default")
    func routeHeadersOverridePlainDefault() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let _: TestPayload = try await router.execute(.customContentType)

        let request = try #require(stub.requests.first)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
    }

    @Test("Query parameter requests go out with a bare GET")
    func queryParametersProduceBareGET() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let _: TestPayload = try await router.execute(.query)

        let request = try #require(stub.requests.first)
        #expect(request.url?.absoluteString == "https://api.example.com/search?page=1")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == nil)
        #expect(request.httpBody == nil)
    }

    @Test("Encodable bodies post as labeled JSON")
    func jsonBodiesPostAsLabeledJSON() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let _: TestPayload = try await router.execute(.jsonBody(TestBody(sender: "SP0")))

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        #expect(try JSONDecoder().decode(TestBody.self, from: body) == TestBody(sender: "SP0"))
    }

    @Test("Route headers survive body encoding")
    func routeHeadersSurviveBodyEncoding() async throws {
        let transaction = Data([0x00, 0x01, 0x02])
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let _: TestPayload = try await router.execute(.broadcast(transaction))

        let request = try #require(stub.requests.first)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")
        #expect(request.httpBody == transaction)
    }

    // MARK: Decoding

    @Test("The default decoder converts snake_case keys")
    func defaultDecoderConvertsSnakeCase() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let payload: TestPayload = try await router.execute(.plain)

        #expect(payload == TestPayload(userName: "perch"))
    }

    @Test("A custom decoder replaces the default")
    func customDecoderIsRespected() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: Data(#"{"userName":"perch"}"#.utf8))
        let router = NetworkRouter<TestAPI>(networking: stub, decoder: JSONDecoder())

        let payload: TestPayload = try await router.execute(.plain)

        #expect(payload == TestPayload(userName: "perch"))
    }

    @Test("executeWithResponse also returns the HTTP response")
    func executeWithResponseReturnsTheResponse() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)

        let (payload, response): (TestPayload, HTTPURLResponse) = try await router.executeWithResponse(.plain)

        #expect(payload == TestPayload(userName: "perch"))
        #expect(response.statusCode == 200)
    }

    @Test("An undecodable success body throws a DecodingError")
    func undecodableBodyThrowsDecodingError() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: Data("not json".utf8))
        let router = NetworkRouter<TestAPI>(networking: stub)

        await #expect(throws: DecodingError.self) {
            let _: TestPayload = try await router.execute(.plain)
        }
    }

    // MARK: Failures

    @Test("Error statuses throw with the code, body, and request attached")
    func errorStatusCarriesCodeBodyAndRequest() async throws {
        let stub = try NetworkingStub.replying(status: 404, body: Data("missing".utf8))
        let router = NetworkRouter<TestAPI>(networking: stub)

        do {
            let _: TestPayload = try await router.execute(.plain)
            Issue.record("Expected NetworkError.statusCode")
        } catch let error as NetworkError {
            guard case .statusCode(let code, let data, let request) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(code == .notFound)
            #expect(String(decoding: data, as: UTF8.self) == "missing")
            #expect(request?.url?.absoluteString == "https://api.example.com/status")
        }
    }

    @Test("Statuses outside the known set surface a nil status code")
    func unknownStatusCodesSurfaceNil() async throws {
        let stub = try NetworkingStub.replying(status: 599)
        let router = NetworkRouter<TestAPI>(networking: stub)

        do {
            let _: TestPayload = try await router.execute(.plain)
            Issue.record("Expected NetworkError.statusCode")
        } catch let error as NetworkError {
            guard case .statusCode(let code, _, _) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(code == nil)
        }
    }

    @Test("A non-HTTP response throws noStatusCode")
    func nonHTTPResponseThrowsNoStatusCode() async throws {
        let url = try requestURL()
        let plainResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let stub = NetworkingStub(replies: [.success(Data(), plainResponse)])
        let router = NetworkRouter<TestAPI>(networking: stub)

        do {
            let _: TestPayload = try await router.execute(.plain)
            Issue.record("Expected NetworkError.noStatusCode")
        } catch NetworkError.noStatusCode {}
    }

    @Test("A route without a base URL fails to build")
    func missingBaseURLFailsToBuild() async throws {
        let stub = NetworkingStub(replies: [])
        let router = NetworkRouter<TestAPI>(networking: stub)

        do {
            let _: TestPayload = try await router.execute(.missingBase)
            Issue.record("Expected NetworkError.encodingFailed")
        } catch NetworkError.encodingFailed {}

        #expect(stub.requests.isEmpty)
    }

    @Test("Transport errors propagate unwrapped")
    func transportErrorsPropagate() async throws {
        let stub = NetworkingStub(replies: [.failure(URLError(.notConnectedToInternet))])
        let router = NetworkRouter<TestAPI>(networking: stub)

        do {
            let _: TestPayload = try await router.execute(.plain)
            Issue.record("Expected URLError")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }

    // MARK: Delegate

    @Test("The delegate intercepts the request before it is sent")
    func delegateInterceptsBeforeSending() async throws {
        let stub = try NetworkingStub.replying(status: 200, body: userPayloadJSON)
        let router = NetworkRouter<TestAPI>(networking: stub)
        let delegate = SpyDelegate()
        delegate.headerToInject = (field: "Authorization", value: "Bearer token")
        router.delegate = delegate

        let _: TestPayload = try await router.execute(.plain)

        #expect(delegate.interceptCount == 1)
        let request = try #require(stub.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
    }

    @Test("Failed requests retry when the delegate allows it")
    func failedRequestsRetryWhenAllowed() async throws {
        let stub = NetworkingStub(replies: [
            .success(Data("boom".utf8), try httpResponse(status: 500)),
            .success(userPayloadJSON, try httpResponse(status: 200)),
        ])
        let router = NetworkRouter<TestAPI>(networking: stub)
        let delegate = SpyDelegate()
        delegate.maxAttempts = 2
        router.delegate = delegate

        let payload: TestPayload = try await router.execute(.plain)

        #expect(payload == TestPayload(userName: "perch"))
        #expect(stub.requests.count == 2)
        #expect(delegate.retryAttempts == [1])
        #expect(delegate.interceptCount == 2)
        #expect(delegate.errorResponses.map(\.statusCode) == [500])
    }

    @Test("Retries stop when the delegate declines")
    func retriesStopWhenDeclined() async throws {
        let stub = try NetworkingStub.replying(status: 500, body: Data("boom".utf8))
        let router = NetworkRouter<TestAPI>(networking: stub)
        let delegate = SpyDelegate()
        router.delegate = delegate

        do {
            let _: TestPayload = try await router.execute(.plain)
            Issue.record("Expected NetworkError.statusCode")
        } catch let error as NetworkError {
            guard case .statusCode(let code, _, _) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(code == .internalServerError)
        }

        #expect(stub.requests.count == 1)
        #expect(delegate.retryAttempts == [1])
        #expect(delegate.errorResponses.map(\.statusCode) == [500])
    }
}
