//
//  ExecuteFromOutside.swift
//  Vault
//
//  Created by Charles Lanier on 15/06/2024.
//

import Foundation
import Starknet

public struct ExecuteFromOutside: APIRequest {
    public typealias Response = Execution

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "execute_from_outside"
    }

    public var httpMethod: HTTPMethod {
        return .POST
    }

    public var headers: [String : String] {
        return ["Content-Type": "application/json"]
    }

    // Parameters
    public let address: String
    public let calldata: [String]

    public init(address: String, outsideExecution: OutsideExecution, signature: StarknetSignature) {
        let rawOutsideExecution = outsideExecution.calldata.map { String($0.value, radix: 10) }
        let rawSignautre = signature.map { String($0.value, radix: 10) }

        self.address = address
        self.calldata = rawOutsideExecution + [String(rawSignautre.count, radix: 10)] + rawSignautre
    }
}
