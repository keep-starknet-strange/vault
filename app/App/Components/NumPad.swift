//
//  NumPad.swift
//  Vault
//
//  Created by Charles Lanier on 17/05/2024.
//

import SwiftUI

enum PadTouch: Hashable, Identifiable {
    var id: Self {
        return self
    }

    case char(String)
    case backspace

    var label: some View {
        Group {
            switch self {
            case .char(let symbol):
                Text(symbol)
                    .textTheme(.headlineLarge)

            case .backspace:
                Image(systemName: "delete.backward")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundStyle(.neutral1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 60)
    }
}

struct NumPad: View {

    @Binding var amount: String

    private let pad = [
        Container(
            [PadTouch.char("1"), PadTouch.char("2"), PadTouch.char("3")]
        ),
        Container(
            [PadTouch.char("4"), PadTouch.char("5"), PadTouch.char("6")]
        ),
        Container(
            [PadTouch.char("7"), PadTouch.char("8"), PadTouch.char("9")]
        ),
        Container(
            [PadTouch.char(","), PadTouch.char("0"), PadTouch.backspace]
        ),
    ]

    private let regex = try! NSRegularExpression(pattern: "^\\d*,?\\d{0,2}$", options: [])

    var body: some View {
        VStack(spacing: 0) {
            ForEach(self.pad, id: \.id) { row in
                HStack(spacing: 0) {
                    ForEach(row.elements, id: \.id) { touch in
                        Button {
                            let oldValue = self.amount

                            switch touch {
                            case .char(let symbol):
                                self.amount += symbol

                            case .backspace:
                                self.amount = String(self.amount.dropLast())
                            }

                            // format input
                            if let amount = self.formattedAmount(self.amount) {
                                self.amount = amount
                            } else {
                                self.amount = oldValue
                            }
                        } label: {
                            touch.label
                        }
                    }
                }
            }
        }
    }

    private func formattedAmount(_ amount: String) -> String? {
        if amount == "" {
            return "0"
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
struct NumPadPreviews : PreviewProvider {

    struct NumPadContainer: View {
        @State private var amount: String = "100"

        var body: some View {
            VStack {
                Spacer()

                FancyAmount(amount: $amount)

                Spacer()

                NumPad(amount: $amount)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .defaultBackground()
        }
    }

    static var previews: some View {
        NumPadContainer()
    }
}
#endif
