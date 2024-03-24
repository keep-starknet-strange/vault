//
//  Text.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct TextInput: View {
    @Binding var text: String

    let placeholder: String

    init(_ placeholder: String = "", text: Binding<String>) {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder).foregroundColor(.neutral2)
            }
            .textFieldStyle(.plain)
            .padding(16)
            .foregroundColor(.neutral1)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background3)
            )
    }
}

#Preview {
    @State var text: String = ""

    return ZStack {
        Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        VStack(alignment: .leading, spacing: 16) {
            TextInput("Example", text: $text)
        }
    }
}
