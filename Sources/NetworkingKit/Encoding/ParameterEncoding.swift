//
//  ParameterEncoding.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

import Foundation

public typealias Parameters = [String: any Sendable]

public protocol ParameterEncoder {
    func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

@NetworkingKitActor
public enum ParameterEncoding: Sendable {

    case urlEncoding(parameters: Parameters)
    case jsonEncoding(parameters: Parameters)
    case jsonDataEncoding(data: Data?)
    case jsonEncodableEncoding(encodable: NetworkingKitEncodable)
    case urlAndJsonEncoding(urlParameters: Parameters, bodyParameters: Parameters)

    public func encode(urlRequest: inout URLRequest) throws {
        do {
            switch self {
            case .urlEncoding(let parameters):
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: parameters)
            case .jsonEncoding(let parameters):
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: parameters)
            case .jsonDataEncoding(let data):
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: data)
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

public enum SynchronousParameterEncoding {

    case urlEncoding(parameters: Parameters)
    case jsonEncoding(parameters: Parameters)
    case jsonDataEncoding(data: Data?)
    case jsonEncodableEncoding(encodable: NetworkingKitEncodable)
    case urlAndJsonEncoding(urlParameters: Parameters, bodyParameters: Parameters)

    public func encode(urlRequest: inout URLRequest) throws {
        do {
            switch self {
            case .urlEncoding(let parameters):
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: parameters)
            case .jsonEncoding(let parameters):
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: parameters)
            case .jsonDataEncoding(let data):
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: data)
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
