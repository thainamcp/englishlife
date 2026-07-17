import SwiftUI

struct MainTabView: View {
  @EnvironmentObject private var state: AppViewModel
  var body: some View {
    TabView(selection: $state.selectedTab) {
      MapView().tabItem { Label("Map", systemImage: "map.fill") }.tag(0)
      CharactersListView().tabItem { Label("Characters", systemImage: "person.2.fill") }.tag(1)
    }.tint(ThemeApp.Colors.roadmapLine)
  }
}

struct MapView: View {
  @EnvironmentObject private var state: AppViewModel
  @StateObject private var viewModel = MapViewModel()
  var body: some View {
    ZStack {
      AdventureBackground()
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 18) {
          HStack {
            VStack(alignment: .leading) {
              Text("English Life").font(ThemeApp.Fonts.gameTitle(size: 29))
              Text("Hi, \(state.learnerName) · \(state.level.rawValue)").font(
                ThemeApp.Fonts.bodyText(size: 14)
              ).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Image(systemName: "star.fill").foregroundStyle(ThemeApp.Colors.roadmapLine).font(
              .title2)
          }
          Text("Complete each situation to unlock the next stop.").font(ThemeApp.Fonts.bodyText())
            .foregroundStyle(.white.opacity(0.85))
          RoadMap(chapters: viewModel.chapters, situations: viewModel.situations) {
            viewModel.select($0, using: state)
          }
          GlassCard {
            HStack {
              Image(systemName: "flame.fill").font(.title2).foregroundStyle(
                ThemeApp.Colors.roadmapLine)
              VStack(alignment: .leading) {
                Text("Your streak").font(ThemeApp.Fonts.bodyText())
                Text("Start a conversation today!").font(ThemeApp.Fonts.bodyText(size: 13))
                  .foregroundStyle(.white.opacity(0.7))
              }
              Spacer()
              Text("0 days").font(ThemeApp.Fonts.ctaButton(size: 14))
            }
          }
        }.foregroundStyle(.white).padding(20).padding(.bottom, 16)
      }
    }
    .sheet(item: $viewModel.selectedSituation) { SituationCardView(situation: $0) }
    .fullScreenCover(item: $state.activeChatSession) { session in
      SituationChatView(character: session.character, situation: session.situation) {
        state.activeChatSession = nil
        state.selectedTab = 0
      }
    }
  }
}

struct RoadMap: View {
  @EnvironmentObject private var state: AppViewModel
  let chapters: [AdventureChapter]
  let situations: [Situation]
  let select: (Situation) -> Void
  var body: some View {
    VStack(spacing: 16) {
      ForEach(chapters) { chapter in
        ChapterRoadmapCard(
          chapter: chapter,
          situations: situations.filter { $0.chapter.hasPrefix("Chapter \(chapter.id)") },
          select: select)
      }
    }
  }
}

struct ChapterRoadmapCard: View {
  @EnvironmentObject private var state: AppViewModel
  let chapter: AdventureChapter
  let situations: [Situation]
  let select: (Situation) -> Void
  var body: some View {
    GlassCard {
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 12) {
          Image(systemName: chapter.icon).font(.title3.weight(.black)).foregroundStyle(
            ThemeApp.Colors.textDark
          ).frame(width: 42, height: 42).background(chapter.color).clipShape(
            RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
          VStack(alignment: .leading, spacing: 2) {
            Text("Chapter \(chapter.id) · \(chapter.title)").font(
              ThemeApp.Fonts.ctaButton(size: 16))
            Text(chapter.subtitle).font(ThemeApp.Fonts.bodyText(size: 12)).foregroundStyle(
              .white.opacity(0.68))
          }
          Spacer()
          Text("\(situations.filter { state.progress(for: $0) == .completed }.count)/10").font(
            ThemeApp.Fonts.ctaButton(size: 13)
          ).foregroundStyle(chapter.color)
        }
        ZStack {
          CurvedRoadLine(nodeCount: situations.count).stroke(
            ThemeApp.Colors.roadmapLine,
            style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
          ).padding(.vertical, 12)
          VStack(spacing: 12) {
            ForEach(Array(situations.enumerated()), id: \.element.id) { index, situation in
              LongRoadMapNode(
                situation: situation, index: index, isLeading: index.isMultiple(of: 2),
                select: select)
            }
          }
        }
      }
    }
  }
}

