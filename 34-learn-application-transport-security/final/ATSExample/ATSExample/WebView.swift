//
//  WebView.swift
//  ATSExample
//
//  Created by Brian on 4/3/20.
//  Copyright © 2020 raywenderlich. All rights reserved.
//

import WebKit
import SwiftUI

struct WebView: UIViewRepresentable {
  
  let url: URL
  
  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    let request = URLRequest(url: url)
    webView.load(request)
    return webView
  }
  
  func updateUIView(_ uiView: WKWebView, context: Context) {
  
  }

}

