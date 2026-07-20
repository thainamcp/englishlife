import Foundation
import SwiftUI

private struct ChapterDTO: Decodable {
  let id: String
  let title: String
  let subtitle: String
  let icon: String
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

/// Provides the bundled roadmap only as an offline fallback and maps an
/// AI-generated `StudyPathDefinition` into the app's runtime view models.
struct AppContentRepository {
  static let shared = AppContentRepository()

  let chapters: [AdventureChapter]
  let situations: [Situation]

  private let charactersByID: [String: CharacterTemplateDTO]
  private let locationsByID: [String: SceneLocation]

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
      charactersByID = [:]
      locationsByID = [:]
      chapters = []
      situations = []
      return
    }

    let characterLookup = Dictionary(uniqueKeysWithValues: characterDTOs.map { ($0.id, $0) })
    let locationLookup = Dictionary(uniqueKeysWithValues: locationDTOs.map { ($0.id, $0) })
    charactersByID = characterLookup
    locationsByID = locationLookup

    let fallbackDefinition = Self.fallbackDefinition(
      chapters: chapterDTOs,
      situations: situationDTOs
    )
    let fallbackPath = Self.makeRuntimePath(
      from: fallbackDefinition,
      charactersByID: characterLookup,
      locationsByID: locationLookup
    )
    chapters = fallbackPath.chapters
    situations = fallbackPath.situations
  }

  func runtimePath(from definition: StudyPathDefinition) -> RuntimeStudyPath {
    Self.makeRuntimePath(
      from: definition,
      charactersByID: charactersByID,
      locationsByID: locationsByID
    )
  }

  private static func fallbackDefinition(
    chapters: [ChapterDTO],
    situations: [SituationDTO]
  ) -> StudyPathDefinition {
    StudyPathDefinition(
      chapters: chapters.map { chapter in
        return StudyPathChapterDefinition(
          id: chapter.id,
          title: chapter.title,
          subtitle: chapter.subtitle,
          icon: chapter.icon,
          situations: situations.compactMap { situation in
            guard situation.chapterId == chapter.id else {
              return nil
            }
            return StudyPathSituationDefinition(
              id: situation.id,
              chapterID: chapter.id,
              title: situation.title,
              subtitle: "Practice practical English for your new life.",
              story:
                "A real-life moment is waiting. Use English to handle \(situation.title.lowercased()).",
              icon: situation.icon,
              imageAsset: situation.imageAsset,
              keywordSeeds: situation.keywords,
              characterID: situation.characterId,
              locationID: situation.locationId
            )
          }
        )
      }
    )
  }

  private static func makeRuntimePath(
    from definition: StudyPathDefinition,
    charactersByID: [String: CharacterTemplateDTO],
    locationsByID: [String: SceneLocation]
  ) -> RuntimeStudyPath {
    let chapterColors = [
      ThemeApp.Colors.primary,
      ThemeApp.Colors.accent,
      ThemeApp.Colors.roadmapLine,
      ThemeApp.Colors.backgroundLight,
      ThemeApp.Colors.accentPink,
    ]
    let chapterDefinitions = definition.chapters.sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }
    let chapters = chapterDefinitions.enumerated().map { index, chapter in
      AdventureChapter(
        id: chapter.id,
        title: chapter.title,
        subtitle: chapter.subtitle,
        icon: chapter.icon,
        color: chapterColors[index % chapterColors.count]
      )
    }
    let chaptersByID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
    let situationDefinitions = chapterDefinitions.flatMap(\.situations).sorted {
      (Int($0.id) ?? 0) < (Int($1.id) ?? 0)
    }
    let fallbackCharacter = CharacterTemplateDTO(
      id: "barista-alex", name: "Alex", gender: "Man", vibe: "Friendly", hair: "Curly",
      accessory: "Glasses"
    )
    let fallbackLocation = SceneLocation(
      id: "coffee-shop", name: "Coffee Shop",
      prompt: "a warm welcoming neighborhood coffee shop", backgroundAsset: "coffeeshope_background"
    )
    let situations = situationDefinitions.compactMap { item -> Situation? in
      guard let chapter = chaptersByID[item.chapterID] else { return nil }
      let character = charactersByID[item.characterID] ?? fallbackCharacter
      let location = locationsByID[item.locationID] ?? fallbackLocation
      let currentIndex = situationDefinitions.firstIndex(where: { $0.id == item.id })
      let unlock =
        currentIndex.flatMap { index in
          situationDefinitions.indices.contains(index + 1)
            ? situationDefinitions[index + 1].title : nil
        } ?? "English Mastery"
      return Situation(
        id: item.id,
        chapter: "Chapter \(chapter.id) · \(chapter.title)",
        title: item.title,
        subtitle: item.subtitle,
        icon: item.icon,
        imageAsset: item.imageAsset,
        color: chapter.color,
        goals: item.keywordSeeds,
        reward: 45 + (Int(item.id) ?? 0) * 5,
        unlock: unlock,
        story: item.story,
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
    return RuntimeStudyPath(chapters: chapters, situations: situations)
  }

  private static func data(named name: String) -> Data? {
    let bundle = Bundle.main
    let url =
      bundle.url(forResource: name, withExtension: "json", subdirectory: "Data/App")
      ?? bundle.url(forResource: name, withExtension: "json")
    return url.flatMap { try? Data(contentsOf: $0) }
  }
}
