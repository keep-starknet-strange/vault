//
//  AmountInput.swift
//  Vault
//
//  Created by Charles Lanier on 03/05/2024.
//

import SwiftUI

struct AmountInput: View {

    @Binding private var amount: String
    @FocusState private var focused: Bool

    private let regex = try! NSRegularExpression(pattern: "^\\d*,?\\d{0,2}$", options: [])

    init(amount: Binding<String>) {
        self._amount = amount
    }

    var body: some View {
        TextField("", text: $amount)
            .focused($focused)
            .onChange(of: self.amount, initial: false) { (oldValue, newValue) in

                // format input
                if let amount = self.formattedAmount(newValue) {
                    self.amount = amount
                } else {
                    self.amount = oldValue
                }
            }
            .keyboardType(.decimalPad)
            .frame(width: 0, height: 0)
            .onAppear {
                // Automatically focus the TextField when the view appears
                DispatchQueue.main.async {
                    self.focused = true
                }
            }

        Text("$\(self.amount.isEmpty ? "0" : self.amount)").textTheme(.hero)
    }

    private func formattedAmount(_ amount: String) -> String? {
        if amount == "," {
            return "0,"
        } else if regex.firstMatch(
            in: amount,
            options: [],
            range: NSRange(location: 0, length: amount.utf8.count)
        ) != nil {
            // remove useless 0 if needed
            return amount.first == "0" && amount.count > 1 && amount[amount.index(amount.startIndex, offsetBy: 1)].isNumber
            ? String(amount.dropFirst())
            : amount
        }

        return nil
    }
}

#if DEBUG
struct AmountInputPreviews : PreviewProvider {

    @State static var amount: String = "100"

    static var previews: some View {
        NavigationStack {
            ZStack {
                Color.background1.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 16) {
                    AmountInput(amount: $amount)
                }
            }
        }.preferredColorScheme(.dark)
    }
}
#endif
