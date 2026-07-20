import SwiftUI

@MainActor
final class SituationSceneViewModel: ObservableObject {
  @Published private(set) var characterImageData: Data?
  @Published private(set) var backgroundImageData: Data?
  @Published private(set) var isPreparing = false
  @Published private(set) var errorMessage: String?

  private let imageClient = AvatarGenerationAPIClient()
  private let cache = GeneratedMediaCache.shared

  func prepare(for situation: Situation, character: Character?) async {
    guard !isPreparing else { return }
    isPreparing = true
    errorMessage = nil
    defer { isPreparing = false }

    characterImageData =
      character?.avatarImageData
      ?? cache.imageData(for: "character-\(situation.characterID)")
    if situation.locationBackgroundAsset == nil {
      backgroundImageData = await backgroundImage(for: situation)
    } else {
      backgroundImageData = nil
    }

    if backgroundImageData == nil && situation.locationBackgroundAsset == nil {
      errorMessage =
        "Some scene artwork could not be generated. You can still practice with the illustrated fallback."
    }
  }

  private func backgroundImage(for situation: Situation) async -> Data? {
    let key = "location-\(situation.locationID)"
    if let cached = cache.imageData(for: key) { return cached }
    do {
      let generated = try await imageClient.generateLocation(
        named: situation.locationName,
        description: situation.locationPrompt
      )
      cache.save(generated, for: key)
      return generated
    } catch {
      return nil
    }
  }
}
