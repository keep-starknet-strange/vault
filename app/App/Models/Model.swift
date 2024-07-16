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

enum Status: Equatable {
    case none // TODO: find a better name
    case loading
    case signing
    case signed
    case success
    case error(String)
}

// Aggregate Model
@MainActor
class Model: ObservableObject {

    @AppStorage("starknetMainAddress") var address: String = ""
    @AppStorage("isOnboarded") var isOnboarded: Bool = false
    @AppStorage("surname") var surname: String = ""

    // App
    @Published var isLoading = false
    @Published var showMessage = false
    @Published var amount: String = ""

    // Onramp
    @Published var showOnrampView = false {
        didSet {
            if self.showOnrampView {
                self.initiateOnramp()
            }
        }
    }
    @Published var onRampQuoteId: String?
    @Published var onRampTotalUsd: String?
    @Published var estSubtotalUsd: Double = 0
    @Published var stripeRedirectUrl: URL? = nil

    // Sending USDC
    @Published var recipient: Recipient?
    @Published var sendingStatus: Status = .none
    @Published var showSendingView = false {
        didSet {
            if self.showSendingView {
                self.initiateTransfer()
            } else {
                self.dismissTransfer()
            }
        }
    }
    @Published var showSendingConfirmation = false
    @Published var pendingTransaction: Transaction? = nil

    // Requesting USDC
    @Published var showRequestingView = false {
        didSet {
            if self.showRequestingView {
                self.initiateRequest()
            }
        }
    }
    @Published var showRequestingConfirmation = false

    // Starknet
    @Published var outsideExecution: OutsideExecution?
    @Published var outsideExecutionSignature: StarknetSignature?

    // Country picker
    @Published var selectedRegionCode = Locale.current.regionOrFrance.identifier
    @Published var searchedCountry = ""

    // Contacts
    @Published var contacts: [Recipient] = []
    @Published var contactsMapping: [String: [Recipient]] = [:]
    @Published var contactsAuthorizationStatus: CNAuthorizationStatus = .notDetermined

    var parsedAmount: Double {
        // Replace the comma with a dot
        let amount = self.amount.replacingOccurrences(of: ",", with: ".")

        // Check if the string ends with a dot and append a zero if true
        // Convert the final string to a Float
        return Double(amount.hasSuffix(".") ? "\(amount)0" : amount) ?? 0
    }

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

    private lazy var signer = P256Signer()

    private var currentTask: Task<Void, Never>? {
        willSet {
            if let task = currentTask {
                if task.isCancelled { return }
                task.cancel()
                // Setting a new task cancelling the current task
            }
        }
    }

    init() {
        // Contacts
        self.checkContactsAuthorizationStatus()
    }
}

// MARK: - Vault API

extension Model {

