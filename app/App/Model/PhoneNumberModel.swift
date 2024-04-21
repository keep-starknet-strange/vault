//
//  PhoneNumberModel.swift
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

class PhoneNumberModel: ObservableObject {

    @Published var selectedRegionCode = Locale.current.regionOrFrance.identifier
    @Published var searchedCountry = ""

    var selectedCountryData: CountryData {
        return self.countryData(forRegionCode: self.selectedRegionCode)
    }

    private let phoneNumberKit = PhoneNumberKit()

    private lazy var countries: [CountryData] = {
        phoneNumberKit.allCountries()
            .map { regionCode in
                return self.countryData(forRegionCode: regionCode)
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

    private var partialFormatter: PartialFormatter {
        PartialFormatter(
            phoneNumberKit: self.phoneNumberKit,
            defaultRegion: self.selectedRegionCode,
            withPrefix: false,
            ignoreIntlNumbers: true
        )
    }

    // MARK: Functions

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

    // MARK: Internal

    private func countryData(forRegionCode regionCode: String) -> CountryData {
        let countryName = Locale.current.localizedString(forRegionCode: regionCode)  ?? "world"
        let phoneCode = phoneNumberKit.countryCode(for: regionCode) ?? 0

        return CountryData(
            regionCode: regionCode,
            phoneCode: "+\(phoneCode)",
            name: countryName
        )
    }
}
