import SwiftUI

struct MapView: View {
  @EnvironmentObject private var state: AppViewModel
  @StateObject private var viewModel = MapViewModel()
  @State private var chapterIndex = 0

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        if let chapter = selectedChapter {
          MapChapterNavigator(
            chapter: chapter,
            index: chapterIndex,
            count: state.chapters.count,
            previous: { changeChapter(by: -1) },
            next: { changeChapter(by: 1) }
          )
          .padding(.horizontal, 20)
          .padding(.bottom, 8)

          ScrollView(showsIndicators: false) {
            RoadMap(chapter: chapter, situations: state.situations) {
              viewModel.select($0, using: state)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
          }
        } else {
          Spacer()
          ProgressView().tint(ThemeApp.Colors.primary)
          Spacer()
        }
      }

      if let situation = viewModel.goalSituation {
        GoalPreviewOverlay(
          situation: situation,
          cancel: { viewModel.goalSituation = nil },
          start: { viewModel.begin(situation, using: state) }
        )
        .zIndex(1)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
      }
    }
    .animation(.easeInOut(duration: 0.18), value: viewModel.goalSituation)
    .sheet(item: $viewModel.selectedSituation) { SituationCardView(situation: $0) }
    .fullScreenCover(item: $state.activeChatSession) { session in
      SituationChatView(character: session.character, situation: session.situation) {
        state.activeChatSession = nil
        state.selectedTab = 0
      }
    }
    .task {
      await state.ensureStudyPath()
      viewModel.restoreCurrentSituation(using: state, situations: state.situations)
      restoreSelectedChapter()
    }
    .onChange(of: state.chapters.count) { _, _ in clampChapterIndex() }
  }

  private var selectedChapter: AdventureChapter? {
    guard state.chapters.indices.contains(chapterIndex) else { return nil }
    return state.chapters[chapterIndex]
  }

  private func changeChapter(by offset: Int) {
    let newIndex = chapterIndex + offset
    guard state.chapters.indices.contains(newIndex) else { return }
    withAnimation(.easeInOut(duration: 0.2)) {
      chapterIndex = newIndex
    }
  }

  private func clampChapterIndex() {
    guard !state.chapters.isEmpty else {
      chapterIndex = 0
      return
    }
    chapterIndex = min(max(chapterIndex, 0), state.chapters.count - 1)
  }

  private func restoreSelectedChapter() {
    clampChapterIndex()
    guard
      let resumeSituation = state.situationToResume(from: state.situations),
      let resumeChapterIndex = state.chapters.firstIndex(where: {
        resumeSituation.chapter.hasPrefix("Chapter \($0.id)")
      })
    else { return }
    chapterIndex = resumeChapterIndex
  }
}

struct RoadMap: View {
  let chapter: AdventureChapter
  let situations: [Situation]
  let select: (Situation) -> Void

  var body: some View {
    ChapterMapRoad(
      situations: situations.filter { $0.chapter.hasPrefix("Chapter \(chapter.id)") },
      select: select
    )
  }
}