    func startRegistration(phoneNumber: PhoneNumber, onSuccess: @escaping () -> Void) {
        self.isLoading = true

        VaultService.shared.send(GetOTP(phoneNumber: phoneNumber, nickname: self.surname)) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success:
                    onSuccess()

                case .failure(let error):
                    // TODO: Handle error
#if DEBUG
                    print(error)
#endif
                }
            }
        }
    }

    func confirmRegistration(
        phoneNumber: PhoneNumber,
        otp: String,
        onSuccess: @escaping () -> Void
    ) {
        do {
            guard let publicKey = try SecureEnclaveManager.shared.getOrGenerateKeyPair() else {
                throw "Failed to generate public key."
            }

            self.isLoading = true

            VaultService.shared.send(VerifyOTP(phoneNumber: phoneNumber, sentOTP: otp, publicKey: publicKey)) { result in
                DispatchQueue.main.async {
                    self.isLoading = false

                    switch result {
                    case .success(let response):
                        self.address = response.contract_address
                        onSuccess()

                    case .failure(let error):
                        // TODO: Handle error
#if DEBUG
                        print(error)
#endif
                    }
                }
            }
        } catch {
            // TODO: Handle error
            #if DEBUG
            print(error)
            #endif
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

    // sign

    func signOutsideExecution(outsideExecution: OutsideExecution) async throws -> StarknetSignature {
        let feltAddress = Felt(fromHex: self.address)!

        print("MessageHash: \(self.outsideExecution!.getMessageHash(forSigner: feltAddress))")
        return try self.signer.sign(transactionHash: self.outsideExecution!.getMessageHash(forSigner: feltAddress))
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

    func addContact(name: String, phoneNumber: String, completionHandler: @escaping (Recipient) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let newContact = CNMutableContact()
            let nameComponents = name.split(separator: " ")

            if let firstName = nameComponents.first {
                newContact.givenName = String(firstName)
            }

            if nameComponents.count > 1 {
                newContact.familyName = nameComponents.dropFirst().joined(separator: " ")
            }

            let phoneValue = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))
            newContact.phoneNumbers = [phoneValue]

            let saveRequest = CNSaveRequest()
            saveRequest.add(newContact, toContainerWithIdentifier: nil)

            do {
                try self?.contactStore.execute(saveRequest)

                DispatchQueue.main.async {
                    self?.fetchContacts() // Refresh the contacts list
                    completionHandler(Recipient(name: name, phoneNumber: phoneNumber))
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

    func setRecipient(_ recipient: Recipient) {
        self.recipient = recipient
    }

    func executeTransfer() async {
        guard
            let outsideExecution = self.outsideExecution,
            let outsideExecutionSignature = self.outsideExecutionSignature
        else {
            self.sendingStatus = .error("Invalid request.")
            return
        }

        self.sendingStatus = .loading

        VaultService.shared.send(
            ExecuteFromOutside(
                address: self.address,
                outsideExecution: outsideExecution,
                signature: outsideExecutionSignature
            )
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let recipient = self.recipient!
                    let amount = Amount.usdc(from: self.parsedAmount)!

                    self.pendingTransaction = Transaction(
                        address: self.address,
                        from: RawTransactionUser(nickname: self.surname, contract_address: self.address, phone_number: nil, balance: ""),
                        to: RawTransactionUser(nickname: recipient.name, contract_address: nil, phone_number: recipient.phoneNumber, balance: ""),
                        amount: amount,
                        date: Date(),
                        transferId: "\(response.transaction_hash)_0"
                    )
                    self.sendingStatus = .success
#if DEBUG
                    print("tx: \(response.transaction_hash)")
#endif

                case .failure(let error):
                    self.sendingStatus = .success
                    //                self.sendingStatus = .error("An error has occured during the transaction.")

#if DEBUG
                    print(error)
#endif
                }
            }
        }
    }

    func signTransfer() async {
        guard
            let recipient = self.recipient,
            let recipientAddress = recipient.address,
            let amount = Amount.usdc(from: self.parsedAmount)
        else {
            self.sendingStatus = .error("Invalid request.")
            return
        }

        let call = StarknetCall(
            contractAddress: Constants.Starknet.usdcAddress,
            entrypoint: starknetSelector(from: "transfer"),
            calldata: [
                recipientAddress,
                amount.value.low,
                amount.value.high,
            ]
        )
        self.outsideExecution = OutsideExecution(calls: [call])

        self.sendingStatus = .signing

        do {
            self.outsideExecutionSignature = try await self.signOutsideExecution(outsideExecution: self.outsideExecution!)

            self.sendingStatus = .signed
        } catch let error {
            self.sendingStatus = .none

#if DEBUG
            print(error)
#endif
        }
    }
}

// MARK: - Deeplinks

extension Model {
    public func handleDeepLink(_ url: URL) {
        guard url.scheme == "vltfinance" else {
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }

        guard let action = components.host, action == "request" else {
            print("Unknown URL, we can't handle this one!")
            return
        }

        guard
            let amount = components.queryItems?.first(where: { $0.name == "amount" })?.value,
            let parsedAmount = Amount.usdc(fromHex: amount),
            let recipientAddress = components.queryItems?.first(where: { $0.name == "recipientAddress" })?.value
        else {
            print("Invalid payment request")
            return
        }

        VaultService.shared.send(GetUser(address: recipientAddress)) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.recipient = Recipient(name: response.user, address: recipientAddress)

                case .failure(let error):
                    self.recipient = Recipient(name: "UNKNOWN", address: recipientAddress)

                    // TODO: Handle error
#if DEBUG
                    print(error)
#endif
                }
            }
        }

        self.amount = parsedAmount.toFixed(2)
        self.showRequestingConfirmation = true
    }
}

// MARK: - Onramp

extension Model {

    public func getOnrampQuote() {
        self.onRampQuoteId = nil
        self.onRampTotalUsd = nil

        if self.parsedAmount <= 0 { return }

        self.isLoading = true

        self.currentTask = Task {
            let response = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FunkitStripeCheckoutQuote, any Error>) in
                VaultService.shared.send(GetFunkitStripeCheckoutQuote(address: self.address, amount: String(self.parsedAmount))) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let response):
                            continuation.resume(returning: response)

                        case .failure(let error):
                            // TODO: Handle error
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

            // task has been cancelled
            if Task.isCancelled { return }

            self.isLoading = false

            self.onRampQuoteId = response.quoteId
            self.onRampTotalUsd = response.totalUsd
            self.estSubtotalUsd = response.estSubtotalUsd
        }
    }

    public func createOnrampCheckout() {
        guard let quoteId = self.onRampQuoteId else { return }

        VaultService.shared.send(
            CreateFunkitStripeCheckout(
                quoteId: quoteId,
                parsedAmount: self.parsedAmount,
                estSubtotalUsd: self.estSubtotalUsd
            )
        ) {  result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.stripeRedirectUrl = URL(string: response.stripeRedirectUrl)

                case .failure(let error):
                    // TODO: Handle error
                    print(error)
                }
            }
        }
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

            var contacts: [Recipient] = []

            do {
                try self?.contactStore.enumerateContacts(with: request) { (cnContact, stop) in
                    let name = "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces)
                    let imageData = cnContact.imageData

                    // Phone
                    let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue ?? ""

                    // Only add contacts with a name AND a phone number
                    if !name.isEmpty && phoneNumber.hasPrefix("+") {
                        let contact = Recipient(name: name, phoneNumber: phoneNumber, imageData: imageData)
                        contacts.append(contact)
                    }
                }

                DispatchQueue.main.async {
                    self?.contacts = contacts
                    self?.contactsMapping = Dictionary(grouping: contacts, by: { $0.phoneNumber! })
                }
            } catch {
                print("Failed to fetch contacts: \(error)")
            }
        }
    }

    private func initiateTransfer() {
        self.recipient = nil
        self.amount = "0"
        self.outsideExecution = nil
        self.outsideExecutionSignature = nil
    }

    private func dismissTransfer() {
        self.sendingStatus = .none
    }

    private func initiateRequest() {
        self.amount = "0"
    }

    private func initiateOnramp() {
        self.amount = "0"
        self.onRampQuoteId = nil
        self.onRampTotalUsd = nil
        self.estSubtotalUsd = 0
        self.stripeRedirectUrl = nil
    }
}
