//
//  Encodable.swift
//  NetworkingKit
//
//  Created by Thomas Rademaker on 1/21/26.
//

import Foundation

extension Encodable {
    func toJSONData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