struct LongRoadMapNode: View {
  @EnvironmentObject private var state: AppViewModel
  let situation: Situation
  let index: Int
  let isLeading: Bool
  let select: (Situation) -> Void
  var body: some View {
    let progress = state.progress(for: situation)
    GeometryReader { proxy in
      let markerX = proxy.size.width / 2 + curveOffset
      let labelWidth = min(160, proxy.size.width * 0.42)
      ZStack {
        nodeLabel(progress)
          .frame(width: labelWidth)
          .position(
            x: labelCenter(
              markerX: markerX, labelWidth: labelWidth, containerWidth: proxy.size.width), y: 38)
        marker(progress).position(x: markerX, y: 38)
      }
    }.frame(height: 76)
  }
  private var curveOffset: CGFloat {
    let offsets: [CGFloat] = [0, 24, 34, 8, -24, -36, -12, 22, 32, 0]
    return offsets[index % offsets.count]
  }
  private func marker(_ progress: SituationProgress) -> some View {
    ZStack {
      Circle().fill(situation.color).frame(width: 56, height: 56)
      Image(systemName: situation.icon).font(.body.weight(.black)).foregroundStyle(
        ThemeApp.Colors.textDark.opacity(progress == .locked ? 0.45 : 1))
      if progress == .locked {
        Circle().fill(ThemeApp.Colors.backgroundDark.opacity(0.62)).frame(width: 56, height: 56)
        Image(systemName: "lock.fill").font(.body.weight(.black)).foregroundStyle(
          .white.opacity(0.78))
      }
    }.overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 3)).zIndex(1)
  }
  private func labelCenter(markerX: CGFloat, labelWidth: CGFloat, containerWidth: CGFloat)
    -> CGFloat
  {
    let desired = isLeading ? markerX - labelWidth / 2 - 42 : markerX + labelWidth / 2 + 42
    return min(max(desired, labelWidth / 2), containerWidth - labelWidth / 2)
  }
  private func nodeLabel(_ progress: SituationProgress) -> some View {
    Button {
      if progress != .locked { select(situation) }
    } label: {
      VStack(alignment: isLeading ? .trailing : .leading, spacing: 3) {
        Text("\(situation.id). \(situation.title)").font(ThemeApp.Fonts.ctaButton(size: 13))
          .lineLimit(2)
        Text(progress.label).font(ThemeApp.Fonts.bodyText(size: 11)).foregroundStyle(
          progress == .locked ? .white.opacity(0.6) : ThemeApp.Colors.roadmapLine)
      }.foregroundStyle(progress == .locked ? .white.opacity(0.5) : .white).frame(
        maxWidth: .infinity, alignment: isLeading ? .trailing : .leading
      ).padding(.horizontal, 10).padding(.vertical, 8).background(
        progress == .locked ? Color.white.opacity(0.08) : Color.white.opacity(0.14)
      ).clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
    }.buttonStyle(.plain).disabled(progress == .locked)
  }
}

struct CurvedRoadLine: Shape {
  let nodeCount: Int
  func path(in rect: CGRect) -> Path {
    let offsets: [CGFloat] = [0, 24, 34, 8, -24, -36, -12, 22, 32, 0]
    let top: CGFloat = 38
    let spacing: CGFloat = 88
    let centerX = rect.midX
    var path = Path()
    guard nodeCount > 0 else { return path }
    var previous = CGPoint(x: centerX + offsets[0], y: top)
    path.move(to: previous)
    for index in 1..<nodeCount {
      let next = CGPoint(
        x: centerX + offsets[index % offsets.count], y: top + CGFloat(index) * spacing)
      let control = CGPoint(
        x: (previous.x + next.x) / 2 + (index.isMultiple(of: 2) ? 16 : -16),
        y: (previous.y + next.y) / 2)
      path.addQuadCurve(to: next, control: control)
      previous = next
    }
    return path
  }
}

struct SituationCardView: View {
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  let situation: Situation
  @State private var goToSetup = false
  private var progress: SituationProgress { state.progress(for: situation) }
  var body: some View {
    NavigationStack {
      ZStack {
        AdventureBackground()
        VStack(alignment: .leading, spacing: 20) {
          HStack {
            Image(systemName: situation.icon).font(.largeTitle.weight(.black)).foregroundStyle(
              situation.color)
            Spacer()
            Button("Close") { dismiss() }.font(ThemeApp.Fonts.bodyText(size: 14)).foregroundStyle(
              .white)
          }
          Text(situation.chapter).font(ThemeApp.Fonts.bodyText(size: 13)).foregroundStyle(
            ThemeApp.Colors.roadmapLine)
          Text(situation.title).font(ThemeApp.Fonts.gameTitle(size: 32)).foregroundStyle(.white)
          Text(situation.subtitle).font(ThemeApp.Fonts.bodyText()).foregroundStyle(
            .white.opacity(0.78))
          GlassCard {
            VStack(alignment: .leading, spacing: 12) {
              Label("Mission keywords", systemImage: "checkmark.seal.fill").font(
                ThemeApp.Fonts.ctaButton(size: 15))
              FlowTags(tags: situation.goals)
              Divider().overlay(.white.opacity(0.2))
              Label(
                "+\(situation.reward) EXP · Unlock \(situation.unlock)", systemImage: "gift.fill"
              ).font(ThemeApp.Fonts.bodyText(size: 14))
            }
          }
          Spacer()
          GameButton(
            title: state.character(for: situation) == nil
              ? "Meet your character"
              : "Talk to \(state.character(for: situation)?.name ?? "character")",
            icon: "arrow.right"
          ) {
            if state.character(for: situation) == nil {
              goToSetup = true
            } else if let character = state.character(for: situation) {
              dismiss()
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                state.presentChat(character: character, situation: situation)
              }
            }
          }
        }.padding(24)
      }
      .navigationDestination(isPresented: $goToSetup) {
        CharacterSetupNameView(situation: situation, onHome: { dismiss() })
      }
    }
  }
}

struct FlowTags: View {
  let tags: [String]
  var body: some View { HStack(spacing: 7) { ForEach(tags, id: \.self) { GameTag(title: $0) } } }
}
