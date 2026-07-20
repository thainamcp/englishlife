import Foundation

/// Central model selection for each OpenAI capability in the app.
enum OpenAIModel {
  static let textToText = "gpt-5.6-luna"
  static let textToImage = "gpt-image-2"
  static let realtimeVoice = "gpt-realtime-2.1-mini"
}

enum APIFlow: String, CaseIterable {
  case studyPath
  case narrative
  case characterChat
  case realtimeVoice
  case avatarGeneration

  var description: String {
    switch self {
    case .studyPath: "Personalized study-path generation after onboarding"
    case .narrative: "AI story guidance for situation setup and reveal"
    case .characterChat: "Text conversation between user and character"
    case .realtimeVoice: "Live voice conversation between user and character"
    case .avatarGeneration: "Avatar image generation for a character"
    }
  }

  fileprivate var infoKey: String {
    switch self {
    case .studyPath: "STUDY_PATH_API_KEY"
    case .narrative: "NARRATIVE_API_KEY"
    case .characterChat: "CHARACTER_CHAT_API_KEY"
    case .realtimeVoice: "REALTIME_API_KEY"
    case .avatarGeneration: "IMAGE_GENERATION_API_KEY"
    }
  }
}

enum APIConfiguration {
  private static let secrets: [String: Any] = {
    guard let url = Bundle.main.url(forResource: "Secret", withExtension: "plist") else {
      return [:]
    }
    return (NSDictionary(contentsOf: url) as? [String: Any]) ?? [:]
  }()

  /// Development-only convenience. Use backend-issued ephemeral tokens for production.
  static func key(for flow: APIFlow) -> String? {
    let value =
      secrets[flow.infoKey] as? String
      ?? Bundle.main.object(forInfoDictionaryKey: flow.infoKey) as? String
      // Study-path generation is text-to-text, so it shares the narrative key
      // unless a dedicated STUDY_PATH_API_KEY is supplied.
      ?? (flow == .studyPath ? secrets[APIFlow.narrative.infoKey] as? String : nil)
    guard let value else { return nil }
    let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return key.isEmpty || key.hasPrefix("$(") ? nil : key
  }
}
