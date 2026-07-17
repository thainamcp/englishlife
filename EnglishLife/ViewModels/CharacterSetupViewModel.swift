import SwiftUI

@MainActor
final class CharacterSetupViewModel: ObservableObject {
  @Published var name = "Alex"
  @Published var vibe = "Friendly"
  @Published var hair = "Curly"
  @Published var accessory = "Glasses"
  @Published var hasRevealedAvatar = false

  let nameSuggestions = ["Alex", "Jamie", "Taylor", "Riley"]

  func selectName(_ name: String) { self.name = name }

  func character(for situation: Situation) -> Character {
    Character(
      id: UUID(),
      name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Alex" : name,
      situationTitle: situation.title,
      vibe: vibe,
      hair: hair,
      accessory: accessory,
      color: situation.color,
      avatar: accessory == "Glasses"
        ? "face.smiling" : accessory == "Cap" ? "baseball.cap.fill" : "face.dashed"
    )
  }

  func revealAvatar() async {
    try? await Task.sleep(for: .seconds(1.2))
    withAnimation(.spring) { hasRevealedAvatar = true }
  }
}
