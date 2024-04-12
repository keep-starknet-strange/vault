//
//  PhoneTextField.swift
//  Vault
//
//  Created by Charles Lanier on 08/04/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneInput: View {
    
    @StateObject private var countryPickerModel = CountryPickerModel()

    @Binding var phoneNumber: String

    var body: some View {
        VStack {
            Text("Selected Country: \(self.countryPickerModel.selectedRegionCode)")

            Button("Select Country") {
                showingPicker = true
            }
        }
        .sheet(isPresented: $showingPicker) {
            CountryPickerView()
                .environmentObject(self.countryPickerModel)
                .preferredColorScheme(.dark)
                .onAppear { self.countryPickerModel.searchedCountry = "" }
        }
    }

    @State private var showingPicker = false
}

#Preview {
    @State var text: String = ""

    return NavigationStack {
        ZStack {
            Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack(alignment: .leading, spacing: 16) {
                PhoneInput(phoneNumber: $text)
            }
        }
    }.preferredColorScheme(.dark)
}
