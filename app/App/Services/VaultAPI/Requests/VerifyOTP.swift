//
//  VerifyOTP.swift
//  Vault
//
//  Created by Charles Lanier on 17/06/2024.
//

import Foundation
import PhoneNumberKit

public struct VerifyOTP: APIRequest {
    public typealias Response = Deployment

    // Notice how we create a composed resourceName
    public var resourceName: String {
        return "verify_otp"
    }

    public var httpMethod: HTTPMethod {
        return .POST
    }

    public var headers: [String : String] {
        return ["Content-Type": "application/json"]
    }

    // Parameters
    public let phone_number: String
    public let sent_otp: String
    public let public_key_x: String
    public let public_key_y: String

    public init(phoneNumber: PhoneNumber, sentOTP: String, publicKey: P256PublicKey) {
        self.phone_number = phoneNumber.rawString()
        self.sent_otp = sentOTP
        self.public_key_x = publicKey.x.toHex()
        self.public_key_y = publicKey.y.toHex()
    }
}



