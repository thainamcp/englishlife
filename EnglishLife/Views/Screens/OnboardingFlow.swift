import SwiftUI

struct OnboardingFlow: View {
  @State private var page = 0
  @State private var isFillingInfo = false
  @EnvironmentObject private var state: AppViewModel
  private let slides: [(String, String, String, Color)] = [
    (
      "Learn English by living it", "Your next conversation is an adventure waiting to happen.",
      "map.fill", ThemeApp.Colors.roadmapLine
    ),
    (
      "Meet your own characters", "Create memorable friends with their own look and personality.",
      "person.2.fill", ThemeApp.Colors.accentPink
    ),
    (
      "Speak with confidence", "Practice real-life situations, one small win at a time.",
      "bubble.left.and.bubble.right.fill", ThemeApp.Colors.mint
    ),
  ]
  var body: some View {
    ZStack {
      AdventureBackground()
      if isFillingInfo {
        FillInfoView()
      } else {
        let slide = slides[page]
        VStack(spacing: 24) {
          Spacer()
          HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { index in
              Circle().fill(index == page ? ThemeApp.Colors.roadmapLine : .white.opacity(0.3))
                .frame(width: index == page ? 24 : 9, height: 9)
            }
          }
          ZStack {
            Circle().fill(slide.3.opacity(0.2)).frame(width: 220, height: 220)
            Image(systemName: slide.2).font(.system(size: 88, weight: .black)).foregroundStyle(
              slide.3)
          }
          Text(slide.0).multilineTextAlignment(.center).font(ThemeApp.Fonts.gameTitle(size: 32))
            .foregroundStyle(.white)
          Text(slide.1).multilineTextAlignment(.center).font(ThemeApp.Fonts.bodyText())
            .foregroundStyle(.white.opacity(0.78)).padding(.horizontal, 30)
          Spacer()
          GameButton(
            title: page == slides.count - 1 ? "Start my journey" : "Next", icon: "arrow.right"
          ) {
            if page < slides.count - 1 {
              withAnimation { page += 1 }
            } else {
              withAnimation { isFillingInfo = true }
            }
          }.padding(.horizontal, 24).padding(.bottom, 28)
        }
      }
    }
  }
}

struct FillInfoView: View {
  @EnvironmentObject private var state: AppViewModel
  @State private var name = ""
  @State private var level: EnglishLevel = .beginner
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Spacer()
      SectionTitle("Before we begin", subtitle: "Tell us a little about your adventure.")
      GlassCard {
        VStack(alignment: .leading, spacing: 18) {
          Text("Your name").font(ThemeApp.Fonts.bodyText()).foregroundStyle(.white)
          TextField("e.g. Mia", text: $name).font(ThemeApp.Fonts.bodyText()).padding(14).background(
            Color.white.opacity(0.12)
          ).clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
            .textInputAutocapitalization(.words)
          Text("English level").font(ThemeApp.Fonts.bodyText()).foregroundStyle(.white)
          HStack(spacing: 8) {
            ForEach(EnglishLevel.allCases) { item in
              Button {
                level = item
              } label: {
                VStack(spacing: 8) {
                  Image(systemName: item.icon)
                  Text(item.rawValue).font(ThemeApp.Fonts.bodyText(size: 11))
                    .multilineTextAlignment(.center)
                }.foregroundStyle(level == item ? ThemeApp.Colors.textDark : .white).frame(
                  maxWidth: .infinity
                ).padding(.vertical, 13).background(
                  level == item ? ThemeApp.Colors.roadmapLine : Color.white.opacity(0.1)
                ).clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
              }.buttonStyle(.plain)
            }
          }
        }
      }
      GameButton(title: "Enter English Life", icon: "sparkles") {
        state.learnerName = name.isEmpty ? "Explorer" : name
        state.level = level
        state.hasCompletedOnboarding = true
      }
      Spacer()
    }.padding(24)
  }
}
