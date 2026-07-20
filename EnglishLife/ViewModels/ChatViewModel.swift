import SwiftUI

struct ChatMessage: Identifiable, Equatable {
  let id = UUID()
  let text: String
  let isMine: Bool
}

@MainActor
final class ChatViewModel: ObservableObject {
  @Published var draft = ""
  @Published var messages: [ChatMessage] = []
  @Published private(set) var isReplying = false
  @Published var showsRequirements = false
  @Published var showsCompletion = false

  private let client = CharacterChatAPIClient()

  func send(as character: Character, using context: SituationAIContext?) {
    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    messages.append(ChatMessage(text: text, isMine: true))
    draft = ""
    Task {
      isReplying = true
      defer { isReplying = false }
      do {
        let reply = try await client.reply(
          as: character,
          to: text,
          context: context,
          history: messages
        )
        messages.append(ChatMessage(text: reply, isMine: false))
      } catch {
        messages.append(ChatMessage(text: fallbackReply(for: context), isMine: false))
      }
    }
  }

  private func fallbackReply(for context: SituationAIContext?) -> String {
    guard let context else { return "That sounds great! I love practicing English with you." }
    let keyword = context.targetKeywords.first ?? "that phrase"
    switch context.level {
    case EnglishLevel.beginner.rawValue:
      return "Great job! Try using \(keyword) in a short sentence."
    case EnglishLevel.intermediate.rawValue:
      return "Nice! Can you add one more detail and include \(keyword)?"
    default:
      return "Good start. Could you make that more natural and explain why you chose that approach?"
    }
  }

  func complete(_ situation: Situation, using app: AppViewModel) {
    app.complete(situation)
    showsRequirements = false
    showsCompletion = true
  }
}
