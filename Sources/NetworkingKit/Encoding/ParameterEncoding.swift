//
//  ParameterEncoding.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias Parameters = [String: any Sendable]

public protocol ParameterEncoder {
    func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

@NetworkingKitActor
public enum ParameterEncoding: Sendable {

    case urlEncoding(parameters: Parameters)
    /// Appends the items to the query string in the order given, percent-escaping
    /// names and values per RFC 3986. A name may repeat, which is how XRPC and most
    /// Go and Rust servers expect an array (`repos=a&repos=b`); a `nil` value
    /// writes the bare name. Nothing is reordered or rewritten, so a Boolean goes
    /// out exactly as the caller spelled it.
    case urlQueryItemsEncoding(queryItems: [URLQueryItem])
    case jsonEncoding(parameters: Parameters)
    case jsonDataEncoding(data: Data)
    case jsonEncodableEncoding(encodable: NetworkingKitEncodable)
    case urlAndJsonEncoding(urlParameters: Parameters, bodyParameters: Parameters)

    public func encode(urlRequest: inout URLRequest) throws {
        do {
            switch self {
            case .urlEncoding(let parameters):
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: parameters)
            case .urlQueryItemsEncoding(let queryItems):
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: queryItems)
            case .jsonEncoding(let parameters):
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: parameters)
            case .jsonDataEncoding(let data):
                JSONParameterEncoder().encode(urlRequest: &urlRequest, with: data)
            case .jsonEncodableEncoding(let encodable):
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: encodable)
            case .urlAndJsonEncoding(let urlParameters, let bodyParameters):
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
            }
        } catch {
            throw NetworkError.encodingFailed
        }
    }
}
