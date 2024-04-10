//
//  PhoneTextField.swift
//  Vault
//
//  Created by Charles Lanier on 08/04/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneInput: View {
    @State private var selectedCountry: CountryData?
    @Binding var phoneNumber: String

    var body: some View {
        VStack {
            if let country = selectedCountry {
                Text("Selected Country: \(country.name) \(country.code)")
            }
            Button("Select Country") {
                showingPicker = true
            }
        }
        .sheet(isPresented: $showingPicker) {
            CountryPickerView(selectedCountry: $selectedCountry)
                .preferredColorScheme(.dark)
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
