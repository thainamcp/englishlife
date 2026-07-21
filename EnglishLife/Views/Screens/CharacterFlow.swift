import SwiftUI
import UIKit

struct CharacterSetupNameView: View {
  let situation: Situation
  let onHome: () -> Void
  @StateObject private var viewModel = CharacterSetupViewModel()

  var body: some View {
    SetupShell(title: "A new friend", progress: 1) {
      VStack(alignment: .leading, spacing: 16) {
        StoryCard(text: situation.story, symbol: "sparkles")
        Text("What is their name?")
          .font(ThemeApp.Fonts.ctaButton(size: 16))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
        TextField(
          "e.g. Alex",
          text: $viewModel.name,
          prompt: Text("e.g. Alex").foregroundStyle(ThemeApp.Colors.textSecondary)
        )
        .font(ThemeApp.Fonts.bodyText(size: 15))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .tint(ThemeApp.Colors.primary)
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.white, in: Capsule())
        .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(viewModel.nameSuggestions, id: \.self) { item in
              Button {
                viewModel.selectName(item)
              } label: {
                SetupChoiceTag(
                  title: item,
                  selected: viewModel.name == item,
                  selectedColor: ThemeApp.Colors.primary
                )
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    } footer: {
      SetupNavigationLink(
        title: "Choose their style",
        destination: CharacterAppearanceView(
          situation: situation,
          viewModel: viewModel,
          onHome: onHome
        )
      )
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
      VStack(alignment: .leading, spacing: 16) {
        StoryCard(
          text: "Every detail shapes how \(viewModel.name) appears on your adventure.",
          symbol: "wand.and.stars")
        ChoiceRow(
          title: "Gender",
          choices: ["Woman", "Man", "Non-binary"],
          selection: $viewModel.gender,
          selectedColor: ThemeApp.Colors.primary
        )
        ChoiceRow(
          title: "Vibe",
          choices: ["Friendly", "Cool", "Cheerful", "Playful"],
          selection: $viewModel.vibe,
          selectedColor: ThemeApp.Colors.primary
        )
        ChoiceRow(
          title: "Hair",
          choices: ["Curly", "Short", "Long", "Wavy", "Straight"],
          selection: $viewModel.hair,
          selectedColor: Color(hex: "#FFE900")
        )
        ChoiceRow(
          title: "Accessory",
          choices: ["Glasses", "Cap", "Earrings", "Scarf"],
          selection: $viewModel.accessory,
          selectedColor: Color(hex: "#F48B8A")
        )
      }
    } footer: {
      SetupNavigationLink(
        title: "Bring \(viewModel.name) to life",
        destination: CharacterRevealView(
          situation: situation,
          viewModel: viewModel,
          onHome: onHome
        ),
        icon: "sparkles"
      )
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
      VStack(alignment: .leading, spacing: 16) {
        StoryCard(
          text: viewModel.hasRevealedAvatar
            ? "\(viewModel.name) is ready to meet you. Your story begins now!"
            : "Your character is arriving from the English universe…", symbol: "sparkles")
        Text(viewModel.name)
          .font(ThemeApp.Fonts.gameTitle(size: 24))
          .frame(maxWidth: .infinity)

        GeneratedCharacterPortrait(
          character: character,
          isLoading: viewModel.isGeneratingAvatar || !viewModel.hasRevealedAvatar
        )

        if let error = viewModel.avatarGenerationError {
          Text(error)
            .font(ThemeApp.Fonts.bodyText(size: 12))
            .foregroundStyle(ThemeApp.Colors.textSecondary)
          Button("Try generating again") {
            Task { await viewModel.regenerateAvatar(for: situation) }
          }
          .font(ThemeApp.Fonts.ctaButton(size: 13))
          .foregroundStyle(ThemeApp.Colors.primary)
        }
      }
    } footer: {
      SetupActionButton(
        title: "Talk to \(viewModel.name)",
        icon: "bubble.left.and.bubble.right.fill",
        backgroundOpacity: viewModel.hasRevealedAvatar ? 1 : 0.55,
        action: {
          state.save(character: character)
          onHome()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            state.presentChat(character: character, situation: situation)
          }
        }
      )
      .allowsHitTesting(viewModel.hasRevealedAvatar)
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

struct SetupShell<Content: View, Footer: View>: View {
  let title: String
  let progress: Int
  private let content: Content
  private let footer: Footer

  init(
    title: String,
    progress: Int,
    @ViewBuilder content: () -> Content,
    @ViewBuilder footer: () -> Footer
  ) {
    self.title = title
    self.progress = progress
    self.content = content()
    self.footer = footer()
  }

  var body: some View {
    ZStack {
      AdventureBackground()
      VStack(spacing: 0) {
        HStack {
          Button {
            dismiss()
          } label: {
            Image(systemName: "chevron.left")
              .font(.body.weight(.bold))
              .foregroundStyle(ThemeApp.Colors.textPrimary)
              .frame(width: 36, height: 36)
              .background(Color(hex: "#F48B8A"), in: Circle())
              .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
          }
          .buttonStyle(.plain)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)

        HStack(alignment: .firstTextBaseline) {
          Text(title)
            .font(ThemeApp.Fonts.gameTitle(size: 24))
            .foregroundStyle(ThemeApp.Colors.textPrimary)

          Spacer()

          Text("\(progress)/3")
            .font(ThemeApp.Fonts.ctaButton(size: 12))
            .foregroundStyle(ThemeApp.Colors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)

        SetupProgressBar(progress: progress)
          .padding(.horizontal, 16)

        ScrollView(showsIndicators: false) {
          content
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }

        footer
          .padding(.horizontal, 16)
          .padding(.top, 10)
          .padding(.bottom, 12)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .navigationBarBackButtonHidden()
  }

  @Environment(\.dismiss) private var dismiss
}

private struct SetupProgressBar: View {
  let progress: Int

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(ThemeApp.Colors.border.opacity(0.18))
        Capsule()
          .fill(Color(hex: "#FFE900"))
          .frame(width: proxy.size.width * CGFloat(progress) / 3)
      }
    }
    .frame(height: 8)
    .overlay(Capsule().stroke(ThemeApp.Colors.border.opacity(0.5), lineWidth: 1))
  }
}

private struct SetupNavigationLink<Destination: View>: View {
  let title: String
  let destination: Destination
  var icon: String = "arrow.right"

  var body: some View {
    NavigationLink(destination: destination) {
      SetupButtonLabel(title: title, icon: icon)
    }
    .buttonStyle(.plain)
  }
}

private struct SetupActionButton: View {
  let title: String
  var icon: String? = nil
  var backgroundOpacity = 1.0
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      SetupButtonLabel(title: title, icon: icon, backgroundOpacity: backgroundOpacity)
    }
    .buttonStyle(.plain)
  }
}

private struct SetupButtonLabel: View {
  let title: String
  let icon: String?
  var backgroundOpacity = 1.0

  var body: some View {
    HStack(spacing: 8) {
      Text(title)
      if let icon { Image(systemName: icon) }
    }
    .font(ThemeApp.Fonts.ctaButton(size: 15))
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity)
    .frame(height: 56)
    .background(ThemeApp.Colors.primary.opacity(backgroundOpacity), in: Capsule())
    .overlay(Capsule().stroke(ThemeApp.Colors.border.opacity(backgroundOpacity), lineWidth: 1.5))
  }
}

private struct GeneratedCharacterPortrait: View {
  let character: Character
  let isLoading: Bool

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.55))

      if isLoading {
        VStack(spacing: 12) {
          ProgressView().tint(ThemeApp.Colors.primary)
          Text("Creating your character portrait...")
            .font(ThemeApp.Fonts.bodyText(size: 13))
            .foregroundStyle(ThemeApp.Colors.textSecondary)
            .multilineTextAlignment(.center)
        }
      } else if let imageData = character.avatarImageData, let image = UIImage(data: imageData) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .padding(12)
      } else {
        AvatarView(character: character, size: 132)
      }
    }
    .frame(width: 190, height: 285)
    .frame(maxWidth: .infinity)
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
  }
}

