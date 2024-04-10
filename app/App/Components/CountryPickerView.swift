//
//  PhoneTextField.swift
//  Vault
//
//  Created by Charles Lanier on 08/04/2024.
//

import SwiftUI
import PhoneNumberKit

struct CountryData: Hashable {
    let country: String
    let name: String
    let code: String
}

struct CountryPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCountry: CountryData?

    let phoneNumberKit = PhoneNumberKit()
    var countries: [CountryData] {
        phoneNumberKit.allCountries()
            .map { country in
                let countryName = Locale.current.localizedString(forRegionCode: country)  ?? "world"
                let countryCode = phoneNumberKit.countryCode(for: country) ?? 0
                return CountryData(
                    country: country,
                    name: countryName,
                    code: "+\(countryCode)"
                )
            }
            .filter { $0.name != "world" }
            .sorted { $0.name < $1.name }
    }

    @State private var searchText = ""

    var filteredCountries: [CountryData] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HStack(spacing: 8) {
                        SearchBar(search: $searchText)
                        Button {
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                                .foregroundStyle(.accent)
                        }
                    }
                    .padding(16)

                    List(Array(self.filteredCountries.enumerated()), id: \.element) { index, countryData in
                        let flagRessource = ImageResource(name: countryData.country.lowercased(), bundle: Bundle.main)
                        let isFirst = index == 0;
                        let isLast = index == self.filteredCountries.count - 1

                        Button {
                            self.selectedCountry = countryData
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                Image(flagRessource)
                                    .resizable()
                                    .frame(width: 42, height: 42)
                                    .scaledToFill()
                                    .clipShape(Capsule())

                                Text("\(countryData.code)")
                                    .foregroundStyle(.neutral2)
                                    .fontWeight(.medium)
                                    .frame(width: 48, alignment: .leading)

                                Text("\(countryData.name)")
                                    .foregroundStyle(.neutral1)
                                    .fontWeight(.medium)

                                Spacer()
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                        .background(.background3)
                        .listRowBackground(EmptyView())
                        .listRowSeparator(.hidden)
                        .clipShape(
                            .rect(
                                topLeadingRadius: isFirst ? 16 : 0,
                                bottomLeadingRadius: isLast ? 16 : 0,
                                bottomTrailingRadius: isLast ? 16 : 0,
                                topTrailingRadius: isFirst ? 16 : 0
                            )
                        )
                    }
                    .scrollContentBackground(.hidden)
                    .padding(.bottom, 32)
                    .ignoresSafeArea()
                    .listRowInsets(EdgeInsets())
                    .listStyle(.inset)
                }
            }.background(.background2)
        }
    }
}

#if DEBUG
struct CountryPickerViewPreviews : PreviewProvider {
    @State static var isPresented = true

    static var previews: some View {
        NavigationStack {
            ZStack {
                PrimaryButton("Open") {
                    self.isPresented = true
                }
                .sheet(isPresented: $isPresented) {
                    CountryPickerView(selectedCountry: .constant(nil))
                        .preferredColorScheme(.dark)
                }
            }
        }.preferredColorScheme(.dark)
    }

}
#endif
