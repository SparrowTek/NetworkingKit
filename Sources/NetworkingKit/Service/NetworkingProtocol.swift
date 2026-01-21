//
//  NetworkingProtocol.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

@preconcurrency import Foundation

@NetworkingKitActor
public protocol Networking {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)

    nonisolated
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask

    nonisolated
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask
}

extension URLSession: Networking { }
