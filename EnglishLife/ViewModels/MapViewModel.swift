import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
  @Published var goalSituation: Situation?
  @Published var selectedSituation: Situation?
  private var hasRestoredResume = false

  func select(_ situation: Situation, using app: AppViewModel) {
    guard app.progress(for: situation) != .locked else { return }
    prefetchBackground(for: situation)
    goalSituation = situation
  }

  func begin(_ situation: Situation, using app: AppViewModel) {
    app.startLearning(situation)
    prefetchBackground(for: situation)
    goalSituation = nil
    DispatchQueue.main.async { [weak self] in
      self?.selectedSituation = situation
    }
  }

  func restoreCurrentSituation(using app: AppViewModel, situations: [Situation]) {
    guard !hasRestoredResume else { return }
    hasRestoredResume = true
  }

  private func prefetchBackground(for situation: Situation) {
    Task {
      let scenePreloader = SituationSceneViewModel()
      await scenePreloader.prefetchBackground(for: situation)
    }
  }
}
