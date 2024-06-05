//
//  Avatar.swift
//  Vault
//
//  Created by Charles Lanier on 04/06/2024.
//

import SwiftUI

struct Avatar: View {
    var imageData: Data?
    var name: String
    var size: CGFloat = 42

    var body: some View {
        if
            let imageData = self.imageData,
            let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .scaledToFit()
                .clipShape(Circle())
        } else {
            NoAvatar(name: self.name)
        }
    }
}
