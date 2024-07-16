//
//  BodyParamsEncoder.swift
//  Vault
//
//  Created by Charles Lanier on 16/06/2024.
//

import Foundation

enum BodyParamsEncoder {
    static func encode<T: Encodable>(_ encodable: T) throws -> Data {
        let parametersData = try JSONEncoder().encode(encodable)
//        let parameters = try JSONDecoder().decode([String: HTTPParameter].self, from: parametersData)
//        let body = parameters.reduce(into: [:] as [String: Any]) { acc, param in
//            acc[param.key] = param.value.description
//        }
//        // Convert the dictionary into JSON data
//        return try! JSONSerialization.data(withJSONObject: body, options: [])
        return parametersData
    }
}
