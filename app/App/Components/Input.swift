//
//  Text.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

struct TextInput: View {
    @Binding var text: String

    @FocusState private var isFocused: Bool

    let placeholder: String

    init(_ placeholder: String = "", text: Binding<String>) {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        TextField("", text: $text)
            .focused($isFocused)
            .placeholder(when: text.isEmpty) {
                Text(placeholder).foregroundColor(.neutral2)
            }
            .textFieldStyle(.plain)
            .padding(16)
            .foregroundColor(.neutral1)
            .background(.background3.opacity(isFocused ? 1.5 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
