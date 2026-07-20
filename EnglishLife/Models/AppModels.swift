import SwiftUI
import UIKit

enum EnglishLevel: String, CaseIterable, Identifiable {
  case beginner = "Beginner"
  case intermediate = "Intermediate"
  case advanced = "Advanced"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .beginner: "leaf.fill"
    case .intermediate: "flame.fill"
    case .advanced: "crown.fill"
    }
  }
}

/// Runtime presentation model. Its content is loaded from `Data/App/situations.json`.
struct Situation: Identifiable, Hashable {
  let id: Int
  let chapter: String
  let title: String
  let subtitle: String
  let icon: String
  let imageAsset: String?
  let color: Color
  let goals: [String]
  let reward: Int
  let unlock: String
  let story: String
  let characterID: String
  let characterName: String
  let characterGender: String
  let characterVibe: String
  let characterHair: String
  let characterAccessory: String
  let locationID: String
  let locationName: String
  let locationPrompt: String
  let locationBackgroundAsset: String?
}

/// Runtime presentation model. Its content is loaded from `Data/App/chapters.json`.
struct AdventureChapter: Identifiable, Hashable {
  let id: Int
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
}

enum SituationProgress: Equatable {
  case locked
  case available
  case completed

  var label: String {
    switch self {
    case .locked: "Locked"
    case .available, .completed: "Ready to play"
    }
  }

  var icon: String {
    switch self {
    case .locked: "lock.fill"
    case .available: "play.fill"
    case .completed: "checkmark"
    }
  }
}

struct Character: Identifiable, Hashable {
  let id: UUID
  /// Stable ID from `characters.json`. A generated image cache is not proof
  /// that the learner has created this character; a saved Character is.
  var templateID: String?
  var name: String
  var situationTitle: String
  var gender: String
  var vibe: String
  var hair: String
  var accessory: String
  var color: Color
  var avatar: String
  var avatarImageData: Data?
}

struct ChatSession: Identifiable {
  let id = UUID()
  let character: Character
  let situation: Situation?
}
