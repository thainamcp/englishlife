import SwiftUI
import UIKit

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
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        sceneHeader

        SituationDialogueCard(
          message: latestCharacterMessage?.text ?? initialDialogue
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)

        Color.clear.frame(height: 16)

        SceneCharacterPortrait(
          character: character,
          imageData: sceneViewModel.characterImageData
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 18)
        .offset(y: -50)

        Spacer(minLength: 0)

      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      if let latestLearnerMessage {
        LearnerDialogueBubble(text: latestLearnerMessage.text)
          .frame(maxWidth: .infinity, alignment: .bottom)
          .padding(.horizontal, 28)
          .padding(.bottom, 192)
          .transition(.opacity.combined(with: .move(edge: .bottom)))
          .zIndex(2)
      } else if voiceViewModel.isCapturingLearnerSpeech {
        LearnerDialogueBubble(text: "Listening…", isPlaceholder: true)
          .frame(maxWidth: .infinity, alignment: .bottom)
          .padding(.horizontal, 28)
          .padding(.bottom, 192)
          .transition(.opacity.combined(with: .move(edge: .bottom)))
          .zIndex(2)
      }

      SceneMicrophoneControl(state: voiceViewModel.state) {
        Task {
          await voiceViewModel.toggleSession(
            character: character,
            situation: situation,
            learnerName: app.learnerName,
            missionKeywords: missionKeywords
          )
        }
      }
      .padding(.bottom, 48)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .foregroundStyle(ThemeApp.Colors.textPrimary)
    .background {
      if situation == nil {
        MainTabBackground()
          .ignoresSafeArea()
      } else {
        SituationGameBackground(
          imageData: sceneViewModel.backgroundImageData,
          assetName: situation?.locationBackgroundAsset
        )
        .ignoresSafeArea()
      }
    }
    .ignoresSafeArea()
    .sheet(isPresented: $viewModel.showsRequirements) {
      if let situation {
        RequirementView(
          situation: situation,
          keywords: missionKeywords,
          achievedKeywords: achievedKeywords,
          onComplete: { viewModel.complete(situation, using: app) }
        )
      }
    }
    .overlay {
      if viewModel.showsCompletion, let situation {
        MissionCompleteView(
          situation: situation,
          onContinue: { viewModel.showsCompletion = false },
          onPlayNext: returnHome
        )
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .zIndex(10)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .task {
      if let situation {
        await sceneViewModel.prepare(for: situation, character: character)
      }
    }
    .onChange(of: achievedKeywords) { _, newValue in
      guard let situation,
        !missionKeywords.isEmpty,
        missionKeywords.allSatisfy(newValue.contains),
        app.progress(for: situation) == .available,
        !viewModel.showsCompletion
      else { return }

      // The mission has its own terminal state. End the live microphone session
      // before presenting completion so Realtime cannot continue listening or
      // create another character response behind the celebration.
      voiceViewModel.stop()
      viewModel.complete(situation, using: app)
    }
  }

  private var sceneHeader: some View {
    ZStack {
      HStack {
        Button(action: returnHome) {
          Image(systemName: "chevron.left")
            .font(.body.weight(.black))
            .foregroundStyle(ThemeApp.Colors.textDark)
            .frame(width: 42, height: 42)
            .background(Color(hex: "#F48B8A"), in: Circle())
            .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)

        Spacer()

        if situation != nil {
          Button {
            viewModel.showsRequirements = true
          } label: {
            Image(systemName: "slider.horizontal.3")
              .font(.title3.weight(.bold))
              .foregroundStyle(ThemeApp.Colors.textPrimary)
              .frame(width: 42, height: 42)
              .background(Color(hex: "#F48B8A"), in: Circle())
              .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
          }
          .buttonStyle(.plain)
        } else {
          Color.clear.frame(width: 42, height: 42)
        }
      }

      Text(situation?.title ?? "Talk with \(character.name)")
        .font(.system(size: 18, weight: .bold, design: .rounded))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 12)
        .frame(maxWidth: 250)
        .frame(height: 34)
        .background(Color(hex: "#FFE900"), in: Capsule())
        .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
    }
    .padding(.horizontal, 20)
    .padding(.top, 78)
    .padding(.bottom, 2)
  }

  private func returnHome() {
    app.selectedTab = situation == nil ? 1 : 0
    onHome()
    dismiss()
  }

  private var initialDialogue: String {
    if situation == nil {
      return "Hi, I’m \(character.name). What would you like to talk about today?"
    }
    return situation?.story ?? "Tap the microphone to begin."
  }

  private var latestCharacterMessage: VoiceTranscript? {
    voiceViewModel.transcript.last(where: { $0.speaker == .character })
  }

  private var latestLearnerMessage: VoiceTranscript? {
    voiceViewModel.transcript.last(where: { $0.speaker == .learner })
  }

  private var achievedKeywords: Set<String> {
    voiceViewModel.achievedMissionKeywords
  }

  private var missionKeywords: [String] {
    guard let situation else { return [] }
    return app.missionKeywords(for: situation)
  }
}

