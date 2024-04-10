//
//  Text.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

struct SearchBar: View {
    @Binding var search: String

    let placeholder: String

    init(_ placeholder: String = "Search", search: Binding<String>) {
        self._search = search
        self.placeholder = placeholder
    }

    var body: some View {
        TextField("", text: $search)
            .placeholder(when: search.isEmpty) {
                Text(placeholder).foregroundColor(.neutral2)
            }
            .textFieldStyle(.plain)
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .foregroundColor(.neutral1)
            .background(
                Capsule()
                    .fill(.background3)
            )
    }
}

#Preview {
    @State var search: String = ""

    return ZStack {
        Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        VStack(alignment: .leading, spacing: 16) {
            SearchBar(search: $search)
        }
    }
}
