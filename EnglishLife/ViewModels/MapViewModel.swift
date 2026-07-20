import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
  @Published var selectedSituation: Situation?
  private var hasRestoredResume = false

  func select(_ situation: Situation, using app: AppViewModel) {
    guard app.progress(for: situation) != .locked else { return }
    app.startLearning(situation)
    selectedSituation = situation
  }

  func restoreCurrentSituation(using app: AppViewModel, situations: [Situation]) {
    guard !hasRestoredResume else { return }
    hasRestoredResume = true
    selectedSituation = app.situationToResume(from: situations)
  }
}
