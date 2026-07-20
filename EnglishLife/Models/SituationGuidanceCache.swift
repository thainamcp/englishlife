import Foundation

/// Persists the AI-generated welcome and mission keywords for a specific
/// learner level and generated situation. Any later visit reuses it.
struct SituationGuidanceCache {
  static let shared = SituationGuidanceCache()

  private let key = "cachedSituationGuidance.v1"

  func guidance(for context: SituationAIContext, using defaults: UserDefaults = .standard)
    -> NodeGuidance?
  {
    allGuidance(using: defaults)[cacheKey(for: context)]
  }

  func save(
    _ guidance: NodeGuidance,
    for context: SituationAIContext,
    using defaults: UserDefaults = .standard
  ) {
    var records = allGuidance(using: defaults)
    records[cacheKey(for: context)] = guidance
    defaults.set(try? JSONEncoder().encode(records), forKey: key)
  }

  private func allGuidance(using defaults: UserDefaults) -> [String: NodeGuidance] {
    guard let data = defaults.data(forKey: key) else { return [:] }
    return (try? JSONDecoder().decode([String: NodeGuidance].self, from: data)) ?? [:]
  }

  private func cacheKey(for context: SituationAIContext) -> String {
    "\(context.situationID)|\(context.level)|\(context.situationTitle)"
  }
}
