//
//  Popover.swift
//  Vault
//
//  Created by Charles Lanier on 04/06/2024.
//

import SwiftUI

struct InnerHeightPreferenceKey: PreferenceKey {

    static let defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PopoverModifier<PopoverContent>: ViewModifier where PopoverContent : View {

    @State private var sheetHeight: CGFloat = .zero

    @Binding var isPresented: Bool

    var popoverContent: () -> PopoverContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$isPresented) {
                VStack {
                    VStack {
                        self.popoverContent()
                    }
                    .padding(EdgeInsets(top: 44, leading: 20, bottom: 32, trailing: 20))
                    .frame(maxWidth: .infinity)
                    .background(.background2)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    self.sheetHeight = newHeight
                }
                .presentationDetents([.height(self.sheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
            }
    }
}

extension View {
    public func sheetPopover<Content>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        self.modifier(
            PopoverModifier(
                isPresented: isPresented,
                popoverContent: content
            )
        )
    }
}

#if DEBUG
struct PopoverViewPreviews : PreviewProvider {

    @State static var isPresented = true

    static var previews: some View {
        VStack {
            Button("Open popover") {
                self.isPresented = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultBackground()
        .sheetPopover(isPresented: self.$isPresented) {
            Text("Holà, I'm the popover")
                .textTheme(.headlineMedium)
        }
    }
}
#endif
