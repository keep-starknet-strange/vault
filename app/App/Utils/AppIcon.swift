//
//  AppIcon.swift
//  Vault
//
//  Created by Charles Lanier on 24/03/2024.
//

import Foundation

enum BundleProvider {
    static func appIcon(in bundle: Bundle = .main) -> String {
        guard let icons = bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last else {
            fatalError("Could not find icons in bundle")
        }

        return iconFileName
    }

    static func appName(in bundle: Bundle = .main) -> String {
        return (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ??
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ??
        "App"
    }
}
