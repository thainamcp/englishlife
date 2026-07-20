import Foundation

/// Persists the AI-generated welcome and mission keywords for each situation.
/// A completed situation reuses this result instead of making another API call.
struct SituationGuidanceCache {
  static let shared = SituationGuidanceCache()

  private let key = "cachedSituationGuidance.v1"

  func guidance(for situationID: Int, using defaults: UserDefaults = .standard) -> NodeGuidance? {
    allGuidance(using: defaults)[String(situationID)]
  }

  func save(
    _ guidance: NodeGuidance,
    for situationID: Int,
    using defaults: UserDefaults = .standard
  ) {
    var records = allGuidance(using: defaults)
    records[String(situationID)] = guidance
    defaults.set(try? JSONEncoder().encode(records), forKey: key)
  }

  private func allGuidance(using defaults: UserDefaults) -> [String: NodeGuidance] {
    guard let data = defaults.data(forKey: key) else { return [:] }
    return (try? JSONDecoder().decode([String: NodeGuidance].self, from: data)) ?? [:]
  }
}
