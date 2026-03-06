//
//  HTTPTask.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

public enum HTTPTask: Sendable {
    case request
    case requestParameters(encoding: ParameterEncoding)
}
