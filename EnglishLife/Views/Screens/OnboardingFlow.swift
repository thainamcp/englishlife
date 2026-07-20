import SwiftUI

struct OnboardingFlow: View {
  @EnvironmentObject private var state: AppViewModel
  @State private var page = 0
  @State private var isFillingInfo = false

  private let slides = [
    OnboardingSlide(
      title: "Leaving Your Hometown",
      message: "It's time to say goodbye and begin a brand-new chapter.",
      tagImage: "onboarding1_tag",
      image: "onboarding1"),
    OnboardingSlide(
      title: "Heading to a New City",
      message: "Get ready for new experiences and\nnew conversations.",
      tagImage: "onboarding2_tag",
      image: "onboarding2"),
    OnboardingSlide(
      title: "Your Story Starts Here",
      message:
        "Learn English as you build your new life, one conversation at a time.",
      tagImage: "onboarding3_tag",
      image: "onboarding3"),
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
          ZStack(alignment: .topLeading) {
            Image(slide.image)
              .resizable()
              .scaledToFill()
              // The current exported artwork includes a thin bitmap outline.
              // Scale it slightly so SwiftUI owns the single 1.5pt outer stroke.
              .scaleEffect(1.015)

            OnboardingBadge(slide: slide)
              .padding(.leading, 20)
              .padding(.top, 50)
          }
          .frame(maxWidth: .infinity)
          .frame(height: 438)
          .clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.card))
          .overlay(
            RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(
              ThemeApp.Colors.border,
              lineWidth: 1.5
            )
          )

          Spacer(minLength: 20)

          VStack(alignment: .leading, spacing: 12) {
            Text(slide.title)
              .font(ThemeApp.Fonts.gameTitle(size: 28))
              .foregroundStyle(ThemeApp.Colors.textPrimary)
            Text(slide.message)
              .font(ThemeApp.Fonts.bodyText(size: 15))
              .foregroundStyle(ThemeApp.Colors.textSecondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(20)
          .background(
            ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.card)
          )
          .overlay(
            RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(
              ThemeApp.Colors.border,
              lineWidth: 1.5
            )
          )

          Spacer(minLength: 10)

          OnboardingPageIndicator(page: page, count: slides.count)
            .frame(height: 44)

          onboardingButton("Continue") {
            if page == slides.count - 1 {
              isFillingInfo = true
            } else {
              page += 1
            }
          }
          .frame(width: 265)
          .padding(.bottom, 50)
        }
        .padding(.top, 16)
      }
    }
    .animation(.easeInOut(duration: 0.28), value: page)
  }

  private func onboardingButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
      .font(ThemeApp.Fonts.ctaButton(size: 17))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 60)
      .background(ThemeApp.Colors.primary, in: Capsule())
      .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 2))
      .buttonStyle(.plain)
  }
}

private struct OnboardingSlide {
  let title: String
  let message: String
  let tagImage: String
  let image: String
}

private struct OnboardingBadge: View {
  let slide: OnboardingSlide

  var body: some View {
    Image(slide.tagImage)
      .resizable()
      .scaledToFit()
      .frame(height: 28)
  }
}

private struct OnboardingPageIndicator: View {
  let page: Int
  let count: Int

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<count, id: \.self) { index in
        Circle()
          .fill(ThemeApp.Colors.border.opacity(index == page ? 1 : 0.3))
          .frame(width: 8, height: 8)
      }
    }
  }
}

struct FillInfoView: View {
  @EnvironmentObject private var state: AppViewModel
  @State private var name = ""
  @State private var level: EnglishLevel = .beginner
  @FocusState private var isNameFocused: Bool

  var body: some View {
    ZStack {
      ThemeApp.Colors.canvas.ignoresSafeArea()
      OnboardingScreenLayout {
        VStack(alignment: .leading, spacing: 0) {
          // Fixed spacing: 16pt screen inset + 40pt = 56pt below the status bar.
          Color.clear.frame(height: 40)
          VStack(alignment: .leading, spacing: 8) {
            Text("Before we begin").font(ThemeApp.Fonts.gameTitle(size: 28))
              .foregroundStyle(ThemeApp.Colors.textPrimary)
            Text("Tell us a little about your adventure.")
              .font(ThemeApp.Fonts.bodyText(size: 15))
              .foregroundStyle(ThemeApp.Colors.textPrimary)
          }
          .padding(.bottom, 24)
          VStack(alignment: .leading, spacing: 16) {
            Text("Your name").font(ThemeApp.Fonts.ctaButton(size: 18))
            TextField(
              "e.g. Mert",
              text: $name,
              prompt: Text("e.g. Mert").foregroundStyle(ThemeApp.Colors.textSecondary)
            )
            .font(ThemeApp.Fonts.bodyText(size: 15))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .tint(ThemeApp.Colors.primary)
            .focused($isNameFocused)
            .padding(.horizontal, 20)
            .frame(height: 54)
            .background(.white, in: Capsule())
            .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1))
            Text("English Level").font(ThemeApp.Fonts.ctaButton(size: 18))
            HStack(spacing: 8) {
              ForEach(EnglishLevel.allCases) { item in
                Button {
                  level = item
                } label: {
                  VStack(spacing: 7) {
                    Text(item.icon).font(ThemeApp.Fonts.bodyText(size: 28))
                    Text(item.rawValue).font(ThemeApp.Fonts.bodyText(size: 15))
                      .multilineTextAlignment(.center)
                  }
                  .foregroundStyle(level == item ? .white : ThemeApp.Colors.textPrimary)
                  .frame(maxWidth: .infinity)
                  .frame(height: 96)
                  .background(
                    level == item ? ThemeApp.Colors.primary : .white,
                    in: RoundedRectangle(cornerRadius: ThemeApp.Radius.card)
                  )
                  .overlay(
                    RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(
                      ThemeApp.Colors.border,
                      lineWidth: 1
                    )
                  )
                }.buttonStyle(.plain)
              }
            }
          }
          .padding(.bottom, 16)
          Spacer(minLength: 0)
          Button {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
              isNameFocused = true
              return
            }

            Task {
              state.learnerName = trimmedName
              await state.createStudyPath(for: level)
              state.hasCompletedOnboarding = true
            }
          } label: {
            HStack(spacing: 10) {
              if state.isGeneratingStudyPath {
                ProgressView().tint(.white)
              }
              Text(state.isGeneratingStudyPath ? "Building your study path…" : "Get Start")
            }
            .font(ThemeApp.Fonts.ctaButton(size: 17))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(ThemeApp.Colors.primary, in: Capsule())
            .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 2))
          }
          .buttonStyle(.plain)
          .disabled(state.isGeneratingStudyPath)
          .opacity(state.isGeneratingStudyPath ? 0.72 : 1)
          .frame(width: 265)
          .frame(maxWidth: .infinity)
          .padding(.bottom, 50)
        }
        .padding(.top, 16)
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
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.horizontal, 16)
  }
}
