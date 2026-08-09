//
//  TestSupport.swift
//  NetworkingKitTests
//

import Foundation
import Testing
@testable import NetworkingKit

// MARK: Shared helpers

/// A canned snake_case payload matching `TestPayload` under the router's default decoder.
let userPayloadJSON = Data(#"{"user_name":"perch"}"#.utf8)

func requestURL(query: String? = nil) throws -> URL {
    var components = try #require(URLComponents(string: "https://api.example.com/v2/accounts/SP0"))
    components.query = query
    return try #require(components.url)
}

func encodedQuery(of request: URLRequest) -> String? {
    guard let url = request.url else { return nil }
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery
}

func httpResponse(status: Int) throws -> HTTPURLResponse {
    let url = try requestURL()
    return try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
}

// MARK: Models

struct TestBody: NetworkingKitCodable, Equatable {
    let sender: String
}

struct TestPayload: NetworkingKitDecodable, Equatable {
    let userName: String
}

struct FailingBody: NetworkingKitEncodable {
    struct Failure: Error {}

    func encode(to encoder: any Encoder) throws {
        throw Failure()
    }
}

// MARK: Endpoint fixture

enum TestAPI {
    case plain
    case customContentType
    case query
    case jsonBody(TestBody)
    case broadcast(Data)
    case missingBase
}

extension TestAPI: EndpointType {
    var baseURL: URL? {
        get async {
            switch self {
            case .missingBase: nil
            default: URL(string: "https://api.example.com")
            }
        }
    }

    var path: String {
        switch self {
        case .plain, .missingBase: "/status"
        case .customContentType: "/text"
        case .query: "/search"
        case .jsonBody: "/submit"
        case .broadcast: "/broadcast"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .plain, .customContentType, .query, .missingBase: .get
        case .jsonBody, .broadcast: .post
        }
    }

    var task: HTTPTask {
        switch self {
        case .plain, .customContentType, .missingBase:
            .request
        case .query:
            .requestParameters(encoding: .urlEncoding(parameters: ["page": "1"]))
        case .jsonBody(let body):
            .requestParameters(encoding: .jsonEncodableEncoding(encodable: body))
        case .broadcast(let data):
            .requestParameters(encoding: .jsonDataEncoding(data: data))
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        case .customContentType: ["Content-Type": "text/plain"]
        case .broadcast: ["Content-Type": "application/octet-stream"]
        default: nil
        }
    }
}

// MARK: Networking stub

/// Serves scripted replies in order and records every request the router sends.
@NetworkingKitActor
final class NetworkingStub: Networking {
    enum Reply {
        case success(Data, URLResponse)
        case failure(any Error)
    }

    struct OutOfReplies: Error {}

    private(set) var requests: [URLRequest] = []
    private var replies: [Reply]

    init(replies: [Reply]) {
        self.replies = replies
    }

    static func replying(status: Int, body: Data = Data()) throws -> NetworkingStub {
        NetworkingStub(replies: [.success(body, try httpResponse(status: status))])
    }

    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !replies.isEmpty else { throw OutOfReplies() }
        switch replies.removeFirst() {
        case .success(let data, let response):
            return (data, response)
        case .failure(let error):
            throw error
        }
    }

    nonisolated func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        fatalError("Unused in tests")
    }

    nonisolated func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
        fatalError("Unused in tests")
    }
}

// MARK: Router delegate spy

/// Records delegate callbacks and optionally injects a header and a retry budget.
@NetworkingKitActor
final class SpyDelegate: NetworkRouterDelegate {
    var maxAttempts = 1
    var headerToInject: (field: String, value: String)?

    private(set) var interceptCount = 0
    private(set) var retryAttempts: [Int] = []
    private(set) var errorResponses: [HTTPURLResponse] = []

    func intercept(_ request: inout URLRequest) async {
        interceptCount += 1
        if let header = headerToInject {
            request.setValue(header.value, forHTTPHeaderField: header.field)
        }
    }

    func shouldRetry(error: any Error, attempts: Int) async throws -> Bool {
        retryAttempts.append(attempts)
        return attempts < maxAttempts
    }

    func didReceiveErrorResponse(_ response: HTTPURLResponse) async {
        errorResponses.append(response)
    }
}
