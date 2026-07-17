import SwiftUI

struct AdventureBackground: View {
  var body: some View {
    LinearGradient(
      colors: [ThemeApp.Colors.backgroundLight, ThemeApp.Colors.backgroundDark],
      startPoint: .topLeading, endPoint: .bottomTrailing
    )
    .overlay(alignment: .topTrailing) {
      Circle().fill(ThemeApp.Colors.mint.opacity(0.16)).frame(width: 240).blur(radius: 2).offset(
        x: 70, y: -90)
    }
    .ignoresSafeArea()
  }
}

struct GameButton: View {
  let title: String
  var icon: String? = nil
  var color: Color = ThemeApp.Colors.roadmapLine
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Text(title).font(ThemeApp.Fonts.ctaButton(size: 16))
        if let icon { Image(systemName: icon).fontWeight(.black) }
      }
      .foregroundStyle(ThemeApp.Colors.textDark)
      .frame(maxWidth: .infinity).padding(.vertical, 16)
      .background(color).clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.button))
      .overlay(
        RoundedRectangle(cornerRadius: ThemeApp.Radius.button).stroke(
          Color.white.opacity(0.35), lineWidth: 2)
      )
      .shadow(color: color.opacity(0.35), radius: 10, y: 6)
    }.buttonStyle(.plain)
  }
}

struct GameNavigationLink<Destination: View>: View {
  let title: String
  var icon: String? = nil
  var color: Color = ThemeApp.Colors.roadmapLine
  let destination: Destination

  var body: some View {
    NavigationLink(destination: destination) {
      HStack(spacing: 8) {
        Text(title).font(ThemeApp.Fonts.ctaButton(size: 16))
        if let icon { Image(systemName: icon).fontWeight(.black) }
      }
      .foregroundStyle(ThemeApp.Colors.textDark)
      .frame(maxWidth: .infinity).padding(.vertical, 16)
      .background(color).clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.button))
      .overlay(
        RoundedRectangle(cornerRadius: ThemeApp.Radius.button).stroke(
          Color.white.opacity(0.35), lineWidth: 2)
      )
      .shadow(color: color.opacity(0.35), radius: 10, y: 6)
    }
    .buttonStyle(.plain)
  }
}

struct GlassCard<Content: View>: View {
  let content: Content
  init(@ViewBuilder content: () -> Content) { self.content = content() }
  var body: some View {
    content.padding(18).background(ThemeApp.Colors.cardBackground)
      .background(.ultraThinMaterial.opacity(0.18))
      .clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.card))
      .overlay(
        RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(Color.white.opacity(0.18)))
  }
}

struct GameTag: View {
  let title: String
  var selected = false
  var body: some View {
    Text(title).font(ThemeApp.Fonts.bodyText(size: 13)).foregroundStyle(
      selected ? ThemeApp.Colors.textDark : ThemeApp.Colors.textLight
    )
    .padding(.horizontal, 12).padding(.vertical, 8)
    .background(selected ? ThemeApp.Colors.roadmapLine : Color.white.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
  }
}

struct SectionTitle: View {
  let title: String
  let subtitle: String?
  init(_ title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(ThemeApp.Fonts.gameTitle(size: 27)).foregroundStyle(
        ThemeApp.Colors.textLight)
      if let subtitle {
        Text(subtitle).font(ThemeApp.Fonts.bodyText(size: 14)).foregroundStyle(.white.opacity(0.72))
      }
    }
  }
}

struct AvatarView: View {
  let character: Character
  var size: CGFloat = 64
  var body: some View {
    ZStack {
      Circle().fill(character.color)
      Image(systemName: character.avatar).font(.system(size: size * 0.4, weight: .black))
        .foregroundStyle(ThemeApp.Colors.textDark)
    }.frame(width: size, height: size).overlay(
      Circle().stroke(Color.white.opacity(0.7), lineWidth: 3))
  }
}
