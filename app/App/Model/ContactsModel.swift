//
//  ContactsModel.swift
//  Vault
//
//  Created by Charles Lanier on 22/05/2024.
//

import Foundation
import Contacts
import Combine
import UIKit
import CoreTelephony

struct Contact: Identifiable {
    var id = UUID()
    var name: String
    var phone: String
    var imageData: Data?
}

class ContactsModel: ObservableObject {

    @Published var contacts: [Contact] = []
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined

    private var contactStore = CNContactStore()

    init() {
        checkAuthorizationStatus()

        //        #if DEBUG
        //        self.contacts = [
        //            Contact(name: "Kenny McCormick", phone: "+123456789"),
        //            Contact(name: "Bobby", phone: "+987654321"),
        //        ]
        //        #endif
    }

    public func checkAuthorizationStatus() {
        self.authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)

        switch authorizationStatus {
        case .notDetermined, .denied, .restricted:
            break

        case .authorized:
            self.fetchContacts()

        @unknown default:
            fatalError("Unknown authorization status")
        }
    }

    public func requestAccess() {
        if authorizationStatus == .denied {
            self.openSettings()
        } else if authorizationStatus == .notDetermined {
            contactStore.requestAccess(for: .contacts) { [weak self] (granted, error) in
                DispatchQueue.main.async {
                    if granted {
                        self?.authorizationStatus = .authorized
                        self?.fetchContacts()
                    } else {
                        self?.authorizationStatus = .denied
                        // TODO: Handle the case where permission is denied
                        print("Permission denied")
                    }
                }
            }
        }
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
