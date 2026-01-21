// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@globalActor public actor NetworkingKitActor {
    public static let shared = NetworkingKitActor()
}

public protocol NetworkingKitCodable: NetworkingKitEncodable, NetworkingKitDecodable, Sendable {}
public protocol NetworkingKitEncodable: Encodable, Sendable {}
public protocol NetworkingKitDecodable: Decodable, Sendable {}

@NetworkingKitActor
public protocol NetworkRouterDelegate: AnyObject {
    func intercept(_ request: inout URLRequest)
    func shouldRetry(error: Error, attempts: Int) async throws -> Bool
}

/// Describes the implementation details of a NetworkRouter
///
/// ``NetworkRouter`` is the only implementation of this protocol available to the end user, but they can create their own
/// implementations that can be used for testing for instance.
@NetworkingKitActor
protocol NetworkRouterProtocol: AnyObject {
    associatedtype Endpoint: EndpointType
    var delegate: NetworkRouterDelegate? { get set }
    func execute<T: Decodable>(_ route: Endpoint, attempts: Int, shouldThrowUnauthorized: Bool) async throws -> T
}

public enum NetworkError: Error, Sendable {
    case noAPIKey
    case encodingFailed
    case missingURL
    case statusCode(_ statusCode: StatusCode?, data: Data, request: URLRequest?)
    case noStatusCode
    case noData
    case tokenRefresh
    case badData
    case noBaseUrl
}

public typealias HTTPHeaders = [String: String]
