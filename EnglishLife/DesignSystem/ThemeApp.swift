import SwiftUI

struct ThemeApp {
  struct Colors {
    static let backgroundDark = Color(hex: "#1A4347")
    static let backgroundLight = Color(hex: "#2B686E")
    static let roadmapLine = Color(hex: "#F4C430")
    static let riverBlue = Color(hex: "#C5E3E6")
    static let accentPink = Color(hex: "#E897A9")
    static let textLight = Color.white
    static let textDark = Color(hex: "#222222")
    static let cardBackground = Color.white.opacity(0.15)
    static let mint = Color(hex: "#9ED9BD")
    static let coral = Color(hex: "#EF875F")
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
    static let card: CGFloat = 20
    static let button: CGFloat = 16
    static let tag: CGFloat = 8
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