private struct SituationDialogueCard: View {
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(message)
        .font(ThemeApp.Fonts.bodyText(size: 18))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading)
        .padding(16)
        .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
        )

      CharacterDialogueTail()
        .fill(ThemeApp.Colors.surface)
        .frame(width: 30, height: 18)
        .overlay(
          CharacterDialogueTail()
            .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
        )
        .padding(.leading, 70)
        .offset(y: -1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct CharacterDialogueTail: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 0))
    path.addLine(to: CGPoint(x: rect.width, y: 0))
    path.addLine(to: CGPoint(x: rect.width * 0.32, y: rect.height))
    path.closeSubpath()
    return path
  }
}

private struct SceneCharacterPortrait: View {
  let character: Character
  let imageData: Data?

  var body: some View {
    Group {
      if let portraitData = imageData ?? character.avatarImageData,
        let image = UIImage(data: portraitData)
      {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        AvatarView(character: character, size: 270)
      }
    }
    .frame(width: 270, height: 450, alignment: .bottom)
    .shadow(color: Color.black.opacity(0.22), radius: 12, y: 7)
  }
}

private struct SceneMicrophoneControl: View {
  let state: VoiceConversationState
  let action: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Button(action: action) {
        ZStack {
          Circle()
            .fill(ThemeApp.Colors.primary)
          Image(systemName: microphoneSymbol)
            .font(.system(size: state.isLive ? 34 : 39, weight: .bold))
            .foregroundStyle(.white)
        }
        .frame(width: 108, height: 108)
        .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
      }
      .buttonStyle(.plain)

