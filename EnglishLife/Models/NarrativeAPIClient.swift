import Foundation

struct NodeGuidance: Codable, Equatable {
  let welcomeMessage: String
  let keywords: [String]
}

/// Generates a structured welcome and level-appropriate vocabulary for one node.
struct NarrativeAPIClient {
  private let apiClient: OpenAIAPIClient

  init(apiClient: OpenAIAPIClient = .shared) {
    self.apiClient = apiClient
  }

  func generate(for context: SituationAIContext) async throws -> NodeGuidance {
    let payload: OpenAIChatCompletionResponse = try await apiClient.post(
      .chatCompletions,
      flow: .narrative,
      body: requestBody(for: context)
    )
    guard let output = payload.choices.first?.message.content?.data(using: .utf8) else {
      throw OpenAIAPIClientError.invalidResponse
    }
    return try JSONDecoder().decode(NodeGuidance.self, from: output)
  }

  private func requestBody(for context: SituationAIContext) -> [String: Any] {
    [
      "model": OpenAIModel.textToText,
      "messages": [
        [
          "role": "system",
          "content": """
          You are an English-learning guide. Create a warm welcome and practical mission keywords.
          Adapt vocabulary, sentence length, and keyword complexity exactly to the learner level.
          Keep 2 keywords for Beginner, 3 for Intermediate, and 4 to 5 for Advanced.
          Keywords must be useful English words or short phrases for this exact situation.
          Return only data matching the requested JSON schema.
          """,
        ],
        [
          "role": "user",
          "content": """
          Learner name: \(context.userName)
          Learner level: \(context.level)
          Situation: \(context.situationTitle)
          Story: \(context.situationStory)
          Existing curriculum targets: \(context.targetKeywords.joined(separator: ", "))
          """,
        ],
      ],
      "response_format": [
        "type": "json_schema",
        "json_schema": [
          "name": "situation_guidance",
          "strict": true,
          "schema": [
            "type": "object",
            "properties": [
              "welcomeMessage": ["type": "string"],
              "keywords": ["type": "array", "items": ["type": "string"]],
            ],
            "required": ["welcomeMessage", "keywords"],
            "additionalProperties": false,
          ],
        ],
      ],
    ]
  }
}
