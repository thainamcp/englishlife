import Foundation

/// Builds the learner's long-term roadmap once after onboarding.
struct StudyPathGenerationAPIClient {
  private let apiClient: OpenAIAPIClient

  init(apiClient: OpenAIAPIClient = .shared) {
    self.apiClient = apiClient
  }

  func generate(for level: EnglishLevel) async throws -> StudyPathDefinition {
    let payload: OpenAIChatCompletionResponse = try await apiClient.post(
      .chatCompletions,
      flow: .studyPath,
      body: requestBody(for: level)
    )
    guard let content = payload.choices.first?.message.content,
      let data = content.data(using: .utf8)
    else {
      throw OpenAIAPIClientError.invalidResponse
    }
    let path = try JSONDecoder().decode(StudyPathDefinition.self, from: data)
    guard path.isValid else { throw OpenAIAPIClientError.invalidResponse }
    return path
  }

  private func requestBody(for level: EnglishLevel) -> [String: Any] {
    [
      "model": OpenAIModel.textToText,
      "messages": [
        [
          "role": "system",
          "content": """
          You design structured English-learning journeys. Return only JSON matching the schema.
          The learner has just moved to an English-speaking town and must use English to live independently: settling in, daily life, community, work or study, and confident independent living.
          Create exactly 5 chapters, each with exactly 10 sequential situations. Give each situation a practical title, short subtitle, story setup, useful SF Symbol icon, and curriculum keyword seeds.
          For Beginner use simple greetings, concrete needs, short phrases, and 2 keyword seeds. For Intermediate use natural everyday exchanges and 3 seeds. For Advanced use nuanced, procedural, negotiation, and cultural exchanges with 4 or 5 seeds.
          Use only these character IDs: barista-alex, neighbor-anna, guide-jamie, vendor-taylor.
          Use only these location IDs: coffee-shop, apartment-entry, apartment-kitchen, city-park, community-lounge, recycling-area, city-street, supermarket, apartment-living-room.
          Assign chapter IDs "1" through "5" and global situation IDs "1" through "50" in strict numeric order. IDs must be JSON strings, never numbers.
          """,
        ],
        [
          "role": "user",
          "content": "Build this study path for a \(level.rawValue) English learner.",
        ],
      ],
      "response_format": [
        "type": "json_schema",
        "json_schema": [
          "name": "learner_study_path",
          "strict": true,
          "schema": schema,
        ],
      ],
    ]
  }

  private var schema: [String: Any] {
    [
      "type": "object",
      "properties": ["chapters": ["type": "array", "items": chapterSchema]],
      "required": ["chapters"],
      "additionalProperties": false,
    ]
  }

  private var chapterSchema: [String: Any] {
    [
      "type": "object",
      "properties": [
        "id": ["type": "string"],
        "title": ["type": "string"],
        "subtitle": ["type": "string"],
        "icon": ["type": "string"],
        "situations": ["type": "array", "items": situationSchema],
      ],
      "required": ["id", "title", "subtitle", "icon", "situations"],
      "additionalProperties": false,
    ]
  }

  private var situationSchema: [String: Any] {
    [
      "type": "object",
      "properties": [
        "id": ["type": "string"],
        "chapterId": ["type": "string"],
        "title": ["type": "string"],
        "subtitle": ["type": "string"],
        "story": ["type": "string"],
        "icon": ["type": "string"],
        "keywordSeeds": ["type": "array", "items": ["type": "string"]],
        "characterId": ["type": "string"],
        "locationId": ["type": "string"],
      ],
      "required": [
        "id", "chapterId", "title", "subtitle", "story", "icon", "keywordSeeds",
        "characterId", "locationId",
      ],
      "additionalProperties": false,
    ]
  }
}
