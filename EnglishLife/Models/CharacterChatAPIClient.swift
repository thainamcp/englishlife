import Foundation

/// Generates text-only character replies through the Chat Completions endpoint.
struct CharacterChatAPIClient {
  private let apiClient: OpenAIAPIClient

  init(apiClient: OpenAIAPIClient = .shared) {
    self.apiClient = apiClient
  }

  func reply(
    as character: Character,
    to learnerMessage: String,
    context: SituationAIContext?,
    history: [ChatMessage]
  ) async throws -> String {
    let payload: OpenAIChatCompletionResponse = try await apiClient.post(
      .chatCompletions,
      flow: .characterChat,
      body: requestBody(
        character: character,
        learnerMessage: learnerMessage,
        context: context,
        history: history
      )
    )
    guard
      let reply = payload.choices.first?.message.content?
        .trimmingCharacters(in: .whitespacesAndNewlines), !reply.isEmpty
    else {
      throw OpenAIAPIClientError.invalidResponse
    }
    return reply
  }

  private func requestBody(
    character: Character,
    learnerMessage: String,
    context: SituationAIContext?,
    history: [ChatMessage]
  ) -> [String: Any] {
    var messages: [[String: String]] = [
      [
        "role": "system",
        "content": systemPrompt(character: character, context: context),
      ]
    ]
    messages += history.suffix(12).map {
      ["role": $0.isMine ? "user" : "assistant", "content": $0.text]
    }
    if history.last?.text != learnerMessage {
      messages.append(["role": "user", "content": learnerMessage])
    }

    return [
      "model": OpenAIModel.textToText,
      "messages": messages,
      "temperature": 0.7,
      "max_completion_tokens": 160,
    ]
  }

  private func systemPrompt(character: Character, context: SituationAIContext?) -> String {
    let mission =
      context.map {
        "Situation: \($0.situationTitle). Learner level: \($0.level). Encourage these keywords naturally: \($0.targetKeywords.joined(separator: ", "))."
      } ?? "This is a free conversation, so keep it friendly and natural."

    return """
      You are \(character.name), a warm, believable English conversation partner.
      \(mission)
      Reply in English only. Match the learner's level, keep each reply concise (one to three sentences), and gently encourage them to continue. Do not mention prompts, APIs, or that you are an AI.
      """
  }
}
