import Foundation
import OSLog

enum OpenAIEndpoint {
  case chatCompletions
  case imageGenerations

  fileprivate var path: String {
    switch self {
    case .chatCompletions: "chat/completions"
    case .imageGenerations: "images/generations"
    }
  }
}

enum OpenAIAPIClientError: LocalizedError {
  case missingAPIKey(APIFlow)
  case invalidResponse
  case server(message: String)

  var errorDescription: String? {
    switch self {
    case .missingAPIKey(let flow):
      return "Add the API key for \(flow.description) to Secret.plist."
    case .invalidResponse:
      return "The OpenAI response could not be read."
    case .server(let message):
      return message
    }
  }
}

/// Centralized HTTP client for all OpenAI REST requests in the app.
final class OpenAIAPIClient {
  static let shared = OpenAIAPIClient()

  private let baseURL = URL(string: "https://api.openai.com/v1/")!
  private let session: URLSession
  private let logger = Logger(subsystem: "com.englishlife.app", category: "OpenAI")

  init(session: URLSession = .shared) {
    self.session = session
  }

  func post<Response: Decodable>(
    _ endpoint: OpenAIEndpoint,
    flow: APIFlow,
    body: [String: Any],
    response: Response.Type = Response.self
  ) async throws -> Response {
    let requestID = String(UUID().uuidString.prefix(8))
    let model = body["model"] as? String ?? "not-specified"
    let startedAt = Date()

    guard let key = APIConfiguration.key(for: flow) else {
      logger.error(
        "[\(requestID, privacy: .public)] missing API key feature=\(flow.rawValue, privacy: .public) model=\(model, privacy: .public)"
      )
      throw OpenAIAPIClientError.missingAPIKey(flow)
    }

    logger.info(
      "[\(requestID, privacy: .public)] request feature=\(flow.rawValue, privacy: .public) endpoint=\(endpoint.path, privacy: .public) model=\(model, privacy: .public)"
    )

    var request = URLRequest(url: baseURL.appending(path: endpoint.path))
    request.httpMethod = "POST"
    request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let data: Data
    let urlResponse: URLResponse
    do {
      (data, urlResponse) = try await session.data(for: request)
    } catch {
      logger.error(
        "[\(requestID, privacy: .public)] network failure feature=\(flow.rawValue, privacy: .public) model=\(model, privacy: .public)"
      )
      throw error
    }
    guard let httpResponse = urlResponse as? HTTPURLResponse else {
      logger.error(
        "[\(requestID, privacy: .public)] invalid HTTP response feature=\(flow.rawValue, privacy: .public) model=\(model, privacy: .public)"
      )
      throw OpenAIAPIClientError.invalidResponse
    }
    guard 200..<300 ~= httpResponse.statusCode else {
      logger.error(
        "[\(requestID, privacy: .public)] response feature=\(flow.rawValue, privacy: .public) model=\(model, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)"
      )
      let message =
        (try? JSONDecoder().decode(OpenAIAPIErrorEnvelope.self, from: data).error.message)
        ?? "OpenAI request failed (\(httpResponse.statusCode))."
      throw OpenAIAPIClientError.server(message: message)
    }

    do {
      let decoded = try JSONDecoder().decode(response, from: data)
      let durationMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
      logger.info(
        "[\(requestID, privacy: .public)] success feature=\(flow.rawValue, privacy: .public) model=\(model, privacy: .public) status=\(httpResponse.statusCode, privacy: .public) duration_ms=\(durationMs, privacy: .public)"
      )
      return decoded
    } catch {
      logger.error(
        "[\(requestID, privacy: .public)] decode failure feature=\(flow.rawValue, privacy: .public) model=\(model, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)"
      )
      throw OpenAIAPIClientError.invalidResponse
    }
  }
}

struct OpenAIChatCompletionResponse: Decodable {
  struct Choice: Decodable {
    struct Message: Decodable { let content: String? }
    let message: Message
  }

  let choices: [Choice]
}

private struct OpenAIAPIErrorEnvelope: Decodable {
  struct APIError: Decodable { let message: String }
  let error: APIError
}
