//
//  APIRequest.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

public enum HTTPMethod: String {
    case GET
    case POST
}

/// All requests must conform to this protocol
/// - Discussion: You must conform to Encodable too, so that all stored public parameters
///   of types conforming this protocol will be encoded as parameters.
public protocol APIRequest: Encodable {
    /// Response (will be wrapped with a DataContainer)
    associatedtype Response: Decodable

    /// Endpoint for this request (the last part of the URL)
    var resourceName: String { get }

    var httpMethod: HTTPMethod { get }

    var headers: [String: String] { get }
}

public extension APIRequest {

    var headers: [String: String] {
        return [:]
    }
}
