//
//  PhoneTextField.swift
//  Vault
//
//  Created by Charles Lanier on 08/04/2024.
//

import SwiftUI
import PhoneNumberKit

struct CountryPickerView: View {

    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject private var countryPickerModel: CountryPickerModel

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    HStack(spacing: 8) {
                        SearchBar(search: $countryPickerModel.searchedCountry)
                        Button {
                            self.presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel").foregroundStyle(.accent)
                        }
                    }
                    .padding(16)

                    List(self.countryPickerModel.filteredCountries.indexed(), id: \.element) { index, countryData in
                        let flagRessource = ImageResource(name: countryData.regionCode.lowercased(), bundle: Bundle.main)
                        let isFirst = index == 0;
                        let isLast = index == self.countryPickerModel.filteredCountries.count - 1
                        let isSelected = self.countryPickerModel.isSelected(countryData.regionCode)

                        Button {
                            self.countryPickerModel.selectedRegionCode = countryData.regionCode
                            self.presentationMode.wrappedValue.dismiss()
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

    @StateObject static var countryPickerModel = CountryPickerModel()

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
                        .preferredColorScheme(.dark)
                        .environmentObject(self.countryPickerModel)
                }
            }
        }.preferredColorScheme(.dark)
    }

}
#endif
