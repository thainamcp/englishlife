import SwiftUI
import UIKit

struct CharacterSetupNameView: View {
  let situation: Situation
  let onHome: () -> Void
  @StateObject private var viewModel = CharacterSetupViewModel()
  var body: some View {
    SetupShell(title: "A new friend", progress: 1) {
      VStack(alignment: .leading, spacing: 20) {
        StoryCard(text: situation.story, symbol: "sparkles")
        Text("What is their name?").font(ThemeApp.Fonts.ctaButton()).foregroundStyle(
          ThemeApp.Colors.textPrimary)
        TextField(
          "Character name",
          text: $viewModel.name,
          prompt: Text("Character name").foregroundStyle(ThemeApp.Colors.textSecondary)
        )
        .font(ThemeApp.Fonts.bodyText())
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .tint(ThemeApp.Colors.primary)
        .padding(16)
        .background(Color.white).clipShape(
          RoundedRectangle(cornerRadius: ThemeApp.Radius.tag)
        ).overlay(
          RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(ThemeApp.Colors.border))
        Text("Quick picks").font(ThemeApp.Fonts.bodyText(size: 14)).foregroundStyle(
          ThemeApp.Colors.textSecondary)
        HStack {
          ForEach(viewModel.nameSuggestions, id: \.self) { item in
            Button {
              viewModel.selectName(item)
            } label: {
              GameTag(title: item, selected: viewModel.name == item)
            }.buttonStyle(.plain)
          }
        }
        Spacer()
        GameNavigationLink(
          title: "Choose their style", icon: "arrow.right",
          destination: CharacterAppearanceView(
            situation: situation, viewModel: viewModel, onHome: onHome))
      }
    }
    .onAppear { viewModel.configure(for: situation) }
  }
}

struct CharacterAppearanceView: View {
  let situation: Situation
  @ObservedObject var viewModel: CharacterSetupViewModel
  let onHome: () -> Void
  var body: some View {
    SetupShell(title: "Style your friend", progress: 2) {
      VStack(alignment: .leading, spacing: 18) {
        StoryCard(
          text: "Every detail shapes how \(viewModel.name) appears on your adventure.",
          symbol: "wand.and.stars")
        ChoiceRow(
          title: "Gender", choices: ["Woman", "Man", "Non-binary"], selection: $viewModel.gender)
        ChoiceRow(
          title: "Vibe", choices: ["Friendly", "Cool", "Cheerful"], selection: $viewModel.vibe)
        ChoiceRow(title: "Hair", choices: ["Curly", "Short", "Long"], selection: $viewModel.hair)
        ChoiceRow(
          title: "Accessory", choices: ["Glasses", "Cap", "Earrings"],
          selection: $viewModel.accessory)
        Spacer()
        GameNavigationLink(
          title: "Bring \(viewModel.name) to life", icon: "sparkles",
          destination: CharacterRevealView(
            situation: situation, viewModel: viewModel, onHome: onHome))
      }
    }
  }
}

struct CharacterRevealView: View {
  @EnvironmentObject private var state: AppViewModel
  let situation: Situation
  @ObservedObject var viewModel: CharacterSetupViewModel
  let onHome: () -> Void
  private var character: Character { viewModel.character(for: situation) }
  var body: some View {
    SetupShell(title: "Say hello", progress: 3) {
      VStack(spacing: 24) {
        StoryCard(
          text: viewModel.hasRevealedAvatar
            ? "\(viewModel.name) is ready to meet you. Your story begins now!"
            : "Your character is arriving from the English universe…", symbol: "sparkles")
        Spacer()
        Group {
          if viewModel.hasRevealedAvatar {
            AvatarView(character: character, size: 176).transition(.scale.combined(with: .opacity))
            Text(viewModel.name).font(ThemeApp.Fonts.gameTitle(size: 35)).foregroundStyle(
              ThemeApp.Colors.textPrimary)
            Text(
              "\(viewModel.gender) · \(viewModel.vibe) · \(viewModel.hair) hair · \(viewModel.accessory)"
            ).font(
              ThemeApp.Fonts.bodyText()
            ).foregroundStyle(ThemeApp.Colors.textSecondary)
            if let error = viewModel.avatarGenerationError {
              Text(error).font(ThemeApp.Fonts.bodyText(size: 12)).multilineTextAlignment(.center)
                .foregroundStyle(ThemeApp.Colors.textSecondary)
              Button("Try generating again") {
                Task { await viewModel.regenerateAvatar(for: situation) }
              }
              .font(ThemeApp.Fonts.ctaButton(size: 13))
              .foregroundStyle(ThemeApp.Colors.primary)
            }
          } else {
            ProgressView().tint(ThemeApp.Colors.roadmapLine).scaleEffect(1.5)
            Text("Creating your character portrait...").font(ThemeApp.Fonts.bodyText())
              .foregroundStyle(
                ThemeApp.Colors.textSecondary)
          }
        }
        Spacer()
        if viewModel.hasRevealedAvatar {
          GameButton(title: "Talk to \(viewModel.name)", icon: "bubble.left.and.bubble.right.fill")
          {
            state.save(character: character)
            onHome()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              state.presentChat(character: character, situation: situation)
            }
          }
        }
      }
      .task {
        await viewModel.revealAvatar(for: situation)
        // A character is created as soon as their reveal is complete. This
        // lets another situation with the same template reuse them even if
        // the learner leaves before tapping the Talk button.
        if viewModel.hasRevealedAvatar {
          state.save(character: character)
        }
      }
    }
  }
}

