import SwiftUI
import UIKit

struct SituationCardView: View {
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  let situation: Situation
  @StateObject private var narrativeViewModel = NarrativeViewModel()
  @StateObject private var sceneViewModel = SituationSceneViewModel()
  @State private var showsCharacterSetup = false
  private var progress: SituationProgress { state.progress(for: situation) }
  private var existingCharacter: Character? { state.character(for: situation) }

  var body: some View {
    NavigationStack {
      ZStack {
        AdventureBackground()
        VStack(spacing: 0) {
          missionHeader
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 10)

          ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
              VStack(alignment: .leading, spacing: 8) {
                Text(situation.title)
                  .font(ThemeApp.Fonts.gameTitle(size: 30))
                  .foregroundStyle(ThemeApp.Colors.textPrimary)
                Text(situation.subtitle)
                  .font(ThemeApp.Fonts.bodyText(size: 17))
                  .foregroundStyle(ThemeApp.Colors.textSecondary)
              }

              aiGuideCard
              keywordCard
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 18)
          }

          MissionPrimaryButton(
            title: missionButtonTitle,
            icon: missionButtonIcon,
            isLoading: isMissionButtonLoading
          ) {
            guard let character = existingCharacter else {
              showsCharacterSetup = true
              return
            }
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              state.presentChat(character: character, situation: situation)
            }
          }
          .allowsHitTesting(!isMissionButtonLoading)
          .padding(.horizontal, 30)
          .padding(.top, 12)
          .padding(.bottom, 14)
        }
      }
      .task {
        narrativeViewModel.configure(
          userName: state.learnerName,
          level: state.level,
          situation: situation,
          useCachedGuidance: true)
        async let guidance: Void = narrativeViewModel.requestGuidance(
          preferCached: true)
        async let scene: Void = sceneViewModel.prepare(for: situation, character: existingCharacter)
        _ = await (guidance, scene)
      }
      .navigationDestination(isPresented: $showsCharacterSetup) {
        CharacterSetupNameView(situation: situation, onHome: { dismiss() })
      }
    }
    .presentationDetents([.height(max(560, UIScreen.main.bounds.height - 210))])
  }

  private var missionHeader: some View {
    HStack {
      Spacer()
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.title3.weight(.bold))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
          .frame(width: 42, height: 42)
          .background(Color(hex: "#F48B8A"), in: Circle())
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)
    }
  }

  private var aiGuideCard: some View {
    MissionPanel {
      VStack(alignment: .leading, spacing: 8) {
        Label("Your AI Guide", systemImage: "sparkles")
          .font(ThemeApp.Fonts.ctaButton(size: 18))
          .foregroundStyle(ThemeApp.Colors.primary)

        if narrativeViewModel.isLoading {
          HStack(spacing: 9) {
            ProgressView().tint(ThemeApp.Colors.primary)
            Text("Creating your personalized mission…")
          }
          .font(ThemeApp.Fonts.bodyText(size: 14))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
        } else if let errorMessage = narrativeViewModel.errorMessage {
          Text(errorMessage)
            .font(ThemeApp.Fonts.bodyText(size: 13))
            .foregroundStyle(ThemeApp.Colors.textSecondary)
          Button("Try again") {
            Task { await narrativeViewModel.requestGuidance() }
          }
          .font(ThemeApp.Fonts.ctaButton(size: 13))
          .foregroundStyle(ThemeApp.Colors.primary)
        } else {
          Text(narrativeViewModel.guidance)
            .font(ThemeApp.Fonts.bodyText(size: 16))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private var keywordCard: some View {
    MissionPanel {
      VStack(alignment: .leading, spacing: 14) {
        Label("Mission Keywords", systemImage: "checkmark.seal.fill")
          .font(ThemeApp.Fonts.ctaButton(size: 18))
          .foregroundStyle(ThemeApp.Colors.textPrimary)

        if narrativeViewModel.isLoading {
          KeywordLoadingGrid()
        } else if let errorMessage = narrativeViewModel.errorMessage {
          Label("Keywords will appear after retrying.", systemImage: "arrow.clockwise")
            .font(ThemeApp.Fonts.bodyText(size: 13))
            .foregroundStyle(ThemeApp.Colors.textSecondary)
            .accessibilityLabel(errorMessage)
        } else {
          MissionKeywordPills(tags: narrativeViewModel.context?.targetKeywords ?? [])
        }

        Divider().overlay(ThemeApp.Colors.border)

        Label(
          "+\(situation.reward) XP · Unlock \(situation.unlock)",
          systemImage: "gift.fill"
        )
        .font(ThemeApp.Fonts.ctaButton(size: 15))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var missionButtonTitle: String {
    if existingCharacter == nil { return "Meet your character" }
    return sceneViewModel.isPreparing ? "Preparing your scene…" : "Start speaking"
  }

  private var missionButtonIcon: String {
    if existingCharacter == nil { return "arrow.right" }
    return sceneViewModel.isPreparing ? "hourglass" : "mic.fill"
  }

  private var isMissionButtonLoading: Bool {
    narrativeViewModel.isLoading || (existingCharacter != nil && sceneViewModel.isPreparing)
  }
}

private struct MissionPanel<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(26)
      .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 28))
      .overlay(RoundedRectangle(cornerRadius: 28).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
  }
}

private struct MissionPrimaryButton: View {
  let title: String
  let icon: String
  var isLoading = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Text(title)
        Image(systemName: icon)
      }
      .font(ThemeApp.Fonts.ctaButton(size: 18))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 64)
      .background(ThemeApp.Colors.primary.opacity(isLoading ? 0.48 : 1), in: Capsule())
      .overlay(
        Capsule().stroke(ThemeApp.Colors.border.opacity(isLoading ? 0.48 : 1), lineWidth: 1.5)
      )
    }
    .buttonStyle(.plain)
  }
}

private struct MissionKeywordPills: View {
  let tags: [String]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(tags, id: \.self) { tag in
          Text(tag)
            .font(ThemeApp.Fonts.bodyText(size: 14))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
      }
    }
  }
}

struct MissionKeywordGrid: View {
  let tags: [String]

  private let columns = [
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(Array(tags.enumerated()), id: \.offset) { index, keyword in
        HStack(alignment: .top, spacing: 8) {
          Text("\(index + 1)")
            .font(ThemeApp.Fonts.ctaButton(size: 11))
            .foregroundStyle(ThemeApp.Colors.primary)
            .frame(width: 22, height: 22)
            .background(ThemeApp.Colors.riverBlue, in: Circle())
          Text(keyword)
            .font(ThemeApp.Fonts.bodyText(size: 13))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
        .overlay(
          RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(ThemeApp.Colors.border)
        )
      }
    }
  }
}

struct KeywordLoadingGrid: View {
  private let columns = [
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(0..<4, id: \.self) { _ in
        RoundedRectangle(cornerRadius: ThemeApp.Radius.tag)
          .fill(ThemeApp.Colors.border.opacity(0.55))
          .frame(height: 54)
          .redacted(reason: .placeholder)
      }
    }
  }
}
