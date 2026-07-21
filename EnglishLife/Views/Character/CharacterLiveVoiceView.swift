import SwiftUI

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
              learnerName: state.learnerName,
              missionKeywords: situation.map { state.missionKeywords(for: $0) } ?? []
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
          situation: situation,
          keywords: state.missionKeywords(for: situation),
          onComplete: { viewModel.complete(situation, using: state) }
        )
      }
    }
    .sheet(isPresented: $viewModel.showsCompletion) {
      if let situation {
        MissionCompleteView(
          situation: situation,
          onContinue: { viewModel.showsCompletion = false },
          onPlayNext: returnHome
        )
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
  }

  private var header: some View {
    HStack(spacing: 12) {
      Button(action: returnHome) {
        Image(systemName: "chevron.left")
          .font(.body.weight(.black))
          .foregroundStyle(ThemeApp.Colors.textDark)
          .frame(width: 38, height: 38)
          .background(ThemeApp.Colors.roadmapLine)
          .clipShape(Circle())
      }
      .buttonStyle(.plain)

      AvatarView(character: character, size: 46)
      VStack(alignment: .leading) {
        Text(character.name).font(ThemeApp.Fonts.ctaButton())
        Text("Live voice · online")
          .font(ThemeApp.Fonts.bodyText(size: 12))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
      }
      Spacer()
      if situation != nil {
        Button {
          viewModel.showsRequirements = true
        } label: {
          Image(systemName: "checklist")
            .font(.title3)
            .foregroundStyle(ThemeApp.Colors.roadmapLine)
            .padding(10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
            .overlay(
              RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(ThemeApp.Colors.border))
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 58)
    .padding(.bottom, 14)
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
          radius: state == .listening ? 34 : 14
        )
      Text(state.isLive ? "Live with \(character.name)" : "Talk with \(character.name)")
        .font(ThemeApp.Fonts.gameTitle(size: 28))
      Text(state.label)
        .font(ThemeApp.Fonts.bodyText())
        .foregroundStyle(ThemeApp.Colors.textSecondary)
      Button(action: action) {
        Image(systemName: state.isLive ? "stop.fill" : "mic.fill")
          .font(.system(size: 32, weight: .black))
          .foregroundStyle(ThemeApp.Colors.textDark)
          .frame(width: 92, height: 92)
          .background(ThemeApp.Colors.roadmapLine)
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 3))
      }
      .buttonStyle(.plain)
      Text(state.isLive ? "Live conversation is active" : "Tap once to start live voice")
        .font(ThemeApp.Fonts.bodyText(size: 13))
        .foregroundStyle(ThemeApp.Colors.textSecondary)
    }
    .padding(28)
  }
}