struct SetupShell<Content: View>: View {
  let title: String
  let progress: Int
  @ViewBuilder let content: Content
  var body: some View {
    ZStack {
      AdventureBackground()
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Text(title).font(ThemeApp.Fonts.gameTitle()).foregroundStyle(ThemeApp.Colors.textPrimary)
          Spacer()
          Text("\(progress)/3").font(ThemeApp.Fonts.ctaButton(size: 14)).foregroundStyle(
            ThemeApp.Colors.roadmapLine)
        }
        ProgressView(value: Double(progress), total: 3).tint(ThemeApp.Colors.roadmapLine)
        content
      }.padding(24)
    }.navigationBarTitleDisplayMode(.inline)
  }
}
struct StoryCard: View {
  let text, symbol: String
  var body: some View {
    GlassCard {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: symbol).foregroundStyle(ThemeApp.Colors.roadmapLine).font(.title3)
        Text(text).font(ThemeApp.Fonts.bodyText()).foregroundStyle(
          ThemeApp.Colors.textPrimary.opacity(0.9))
      }
    }
  }
}
struct ChoiceRow: View {
  let title: String
  let choices: [String]
  @Binding var selection: String
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title).font(ThemeApp.Fonts.ctaButton(size: 16)).foregroundStyle(
        ThemeApp.Colors.textPrimary)
      HStack {
        ForEach(choices, id: \.self) { choice in
          Button {
            selection = choice
          } label: {
            GameTag(title: choice, selected: selection == choice)
          }.buttonStyle(.plain)
        }
      }
    }
  }
}

struct ChatView: View {
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  let character: Character
  let situation: Situation?
  var onHome: () -> Void = {}
  @StateObject private var viewModel = ChatViewModel()
  @StateObject private var voiceViewModel = VoiceConversationViewModel()
  var body: some View {
    ZStack {
      AdventureBackground()
      VStack(spacing: 0) {
        header
        Spacer()
        VoiceConversationPanel(character: character, state: voiceViewModel.state) {
          Task {
            await voiceViewModel.toggleSession(
              character: character,
              situation: situation,
              learnerName: state.learnerName
            )
          }
        }
        Spacer()
        Text("Voice conversation powered by \(voiceViewModel.modelName)")
          .font(ThemeApp.Fonts.bodyText(size: 12))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .padding(.bottom, 34)
      }
      .foregroundStyle(ThemeApp.Colors.textPrimary)
      .ignoresSafeArea(edges: .top)
    }
    .sheet(isPresented: $viewModel.showsRequirements) {
      if let situation {
        RequirementView(
          situation: situation, onComplete: { viewModel.complete(situation, using: state) })
      }
    }
    .sheet(isPresented: $viewModel.showsCompletion) {
      if let situation { MissionCompleteView(situation: situation, onHome: returnHome) }
    }
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
  }
  private var header: some View {
    HStack(spacing: 12) {
      Button(action: returnHome) {
        Image(systemName: "chevron.left").font(.body.weight(.black)).foregroundStyle(
          ThemeApp.Colors.textDark
        ).frame(width: 38, height: 38).background(ThemeApp.Colors.roadmapLine).clipShape(Circle())
      }.buttonStyle(.plain)
      AvatarView(character: character, size: 46)
      VStack(alignment: .leading) {
        Text(character.name).font(ThemeApp.Fonts.ctaButton())
        Text("Live voice · online").font(ThemeApp.Fonts.bodyText(size: 12)).foregroundStyle(
          ThemeApp.Colors.textSecondary)
      }
      Spacer()
      if situation != nil {
        Button {
          viewModel.showsRequirements = true
        } label: {
          Image(systemName: "checklist").font(.title3).foregroundStyle(ThemeApp.Colors.roadmapLine)
            .padding(10).background(Color.white).clipShape(
              RoundedRectangle(cornerRadius: ThemeApp.Radius.tag)
            ).overlay(
              RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(ThemeApp.Colors.border))
        }
      }
    }.padding(.horizontal, 20).padding(.top, 58).padding(.bottom, 14)
  }
  private func returnHome() {
    onHome()
    dismiss()
  }
}
struct VoiceConversationPanel: View {
  let character: Character
  let state: VoiceConversationState
  let action: () -> Void
  var body: some View {
    VStack(spacing: 20) {
      AvatarView(character: character, size: 150)
        .shadow(
          color: character.color.opacity(state == .listening ? 0.9 : 0.35),
          radius: state == .listening ? 34 : 14)
      Text(state.isLive ? "Live with \(character.name)" : "Talk with \(character.name)")
        .font(ThemeApp.Fonts.gameTitle(size: 28))
      Text(state.label).font(ThemeApp.Fonts.bodyText()).foregroundStyle(
        ThemeApp.Colors.textSecondary)
      Button(action: action) {
        Image(systemName: state.isLive ? "stop.fill" : "mic.fill")
          .font(.system(size: 32, weight: .black)).foregroundStyle(ThemeApp.Colors.textDark)
          .frame(width: 92, height: 92).background(ThemeApp.Colors.roadmapLine).clipShape(Circle())
          .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 3))
      }.buttonStyle(.plain)
      Text(state.isLive ? "Live conversation is active" : "Tap once to start live voice")
        .font(ThemeApp.Fonts.bodyText(size: 13)).foregroundStyle(ThemeApp.Colors.textSecondary)
    }.padding(28)
  }
}

