//
//  OutsideExecution.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation
import Starknet

class OutsideExecution {

    static let OUTSIDE_EXECUTION_TYPE_SELECTOR = Felt(fromHex: "0x312b56c05a7965066ddbda31c016d8d05afc305071c0ca3cdc2192c3c2f1f0f")!
    static let CALL_TYPE_SELECTOR = Felt(fromHex: "0x3635c7f2a7ba93844c0d064e18e487f35ab90f7c39d00f186a781fc3f0c2ca9")!
    static let STARKNET_MESSAGE = Felt.fromShortString("StarkNet Message")!
    static let SN_MAIN_DOMAIN_HASH = Felt(fromHex: "0x9951e1d5316915dc4436acce0a48afd57bb4b6c501687c151e869ab878a2ac")!
    static let SN_SEPOLIA_DOMAIN_HASH = Felt(fromHex: "0x2534050c42890f9cad3cf470a8b54a39c4d283a246dfceb486a8755e44a91df")!
    static let ANY_CALLER = Felt.fromShortString("ANY_CALLER")!
    static let EXECUTE_AFTER = Felt.zero
    static let EXECUTE_BEFORE = Felt(clamping: 999_999_999_999)

    var nonce: Felt
    var calls: [StarknetCall]

    var calldata: [Felt] {
        [Self.ANY_CALLER, self.nonce, Self.EXECUTE_AFTER, Self.EXECUTE_BEFORE, Felt(clamping: self.calls.count)] +
        self.calls.flatMap { [$0.contractAddress, $0.entrypoint, Felt(clamping: $0.calldata.count)] + $0.calldata }
    }

    init(calls: [StarknetCall]) {
        self.calls = calls
        self.nonce = Felt(clamping: Int64(Date().timeIntervalSince1970))
    }

    func getMessageHash(forSigner address: Felt) -> Felt {
        let callsHash = StarknetPoseidon.poseidonHash(calls.map { call -> Felt in
            return StarknetPoseidon.poseidonHash([
                Self.CALL_TYPE_SELECTOR,
                call.contractAddress,
                call.entrypoint,
                StarknetPoseidon.poseidonHash(call.calldata),
            ])
        })

        let outsideExecutionHash = StarknetPoseidon.poseidonHash([
            Self.OUTSIDE_EXECUTION_TYPE_SELECTOR,
            Self.ANY_CALLER,
            self.nonce,
            Self.EXECUTE_AFTER,
            Self.EXECUTE_BEFORE,
            callsHash,
        ])

        return StarknetPoseidon.poseidonHash([
            Self.STARKNET_MESSAGE,
            Self.SN_SEPOLIA_DOMAIN_HASH,
            address,
            outsideExecutionHash,
        ])
    }
}
