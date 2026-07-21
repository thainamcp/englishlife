import SwiftUI

struct UserProfileView: View {
  @EnvironmentObject private var state: AppViewModel

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 24) {
        learnerCard
        progressCard
        learnedWords
      }
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .padding(.bottom, 112)
    }
  }

  private var learnerCard: some View {
    HStack(spacing: 14) {
      ZStack {
        Circle().fill(ThemeApp.Colors.primary.opacity(0.24))
        Image(systemName: "person.fill")
          .font(.title2.weight(.bold))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
      }
      .frame(width: 60, height: 60)

      Text(state.learnerName.isEmpty ? "Explorer" : state.learnerName)
        .font(ThemeApp.Fonts.gameTitle(size: 24))
        .foregroundStyle(ThemeApp.Colors.textPrimary)

      Spacer(minLength: 0)

      Text(state.level.rawValue)
        .font(ThemeApp.Fonts.ctaButton(size: 14))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(ThemeApp.Colors.roadmapLine, in: Capsule())
        .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
    }
    .padding(.horizontal, 16)
    .frame(height: 90)
    .background(ThemeApp.Colors.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 24))
    .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
  }

  private var progressCard: some View {
    VStack(alignment: .leading, spacing: 13) {
      Label("Learning Progress", systemImage: "flag.checkered")
        .font(ThemeApp.Fonts.ctaButton(size: 20))
        .foregroundStyle(ThemeApp.Colors.textPrimary)
      Text("You’ve completed \(completedChapterCount) chapters. Keep going!")
        .font(ThemeApp.Fonts.body2Text())
        .foregroundStyle(ThemeApp.Colors.textSecondary)
      Divider().overlay(ThemeApp.Colors.border.opacity(0.7))
      Label("\(state.characters.count) characters unlocked", systemImage: "person.2.fill")
        .font(ThemeApp.Fonts.body2Text(size: 16))
        .foregroundStyle(ThemeApp.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(22)
    .background(ThemeApp.Colors.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 24))
    .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
  }

  private var learnedWords: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Vocabulary Library")
          .font(ThemeApp.Fonts.ctaButton(size: 21))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
        Spacer()
        NavigationLink {
          VocabularyLibraryView()
            .environmentObject(state)
        } label: {
          Text("See all")
            .font(ThemeApp.Fonts.ctaButton(size: 14))
            .foregroundStyle(ThemeApp.Colors.primary)
        }
        .buttonStyle(.plain)
      }

      if displayedWords.isEmpty {
        Text("Your study path will add useful words here.")
          .font(ThemeApp.Fonts.body2Text())
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(18)
          .background(ThemeApp.Colors.surface.opacity(0.88), in: RoundedRectangle(cornerRadius: 20))
          .overlay(
            RoundedRectangle(cornerRadius: 20).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      } else {
        LazyVGrid(
          columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
          spacing: 12
        ) {
          ForEach(displayedWords) { word in
            NavigationLink {
              VocabularyWordDetailView(wordID: word.id)
                .environmentObject(state)
            } label: {
              Text(word.word)
                .font(ThemeApp.Fonts.body2Text(size: 16))
                .foregroundStyle(ThemeApp.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .padding(.horizontal, 8)
                .background(
                  ThemeApp.Colors.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 32)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 32)
                    .strokeBorder(ThemeApp.Colors.border, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private let initialKeywordLimit = 8

  private var completedChapterCount: Int {
    state.chapters.filter { chapter in
      let chapterSituations = state.situations.filter {
        $0.chapter.hasPrefix("Chapter \(chapter.id)")
      }
      return !chapterSituations.isEmpty
        && chapterSituations.allSatisfy { state.progress(for: $0) == .completed }
    }.count
  }

  private var displayedWords: [VocabularyWord] {
    Array(state.vocabulary.prefix(initialKeywordLimit))
  }
}
