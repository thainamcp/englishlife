import SwiftUI

@MainActor
final class CharacterSetupViewModel: ObservableObject {
  @Published var name = "Alex"
  @Published var gender = "Woman"
  @Published var vibe = "Friendly"
  @Published var hair = "Curly"
  @Published var accessory = "Glasses"
  @Published var hasRevealedAvatar = false
  @Published private(set) var isGeneratingAvatar = false
  @Published private(set) var avatarImageData: Data?
  @Published private(set) var avatarGenerationError: String?

  private let avatarClient = AvatarGenerationAPIClient()
  private let cache = GeneratedMediaCache.shared
  private var templateID: String?

  let nameSuggestions = ["Alex", "Jamie", "Taylor", "Riley"]

  func selectName(_ name: String) { self.name = name }

  func configure(for situation: Situation) {
    guard templateID != situation.characterID else { return }
    templateID = situation.characterID
    name = situation.characterName
    gender = situation.characterGender
    vibe = situation.characterVibe
    hair = situation.characterHair
    accessory = situation.characterAccessory
    hasRevealedAvatar = false
    avatarImageData = nil
    avatarGenerationError = nil
  }

  func character(for situation: Situation) -> Character {
    Character(
      id: UUID(),
      templateID: situation.characterID,
      name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Alex" : name,
      situationTitle: situation.title,
      gender: gender,
      vibe: vibe,
      hair: hair,
      accessory: accessory,
      color: situation.color,
      avatar: accessory == "Glasses"
        ? "face.smiling" : accessory == "Cap" ? "baseball.cap.fill" : "face.dashed",
      avatarImageData: avatarImageData
    )
  }

  func revealAvatar(for situation: Situation) async {
    guard !isGeneratingAvatar else { return }
    isGeneratingAvatar = true
    avatarGenerationError = nil
    defer { isGeneratingAvatar = false }

    let cacheKey = "character-\(situation.characterID)"
    if let cached = cache.imageData(for: cacheKey) {
      avatarImageData = cached
      withAnimation(.spring) { hasRevealedAvatar = true }
      return
    }

    do {
      avatarImageData = try await avatarClient.generate(
        name: name,
        gender: gender,
        vibe: vibe,
        hair: hair,
        accessory: accessory
      )
      if let avatarImageData { cache.save(avatarImageData, for: cacheKey) }
    } catch {
      avatarGenerationError = error.localizedDescription
    }
    withAnimation(.spring) { hasRevealedAvatar = true }
  }

  func regenerateAvatar(for situation: Situation) async {
    hasRevealedAvatar = false
    await revealAvatar(for: situation)
  }
}
