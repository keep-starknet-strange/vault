//
//  P256Signer.swift
//  Vault
//
//  Created by Charles Lanier on 02/06/2024.
//

import Foundation
import Starknet

struct P256PublicKey {
    var x: Uint256
    var y: Uint256
}

class P256Signer: StarknetSignerProtocol {
    // mandatory to respect the protocol
    public let publicKey: Felt = Felt(fromHex: "0xdead")!

    private let secureEnclaveManager = SecureEnclaveManager()

    public func sign(transaction: any StarknetTransaction) throws -> StarknetSignature {
        try self.sign(transactionHash: transaction.hash!)
    }

    public func sign(transactionHash: Felt) throws -> StarknetSignature {
        let signature = try secureEnclaveManager.sign(hash: transactionHash)

        return [signature.r.low, signature.r.high, signature.s.low, signature.s.high]
    }

    public func sign(typedData: StarknetTypedData, accountAddress: Felt) throws -> StarknetSignature {
        let messageHash = try typedData.getMessageHash(accountAddress: accountAddress)

        return try self.sign(transactionHash: messageHash)
    }
}
