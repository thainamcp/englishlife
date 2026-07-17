import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
  @AppStorage("learnerName") var learnerName = ""
  @Published var level: EnglishLevel = .beginner
  @Published var selectedTab = 0
  @Published var characters: [Character] = []
  @Published var activeChatSession: ChatSession?
  @Published private(set) var completedSituationIDs: Set<Int> = []

  func character(for situation: Situation) -> Character? {
    characters.first { $0.situationTitle == situation.title }
  }
  func save(character: Character) {
    if let index = characters.firstIndex(where: { $0.situationTitle == character.situationTitle }) {
      characters[index] = character
    } else {
      characters.append(character)
    }
  }

  func progress(for situation: Situation) -> SituationProgress {
    if completedSituationIDs.contains(situation.id) { return .completed }
    if situation.id == 1 || completedSituationIDs.contains(situation.id - 1) { return .available }
    return .locked
  }

  func complete(_ situation: Situation) {
    guard progress(for: situation) == .available else { return }
    completedSituationIDs.insert(situation.id)
  }

  func presentChat(character: Character, situation: Situation?) {
    activeChatSession = ChatSession(character: character, situation: situation)
  }
}
