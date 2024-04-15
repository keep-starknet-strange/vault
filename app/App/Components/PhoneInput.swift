//
//  PhoneTextField.swift
//  Vault
//
//  Created by Charles Lanier on 08/04/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneInput: View {

    @StateObject private var phoneNumberModel = PhoneNumberModel()

    @Binding var phoneNumber: String {
        didSet {
            self.parsedPhoneNumber = self.phoneNumberModel.parse(phoneNumber: self.phoneNumber)
        }
    }
    @Binding var parsedPhoneNumber: PhoneNumber?

    private let phoneNumberKit = PhoneNumberKit()

    var body: some View {
        HStack(spacing: 8) {
            Button {
                showingPicker = true
            } label: {
                let flagRessource = ImageResource(
                    name: self.phoneNumberModel.selectedCountryData.regionCode.lowercased(),
                    bundle: Bundle.main
                )

                HStack(spacing: 12) {
                    Image(flagRessource)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .scaledToFill()
                        .clipShape(Capsule())

                Text("\(self.phoneNumberModel.selectedCountryData.phoneCode)")
                    .foregroundStyle(.neutral2)
                    .fontWeight(.medium)
                }
                .frame(height: self.textInputHeight)
                .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 16))
                .background(.background3)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(NoopButtonStyle())
            .sheet(isPresented: $showingPicker) {
                CountryPickerView()
                    .environmentObject(self.phoneNumberModel)
                    .preferredColorScheme(.dark)
                    .onAppear {
                        self.phoneNumberModel.searchedCountry = ""
                    }
            }

            TextInput("Phone number", text: $phoneNumber)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            // Update the height state when the view appears
                            self.textInputHeight = geometry.size.height
                        }
                })
                .keyboardType(.numberPad)
                .onChange(of: self.phoneNumber, initial: false) { (_, newValue) in
                    print("test")
                    print(self.phoneNumberModel.format(phoneNumber: newValue))
                    self.phoneNumber = self.phoneNumberModel.format(phoneNumber: newValue)
                }
        }
        .onReceive(self.phoneNumberModel.$selectedRegionCode) { _ in
            self.phoneNumber = ""
        }
    }


    @State private var showingPicker = false
    @State private var textInputHeight: CGFloat?
}

#Preview {
    @State var text: String = ""
    @State var phoneNumber: PhoneNumber?

    return NavigationStack {
        ZStack {
            Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack(alignment: .leading, spacing: 16) {
                PhoneInput(phoneNumber: $text, parsedPhoneNumber: $phoneNumber)
            }
        }
    }.preferredColorScheme(.dark)
}
