//
//  Notification.swift
//  Vault
//
//  Created by Charles Lanier on 24/03/2024.
//

import SwiftUI

struct Notification: View {
    var text: String

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                .frame(height: 74)
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14))

            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                .frame(height: 66)

            HStack(spacing: 10) {
                if let appIcon = UIImage(named: BundleProvider.appIcon()) {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 8.5))
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(BundleProvider.appName())
                        .font(.system(size: 15))
                        .fontWeight(.semibold)
                        .foregroundStyle(.neutral1)

                    Text(self.text)
                        .font(.system(size: 15))
                        .foregroundStyle(.neutral1)
                }

                Spacer()
            }
            .frame(height: 66)
            .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14))
        }
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        VStack {
            Notification(text: "Vitalik sent you $32.49")
        }
    }
}