struct StoryCard: View {
  let text, symbol: String
  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: symbol)
        .foregroundStyle(ThemeApp.Colors.primary)
        .font(.body.weight(.bold))
      Text(text)
        .font(ThemeApp.Fonts.body2Text())
        .foregroundStyle(ThemeApp.Colors.textPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .frame(minHeight: 70)
    .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
  }
}

struct ChoiceRow: View {
  let title: String
  let choices: [String]
  @Binding var selection: String
  var selectedColor: Color = ThemeApp.Colors.primary

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(ThemeApp.Fonts.ctaButton(size: 14))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(choices, id: \.self) { choice in
            Button {
              selection = choice
            } label: {
              SetupChoiceTag(
                title: choice,
                selected: selection == choice,
                selectedColor: selectedColor
              )
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

private struct SetupChoiceTag: View {
  let title: String
  let selected: Bool
  let selectedColor: Color

  var body: some View {
    Text(title)
      .font(ThemeApp.Fonts.bodyText(size: 12))
      .foregroundStyle(selected ? ThemeApp.Colors.textPrimary : ThemeApp.Colors.textPrimary)
      .lineLimit(1)
      .padding(.horizontal, 12)
      .frame(height: 33)
      .background(selected ? selectedColor : Color.white, in: Capsule())
      .overlay(Capsule().stroke(ThemeApp.Colors.border.opacity(0.75), lineWidth: 1))
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

      Spacer(minLength: 0)

      if let latestLearnerMessage {
        LearnerDialogueBubble(message: latestLearnerMessage)
          .padding(.horizontal, 28)
          .padding(.bottom, 10)
      }

      SceneMicrophoneControl(state: voiceViewModel.state) {
        Task {
          await voiceViewModel.toggleSession(
            character: character,
            situation: situation,
            learnerName: app.learnerName
          )
        }
      }
      .padding(.bottom, 22)
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
          achievedKeywords: achievedKeywords,
          onComplete: { viewModel.complete(situation, using: app) }
        )
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
          .frame(width: 42, height: 42)
          .background(Color(hex: "#F48B8A"), in: Circle())
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)

      Text(situation?.title ?? "Talk with \(character.name)")
        .font(ThemeApp.Fonts.ctaButton(size: 18))
        .lineLimit(1)
        .minimumScaleFactor(0.72)

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
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 58)
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
    guard let situation else { return [] }
    let learnerSpeech = voiceViewModel.transcript
      .filter { $0.speaker == .learner }
      .map(\.text)
      .joined(separator: " ")
      .lowercased()
    return Set(
      situation.goals.filter { keyword in
        learnerSpeech.contains(keyword.lowercased())
      }
    )
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
    VStack(spacing: 10) {
      Button(action: action) {
        ZStack {
          Circle()
            .fill(ThemeApp.Colors.primary)
          Circle()
            .stroke(.white.opacity(0.9), lineWidth: 3)
            .padding(3)
          Image(systemName: microphoneSymbol)
            .font(.system(size: state.isLive ? 34 : 39, weight: .bold))
            .foregroundStyle(.white)
        }
        .frame(width: 108, height: 108)
        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
      }
      .buttonStyle(.plain)

      Text(microphoneHint)
        .font(ThemeApp.Fonts.ctaButton(size: 15))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .frame(maxWidth: .infinity)
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
  var achievedKeywords: Set<String> = []
  let onComplete: () -> Void
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      requirementHeader

      VStack(alignment: .leading, spacing: 14) {
        Label("New location unlocked!", systemImage: "record.circle.fill")
          .font(ThemeApp.Fonts.ctaButton(size: 18))
          .foregroundStyle(ThemeApp.Colors.textPrimary)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(situation.goals, id: \.self) { keyword in
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
        .font(ThemeApp.Fonts.bodyText(size: 14))
        .foregroundStyle(ThemeApp.Colors.primary)
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(22)
      .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 26))
      .overlay(
        RoundedRectangle(cornerRadius: 26)
          .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
      )

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 18)
    .padding(.top, 28)
    .padding(.bottom, 22)
    .background(ThemeApp.Colors.surface)
    .presentationDetents([.height(max(560, UIScreen.main.bounds.height - 210))])
    .presentationDragIndicator(.hidden)
  }

  private var requirementHeader: some View {
    ZStack {
      Text("Mission")
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
      || situation.goals.allSatisfy(isKeywordComplete)
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
          isComplete ? ThemeApp.Colors.primary : ThemeApp.Colors.textSecondary.opacity(0.72)
        )
      Text(keyword)
        .font(ThemeApp.Fonts.bodyText(size: 17))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
      Spacer(minLength: 0)
    }
    .frame(minHeight: 28, alignment: .leading)
  }
}