/// Situation mode is a voice-only game scene, opened from the roadmap.
struct SituationChatView: View {
  @EnvironmentObject private var app: AppViewModel
  @Environment(\.dismiss) private var dismiss
  let character: Character
  let situation: Situation?
  var onHome: () -> Void = {}
  @StateObject private var viewModel = ChatViewModel()
  @StateObject private var voiceViewModel = VoiceConversationViewModel()
  @StateObject private var sceneViewModel = SituationSceneViewModel()

  var body: some View {
    VStack(spacing: 0) {
      sceneHeader

      HStack(alignment: .top, spacing: 12) {
        SceneCharacterColumn(character: character)
          .frame(width: 142)

        LiveDialoguePanel(
          characterName: character.name,
          message: latestCharacterMessage,
          isListening: voiceViewModel.state.isLive
        )
      }
      .padding(.horizontal, 18)
      .padding(.top, 8)

      Spacer()

      LiveSpeakControl(
        state: voiceViewModel.state,
        action: {
          Task {
            await voiceViewModel.toggleSession(
              character: character,
              situation: situation,
              learnerName: app.learnerName
            )
          }
        }
      )
      .padding(.horizontal, 24)

      if let latestLearnerMessage {
        LearnerDialogueBubble(message: latestLearnerMessage)
          .padding(.horizontal, 24)
          .padding(.top, 12)
      }

      Spacer(minLength: 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .foregroundStyle(ThemeApp.Colors.textPrimary)
    .background {
      SituationGameBackground(
        imageData: sceneViewModel.backgroundImageData,
        assetName: situation?.locationBackgroundAsset
      )
    }
    .ignoresSafeArea()
    .sheet(isPresented: $viewModel.showsRequirements) {
      if let situation {
        RequirementView(
          situation: situation, onComplete: { viewModel.complete(situation, using: app) })
      }
    }
    .sheet(isPresented: $viewModel.showsCompletion) {
      if let situation { MissionCompleteView(situation: situation, onHome: returnHome) }
    }
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .task {
      if let situation {
        await sceneViewModel.prepare(for: situation, character: character)
      }
    }
  }

  private var sceneHeader: some View {
    HStack(spacing: 12) {
      Button(action: returnHome) {
        Image(systemName: "chevron.left")
          .font(.body.weight(.black))
          .foregroundStyle(ThemeApp.Colors.textDark)
          .frame(width: 38, height: 38)
          .background(ThemeApp.Colors.roadmapLine, in: Circle())
      }
      .buttonStyle(.plain)
      VStack(alignment: .leading, spacing: 2) {
        Text(situation?.locationName ?? "Practice mission")
          .font(ThemeApp.Fonts.ctaButton(size: 15))
        Text("Live voice · \(voiceViewModel.modelName)")
          .font(ThemeApp.Fonts.bodyText(size: 11))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
      }
      Spacer()
      Button {
        viewModel.showsRequirements = true
      } label: {
        Image(systemName: "checklist")
          .font(.title3)
          .foregroundStyle(ThemeApp.Colors.roadmapLine)
          .padding(10)
          .background(Color.white, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
          .overlay(
            RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(ThemeApp.Colors.border))
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.top, 58)
    .padding(.bottom, 6)
  }

  private func returnHome() {
    app.selectedTab = 0
    onHome()
    dismiss()
  }

  private var latestCharacterMessage: VoiceTranscript? {
    voiceViewModel.transcript.last(where: { $0.speaker == .character })
  }

  private var latestLearnerMessage: VoiceTranscript? {
    voiceViewModel.transcript.last(where: { $0.speaker == .learner })
  }
}

private struct SituationGameBackground: View {
  let imageData: Data?
  let assetName: String?

  var body: some View {
    Group {
      if let assetName {
        Image(assetName).resizable().scaledToFill()
      } else if let imageData, let image = UIImage(data: imageData) {
        Image(uiImage: image).resizable().scaledToFill()
      } else {
        LinearGradient(
          colors: [ThemeApp.Colors.riverBlue, ThemeApp.Colors.canvas],
          startPoint: .top, endPoint: .bottom
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
    .overlay(Color.black.opacity(0.08))
  }
}

private struct SceneCharacterColumn: View {
  let character: Character

  var body: some View {
    VStack(spacing: 8) {
      Group {
        if let imageData = character.avatarImageData, let image = UIImage(data: imageData) {
          Image(uiImage: image).resizable().scaledToFit()
        } else {
          AvatarView(character: character, size: 118)
        }
      }
      .frame(width: 132, height: 224, alignment: .bottom)
      .shadow(color: Color.black.opacity(0.25), radius: 13, y: 8)
      Text(character.name)
        .font(ThemeApp.Fonts.ctaButton(size: 14))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.9), in: Capsule())
    }
  }
}

private struct LiveDialoguePanel: View {
  let characterName: String
  let message: VoiceTranscript?
  let isListening: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("LIVE DIALOGUE")
          .font(ThemeApp.Fonts.ctaButton(size: 11))
          .foregroundStyle(ThemeApp.Colors.primary)
        Spacer()
        Circle()
          .fill(isListening ? ThemeApp.Colors.accentPink : ThemeApp.Colors.primary)
          .frame(width: 8, height: 8)
      }
      if let message {
        dialogueBubble(text: message.text)
      } else {
        Text("Your character will reply after you speak.")
          .font(ThemeApp.Fonts.bodyText(size: 13))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
    .padding(14)
    .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: ThemeApp.Radius.card))
    .overlay(
      RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(
        ThemeApp.Colors.primary, lineWidth: 2)
    )
  }

  private func dialogueBubble(text: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(characterName.uppercased())
        .font(ThemeApp.Fonts.ctaButton(size: 11))
        .foregroundStyle(ThemeApp.Colors.primary)
      Text(text)
        .font(ThemeApp.Fonts.bodyText(size: 13))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(
      ThemeApp.Colors.riverBlue.opacity(0.55),
      in: RoundedRectangle(cornerRadius: ThemeApp.Radius.tag)
    )
  }
}

private struct LearnerDialogueBubble: View {
  let message: VoiceTranscript

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("YOU")
        .font(ThemeApp.Fonts.ctaButton(size: 11))
        .foregroundStyle(ThemeApp.Colors.accent)
      Text(message.text)
        .font(ThemeApp.Fonts.bodyText(size: 14))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      Color.white.opacity(0.95),
      in: RoundedRectangle(cornerRadius: ThemeApp.Radius.card)
    )
    .overlay(
      RoundedRectangle(cornerRadius: ThemeApp.Radius.card).stroke(
        ThemeApp.Colors.accent,
        lineWidth: 2
      )
    )
  }
}

