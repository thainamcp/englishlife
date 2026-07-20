import SwiftUI
import UIKit

struct MainTabView: View {
  @EnvironmentObject private var state: AppViewModel
  var body: some View {
    TabView(selection: $state.selectedTab) {
      MapView().tabItem { Label("Map", systemImage: "map.fill") }.tag(0)
      CharactersListView().tabItem { Label("Characters", systemImage: "person.2.fill") }.tag(1)
      UserProfileView().tabItem { Label("User", systemImage: "person.crop.circle.fill") }.tag(2)
    }.tint(ThemeApp.Colors.roadmapLine)
  }
}

struct UserProfileView: View {
  @EnvironmentObject private var state: AppViewModel

  var body: some View {
    ZStack {
      AdventureBackground()
      VStack(alignment: .leading, spacing: 22) {
        SectionTitle("Your profile", subtitle: "Your English adventure")
        GlassCard {
          HStack(spacing: 16) {
            ZStack {
              Circle().fill(ThemeApp.Colors.roadmapLine)
              Image(systemName: state.level.icon).font(.title.weight(.black)).foregroundStyle(
                ThemeApp.Colors.textDark)
            }.frame(width: 76, height: 76)
            VStack(alignment: .leading, spacing: 5) {
              Text(state.learnerName.isEmpty ? "Explorer" : state.learnerName).font(
                ThemeApp.Fonts.gameTitle(size: 25))
              Text(state.level.rawValue).font(ThemeApp.Fonts.bodyText(size: 15)).foregroundStyle(
                ThemeApp.Colors.roadmapLine)
            }
          }
        }
        GlassCard {
          VStack(alignment: .leading, spacing: 14) {
            Label("Current level", systemImage: state.level.icon).font(
              ThemeApp.Fonts.ctaButton(size: 16))
            Text(levelDescription).font(ThemeApp.Fonts.bodyText(size: 14)).foregroundStyle(
              ThemeApp.Colors.textSecondary)
            Divider().overlay(ThemeApp.Colors.border)
            Label("\(state.characters.count) characters unlocked", systemImage: "person.2.fill")
              .font(ThemeApp.Fonts.bodyText(size: 14))
          }.foregroundStyle(ThemeApp.Colors.textPrimary)
        }
        Spacer()
      }.padding(20).foregroundStyle(ThemeApp.Colors.textPrimary)
    }
  }

  private var levelDescription: String {
    switch state.level {
    case .beginner: "Start with friendly, everyday conversations."
    case .intermediate: "Take on more varied real-life situations."
    case .advanced: "Handle complex conversations with confidence."
    }
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
              Text("English").font(ThemeApp.Fonts.gameTitle(size: 29))
              Text("Hi, \(state.learnerName) · \(state.level.rawValue)").font(
                ThemeApp.Fonts.bodyText(size: 14)
              ).foregroundStyle(ThemeApp.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "star.fill").foregroundStyle(ThemeApp.Colors.roadmapLine).font(
              .title2)
          }
          Text("Complete each situation to unlock the next stop.").font(ThemeApp.Fonts.bodyText())
            .foregroundStyle(ThemeApp.Colors.textSecondary)
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
                  .foregroundStyle(ThemeApp.Colors.textSecondary)
              }
              Spacer()
              Text("0 days").font(ThemeApp.Fonts.ctaButton(size: 14))
            }
          }
        }.foregroundStyle(ThemeApp.Colors.textPrimary).padding(20).padding(.bottom, 16)
      }
    }
    .sheet(item: $viewModel.selectedSituation) { SituationCardView(situation: $0) }
    .fullScreenCover(item: $state.activeChatSession) { session in
      SituationChatView(character: session.character, situation: session.situation) {
        state.activeChatSession = nil
        state.selectedTab = 0
      }
    }
    .task {
      viewModel.restoreCurrentSituation(using: state)
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
              ThemeApp.Colors.textSecondary)
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
          VStack(spacing: 24) {
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
      let labelWidth = min(150, proxy.size.width * 0.38)
      ZStack {
        nodeLabel(progress)
          .frame(width: labelWidth)
          .position(
            x: labelCenter(
              markerX: markerX, labelWidth: labelWidth, containerWidth: proxy.size.width), y: 60)
        marker(progress).position(x: markerX, y: 60)
      }
    }.frame(height: 132)
  }
  private var curveOffset: CGFloat {
    let offsets: [CGFloat] = [0, 52, 0, -52, 0, 52, 0, -52, 0, 52]
    return offsets[index % offsets.count]
  }
  private func marker(_ progress: SituationProgress) -> some View {
    ZStack {
      Circle().fill(situation.color).frame(width: 96, height: 96)
      if let assetName = situation.imageAsset, let image = UIImage(named: assetName) {
        Image(uiImage: image).resizable().scaledToFill().frame(width: 88, height: 88).clipShape(
          Circle())
      } else {
        Image(systemName: situation.icon).font(.system(size: 34, weight: .black)).foregroundStyle(
          ThemeApp.Colors.textDark.opacity(progress == .locked ? 0.45 : 1))
      }
      if progress == .locked {
        Circle().fill(ThemeApp.Colors.backgroundDark.opacity(0.62)).frame(width: 96, height: 96)
        Image(systemName: "lock.fill").font(.title.weight(.black)).foregroundStyle(
          .white.opacity(0.78))
      }
    }.overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 4)).zIndex(1)
  }
  private func labelCenter(markerX: CGFloat, labelWidth: CGFloat, containerWidth: CGFloat)
    -> CGFloat
  {
    let desired =
      curveOffset >= 0
      ? markerX - labelWidth / 2 - 62
      : markerX + labelWidth / 2 + 62
    return min(max(desired, labelWidth / 2), containerWidth - labelWidth / 2)
  }
  private func nodeLabel(_ progress: SituationProgress) -> some View {
    Button {
      if progress != .locked { select(situation) }
    } label: {
      VStack(alignment: curveOffset >= 0 ? .trailing : .leading, spacing: 3) {
        Text("\(situation.id). \(situation.title)").font(ThemeApp.Fonts.ctaButton(size: 13))
          .lineLimit(2)
        Text(progress.label).font(ThemeApp.Fonts.bodyText(size: 11)).foregroundStyle(
          progress == .locked
            ? ThemeApp.Colors.textSecondary.opacity(0.8) : ThemeApp.Colors.roadmapLine)
      }.foregroundStyle(
        progress == .locked
          ? ThemeApp.Colors.textSecondary.opacity(0.65) : ThemeApp.Colors.textPrimary
      ).frame(
        maxWidth: .infinity, alignment: curveOffset >= 0 ? .trailing : .leading
      ).padding(.horizontal, 10).padding(.vertical, 8).background(
        progress == .locked ? ThemeApp.Colors.surface.opacity(0.65) : Color.white
      ).clipShape(RoundedRectangle(cornerRadius: ThemeApp.Radius.tag)).overlay(
        RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(
          ThemeApp.Colors.border.opacity(0.7))
      )
    }.buttonStyle(.plain).disabled(progress == .locked)
  }
}

