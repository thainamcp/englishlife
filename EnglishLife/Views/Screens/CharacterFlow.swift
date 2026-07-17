import SwiftUI

struct CharacterSetupNameView: View {
    let situation: Situation
    let onHome: () -> Void
    @StateObject private var viewModel = CharacterSetupViewModel()
    var body: some View {
        SetupShell(title: "A new friend", progress: 1) {
            VStack(alignment: .leading, spacing: 20) {
                StoryCard(text: situation.story, symbol: "sparkles")
                Text("What is their name?").font(ThemeApp.Fonts.ctaButton()).foregroundStyle(.white)
                TextField("Character name", text: $viewModel.name).font(ThemeApp.Fonts.bodyText()).padding(
                    16
                ).background(Color.white.opacity(0.13)).clipShape(
                    RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
                Text("Quick picks").font(ThemeApp.Fonts.bodyText(size: 14)).foregroundStyle(
                    .white.opacity(0.75))
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
                    : "Your character is arriving from the English Life universe…", symbol: "sparkles")
                Spacer()
                Group {
                    if viewModel.hasRevealedAvatar {
                        AvatarView(character: character, size: 176).transition(.scale.combined(with: .opacity))
                        Text(viewModel.name).font(ThemeApp.Fonts.gameTitle(size: 35)).foregroundStyle(.white)
                        Text("\(viewModel.vibe) · \(viewModel.hair) hair · \(viewModel.accessory)").font(
                            ThemeApp.Fonts.bodyText()
                        ).foregroundStyle(.white.opacity(0.72))
                    } else {
                        ProgressView().tint(ThemeApp.Colors.roadmapLine).scaleEffect(1.5)
                        Text("Creating your avatar...").font(ThemeApp.Fonts.bodyText()).foregroundStyle(
                            .white.opacity(0.8))
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
            }.task { await viewModel.revealAvatar() }
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
                    Text(title).font(ThemeApp.Fonts.gameTitle()).foregroundStyle(.white)
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
                Text(text).font(ThemeApp.Fonts.bodyText()).foregroundStyle(.white.opacity(0.9))
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
            Text(title).font(ThemeApp.Fonts.ctaButton(size: 16)).foregroundStyle(.white)
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
                    Task { await voiceViewModel.toggleListening() }
                }
                Spacer()
                Text("Voice conversation powered by OpenAI Realtime")
                    .font(ThemeApp.Fonts.bodyText(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 34)
            }
            .foregroundStyle(.white)
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
                    .white.opacity(0.65))
            }
            Spacer()
            if situation != nil {
                Button {
                    viewModel.showsRequirements = true
                } label: {
                    Image(systemName: "checklist").font(.title3).foregroundStyle(ThemeApp.Colors.roadmapLine)
                        .padding(10).background(.white.opacity(0.12)).clipShape(
                            RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
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
            Text(state == .listening ? "I’m listening" : "Talk with \(character.name)")
                .font(ThemeApp.Fonts.gameTitle(size: 28))
            Text(state.label).font(ThemeApp.Fonts.bodyText()).foregroundStyle(.white.opacity(0.75))
            Button(action: action) {
                Image(systemName: state == .listening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .black)).foregroundStyle(ThemeApp.Colors.textDark)
                    .frame(width: 92, height: 92).background(ThemeApp.Colors.roadmapLine).clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 3))
            }.buttonStyle(.plain)
            Text(state == .listening ? "Tap to end your turn" : "Tap the microphone to speak")
                .font(ThemeApp.Fonts.bodyText(size: 13)).foregroundStyle(.white.opacity(0.6))
        }.padding(28)
    }
}

/// Situation mode, opened from the roadmap. It intentionally supports text practice
/// and mission tracking, unlike the voice-only character tab.
struct SituationChatView: View {
    @EnvironmentObject private var app: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let character: Character
    let situation: Situation?
    var onHome: () -> Void = {}
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        ZStack {
            AdventureBackground()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: returnHome) {
                        Image(systemName: "chevron.left").font(.body.weight(.black)).foregroundStyle(
                            ThemeApp.Colors.textDark
                        ).frame(width: 38, height: 38).background(ThemeApp.Colors.roadmapLine).clipShape(
                            Circle())
                    }.buttonStyle(.plain)
                    AvatarView(character: character, size: 46)
                    VStack(alignment: .leading) {
                        Text(character.name).font(ThemeApp.Fonts.ctaButton())
                        Text(situation?.title ?? "Practice mission").font(ThemeApp.Fonts.bodyText(size: 12))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                    Button {
                        viewModel.showsRequirements = true
                    } label: {
                        Image(systemName: "checklist").font(.title3).foregroundStyle(
                            ThemeApp.Colors.roadmapLine
                        ).padding(10).background(.white.opacity(0.12)).clipShape(
                            RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 20).padding(.top, 58).padding(.bottom, 14)
                ScrollView {
                    VStack(spacing: 14) {
                        ChatBubble(
                            text: "Hi! I’m \(character.name). Let’s complete this mission together!", mine: false)
                        ForEach(viewModel.messages) { ChatBubble(text: $0.text, mine: $0.isMine) }
                    }.padding(20)
                }
                HStack(spacing: 10) {
                    TextField("Write your reply...", text: $viewModel.draft).font(ThemeApp.Fonts.bodyText())
                        .padding(14).background(.white.opacity(0.12)).clipShape(
                            RoundedRectangle(cornerRadius: ThemeApp.Radius.button))
                    Button {
                        viewModel.send()
                    } label: {
                        Image(systemName: "arrow.up").fontWeight(.black).foregroundStyle(
                            ThemeApp.Colors.textDark
                        ).padding(15).background(ThemeApp.Colors.roadmapLine).clipShape(Circle())
                    }.disabled(viewModel.draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }.padding(16)
            }.foregroundStyle(.white).ignoresSafeArea(edges: .top)
        }
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
    }
    
    private func returnHome() {
        app.selectedTab = 0
        onHome()
        dismiss()
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
                Text("Mission complete!").font(ThemeApp.Fonts.gameTitle(size: 32)).foregroundStyle(.white)
                Text("You completed \(situation.title) and earned +\(situation.reward) EXP.").font(
                    ThemeApp.Fonts.bodyText()
                ).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
                GlassCard {
                    VStack(spacing: 8) {
                        Label("New situation unlocked", systemImage: "lock.open.fill").font(
                            ThemeApp.Fonts.ctaButton(size: 15)
                        ).foregroundStyle(ThemeApp.Colors.roadmapLine)
                        Text(situation.unlock).font(ThemeApp.Fonts.gameTitle(size: 22)).foregroundStyle(.white)
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
            Text(text).font(ThemeApp.Fonts.bodyText()).foregroundStyle(
                mine ? ThemeApp.Colors.textDark : .white
            ).padding(14).background(mine ? ThemeApp.Colors.roadmapLine : Color.white.opacity(0.15))
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
                            .foregroundStyle(.white.opacity(0.75))
                        ForEach(situation.goals, id: \.self) { word in
                            HStack {
                                Image(
                                    systemName: state.progress(for: situation) == .completed
                                    ? "checkmark.circle.fill" : "circle"
                                ).foregroundStyle(
                                    state.progress(for: situation) == .completed
                                    ? ThemeApp.Colors.mint : .white.opacity(0.55))
                                Text(word).font(ThemeApp.Fonts.bodyText())
                                Spacer()
                            }
                        }
                        Divider().overlay(.white.opacity(0.2))
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
