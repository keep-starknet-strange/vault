//
//  SettingsModel.swift
//  Vault
//
//  Created by Charles Lanier on 26/03/2024.
//

import Foundation

// UserDefaults Keys
enum UserDefaultsKeys: String {
    case surname
    case isOnboarded
}

class SettingsModel: ObservableObject {

    @Published var surname: String {
        didSet {
            UserDefaults.standard.set(surname, forKey: UserDefaultsKeys.surname.rawValue)
        }
    }
    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: UserDefaultsKeys.isOnboarded.rawValue)
        }
    }

    init() {
        self.surname = UserDefaults.standard.string(forKey: UserDefaultsKeys.surname.rawValue) ?? ""
        self.isOnboarded = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isOnboarded.rawValue)
    }
}