struct CurvedRoadLine: Shape {
  let nodeCount: Int
  func path(in rect: CGRect) -> Path {
    let offsets: [CGFloat] = [0, 52, 0, -52, 0, 52, 0, -52, 0, 52]
    let top: CGFloat = 60
    let spacing: CGFloat = 156
    let centerX = rect.midX
    var path = Path()
    guard nodeCount > 0 else { return path }
    let points = (0..<nodeCount).map {
      CGPoint(x: centerX + offsets[$0 % offsets.count], y: top + CGFloat($0) * spacing)
    }
    path.move(to: points[0])
    for index in 0..<(points.count - 1) {
      let before = points[max(0, index - 1)]
      let start = points[index]
      let end = points[index + 1]
      let after = points[min(points.count - 1, index + 2)]
      let smoothing: CGFloat = 0.14
      let control1 = CGPoint(
        x: start.x + (end.x - before.x) * smoothing,
        y: start.y + (end.y - before.y) * smoothing
      )
      let control2 = CGPoint(
        x: end.x - (after.x - start.x) * smoothing,
        y: end.y - (after.y - start.y) * smoothing
      )
      path.addCurve(to: end, control1: control1, control2: control2)
    }
    return path
  }
}

struct SituationCardView: View {
  @EnvironmentObject private var state: AppViewModel
  @Environment(\.dismiss) private var dismiss
  let situation: Situation
  @StateObject private var narrativeViewModel = NarrativeViewModel()
  @StateObject private var sceneViewModel = SituationSceneViewModel()
  @State private var showsCharacterSetup = false
  private var progress: SituationProgress { state.progress(for: situation) }
  private var existingCharacter: Character? { state.character(for: situation) }
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
              ThemeApp.Colors.textPrimary)
          }
          Text(situation.chapter).font(ThemeApp.Fonts.bodyText(size: 13)).foregroundStyle(
            ThemeApp.Colors.roadmapLine)
          Text(situation.title).font(ThemeApp.Fonts.gameTitle(size: 32)).foregroundStyle(
            ThemeApp.Colors.textPrimary)
          Text(situation.subtitle).font(ThemeApp.Fonts.bodyText()).foregroundStyle(
            ThemeApp.Colors.textSecondary)
          Label(situation.locationName, systemImage: "mappin.and.ellipse")
            .font(ThemeApp.Fonts.bodyText(size: 13))
            .foregroundStyle(ThemeApp.Colors.primary)
          GlassCard {
            VStack(alignment: .leading, spacing: 10) {
              Label("Your AI welcome", systemImage: "sparkles")
                .font(ThemeApp.Fonts.ctaButton(size: 15))
                .foregroundStyle(ThemeApp.Colors.roadmapLine)
              if narrativeViewModel.isLoading {
                HStack(spacing: 9) {
                  ProgressView().tint(ThemeApp.Colors.roadmapLine)
                  Text("Creating your personalized mission…")
                }
                .font(ThemeApp.Fonts.bodyText(size: 14))
                .foregroundStyle(ThemeApp.Colors.textSecondary)
              } else if let errorMessage = narrativeViewModel.errorMessage {
                Text(errorMessage)
                  .font(ThemeApp.Fonts.bodyText(size: 13))
                  .foregroundStyle(ThemeApp.Colors.textSecondary)
                Button("Try again") {
                  Task { await narrativeViewModel.requestGuidance() }
                }
                .font(ThemeApp.Fonts.ctaButton(size: 13))
                .foregroundStyle(ThemeApp.Colors.primary)
              } else {
                Text(narrativeViewModel.guidance)
                  .font(ThemeApp.Fonts.bodyText(size: 14))
                  .foregroundStyle(ThemeApp.Colors.textPrimary.opacity(0.86))
                  .multilineTextAlignment(.leading)
                  .lineLimit(nil)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
          }
          GlassCard {
            VStack(alignment: .leading, spacing: 14) {
              Label("Mission keywords", systemImage: "checkmark.seal.fill").font(
                ThemeApp.Fonts.ctaButton(size: 15)
              )
              .foregroundStyle(ThemeApp.Colors.textPrimary)
              if narrativeViewModel.isLoading {
                KeywordLoadingGrid()
              } else if let errorMessage = narrativeViewModel.errorMessage {
                Label("Keywords will appear after retrying.", systemImage: "arrow.clockwise")
                  .font(ThemeApp.Fonts.bodyText(size: 13))
                  .foregroundStyle(ThemeApp.Colors.textSecondary)
                  .accessibilityLabel(errorMessage)
              } else {
                MissionKeywordGrid(tags: narrativeViewModel.context?.targetKeywords ?? [])
              }
              Divider().overlay(ThemeApp.Colors.border)
              Label(
                "+\(situation.reward) EXP · Unlock \(situation.unlock)", systemImage: "gift.fill"
              ).font(ThemeApp.Fonts.bodyText(size: 14)).foregroundStyle(
                ThemeApp.Colors.textSecondary)
            }
          }
          Spacer()
          GameButton(
            title: buttonTitle,
            icon: buttonIcon
          ) {
            guard let character = existingCharacter else {
              showsCharacterSetup = true
              return
            }
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
              state.presentChat(character: character, situation: situation)
            }
          }
          .disabled(
            narrativeViewModel.isLoading || (existingCharacter != nil && sceneViewModel.isPreparing)
          )
          .opacity(
            narrativeViewModel.isLoading || (existingCharacter != nil && sceneViewModel.isPreparing)
              ? 0.58 : 1)
        }.padding(24)
      }
      .task {
        narrativeViewModel.configure(
          userName: state.learnerName,
          level: state.level,
          situation: situation,
          useCachedGuidance: progress == .completed)
        async let guidance = narrativeViewModel.requestGuidance(
          preferCached: progress == .completed)
        async let scene = sceneViewModel.prepare(for: situation, character: existingCharacter)
        _ = await (guidance, scene)
      }
      .navigationDestination(isPresented: $showsCharacterSetup) {
        CharacterSetupNameView(situation: situation, onHome: { dismiss() })
      }
    }
  }

  private var buttonTitle: String {
    if existingCharacter == nil { return "Create \(situation.characterName)" }
    return sceneViewModel.isPreparing ? "Preparing your scene…" : "Start speaking"
  }

  private var buttonIcon: String {
    if existingCharacter == nil { return "person.badge.plus" }
    return sceneViewModel.isPreparing ? "hourglass" : "mic.fill"
  }
}

struct MissionKeywordGrid: View {
  let tags: [String]

  private let columns = [
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(Array(tags.enumerated()), id: \.offset) { index, keyword in
        HStack(alignment: .top, spacing: 8) {
          Text("\(index + 1)")
            .font(ThemeApp.Fonts.ctaButton(size: 11))
            .foregroundStyle(ThemeApp.Colors.primary)
            .frame(width: 22, height: 22)
            .background(ThemeApp.Colors.riverBlue, in: Circle())
          Text(keyword)
            .font(ThemeApp.Fonts.bodyText(size: 13))
            .foregroundStyle(ThemeApp.Colors.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: ThemeApp.Radius.tag))
        .overlay(
          RoundedRectangle(cornerRadius: ThemeApp.Radius.tag).stroke(ThemeApp.Colors.border)
        )
      }
    }
  }
}

struct KeywordLoadingGrid: View {
  private let columns = [
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      ForEach(0..<4, id: \.self) { _ in
        RoundedRectangle(cornerRadius: ThemeApp.Radius.tag)
          .fill(ThemeApp.Colors.border.opacity(0.55))
          .frame(height: 54)
          .redacted(reason: .placeholder)
      }
    }
  }
}
