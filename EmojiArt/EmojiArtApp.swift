//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Track Ensure on 2021-08-04.
//

import SwiftUI

@main
struct EmojiArtApp: App {
  let document = EmojiArtDocument()
  
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
