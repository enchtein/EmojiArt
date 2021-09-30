//
//  ContentView.swift
//  EmojiArt
//
//  Created by Track Ensure on 2021-08-04.
//

import SwiftUI

struct EmojiArtDocumentView: View {
  @ObservedObject var document: EmojiArtDocument
  //  @State private var tapsIdState = [(id: Int, state: Bool, offset: CGSize)]()
  @State private var tapsIdState = [(id: Int, state: Bool, offset: CGSize, emojiScale: CGFloat)]()
  
  
  var foreverAnimation: Animation {
    //    Animation.linear(duration: 2.0)
    Animation.easeInOut(duration: 0.5)
      .repeatForever(autoreverses: true) // was false
  }
  
  let defaultEmojiFontSize: CGFloat = 40
//  var ss = TrashEmoji(isVisible: true)
  var body: some View {
    VStack(spacing: 0) {
      documentBody
      palette
    }
  }
  @State private var dragOffset = CGSize.zero
  @State private var pinchingScale: CGFloat = 1
  
  @State var canRemove: Bool = true
  var trashView = TrashEmoji(isVisible: true)
  
  var documentBody: some View {
    GeometryReader { geometry in
      ZStack {
        Color.yellow
          ForEach(document.emojis) { emoji in
            let emojiState = tapsIdState.first(where: {$0.id == emoji.id})
            let emojiPos = position(for: emoji, in: geometry)
            
            Text(emoji.text)
              
              .font(.system(size: fontSize(for: emoji)))
              .position(emojiState?.state ?? false ? CGPoint(x: emojiPos.x, y: emojiPos.y-20) : emojiPos)
              .animation(emojiState?.state ?? false ? foreverAnimation : .default)
              
              .onTapGesture {
//                print("trashView.body: ", trashView.body.frame(.))
                print(emoji.id)
                if let index = tapsIdState.firstIndex(where: {$0.id == emoji.id}) {
                  tapsIdState[index].state.toggle()
                } else {
                  tapsIdState.append((id: emoji.id, state: true, offset: .zero, emojiScale: 1))
                }
              }
              .offset(emojiState?.offset ?? .zero)
              .scaleEffect(emojiState?.emojiScale ?? 1)
          }
      }
      .offset(dragOffset)
      .scaleEffect(pinchingScale)
      .gesture(
        DragGesture()
          .onChanged { gesture in
            let selectedEmojis = self.getSelectedEmojis()
            if !selectedEmojis.isEmpty {
              for replacedEmoji in selectedEmojis {
                guard let index = tapsIdState.firstIndex(where: {$0.id == replacedEmoji.id}) else { return }
                tapsIdState[index].offset = gesture.translation
              }
            } else {
              self.tapsIdState = [(id: Int, state: Bool, offset: CGSize, emojiScale: CGFloat)]()
              dragOffset = gesture.translation
            }
          }
          .onEnded { gesture in
            let selectedEmojis = self.getSelectedEmojis()
            if !selectedEmojis.isEmpty {
              for replacedEmoji in selectedEmojis {
                guard let index = tapsIdState.firstIndex(where: {$0.id == replacedEmoji.id}) else { return }
                tapsIdState[index].state = false
                document.moveEmoji(replacedEmoji, by: tapsIdState[index].offset)
                tapsIdState[index].offset = .zero
              }
            } else {
              dragOffset = gesture.translation
            }
          }
      )
      .gesture(
        MagnificationGesture()
          .onChanged { newScale in
            let selectedEmojis = self.getSelectedEmojis()
            if !selectedEmojis.isEmpty {
              for replacedEmoji in selectedEmojis {
                guard let index = tapsIdState.firstIndex(where: {$0.id == replacedEmoji.id}) else { return }
                tapsIdState[index].emojiScale = newScale
              }
            } else {
              pinchingScale = newScale
            }
          }
          .onEnded { scale in
            let selectedEmojis = self.getSelectedEmojis()
            if !selectedEmojis.isEmpty {
              for replacedEmoji in selectedEmojis {
                guard let index = tapsIdState.firstIndex(where: {$0.id == replacedEmoji.id}) else { return }
                tapsIdState[index].emojiScale = scale
              }
            } else {
              pinchingScale = scale
            }
          }
      )
      .onDrop(of: [.plainText], isTargeted: nil) { providers, location in
        return drop(providers: providers, at: location, in: geometry)
      }
      .onTapGesture {
        
        if !self.tapsIdState.isEmpty {
          self.tapsIdState.indices.forEach{self.tapsIdState[$0].state = false}
        }
      }
      .overlay(trashView, alignment: .top)
    }
  }
  private func getSelectedEmojis() -> [EmojiArtModel.Emoji] {
    var selectThis = [EmojiArtModel.Emoji]()
    for emoji in document.emojis {
      for activeEmoji in tapsIdState {
        if activeEmoji.state, emoji.id == activeEmoji.id {
          selectThis.append(emoji)
        }
      }
    }
    return selectThis
  }
  
  private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
    return providers.loadObjects(ofType: String.self) { string in
      if let emoji = string.first, emoji.isEmoji {
        document.addEmoji(
          String(emoji),
          at: convertToEmojiCoordinates(location, in: geometry),
          size: defaultEmojiFontSize
        )
      }
    }
  }
  
  private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
    convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
  }
  private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
    let center = geometry.frame(in: .local).center
    let location = CGPoint(
      x: location.x - center.x,
      y: location.y - center.y
    )
    return (Int(location.x), Int(location.y))
  }
  private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
    let center = geometry.frame(in: .local).center
    
    return CGPoint(
      x: center.x + CGFloat(location.x),
      y: center.y + CGFloat(location.y)
    )
  }
  
  private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
    CGFloat(emoji.size)
  }
  
  var palette: some View {
    ScrollingEmojisView(emojis: testEmojis)
      .font(.system(size: defaultEmojiFontSize))
  }
  
  
  let testEmojis = "☠️👿👺🏉🕸👽👻🕷"
}

struct ScrollingEmojisView: View {
  let emojis: String
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(emojis.map { String($0) }, id: \.self) { emoji in
          Text(emoji)
            .onDrag {
              NSItemProvider(object: emoji as NSString)
            }
        }
      }
    }
  }
}

//MARK: - TRASH
struct TrashEmoji: View {
  var isVisible = false
  
  var body: some View {
    HStack {
      Image(systemName: "trash.fill")
        .font(.system(size: 40))
//        .scaleEffect(isVisible ? 1 : 0)
        .opacity(isVisible ? 1 : 0)
        .animation(.linear(duration: 5))
    }
    
  }
}



















struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    EmojiArtDocumentView(document: EmojiArtDocument())
  }
}
