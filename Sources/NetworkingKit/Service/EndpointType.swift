//
//  EndpointType.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

import Foundation

@NetworkingKitActor
public protocol EndpointType: Sendable {
    var baseURL: URL? { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: HTTPHeaders? { get }
}

extension EndpointType {
    /// Combines `baseURL` + `path` into a single URL (if valid).
    var fullURL: URL? {
        guard let base = baseURL else { return nil }
        return base.appendingPathComponent(path)
    }
}

public protocol SynchronousEndpointType: Sendable {
    var baseURL: URL? { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var task: SynchronousHTTPTask { get }
    var headers: HTTPHeaders? { get }
}

extension SynchronousEndpointType {
    /// Combines `baseURL` + `path` into a single URL (if valid).
    var fullURL: URL? {
        guard let base = baseURL else { return nil }
        return base.appendingPathComponent(path)
    }
}
