import Foundation
import SwiftUI

/// Local persistence for the learner's journey. It deliberately stores stable
/// IDs and simple values rather than UI objects such as `Color`.
struct LearnerProgressStore {
  private enum Key {
    static let level = "learnerLevel"
    static let completedSituationIDs = "completedSituationIDs"
    static let resumeSituationID = "resumeSituationID"
    static let characters = "savedCharacters"
  }

  struct Snapshot {
    var level: EnglishLevel
    var completedSituationIDs: Set<Int>
    var resumeSituationID: Int?
    var characters: [Character]
  }

  private struct SavedCharacter: Codable {
    let id: UUID
    let templateID: String?
    let name: String
    let situationTitle: String
    let gender: String?
    let vibe: String
    let hair: String
    let accessory: String
    let avatar: String
    let avatarImageData: Data?
  }

  static func load(using defaults: UserDefaults = .standard) -> Snapshot {
    let level = EnglishLevel(rawValue: defaults.string(forKey: Key.level) ?? "") ?? .beginner
    let completed = Set(defaults.array(forKey: Key.completedSituationIDs) as? [Int] ?? [])
    let resumeID = defaults.object(forKey: Key.resumeSituationID) as? Int
    let savedCharacters = decodeCharacters(defaults.data(forKey: Key.characters))

    return Snapshot(
      level: level,
      completedSituationIDs: completed,
      resumeSituationID: resumeID,
      characters: savedCharacters.map(makeCharacter))
  }

  static func save(
    level: EnglishLevel,
    completedSituationIDs: Set<Int>,
    resumeSituationID: Int?,
    characters: [Character],
    using defaults: UserDefaults = .standard
  ) {
    defaults.set(level.rawValue, forKey: Key.level)
    defaults.set(Array(completedSituationIDs).sorted(), forKey: Key.completedSituationIDs)
    if let resumeSituationID {
      defaults.set(resumeSituationID, forKey: Key.resumeSituationID)
    } else {
      defaults.removeObject(forKey: Key.resumeSituationID)
    }

    let saved = characters.map {
      SavedCharacter(
        id: $0.id, templateID: $0.templateID, name: $0.name, situationTitle: $0.situationTitle,
        gender: $0.gender, vibe: $0.vibe, hair: $0.hair, accessory: $0.accessory,
        avatar: $0.avatar, avatarImageData: $0.avatarImageData)
    }
    defaults.set(try? JSONEncoder().encode(saved), forKey: Key.characters)
  }

  private static func decodeCharacters(_ data: Data?) -> [SavedCharacter] {
    guard let data else { return [] }
    return (try? JSONDecoder().decode([SavedCharacter].self, from: data)) ?? []
  }

  private static func makeCharacter(_ saved: SavedCharacter) -> Character {
    let situation = AppContentRepository.shared.situations.first {
      $0.title == saved.situationTitle
    }
    return Character(
      // Migrate characters saved before template IDs were introduced. Their
      // original situation tells us which reusable character they represent.
      id: saved.id, templateID: saved.templateID ?? situation?.characterID, name: saved.name,
      situationTitle: saved.situationTitle,
      gender: saved.gender ?? "Unspecified", vibe: saved.vibe, hair: saved.hair,
      accessory: saved.accessory,
      color: situation?.color ?? ThemeApp.Colors.accentPink, avatar: saved.avatar,
      avatarImageData: saved.avatarImageData)
  }
}
