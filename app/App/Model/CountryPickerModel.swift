//
//  CountryPickerModel.swift
//  Vault
//
//  Created by Charles Lanier on 11/04/2024.
//

import Foundation
import PhoneNumberKit

struct CountryData: Hashable {
    let regionCode: String
    let phoneCode: String
    let name: String
}

class CountryPickerModel: ObservableObject {
    @Published var selectedRegionCode = Locale.current.regionOrFrance.identifier
    @Published var searchedCountry = ""

    private let phoneNumberKit = PhoneNumberKit()

    private lazy var countries: [CountryData] = {
        phoneNumberKit.allCountries()
            .map { regionCode in
                let countryName = Locale.current.localizedString(forRegionCode: regionCode)  ?? "world"
                let phoneCode = phoneNumberKit.countryCode(for: regionCode) ?? 0
                return CountryData(
                    regionCode: regionCode,
                    phoneCode: "+\(phoneCode)",
                    name: countryName
                )
            }
            .filter { $0.name != "world" }
            .sorted { $0.name < $1.name }
    }()

    var filteredCountries: [CountryData] {
        if self.searchedCountry.isEmpty {
            return self.countries
        } else {
            return self.countries.filter { $0.name.lowercased().contains(self.searchedCountry.lowercased()) }
        }
    }

    func isSelected(_ regionCode: String) -> Bool {
        return self.selectedRegionCode == regionCode
    }
}
