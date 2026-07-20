import SwiftUI

struct ThemeApp {
  struct Colors {
    // English foundations, extracted from the onboarding Figma frames.
    static let canvas = Color(hex: "#FAF6F0")
    static let primary = Color(hex: "#2E6F40")
    static let primaryLight = Color(hex: "#5A9B6B")
    static let accent = Color(hex: "#FF9F43")
    static let border = Color(hex: "#EADFC9")
    static let textPrimary = Color(hex: "#22252A")
    static let textSecondary = Color(hex: "#6D727A")
    static let surface = Color.white.opacity(0.70)

    // Existing semantic names retained so every screen adopts the new theme.
    static let backgroundDark = canvas
    static let backgroundLight = Color.white
    static let roadmapLine = accent
    static let riverBlue = Color(hex: "#DDEDE1")
    static let accentPink = Color(hex: "#F6B6A4")
    static let textLight = textPrimary
    static let textDark = textPrimary
    static let cardBackground = surface
    static let mint = Color(hex: "#BFE3C8")
    static let coral = accent
  }

  struct Fonts {
    static func gameTitle(size: CGFloat = 28) -> Font {
      .system(size: size, weight: .black, design: .rounded)
    }
    static func bodyText(size: CGFloat = 16) -> Font {
      .system(size: size, weight: .medium, design: .rounded)
    }
    static func ctaButton(size: CGFloat = 18) -> Font {
      .system(size: size, weight: .bold, design: .rounded)
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
