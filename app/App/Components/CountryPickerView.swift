//
//  PhoneTextField.swift
//  Vault
//
//  Created by Charles Lanier on 08/04/2024.
//

import SwiftUI
import PhoneNumberKit

struct CountryPickerView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var model: Model

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HStack(spacing: 8) {
                        SearchBar(search: $model.searchedCountry)
                        Button {
                            self.dismiss()
                        } label: {
                            Text("Cancel").textTheme(.buttonSmall)
                        }
                    }
                    .padding(16)

                    List(self.model.filteredCountries.indexed(), id: \.element) { index, countryData in
                        let flagRessource = ImageResource(name: countryData.regionCode.lowercased(), bundle: Bundle.main)
                        let isFirst = index == 0;
                        let isLast = index == self.model.filteredCountries.count - 1
                        let isSelected = self.model.isSelected(countryData.regionCode)

                        Button {
                            self.model.selectedRegionCode = countryData.regionCode
                            self.dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                Image(flagRessource)
                                    .resizable()
                                    .frame(width: 42, height: 42)
                                    .scaledToFill()
                                    .clipShape(Capsule())

                                Text("\(countryData.phoneCode)")
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
                        .if(isSelected) { view in
                            view.background(.accent.opacity(0.2))
                        }
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

    @StateObject static var model = Model(vaultService: VaultService())

    @State static var isPresented = true
    @State static var selectedRegionCode = Locale.current.regionOrFrance.identifier

    static var previews: some View {
        NavigationStack {
            ZStack {
                PrimaryButton("Open") {
                    self.isPresented = true
                }
                .sheet(isPresented: $isPresented) {
                    CountryPickerView()
                        .environmentObject(self.model)
                }
            }
        }
    }
}
#endif