private struct LiveSpeakControl: View {
  let state: VoiceConversationState
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: state.isLive ? "waveform" : "mic.fill")
          .font(.title3.weight(.black))
          .frame(width: 44, height: 44)
          .foregroundStyle(ThemeApp.Colors.textDark)
          .background(ThemeApp.Colors.roadmapLine, in: Circle())
        VStack(alignment: .leading, spacing: 2) {
          Text(buttonTitle)
            .font(ThemeApp.Fonts.ctaButton(size: 17))
          Text(buttonHint)
            .font(ThemeApp.Fonts.bodyText(size: 12))
        }
        Spacer()
        Image(systemName: state.isLive ? "stop.fill" : "arrow.up.circle.fill")
          .font(.title2)
      }
      .foregroundStyle(ThemeApp.Colors.textPrimary)
      .padding(12)
      .background(
        Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: ThemeApp.Radius.button)
      )
      .overlay(
        RoundedRectangle(cornerRadius: ThemeApp.Radius.button).stroke(
          state.isLive ? ThemeApp.Colors.roadmapLine : ThemeApp.Colors.primary,
          lineWidth: 2)
      )
      .shadow(color: Color.black.opacity(0.14), radius: 12, y: 6)
    }
    .buttonStyle(.plain)
  }

  private var buttonTitle: String {
    if state.isLive { return "Live voice is on" }
    if case .failed = state { return "Try live voice again" }
    return "Speak"
  }

  private var buttonHint: String {
    if state.isLive { return "Speak naturally — your character replies automatically" }
    if case .failed(let message) = state { return message }
    return "Tap once to start a live conversation"
  }
}

