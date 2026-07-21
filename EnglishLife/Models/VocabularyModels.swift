import Foundation

/// A durable vocabulary entry. It starts as a study-path seed and gains its
/// AI-generated dictionary content only when the learner asks for it.
struct VocabularyWord: Identifiable, Codable, Hashable {
  let id: String
  var word: String
  var addedAt: Date
  var detail: VocabularyWordDetail?

  init(word: String, addedAt: Date = .now, detail: VocabularyWordDetail? = nil) {
    let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
    id = Self.identifier(for: cleanWord)
    self.word = cleanWord
    self.addedAt = addedAt
    self.detail = detail
  }

  static func identifier(for word: String) -> String {
    word
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
  }
}

struct VocabularyWordDetail: Codable, Equatable, Hashable {
  let partOfSpeech: String
  let phonetic: String
  let definition: String
  let examples: [String]

  /// Keeps legacy cached dictionary responses clean if an older prompt put
  /// sample sentences after the definition.
  var meaningOnly: String {
    let markers = ["Examples:", "Example:", "For example:"]
    let firstMarker = markers.compactMap { marker in
      definition.range(of: marker, options: [.caseInsensitive, .diacriticInsensitive])
    }
    .map(\.lowerBound)
    .min()

    guard let firstMarker else {
      return definition.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return String(definition[..<firstMarker])
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

/// Produces the dictionary card and contextual examples displayed in the
/// Vocabulary Library. The response uses the app's shared text API client.
struct VocabularyAPIClient {
  private let apiClient: OpenAIAPIClient

  init(apiClient: OpenAIAPIClient = .shared) {
    self.apiClient = apiClient
  }

  func generateDetail(for word: String, learnerLevel: EnglishLevel) async throws
    -> VocabularyWordDetail
  {
    let payload: OpenAIChatCompletionResponse = try await apiClient.post(
      .chatCompletions,
      flow: .vocabulary,
      body: requestBody(for: word, learnerLevel: learnerLevel)
    )
    guard let content = payload.choices.first?.message.content,
      let data = content.data(using: .utf8)
    else {
      throw OpenAIAPIClientError.invalidResponse
    }
    let detail = try JSONDecoder().decode(VocabularyWordDetail.self, from: data)
    return VocabularyWordDetail(
      partOfSpeech: detail.partOfSpeech,
      phonetic: detail.phonetic,
      definition: detail.meaningOnly,
      examples: detail.examples
    )
  }

  private func requestBody(for word: String, learnerLevel: EnglishLevel) -> [String: Any] {
    [
      "model": OpenAIModel.textToText,
      "messages": [
        [
          "role": "system",
          "content": """
          You are a precise, friendly English dictionary for an English learner.
          Return only JSON matching the schema.
          The "definition" field is meaning only: a single concise dictionary definition
          in plain English appropriate for the learner level. Never include examples,
          sample sentences, numbered lists, labels such as "Example", or the word
          "examples" in "definition". Put exactly three natural, everyday sample
          sentences only in the "examples" array. Do not use markdown.
          """,
        ],
        [
          "role": "user",
          "content": "Word: \(word)\nLearner level: \(learnerLevel.rawValue)",
        ],
      ],
      "response_format": [
        "type": "json_schema",
        "json_schema": [
          "name": "vocabulary_word_detail",
          "strict": true,
          "schema": [
            "type": "object",
            "properties": [
              "partOfSpeech": ["type": "string"],
              "phonetic": ["type": "string"],
              "definition": ["type": "string"],
              "examples": ["type": "array", "items": ["type": "string"]],
            ],
            "required": ["partOfSpeech", "phonetic", "definition", "examples"],
            "additionalProperties": false,
          ],
        ],
      ],
    ]
  }
}
