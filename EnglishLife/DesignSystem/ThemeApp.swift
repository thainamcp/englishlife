import SwiftUI

struct ThemeApp {
  struct Colors {
    // Onboarding Figma foundations — node 26:890.
    static let canvas = Color(hex: "#FFFFFF")
    static let primary = Color(hex: "#49B0AC")
    static let primaryLight = Color(hex: "#E6F4F4")
    static let accent = Color(hex: "#49B0AC")
    static let border = Color(hex: "#0D0D0D")
    static let textPrimary = Color(hex: "#0D0D0D")
    static let textSecondary = Color(hex: "#959595")
    static let surface = Color(hex: "#FAFEFD")

    // Existing semantic names retained so every screen adopts the new theme.
    static let backgroundDark = canvas
    static let backgroundLight = surface
    static let roadmapLine = primary
    static let riverBlue = primaryLight
    static let accentPink = Color(hex: "#8BCFCB")
    static let textLight = textPrimary
    static let textDark = textPrimary
    static let cardBackground = surface
    static let mint = primaryLight
    static let coral = primary
  }

  struct Fonts {
    static func gameTitle(size: CGFloat = 28) -> Font {
      .system(size: size, weight: .bold)
    }
    static func bodyText(size: CGFloat = 16) -> Font {
      .system(size: size, weight: .regular)
    }
    static func ctaButton(size: CGFloat = 18) -> Font {
      .system(size: size, weight: .bold)
    }

    static func tabLabel(size: CGFloat = 10) -> Font {
      .system(size: size, weight: .medium)
    }
  }

  struct Radius {
    static let card: CGFloat = 24
    static let button: CGFloat = 28
    static let tag: CGFloat = 12
  }
}

extension Color {
  init(hex: String) {
    let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: value).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch value.count {
    case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: (a, r, g, b) = (int >> 24, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    default: (a, r, g, b) = (1, 1, 1, 1)
    }
    self.init(
      .sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255,
      opacity: Double(a) / 255)
  }
}
