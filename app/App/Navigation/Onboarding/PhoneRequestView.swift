//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneRequestView: View {
    
    @EnvironmentObject private var registrationModel: RegistrationModel
    
    @State private var presentingNextView = false
    @State private var phoneNumber = ""
    @State private var parsedPhoneNumber: PhoneNumber?
    
    var body: some View {
        OnboardingPage(isLoading: $registrationModel.isLoading) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Let's get started !").textTheme(.headlineLarge)
                
                Text("Enter your phone number. We will send you a confirmation code.").textTheme(.bodyPrimary)
                
                PhoneInput(phoneNumber: $phoneNumber, parsedPhoneNumber: $parsedPhoneNumber)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 16) {
                // TODO: implement login
                PrimaryButton("Sign up", disabled: self.parsedPhoneNumber == nil) {
                    registrationModel.startRegistration(phoneNumber: self.parsedPhoneNumber!) { result in
                        switch result {
                        case .success():
                            presentingNextView = true
                            
                        case .failure(let error):
                            print(error)
                            // TODO: handle error
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            PhoneValidationView(phoneNumber: parsedPhoneNumber)
        }
    }
}

#if DEBUG
struct PhoneRequestViewPreviews : PreviewProvider {

    @StateObject static var registrationModel = RegistrationModel(vaultService: VaultService())

    static var previews: some View {
        NavigationStack {
            PhoneRequestView()
                .environmentObject(self.registrationModel)
        }
    }
}
#endif
