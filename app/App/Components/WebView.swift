//
//  WebView.swift
//  Vault
//
//  Created by Charles Lanier on 07/05/2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.uiDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class Coordinator: NSObject, WKUIDelegate {
    var parent: WebView

    init(_ parent: WebView) {
        self.parent = parent
    }

    // Delegate methods go here

    @available(iOS 15, *)
     func webView(
         _ webView: WKWebView,
         requestMediaCapturePermissionFor origin: WKSecurityOrigin,
         initiatedByFrame frame: WKFrameInfo,
         type: WKMediaCaptureType,
         decisionHandler: @escaping (WKPermissionDecision) -> Void
     ) {
         decisionHandler(.grant)
     }
}
