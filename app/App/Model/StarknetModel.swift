//
//  StarknetModel.swift
//  Vault
//
//  Created by Charles Lanier on 02/06/2024.
//

import SwiftUI
import Starknet
import BigInt

class StarknetModel: ObservableObject {

    @AppStorage("starknetMainAddress") private var address: String = "0x014DfAEE92F238254e3eb3621ADcC6323C5eCde6F2417980D56eaEc7ee23Cc2d"

    private lazy var account: StarknetAccountProtocol = {
        let provider = StarknetProvider(url: "https://rpc.nethermind.io/sepolia-juno/?apikey=\(Constants.starknetRpcApiKey)")!

        return StarknetAccount(
            address: Felt(stringLiteral: self.address),
            signer: P256Signer(),
            provider: provider,
            chainId: .sepolia,
            cairoVersion: .one
        )
    }()

    func sendUSDC(to phoneNumber: String) async throws {
        guard let recipientAddress = self.getAddress(from: phoneNumber) else {
            return
        }

        let calldata: [Felt] = [
            recipientAddress,
            1000,
            0,
        ]

        let call = StarknetCall(
            contractAddress: Constants.Starknet.usdcAddress,
            entrypoint: starknetSelector(from: "transfer"),
            calldata: calldata
        )

        let result = try await account.executeV1(call: call)

        #if DEBUG
        print("tx: \(result.transactionHash)")
        #endif
    }

    func getAddress(from phoneNumber: String) -> Felt? {
        guard let phoneNumberFelt = Felt.fromShortString(phoneNumber) else {
            return nil
        }
        let phoneNumberHex = phoneNumberFelt.toHex().dropFirst(2)
        guard let phoneNumberBytes = BigUInt(phoneNumberHex, radix: 16)?.serialize().bytes else {
            return nil
        }

        return StarknetContractAddressCalculator.calculateFrom(
            classHash: Constants.Starknet.blankAccountClassHash,
            calldata: [],
            salt: starknetKeccak(on: phoneNumberBytes),
            deployerAddress: Constants.Starknet.vaultFactoryAddress
        )
    }
}