      Text(microphoneHint)
        .font(.system(size: 14, weight: .regular, design: .rounded))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(hex: "#FFE900"), in: Capsule())
    }
  }

  private var microphoneSymbol: String {
    switch state {
    case .connecting, .requestingPermission:
      "ellipsis"
    case .listening:
      "waveform"
    case .speaking:
      "speaker.wave.2.fill"
    case .idle, .unavailable, .failed:
      "mic.fill"
    }
  }

  private var microphoneHint: String {
    switch state {
    case .idle:
      "Tap the microphone to speak"
    case .requestingPermission:
      "Allow microphone access to begin"
    case .connecting:
      "Connecting to live voice…"
    case .listening:
      "Listening — speak naturally"
    case .speaking:
      "Your character is replying…"
    case .unavailable:
      "Microphone access is required"
    case .failed:
      "Tap the microphone to try again"
    }
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
    .clipped()
    .overlay(Color.black.opacity(0.08))
    .allowsHitTesting(false)
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
  let text: String
  var isPlaceholder = false

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 3) {
        Text("YOU")
          .font(ThemeApp.Fonts.ctaButton(size: 11))
          .foregroundStyle(ThemeApp.Colors.accent)
        Text(text)
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

      CharacterDialogueTail()
        .fill(Color.white.opacity(0.95))
        .frame(width: 28, height: 16)
        .overlay(
          CharacterDialogueTail()
            .stroke(ThemeApp.Colors.accent, lineWidth: 2)
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.trailing, 48)
        .offset(y: -1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isPlaceholder ? 0.82 : 1)
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
  let onContinue: () -> Void
  let onPlayNext: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "checkmark.seal.fill")
        .font(.system(size: 56, weight: .black))
        .foregroundStyle(ThemeApp.Colors.primary)
      Text("Mission Complete! 🎉")
        .font(ThemeApp.Fonts.gameTitle(size: 25))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
      Text("You earned +\(situation.reward) XP and unlocked\nthe next mission.")
        .font(ThemeApp.Fonts.bodyText(size: 16))
        .multilineTextAlignment(.center)
        .foregroundStyle(ThemeApp.Colors.textPrimary)

      HStack(spacing: 10) {
        completionButton(title: "Continue", isPrimary: false, action: onContinue)
        completionButton(title: "Play next", isPrimary: true, action: onPlayNext)
      }
    }
    .padding(24)
    .frame(height: 280)
    .frame(maxWidth: 560)
    .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 48))
    .overlay(
      RoundedRectangle(cornerRadius: 48)
        .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
    )
    .padding(.horizontal, 18)
  }

  private func completionButton(
    title: String,
    isPrimary: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .font(ThemeApp.Fonts.ctaButton(size: 15))
        .foregroundStyle(isPrimary ? Color.white : ThemeApp.Colors.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
          isPrimary ? ThemeApp.Colors.primary : Color.white.opacity(0.94),
          in: Capsule()
        )
        .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
    }
    .buttonStyle(.plain)
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
  var keywords: [String]
  var achievedKeywords: Set<String> = []
  let onComplete: () -> Void
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      requirementHeader

      VStack(alignment: .leading, spacing: 16) {
        Label("Use these keywords in your\nconversation", systemImage: "text.book.closed.fill")
          .font(ThemeApp.Fonts.ctaButton(size: 20))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
          .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading, spacing: 10) {
          ForEach(keywords, id: \.self) { keyword in
            RequirementKeywordRow(keyword: keyword, isComplete: isKeywordComplete(keyword))
          }
        }

        Divider()
          .overlay(ThemeApp.Colors.border.opacity(0.7))
          .padding(.top, 2)

        Label(
          "Complete all to unlock \(situation.unlock)",
          systemImage: allKeywordsComplete ? "lock.open.fill" : "lock.fill"
        )
        .font(ThemeApp.Fonts.bodyText(size: 16))
        .foregroundStyle(ThemeApp.Colors.primary)
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
      .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 28))
      .overlay(
        RoundedRectangle(cornerRadius: 28)
          .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
      )

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 20)
    .padding(.top, 22)
    .padding(.bottom, 22)
    .background(ThemeApp.Colors.surface)
    .presentationDetents([.height(max(560, UIScreen.main.bounds.height - 210))])
    .presentationDragIndicator(.hidden)
    .presentationCornerRadius(44)
  }

  private var requirementHeader: some View {
    ZStack {
      Text("Mission check")
        .font(ThemeApp.Fonts.gameTitle(size: 24))
        .foregroundStyle(ThemeApp.Colors.textPrimary)

      HStack {
        Spacer()
        Button {
          if allKeywordsComplete, state.progress(for: situation) == .available {
            onComplete()
          } else {
            dismiss()
          }
        } label: {
          Image(systemName: "checkmark")
            .font(.title3.weight(.black))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .frame(width: 42, height: 42)
            .background(Color(hex: "#F48B8A"), in: Circle())
            .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var allKeywordsComplete: Bool {
    state.progress(for: situation) == .completed
      || keywords.allSatisfy(isKeywordComplete)
  }

  private func isKeywordComplete(_ keyword: String) -> Bool {
    state.progress(for: situation) == .completed || achievedKeywords.contains(keyword)
  }
}

private struct RequirementKeywordRow: View {
  let keyword: String
  let isComplete: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(
          isComplete ? Color(hex: "#75BF20") : ThemeApp.Colors.textPrimary
        )
      Text(keyword)
        .font(ThemeApp.Fonts.bodyText(size: 18))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
      Spacer(minLength: 0)
    }
    .frame(minHeight: 28, alignment: .leading)
  }
}
