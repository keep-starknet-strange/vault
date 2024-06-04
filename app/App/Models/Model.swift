//
//  Model.swift
//  Vault
//
//  Created by Charles Lanier on 11/04/2024.
//

import Foundation
import PhoneNumberKit
import Contacts
import SwiftUI
import Starknet
import BigInt

// Aggregate Model
@MainActor
class Model: ObservableObject {

    @AppStorage("starknetMainAddress") private var address: String = ""

    // App
    @Published var isLoading = false

    // Sending USDC
    @Published var recipientPhoneNumber: String?

    // Country picker
    @Published var selectedRegionCode = Locale.current.regionOrFrance.identifier
    @Published var searchedCountry = ""

    // Contacts
    @Published var contacts: [Contact] = []
    @Published var contactsAuthorizationStatus: CNAuthorizationStatus = .notDetermined

    private var updatesHandler: Task<Void, Error>? = nil

    private var vaultService: VaultService

    private var contactStore = CNContactStore()

    private let phoneNumberKit = PhoneNumberKit()
    private lazy var countries: [CountryData] = {
        phoneNumberKit.allCountries()
            .map { regionCode in
                return self.countryData(forRegionCode: regionCode)
            }
            .filter { $0.name != "world" }
            .sorted { $0.name < $1.name }
    }()

    private lazy var provider: StarknetProviderProtocol = StarknetProvider(url: "https://rpc.nethermind.io/sepolia-juno/?apikey=\(Constants.starknetRpcApiKey)")!

    private lazy var account: StarknetAccountProtocol = {
        return StarknetAccount(
            address: Felt(stringLiteral: self.address),
            signer: P256Signer(),
            provider: self.provider,
            chainId: .sepolia,
            cairoVersion: .one
        )
    }()

    init(vaultService: VaultService) {
        // Vault API
        self.vaultService = vaultService

        // Contacts
        checkContactsAuthorizationStatus()

        self.address = "0x014DfAEE92F238254e3eb3621ADcC6323C5eCde6F2417980D56eaEc7ee23Cc2d"
    }

    deinit {
        updatesHandler?.cancel()
    }
}

// MARK: - Vault API

extension Model {

    func startRegistration(phoneNumber: PhoneNumber, completion: @escaping (Result<Void, Error>) -> Void) {
        self.isLoading = true

        vaultService.getOTP(phoneNumber: phoneNumber.rawString()) { result in
            self.isLoading = false
            completion(result)
        }
    }

    func confirmRegistration(
        phoneNumber: PhoneNumber,
        otp: String,
        publicKeyX: String,
        publicKeyY: String,
        completion: @escaping (Result<String, Error>
        ) -> Void) {
        self.isLoading = true

        vaultService.verifyOTP(
            phoneNumber: phoneNumber.rawString(),
            otp: otp,
            publicKeyX: publicKeyX,
            publicKeyY: publicKeyY
        ) { result in
            self.isLoading = false
            completion(result)
        }
    }
}


// MARK: - Country picker

extension Model {

    var selectedCountryData: CountryData {
        return self.countryData(forRegionCode: self.selectedRegionCode)
    }

    var filteredCountries: [CountryData] {
        if self.searchedCountry.isEmpty {
            return self.countries
        } else {
            return self.countries.filter { $0.name.lowercased().contains(self.searchedCountry.lowercased()) }
        }
    }

    private var partialFormatter: PartialFormatter {
        PartialFormatter(
            phoneNumberKit: self.phoneNumberKit,
            defaultRegion: self.selectedRegionCode,
            withPrefix: false,
            ignoreIntlNumbers: true
        )
    }

    func isSelected(_ regionCode: String) -> Bool {
        return self.selectedRegionCode == regionCode
    }

    func format(phoneNumber: String) -> String {
        return self.partialFormatter.formatPartial(phoneNumber)
    }

    func parse(phoneNumber: String) -> PhoneNumber? {
        do {
            return try phoneNumberKit.parse(phoneNumber, withRegion: self.selectedRegionCode, ignoreType: true)
        } catch {
            return nil
        }
    }
}

// MARK: - Starknet

extension Model {

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

