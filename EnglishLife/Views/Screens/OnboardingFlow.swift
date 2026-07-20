import SwiftUI

struct OnboardingFlow: View {
  @EnvironmentObject private var state: AppViewModel
  @State private var page = 0
  @State private var isFillingInfo = false

  private let slides = [
    OnboardingSlide(
      title: "Time for a new adventure",
      message:
        "Learn English by interacting with friendly locals, exploring charming neighborhoods, and solving real-life challenges as you travel.",
      badge: "🚌 City Express",
      badgeColor: ThemeApp.Colors.primary,
      image: "OnboardingBus"),
    OnboardingSlide(
      title: "Flying to new horizons",
      message:
        "Embark on an immersive journey. Gain real conversational confidence by chatting with AI characters who respond just like real people.",
      badge: "✈️ Flight LV-101",
      badgeColor: ThemeApp.Colors.accent,
      image: "OnboardingPlane"),
    OnboardingSlide(
      title: "Welcome to your new city",
      message:
        "Every café, bookstore, and street corner hides a new puzzle. Solve real challenges to unlock locations and grow your skills!",
      badge: "🏙️ Lingo City",
      badgeColor: ThemeApp.Colors.primary,
      image: "OnboardingCity"),
  ]

  var body: some View {
    Group {
      if isFillingInfo {
        FillInfoView()
      } else {
        slideView
      }
    }
  }

  private var slideView: some View {
    let slide = slides[page]
    return ZStack {
      ThemeApp.Colors.canvas.ignoresSafeArea()
      OnboardingScreenLayout {
        VStack(spacing: 0) {
          HStack {
            Text("English").font(ThemeApp.Fonts.gameTitle(size: 24))
              .foregroundStyle(ThemeApp.Colors.primary)
            Spacer()
          }

          Spacer(minLength: 18)

          ZStack(alignment: .topLeading) {
            Image(slide.image)
              .resizable()
              .scaledToFill()
              .frame(maxWidth: .infinity)
              .frame(height: 340)
              .clipShape(RoundedRectangle(cornerRadius: 28))
            Text(slide.badge)
              .font(ThemeApp.Fonts.ctaButton(size: 12))
              .foregroundStyle(slide.badgeColor)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))
              .padding(14)
          }
          .overlay(RoundedRectangle(cornerRadius: 28).stroke(ThemeApp.Colors.border, lineWidth: 2))

          Spacer(minLength: 20)

          VStack(alignment: .leading, spacing: 12) {
            Text(slide.title)
              .font(ThemeApp.Fonts.gameTitle(size: 28))
              .foregroundStyle(ThemeApp.Colors.textPrimary)
            Text(slide.message)
              .font(ThemeApp.Fonts.bodyText(size: 15))
              .lineSpacing(3)
              .foregroundStyle(ThemeApp.Colors.textSecondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(20)
          .background(
            ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.card)
          )
          .overlay(
            RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(.white.opacity(0.93))
          )
          .shadow(color: ThemeApp.Colors.primary.opacity(0.08), radius: 12, y: 6)

          Spacer(minLength: 20)

          if page == slides.count - 1 {
            onboardingButton("Get Started") { isFillingInfo = true }
          } else {
            HStack {
              OnboardingPageIndicator(page: page, count: slides.count)
              Spacer()
              onboardingButton("Next") { page += 1 }
                .frame(width: 140)
            }
          }
        }
      }
    }
    .animation(.easeInOut(duration: 0.28), value: page)
  }

  private func onboardingButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
      .font(ThemeApp.Fonts.ctaButton(size: 17))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(ThemeApp.Colors.primary, in: Capsule())
      .shadow(color: ThemeApp.Colors.primary.opacity(0.18), radius: 8, y: 6)
      .buttonStyle(.plain)
  }
}

private struct OnboardingSlide {
  let title: String
  let message: String
  let badge: String
  let badgeColor: Color
  let image: String
}

private struct OnboardingPageIndicator: View {
  let page: Int
  let count: Int

  var body: some View {
    HStack(spacing: 6) {
      ForEach(0..<count, id: \.self) { index in
        Capsule()
          .fill(index == page ? ThemeApp.Colors.primary : ThemeApp.Colors.border)
          .frame(width: index == page ? 24 : 8, height: 8)
      }
    }
  }
}

struct FillInfoView: View {
  @EnvironmentObject private var state: AppViewModel
  @State private var name = ""
  @State private var level: EnglishLevel = .beginner

  var body: some View {
    ZStack {
      ThemeApp.Colors.canvas.ignoresSafeArea()
      OnboardingScreenLayout {
        VStack(alignment: .leading, spacing: 24) {
          Text("English").font(ThemeApp.Fonts.gameTitle(size: 24))
            .foregroundStyle(ThemeApp.Colors.primary)
          Spacer()
          Text("Before we begin").font(ThemeApp.Fonts.gameTitle(size: 30))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
          Text("Tell us a little about your adventure.")
            .font(ThemeApp.Fonts.bodyText()).foregroundStyle(ThemeApp.Colors.textSecondary)
          VStack(alignment: .leading, spacing: 18) {
            Text("Your name").font(ThemeApp.Fonts.ctaButton(size: 15))
            TextField(
              "e.g. Mia",
              text: $name,
              prompt: Text("e.g. Mia").foregroundStyle(ThemeApp.Colors.textSecondary)
            )
            .font(ThemeApp.Fonts.bodyText())
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .tint(ThemeApp.Colors.primary)
            .padding(14).background(
              .white, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
            Text("English level").font(ThemeApp.Fonts.ctaButton(size: 15))
            HStack(spacing: 8) {
              ForEach(EnglishLevel.allCases) { item in
                Button {
                  level = item
                } label: {
                  VStack(spacing: 7) {
                    Image(systemName: item.icon)
                    Text(item.rawValue).font(ThemeApp.Fonts.bodyText(size: 11))
                      .multilineTextAlignment(.center)
                  }
                  .foregroundStyle(level == item ? .white : ThemeApp.Colors.textPrimary)
                  .frame(maxWidth: .infinity).padding(.vertical, 12)
                  .background(
                    level == item ? ThemeApp.Colors.primary : .white,
                    in: RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
                }.buttonStyle(.plain)
              }
            }
          }
          .padding(20)
          .background(
            ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.card))
          Button("Enter English") {
            state.learnerName = name.isEmpty ? "Explorer" : name
            state.level = level
            state.hasCompletedOnboarding = true
          }
          .font(ThemeApp.Fonts.ctaButton(size: 17)).foregroundStyle(.white)
          .frame(maxWidth: .infinity).frame(height: 56)
          .background(ThemeApp.Colors.primary, in: Capsule())
          .buttonStyle(.plain)
          Spacer()
        }
      }
    }
  }
}

private struct OnboardingScreenLayout<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    GeometryReader { proxy in
      content
        .frame(
          width: max(proxy.size.width - 48, 0),
          height: max(proxy.size.height - 48, 0),
          alignment: .top
        )
        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
    }
  }
}
