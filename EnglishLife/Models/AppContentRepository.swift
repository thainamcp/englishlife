import Foundation
import SwiftUI

private struct ChapterDTO: Decodable {
  let id: String
  let title: String
  let subtitle: String
  let icon: String
  let colorHex: String
}

private struct SituationDTO: Decodable {
  let id: String
  let chapterId: String
  let title: String
  let icon: String
  let imageAsset: String?
  let keywords: [String]
  let characterId: String
  let locationId: String
}

private struct CharacterTemplateDTO: Decodable {
  let id: String
  let name: String
  let gender: String?
  let vibe: String
  let hair: String
  let accessory: String
}

private struct SceneLocation: Decodable {
  let id: String
  let name: String
  let prompt: String
  let backgroundAsset: String?
}

/// The roadmap's source of truth. Add or edit records in `Data/App/*.json`.
struct AppContentRepository {
  static let shared = AppContentRepository()

  let chapters: [AdventureChapter]
  let situations: [Situation]

  private init() {
    guard
      let chapterData = Self.data(named: "chapters"),
      let situationData = Self.data(named: "situations"),
      let characterData = Self.data(named: "characters"),
      let locationData = Self.data(named: "locations"),
      let chapterDTOs = try? JSONDecoder().decode([ChapterDTO].self, from: chapterData),
      let situationDTOs = try? JSONDecoder().decode([SituationDTO].self, from: situationData),
      let characterDTOs = try? JSONDecoder().decode(
        [CharacterTemplateDTO].self, from: characterData),
      let locationDTOs = try? JSONDecoder().decode([SceneLocation].self, from: locationData)
    else {
      chapters = []
      situations = []
      return
    }

    chapters = chapterDTOs.compactMap { item -> AdventureChapter? in
      guard let id = Int(item.id) else { return nil }
      return AdventureChapter(
        id: id, title: item.title, subtitle: item.subtitle, icon: item.icon,
        color: Color(hex: item.colorHex))
    }
    let chaptersByID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
    let charactersByID = Dictionary(uniqueKeysWithValues: characterDTOs.map { ($0.id, $0) })
    let locationsByID = Dictionary(uniqueKeysWithValues: locationDTOs.map { ($0.id, $0) })
    situations = situationDTOs.compactMap { item -> Situation? in
      guard let id = Int(item.id), let chapterID = Int(item.chapterId),
        let chapter = chaptersByID[chapterID]
      else { return nil }
      let unlockTitle =
        situationDTOs.first(where: { Int($0.id) == id + 1 })?.title ?? "English Mastery"
      let character =
        charactersByID[item.characterId]
        ?? characterDTOs.first
        ?? CharacterTemplateDTO(
          id: "alex", name: "Alex", gender: "Man", vibe: "Friendly", hair: "Curly",
          accessory: "Glasses")
      guard let location = locationsByID[item.locationId] else { return nil }
      return Situation(
        id: id,
        chapter: "Chapter \(chapter.id) · \(chapter.title)",
        title: item.title,
        subtitle: "Practice practical English for your new life.",
        icon: item.icon,
        imageAsset: item.imageAsset,
        color: chapter.color,
        goals: item.keywords,
        reward: 45 + id * 5,
        unlock: unlockTitle,
        story: "A real-life moment is waiting. Use English to handle \(item.title.lowercased()).",
        characterID: character.id,
        characterName: character.name,
        characterGender: character.gender ?? "Non-binary",
        characterVibe: character.vibe,
        characterHair: character.hair,
        characterAccessory: character.accessory,
        locationID: location.id,
        locationName: location.name,
        locationPrompt: location.prompt,
        locationBackgroundAsset: location.backgroundAsset
      )
    }
  }

  private static func data(named name: String) -> Data? {
    let bundle = Bundle.main
    let url =
      bundle.url(forResource: name, withExtension: "json", subdirectory: "Data/App")
      ?? bundle.url(forResource: name, withExtension: "json")
    return url.flatMap { try? Data(contentsOf: $0) }
  }

}
