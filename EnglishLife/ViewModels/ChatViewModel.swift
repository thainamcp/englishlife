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
  @Published var showsRequirements = false
  @Published var showsCompletion = false

  func send() {
    let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    messages.append(ChatMessage(text: text, isMine: true))
    draft = ""
    Task {
      try? await Task.sleep(for: .milliseconds(550))
      messages.append(
        ChatMessage(text: "That sounds great! I love practicing English with you.", isMine: false))
    }
  }

  func complete(_ situation: Situation, using app: AppViewModel) {
    app.complete(situation)
    showsRequirements = false
    showsCompletion = true
  }
}
