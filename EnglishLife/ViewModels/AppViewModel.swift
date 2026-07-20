import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
  @AppStorage("learnerName") var learnerName = ""
  @Published var level: EnglishLevel = .beginner { didSet { persistJourney() } }
  @Published var selectedTab = 0
  @Published var characters: [Character] = [] { didSet { persistJourney() } }
  @Published var activeChatSession: ChatSession?
  @Published private(set) var completedSituationIDs: Set<Int> = [] { didSet { persistJourney() } }
  @Published private(set) var resumeSituationID: Int? { didSet { persistJourney() } }

  init() {
    let snapshot = LearnerProgressStore.load()
    level = snapshot.level
    completedSituationIDs = snapshot.completedSituationIDs
    resumeSituationID = snapshot.resumeSituationID
    characters = snapshot.characters
  }

  func character(for situation: Situation) -> Character? {
    let migratedCharacter = characters.first { character in
      // Keeps learners' characters from an older app version usable before the
      // persisted record has been migrated on the next launch.
      guard character.templateID == nil else { return false }
      return AppContentRepository.shared.situations.first(where: {
        $0.title == character.situationTitle
      })?.characterID == situation.characterID
    }
    return characters.first { $0.templateID == situation.characterID } ?? migratedCharacter
  }
  func save(character: Character) {
    let index = characters.firstIndex {
      if let templateID = character.templateID {
        return $0.templateID == templateID
      }
      return $0.templateID == nil && $0.situationTitle == character.situationTitle
    }
    if let index {
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
    resumeSituationID =
      AppContentRepository.shared.situations.contains(where: { $0.id == situation.id + 1 })
      ? situation.id + 1
      : nil
  }

  func startLearning(_ situation: Situation) {
    resumeSituationID = situation.id
  }

  func situationToResume(from situations: [Situation]) -> Situation? {
    guard let resumeSituationID else { return nil }
    return situations.first { $0.id == resumeSituationID && progress(for: $0) != .completed }
  }

  func presentChat(character: Character, situation: Situation?) {
    if let situation { startLearning(situation) }
    activeChatSession = ChatSession(character: character, situation: situation)
  }

  private func persistJourney() {
    LearnerProgressStore.save(
      level: level,
      completedSituationIDs: completedSituationIDs,
      resumeSituationID: resumeSituationID,
      characters: characters)
  }
}
