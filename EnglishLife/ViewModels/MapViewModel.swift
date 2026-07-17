import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
  @Published var selectedSituation: Situation?

  let chapters = Situation.chapters
  let situations = Situation.demo

  func situations(in chapter: AdventureChapter) -> [Situation] {
    situations.filter { $0.chapter.hasPrefix("Chapter \(chapter.id)") }
  }

  func select(_ situation: Situation, using app: AppViewModel) {
    guard app.progress(for: situation) != .locked else { return }
    selectedSituation = situation
  }
}