struct MissionCompleteView: View {
  let situation: Situation
  let onHome: () -> Void
  var body: some View {
    ZStack {
      AdventureBackground()
      VStack(spacing: 22) {
        Spacer()
        Image(systemName: "checkmark.seal.fill").font(.system(size: 82, weight: .black))
          .foregroundStyle(ThemeApp.Colors.roadmapLine)
        Text("Mission complete!").font(ThemeApp.Fonts.gameTitle(size: 32)).foregroundStyle(
          ThemeApp.Colors.textPrimary)
        Text("You completed \(situation.title) and earned +\(situation.reward) EXP.").font(
          ThemeApp.Fonts.bodyText()
        ).multilineTextAlignment(.center).foregroundStyle(ThemeApp.Colors.textSecondary)
        GlassCard {
          VStack(spacing: 8) {
            Label("New situation unlocked", systemImage: "lock.open.fill").font(
              ThemeApp.Fonts.ctaButton(size: 15)
            ).foregroundStyle(ThemeApp.Colors.roadmapLine)
            Text(situation.unlock).font(ThemeApp.Fonts.gameTitle(size: 22)).foregroundStyle(
              ThemeApp.Colors.textPrimary)
          }
        }
        GameButton(title: "Back to map", icon: "map.fill", action: onHome)
        Spacer()
      }.padding(24)
    }
  }
}
struct ChatBubble: View {
  let text: String
  let mine: Bool
  var body: some View {
    HStack {
      if mine { Spacer(minLength: 45) }
      Text(text).font(ThemeApp.Fonts.bodyText()).foregroundStyle(ThemeApp.Colors.textPrimary)
        .padding(14).background(mine ? ThemeApp.Colors.roadmapLine : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.card))
      if !mine { Spacer(minLength: 45) }
    }
  }
}

struct RequirementView: View {
  let situation: Situation
  let onComplete: () -> Void
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    ZStack {
      AdventureBackground()
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          SectionTitle("Mission check", subtitle: situation.title)
          Spacer()
          Button("Done") { dismiss() }.font(ThemeApp.Fonts.bodyText()).foregroundStyle(
            ThemeApp.Colors.roadmapLine)
        }
        GlassCard {
          VStack(alignment: .leading, spacing: 16) {
            Text("Use these keywords in your conversation").font(ThemeApp.Fonts.bodyText(size: 14))
              .foregroundStyle(ThemeApp.Colors.textSecondary)
            ForEach(situation.goals, id: \.self) { word in
              HStack {
                Image(
                  systemName: state.progress(for: situation) == .completed
                    ? "checkmark.circle.fill" : "circle"
                ).foregroundStyle(
                  state.progress(for: situation) == .completed
                    ? ThemeApp.Colors.mint : ThemeApp.Colors.textSecondary.opacity(0.65))
                Text(word).font(ThemeApp.Fonts.bodyText())
                Spacer()
              }
            }
            Divider().overlay(ThemeApp.Colors.border)
            Label("Complete all to unlock \(situation.unlock)", systemImage: "lock.open.fill").font(
              ThemeApp.Fonts.bodyText(size: 14)
            ).foregroundStyle(ThemeApp.Colors.roadmapLine)
          }
        }
        Spacer()
        if state.progress(for: situation) == .available {
          GameButton(title: "Complete mission", icon: "checkmark", action: onComplete)
        }
      }.padding(24)
    }
  }
}
