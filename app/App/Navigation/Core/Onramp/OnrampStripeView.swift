//
//  OnrampStripeView.swift
//  Vault
//
//  Created by Charles Lanier on 01/07/2024.
//

import SwiftUI

struct OnrampStripeView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var model: Model

    @State private var presentingNextView = false

    var body: some View {
        ZStack {
            if let stripeRedirectUrl = self.model.stripeRedirectUrl {
                WebView(url: stripeRedirectUrl)
            } else {
                VStack {
                    Spacer()

                    Spacer().frame(height: 32)

                    HStack {
                        Spacer(minLength: 24)

                        HStack {
                            Image(.logo)
                                .iconify()
                                .frame(width: 64)
                                .foregroundStyle(.background1)
                                .padding(.top, 8)
                        }
                        .frame(width: 100, height: 100)
                        .background(.neutral1)
                        .clipShape(Circle())

                        Line()
                           .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                           .frame(height: 1)

                        HStack {
                            Image(.fun)
                                .iconify()
                                .frame(width: 64)
                                .foregroundStyle(.background1)
                                .padding(.bottom, 8)
                        }
                        .frame(width: 100, height: 100)
                        .background(.neutral1)
                        .clipShape(Circle())

                        Spacer(minLength: 24)
                    }

                    Spacer().frame(height: 64)

                    VStack(spacing: 16) {
                        Text("Vault x Fun").textTheme(.headlineLarge)

                        Text("Please wait a few moments on this screen")
                            .textTheme(.headlineSubtitle)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    HStack(alignment: .center, spacing: 4) {
                        ZStack {
                            Image(systemName: "shield.fill").foregroundStyle(.accent)
                                .font(.system(size: 22))

                            Image(systemName: "lock.fill")
                                .padding(.bottom, 2)
                                .font(.system(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.neutral1)
                        }

                        Text("Payment secured by").textTheme(.bodyPrimary)

                        Text("Stripe")
                            .textTheme(.headlineMedium)
                            .padding(.top, 4)

                        Spacer().frame(width: 12)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            self.model.createOnrampCheckout()
        }
        .navigationBarItems(
            leading: IconButton {
                self.dismiss()
            } icon: {
                Image(systemName: "chevron.left")
                    .iconify()
                    .fontWeight(.bold)
            }
        )
        .defaultBackground()
        .removeNavigationBarBorder()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Checkout")
    }
}

#if DEBUG
struct OnrampStripeViewPreviews : PreviewProvider {

    @StateObject static var model = Model()

    static var previews: some View {
        OnrampStripeView()
            .environmentObject(self.model)
    }
}
#endif
