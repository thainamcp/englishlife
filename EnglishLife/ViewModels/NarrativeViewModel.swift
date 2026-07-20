import Combine
import Foundation

struct SituationAIContext: Codable {
  let userName: String
  let level: String
  let situationID: Int
  let situationTitle: String
  let situationStory: String
  var targetKeywords: [String]
  let characterGoal: String
  var welcomeMessage: String?
}

@MainActor
final class NarrativeViewModel: ObservableObject {
  @Published private(set) var context: SituationAIContext?
  @Published private(set) var isLoading = false
  @Published private(set) var errorMessage: String?

  private let client = NarrativeAPIClient()
  private let cache = SituationGuidanceCache.shared

  func configure(
    userName: String,
    level: EnglishLevel,
    situation: Situation,
    useCachedGuidance: Bool = false
  ) {
    let keywords = keywords(for: level, situation: situation)
    var newContext = SituationAIContext(
      userName: userName.isEmpty ? "Explorer" : userName,
      level: level.rawValue,
      situationID: situation.id,
      situationTitle: situation.title,
      situationStory: situation.story,
      targetKeywords: keywords,
      characterGoal:
        "Guide the learner through \(situation.title) naturally and encourage the target keywords.",
      welcomeMessage: nil
    )
    if useCachedGuidance, let cached = cache.guidance(for: situation.id) {
      newContext.targetKeywords = cached.keywords
      newContext.welcomeMessage = cached.welcomeMessage
    }
    context = newContext
  }

  func requestGuidance(preferCached: Bool = false) async {
    guard let context, !isLoading else { return }
    if preferCached, let cached = cache.guidance(for: context.situationID) {
      apply(cached, to: context)
      return
    }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      let guidance = try await client.generate(for: context)
      cache.save(guidance, for: context.situationID)
      apply(guidance, to: context)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func apply(_ guidance: NodeGuidance, to context: SituationAIContext) {
    var updatedContext = context
    updatedContext.targetKeywords = guidance.keywords
    updatedContext.welcomeMessage = guidance.welcomeMessage
    self.context = updatedContext
  }

  func keywords(for level: EnglishLevel, situation: Situation) -> [String] {
    switch level {
    case .beginner:
      return Array(situation.goals.prefix(2))
    case .intermediate:
      return Array(situation.goals.prefix(3))
    case .advanced:
      return situation.goals + ["could you clarify", "just to confirm"]
    }
  }

  var guidance: String {
    guard let context else { return "Preparing your guided conversation…" }
    if let welcomeMessage = context.welcomeMessage { return welcomeMessage }
    switch context.level {
    case EnglishLevel.beginner.rawValue:
      return
        "Hi \(context.userName)! I’ll use short sentences and help you say one thing at a time."
    case EnglishLevel.intermediate.rawValue:
      return "Hi \(context.userName)! Let’s handle this naturally with a few useful phrases."
    default:
      return "Hi \(context.userName)! I’ll challenge you with a realistic, nuanced conversation."
    }
  }

  /// This is the exact instruction payload that the narrative/chat API can send
  /// to a server without letting UI code assemble prompts itself.
  var systemPrompt: String {
    guard let context else { return "You are a friendly English practice guide." }
    return """
      You are a warm English practice guide in the English app.
      Learner: \(context.userName)
      Learner level: \(context.level)
      Situation: \(context.situationTitle)
      Scenario: \(context.situationStory)
      Required keywords: \(context.targetKeywords.joined(separator: ", "))
      Goal: \(context.characterGoal)
      Adapt vocabulary, sentence length, corrections, and follow-up questions to the learner level. Encourage the required keywords naturally; never list them mechanically.
      """
  }

  func openingLine(for characterName: String) -> String {
    guard let context else { return "Hi! Let’s practice together." }
    if let welcomeMessage = context.welcomeMessage { return welcomeMessage }
    switch context.level {
    case EnglishLevel.beginner.rawValue:
      return
        "Hi \(context.userName)! I’m \(characterName). Let’s try this one step at a time. Can you say hello first?"
    case EnglishLevel.intermediate.rawValue:
      return
        "Hi \(context.userName)! I’m \(characterName). We’re in \(context.situationTitle). How would you start?"
    default:
      return
        "Hi \(context.userName)! I’m \(characterName). Let’s make this feel real—how would you handle \(context.situationTitle.lowercased())?"
    }
  }
}
