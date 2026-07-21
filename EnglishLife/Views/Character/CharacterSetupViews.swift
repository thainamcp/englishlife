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
                icon: "sparkles",
                height: 60
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
    var height: CGFloat = 56
    
    var body: some View {
        NavigationLink(destination: destination) {
            SetupButtonLabel(title: title, icon: icon, height: height)
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
    var height: CGFloat = 56
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
            if let icon { Image(systemName: icon) }
        }
        .font(ThemeApp.Fonts.ctaButton(size: 15))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: height)
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
