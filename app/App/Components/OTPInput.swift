//
//  OTPInput.swift
//  Vault
//
//  Created by Charles Lanier on 15/04/2024.
//

import SwiftUI

struct OTPInput: View {

    @Binding private var otp: String
    @FocusState private var focused: Bool

    var numberOfFields: Int

    enum FocusPin: Hashable {
        case pin(Int)
    }

    init(otp: Binding<String>, numberOfFields: Int) {
        self.numberOfFields = numberOfFields
        self._otp = otp
    }

    var body: some View {
        ZStack {
            TextField("", text: $otp)
                .focused($focused)
                .onChange(of: self.otp, initial: false) { (_, newValue) in
                    // remove non digit chars
                    self.otp = String(
                        self.otp.filter { $0.isWholeNumber }.prefix(self.numberOfFields)
                    )
                }
                .keyboardType(.numberPad)
                .frame(width: 0, height: 0)
                .onAppear {
                    // Automatically focus the TextField when the view appears
                    DispatchQueue.main.async {
                        self.focused = true
                    }
                }

            HStack(spacing: 12) {
                ForEach(0..<self.numberOfFields, id: \.self) { index in
                    let isFirstCharacter = index == 0

                    let character = self.otp.character(at: index)
                    let previousCharacter = isFirstCharacter ? nil : self.otp.character(at: index - 1)

                    let isActive = character == nil && (previousCharacter != nil || isFirstCharacter)

                    ZStack(alignment: .center) {
                        Text(character ?? " ")
                            .font(.system(size: 18))
                            .monospaced()
                            .padding(18)
                            .background(.background3.opacity(isActive ? 1.5 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        if isActive {
                            // Simulated cursor
                            Rectangle()
                                .fill(.accent)
                                .frame(
                                    width: 2,
                                    height: UIFont.systemFont(ofSize: 20).lineHeight
                                )
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct OTPInputPreviews : PreviewProvider {

    @State static var otp: String = ""

    static var previews: some View {
        NavigationStack {
            ZStack {
                Color.background1.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 16) {
                    OTPInput(otp: $otp, numberOfFields: 6)
                }
            }
        }
    }
}
#endif
