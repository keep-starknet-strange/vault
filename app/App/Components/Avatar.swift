//
//  Avatar.swift
//  Vault
//
//  Created by Charles Lanier on 04/06/2024.
//

import SwiftUI

struct Avatar: View {

    private var imageData: Data? = nil
    private var imageURL: URL? = nil

    private let name: String
    private let size: CGFloat
    private let salt: String?

    static let defaultName = "?"
    static let defaultSize: CGFloat = 42

    init(
        salt: String? = nil,
        name: String = Self.defaultName,
        size: CGFloat = Self.defaultSize
    ) {
        self.name = name
        self.size = size
        self.salt = salt
    }

    init(
        salt: String? = nil,
        name: String = Self.defaultName,
        size: CGFloat = Self.defaultSize,
        url: String? = nil
    ) {
        self.init(salt: salt, name: name, size: size)
        self.imageURL = if let url = url { URL(string: url) } else { nil }
    }

    init(
        salt: String? = nil,
        name: String = Self.defaultName,
        size: CGFloat = Self.defaultSize,
        data: Data? = nil
    ) {
        self.init(salt: salt, name: name, size: size)
        self.imageData = data
    }

    var body: some View {
        if let imageURL = self.imageURL {
            AsyncImage(
                url: imageURL,
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 42, height: 42)
                        .scaledToFit()
                },
                placeholder: {
                    ProgressView()
                }
            )
            .clipShape(Circle())
        } else if
            let imageData = self.imageData,
            let uiImage = UIImage(data: imageData)
        {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .scaledToFit()
                .clipShape(Circle())
        } else {
            NoAvatar(salt: self.salt, name: self.name)
        }
    }
}
