import SwiftUI

struct CharactersListView: View {
  @EnvironmentObject private var state: AppViewModel
  @State private var selectedCharacter: Character?

  var body: some View {
    Group {
      if state.characters.isEmpty {
        emptyState
      } else {
        characterList
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // The shared MainTabView owns the map image background for all tab screens.
    .background(Color.clear)
    .fullScreenCover(item: $selectedCharacter) { character in
      SituationChatView(
        character: character,
        situation: nil,
        onHome: { state.selectedTab = 1 }
      )
    }
  }

  private var emptyState: some View {
    VStack(spacing: 0) {
      Spacer()

      Image(systemName: "person.2.fill")
        .font(.system(size: 64, weight: .bold))
        .foregroundStyle(ThemeApp.Colors.textSecondary.opacity(0.72))
        .padding(.bottom, 22)

      Text("Your character book is empty")
        .font(ThemeApp.Fonts.ctaButton(size: 19))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .multilineTextAlignment(.center)

      Text("Complete a map situation to create your first\nconversation partner.")
        .font(ThemeApp.Fonts.bodyText(size: 15))
        .foregroundStyle(ThemeApp.Colors.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.top, 3)
        .padding(.horizontal, 22)

      Button {
        state.selectedTab = 0
      } label: {
        Label("Explore the map", systemImage: "map.fill")
          .font(ThemeApp.Fonts.ctaButton(size: 16))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(ThemeApp.Colors.primary, in: Capsule())
          .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)
      .padding(.top, 18)
      .padding(.horizontal, 64)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 20)
  }

  private var characterList: some View {
    VStack(spacing: 0) {
      ScrollView(showsIndicators: false) {
        LazyVStack(spacing: 12) {
          ForEach(state.characters) { character in
            Button {
              selectedCharacter = character
            } label: {
              CharacterListRow(character: character)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.top, 14)
        .padding(.bottom, 110)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 20)
  }
}

private struct CharacterListRow: View {
  let character: Character

  var body: some View {
    HStack(spacing: 12) {
      CharacterListPortrait(character: character)

      VStack(alignment: .leading, spacing: 2) {
        Text(character.name)
          .font(ThemeApp.Fonts.ctaButton(size: 17))
          .foregroundStyle(ThemeApp.Colors.textPrimary)

        Text(character.situationTitle)
          .font(ThemeApp.Fonts.body2Text(size: 14))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }

      Spacer(minLength: 0)

      Image(systemName: "chevron.right")
        .font(.body.weight(.bold))
        .foregroundStyle(ThemeApp.Colors.textSecondary)
    }
    .padding(.horizontal, 18)
    .frame(minHeight: 94)
    .background(ThemeApp.Colors.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 22))
    .overlay(
      RoundedRectangle(cornerRadius: 22)
        .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
    )
  }
}

private struct CharacterListPortrait: View {
  let character: Character

  var body: some View {
    Group {
      if let data = character.avatarImageData, let image = UIImage(data: data) {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
      } else {
        Image(systemName: character.avatar)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
      }
    }
    .frame(width: 54, height: 72, alignment: .bottom)
  }
}
