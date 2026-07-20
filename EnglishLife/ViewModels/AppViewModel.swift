import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
  @AppStorage("learnerName") var learnerName = ""
  @Published var level: EnglishLevel = .beginner { didSet { persistJourney() } }
  @Published var selectedTab = 0
  @Published var characters: [Character] = [] { didSet { persistJourney() } }
  @Published var activeChatSession: ChatSession?
  @Published private(set) var completedSituationIDs: Set<String> = [] {
    didSet { persistJourney() }
  }
  @Published private(set) var resumeSituationID: String? { didSet { persistJourney() } }
  @Published private(set) var studyPathDefinition: StudyPathDefinition?
  @Published private(set) var chapters: [AdventureChapter] = []
  @Published private(set) var situations: [Situation] = []
  @Published private(set) var isGeneratingStudyPath = false
  @Published private(set) var studyPathError: String?

  private let studyPathClient = StudyPathGenerationAPIClient()

  init() {
    let snapshot = LearnerProgressStore.load()
    level = snapshot.level
    completedSituationIDs = snapshot.completedSituationIDs
    resumeSituationID = snapshot.resumeSituationID
    characters = snapshot.characters
    applyStudyPath(snapshot.studyPath)
  }

  func character(for situation: Situation) -> Character? {
    let migratedCharacter = characters.first { character in
      // Keeps learners' characters from an older app version usable before the
      // persisted record has been migrated on the next launch.
      guard character.templateID == nil else { return false }
      return situations.first(where: {
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
    guard let index = situations.firstIndex(where: { $0.id == situation.id }) else {
      return .locked
    }
    if index == 0 || completedSituationIDs.contains(situations[index - 1].id) { return .available }
    return .locked
  }

  func complete(_ situation: Situation) {
    guard progress(for: situation) == .available else { return }
    completedSituationIDs.insert(situation.id)
    let nextIndex = situations.firstIndex(where: { $0.id == situation.id }).map { $0 + 1 }
    resumeSituationID = nextIndex.flatMap {
      situations.indices.contains($0) ? situations[$0].id : nil
    }
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

  /// Generates and saves the learner's one-time personalized roadmap.
  func createStudyPath(for selectedLevel: EnglishLevel) async {
    guard !isGeneratingStudyPath else { return }
    level = selectedLevel
    isGeneratingStudyPath = true
    studyPathError = nil
    defer { isGeneratingStudyPath = false }

    do {
      applyStudyPath(try await studyPathClient.generate(for: selectedLevel))
      persistJourney()
    } catch {
      // The bundled content keeps onboarding usable offline; it is not used
      // once a generated path has been successfully saved.
      applyStudyPath(nil)
      studyPathError = error.localizedDescription
      persistJourney()
    }
  }

  func ensureStudyPath() async {
    guard studyPathDefinition == nil else { return }
    await createStudyPath(for: level)
  }

  private func applyStudyPath(_ definition: StudyPathDefinition?) {
    studyPathDefinition = definition
    let path =
      definition.map { AppContentRepository.shared.runtimePath(from: $0) }
      ?? RuntimeStudyPath(
        chapters: AppContentRepository.shared.chapters,
        situations: AppContentRepository.shared.situations
      )
    chapters = path.chapters
    situations = path.situations
  }

  private func persistJourney() {
    LearnerProgressStore.save(
      level: level,
      completedSituationIDs: completedSituationIDs,
      resumeSituationID: resumeSituationID,
      characters: characters,
      studyPath: studyPathDefinition)
  }
}