        do {
            let nonce = try await self.account.getNonce()
            let maxFee = try await self.estimateFees(calls: [call], nonce: nonce)
            let result = try await account.executeV1(call: call, params: StarknetOptionalInvokeParamsV1(nonce: nonce, maxFee: maxFee))

            #if DEBUG
            print("tx: \(result.transactionHash)")
            #endif
        } catch let error {
            print(error)
        }
    }

    func estimateFees(calls: [StarknetCall], nonce: Felt) async throws -> Felt {
        let calldata = starknetCallsToExecuteCalldata(calls: calls, cairoVersion: .one)
        let transaction = StarknetInvokeTransactionV1(
            senderAddress: self.account.address,
            calldata: calldata,
            signature: [],
            maxFee: .zero,
            nonce: nonce,
            forFeeEstimation: true
        )

        return try await self.provider.estimateFee(for: transaction, simulationFlags: [.skipValidate]).toMaxFee(multiplier: 2)
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

// MARK: - Contacts

extension Model {

    public func checkContactsAuthorizationStatus() {
        self.contactsAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

        switch self.contactsAuthorizationStatus {
        case .notDetermined, .denied, .restricted:
            break

        case .authorized:
            self.fetchContacts()

        @unknown default:
            fatalError("Unknown authorization status")
        }
    }

    public func requestContactsAccess() {
        if self.contactsAuthorizationStatus == .denied {
            self.openSettings()
        } else if self.contactsAuthorizationStatus == .notDetermined {
            contactStore.requestAccess(for: .contacts) { [weak self] (granted, error) in
                DispatchQueue.main.async {
                    if granted {
                        self?.contactsAuthorizationStatus = .authorized
                        self?.fetchContacts()
                    } else {
                        self?.contactsAuthorizationStatus = .denied
                        // TODO: Handle the case where permission is denied
                        print("Permission denied")
                    }
                }
            }
        }
    }

    func addContact(name: String, phone: String, completionHandler: @escaping (Contact) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newContact = CNMutableContact()
            let nameComponents = name.split(separator: " ")

            if let firstName = nameComponents.first {
                newContact.givenName = String(firstName)
            }

            if nameComponents.count > 1 {
                newContact.familyName = nameComponents.dropFirst().joined(separator: " ")
            }

            let phoneValue = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone))
            newContact.phoneNumbers = [phoneValue]

            let saveRequest = CNSaveRequest()
            saveRequest.add(newContact, toContainerWithIdentifier: nil)

            do {
                try self?.contactStore.execute(saveRequest)

                DispatchQueue.main.async {
                    self?.fetchContacts() // Refresh the contacts list
                    completionHandler(Contact(name: name, phone: phone))
                }
            } catch {
                print("Failed to save contact: \(error)")
                // TODO: Handle this case
            }
        }
    }
}

// MARK: - Sending Logic

extension Model {

    func setPhoneNumber(_ phoneNumber: String) {
        self.recipientPhoneNumber = phoneNumber
    }
}

// MARK: - Private Logic

extension Model {

    private func countryData(forRegionCode regionCode: String) -> CountryData {
        let countryName = Locale.current.localizedString(forRegionCode: regionCode)  ?? "world"
        let phoneCode = phoneNumberKit.countryCode(for: regionCode) ?? 0

        return CountryData(
            regionCode: regionCode,
            phoneCode: "+\(phoneCode)",
            name: countryName
        )
    }

    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func fetchContacts() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let request = CNContactFetchRequest(
                keysToFetch: [
                    CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactPhoneNumbersKey,
                    CNContactImageDataKey,
                ] as [CNKeyDescriptor]
            )
            request.sortOrder = CNContactSortOrder.givenName

            var contacts: [Contact] = []

            do {
                try self?.contactStore.enumerateContacts(with: request) { (cnContact, stop) in
                    let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
                    let imageData = cnContact.imageData

                    // Phone
                    let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue ?? ""

                    // Only add contacts with a name AND a phone number
                    if !name.isEmpty && phoneNumber.hasPrefix("+") {
                        let contact = Contact(name: name, phone: phoneNumber, imageData: imageData)
                        contacts.append(contact)
                    }
                }

                DispatchQueue.main.async {
                    self?.contacts = contacts
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }
}

// 0x2334fc9b4a819bba25a30049b77f0b70, 0x9e46dd8c93845f498cf2d7ba56dffdac, 0x94d7ee023f38c2806c7e481c7ba8a86f, 0x2223df297537543c658505ccf5c21500

// 0x3f10e3271c59e25cec85e5745da7c29d, 0xbc20ce5c846a01abda56dbab1c7c7cb8, 0xe9cfb575d16a256c551860e0f0619123, 0x8970ea31c4d2417ed69bc51d2548e219
