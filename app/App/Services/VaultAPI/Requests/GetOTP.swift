//
//  GetOTP.swift
//  Vault
//
//  Created by Charles Lanier on 17/06/2024.
//

import Foundation
import PhoneNumberKit

public struct GetOTP: APIRequest {
    public typealias Response = Empty

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "get_otp"
    }

    public var httpMethod: HTTPMethod {
        return .POST
    }

    public var headers: [String : String] {
        return ["Content-Type": "application/json"]
    }

    // Parameters
    public let phone_number: String
    public let nickname: String

    public init(phoneNumber: PhoneNumber, nickname: String) {
        self.phone_number = phoneNumber.rawString()
        self.nickname = nickname
    }
}
