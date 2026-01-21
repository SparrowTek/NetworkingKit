//
//  NetworkRouter.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

import Foundation

@NetworkingKitActor
public class NetworkRouter<Endpoint: EndpointType>: NetworkRouterProtocol {
    public weak var delegate: NetworkRouterDelegate?
    let networking: Networking
    let urlSessionTaskDelegate: URLSessionTaskDelegate?
    nonisolated let decoder: JSONDecoder

    public init(networking: Networking? = nil, urlSessionDelegate: URLSessionDelegate? = nil, urlSessionTaskDelegate: URLSessionTaskDelegate? = nil, decoder: JSONDecoder? = nil) {
        self.networking = if let networking {
            networking
        } else {
            URLSession(configuration: URLSessionConfiguration.default, delegate: urlSessionDelegate, delegateQueue: nil)
        }

        self.urlSessionTaskDelegate = urlSessionTaskDelegate

        if let decoder {
            self.decoder = decoder
        } else {
            self.decoder = JSONDecoder()
            self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        }
    }

    public func execute<T: Decodable & Sendable>(_ route: Endpoint, attempts: Int = 1, shouldThrowUnauthorized: Bool = true) async throws -> T {
        guard var request = try? await buildRequest(from: route) else { throw NetworkError.encodingFailed }
        delegate?.intercept(&request)
        return try await performRequest(request, attempts: attempts, shouldThrowUnauthorized: shouldThrowUnauthorized)
    }

    private func performRequest<T: Decodable & Sendable>(_ request: URLRequest, attempts: Int, shouldThrowUnauthorized: Bool) async throws -> T {
        let (data, response) = try await networking.data(for: request, delegate: urlSessionTaskDelegate)
//        prettyPrintJSON(from: data)

        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noStatusCode }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw NetworkError.statusCode(.unauthorized, data: data, request: request)
        default:
            let statusCode = StatusCode(rawValue: httpResponse.statusCode)
            let error = NetworkError.statusCode(statusCode, data: data, request: request)

            guard let delegate else { throw error }
            guard try await delegate.shouldRetry(error: error, attempts: attempts) else { throw error }
            return try await performRequest(request, attempts: attempts + 1, shouldThrowUnauthorized: shouldThrowUnauthorized)
        }
    }

    func buildRequest(from route: Endpoint) async throws -> URLRequest {
        guard let baseURL = route.baseURL else { throw NetworkError.noBaseUrl }
        return try buildRequest(from: route, using: baseURL)
    }
    
    private func buildRequest(from route: Endpoint, using baseURL: URL) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(route.path), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        request.httpMethod = route.httpMethod.rawValue

        switch route.task {
        case .request:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            addAdditionalHeaders(route.headers, request: &request)
        case .requestParameters(let parameterEncoding):
            addAdditionalHeaders(route.headers, request: &request)
            try configureParameters(parameterEncoding: parameterEncoding, request: &request)
        }

        return request
    }

    private func configureParameters(parameterEncoding: ParameterEncoding, request: inout URLRequest) throws {
        try parameterEncoding.encode(urlRequest: &request)
    }

    private func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let additionalHeaders else { return }
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func prettyPrintJSON(from data: Data) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            print("Failed to pretty print data")
            return
        }
        print(prettyString)
    }
}
