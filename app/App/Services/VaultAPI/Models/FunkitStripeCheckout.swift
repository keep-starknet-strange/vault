//
//  FunkitStripeCheckout.swift
//  Vault
//
//  Created by Charles Lanier on 03/07/2024.
//

import Foundation


public struct FunkitStripeCheckout: Decodable {
    public let stripeCheckoutId: String
    public let stripeRedirectUrl: String
    public let funkitDepositAddress: String
}


//"stripeCheckoutId": "cos_1PVjoJCLFtXbeHljSqENG8EX",
//"stripeRedirectUrl": "https://crypto.link.com?session_hash=CCwQARoXChVhY2N0XzFQMUM1aENMRnRYYmVIbGoo_8PtswYyBvLEArs-lzotpIVcOo5xRizqxo51f_a6heze3V8sZAGkN1KRsvkFrKnhSf084RfpQ4-Iws7u",
//"funkitDepositAddress": "0
