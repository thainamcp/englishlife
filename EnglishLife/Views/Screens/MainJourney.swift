import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var state: AppViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                MainTabHeader(title: selectedTabTitle)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                
                selectedScreen
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: 96)
                    }
            }
            
            MainTabBar(selection: $state.selectedTab)
                .padding(.horizontal, 70)
                .padding(.bottom, -12)
        }
        .background {
            MainTabBackground()
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private var selectedScreen: some View {
        switch state.selectedTab {
        case 0:
            MapView()
        case 1:
            CharactersListView()
        default:
            UserProfileView()
        }
    }
    
    private var selectedTabTitle: String {
        switch state.selectedTab {
        case 0: "MAP"
        case 1: "CHARACTERS"
        default: "PROFILE"
        }
    }
}

private struct MainTabBar: View {
    @Binding var selection: Int
    
    private let items = [
        MainTabItem(title: "Map", icon: "map.fill"),
        MainTabItem(title: "Characters", icon: "person.2.fill"),
        MainTabItem(title: "Profile", icon: "person.fill"),
    ]
    
    var body: some View {
        GeometryReader { proxy in
            let itemWidth = proxy.size.width / CGFloat(items.count)
            let isFirstTab = selection == 0
            let isLastTab = selection == items.count - 1
            let selectedWidth = itemWidth - (isFirstTab || isLastTab ? 3 : 0)
            let selectedOffset = itemWidth * CGFloat(selection) + (isFirstTab ? 3 : 0)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ThemeApp.Colors.primary)
                
                Capsule()
                    .fill(Color(hex: "#FFE900"))
                    .frame(width: selectedWidth, height: proxy.size.height - 6)
                    .offset(x: selectedOffset)
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: selection)
                
                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Button {
                            selection = index
                        } label: {
                            VStack(spacing: 1) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 17, weight: .bold))
                                Text(item.title)
                                    .font(ThemeApp.Fonts.tabLabel())
                            }
                            .foregroundStyle(
                                index == selection ? ThemeApp.Colors.textPrimary : Color.white
                            )
                            .frame(width: itemWidth, height: proxy.size.height)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
        .frame(height: 60)
    }
}

private struct MainTabItem {
    let title: String
    let icon: String
}

struct UserProfileView: View {
    @EnvironmentObject private var state: AppViewModel
    @State private var showsAllKeywords = false
    
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
                Circle()
                    .fill(ThemeApp.Colors.primary.opacity(0.24))
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
            
            Divider()
                .overlay(ThemeApp.Colors.border.opacity(0.7))
            
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
                Text("Learned Words")
                    .font(ThemeApp.Fonts.ctaButton(size: 21))
                    .foregroundStyle(ThemeApp.Colors.textPrimary)
                
                Spacer()
                
                if learnedKeywords.count > initialKeywordLimit {
                    Button(showsAllKeywords ? "Show less" : "See all") {
                        showsAllKeywords.toggle()
                    }
                    .font(ThemeApp.Fonts.ctaButton(size: 14))
                    .foregroundStyle(ThemeApp.Colors.primary)
                    .buttonStyle(.plain)
                }
            }
            
            if displayedKeywords.isEmpty {
                Text("Complete a situation to add your first learned words.")
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
                    ForEach(displayedKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(ThemeApp.Fonts.body2Text(size: 16))
                            .foregroundStyle(ThemeApp.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 62)
                            .padding(.horizontal, 8)
                            .background(
                                ThemeApp.Colors.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 24)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(ThemeApp.Colors.border, lineWidth: 1.5)
                            )
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
    
    private var learnedKeywords: [String] {
        let words = state.situations
            .filter { state.progress(for: $0) == .completed }
            .flatMap(\.goals)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(words)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    private var displayedKeywords: [String] {
        showsAllKeywords ? learnedKeywords : Array(learnedKeywords.prefix(initialKeywordLimit))
    }
}

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
                    ProgressView()
                        .tint(ThemeApp.Colors.primary)
                    Spacer()
                }
            }
            
            if let situation = viewModel.goalSituation {
                GoalPreviewOverlay(
                    situation: situation,
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
        else {
            return
        }
        
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
            select: select)
    }
}

private struct MainTabHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ThemeApp.Colors.border)
                .frame(width: 44, height: 44)
            
            Text(title)
                .font(ThemeApp.Fonts.gameTitle(size: 24))
                .foregroundStyle(ThemeApp.Colors.textPrimary)
            
            Spacer()
            
            ZStack {
                Circle().fill(Color(hex: "#F48B8A"))
                Circle().fill(ThemeApp.Colors.border).frame(width: 22, height: 22)
            }
            .frame(width: 44, height: 44)
            .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
    }
}

private struct ChapterMapRoad: View {
    @EnvironmentObject private var state: AppViewModel
    let situations: [Situation]
    let select: (Situation) -> Void
    
    private let offsets: [CGFloat] = [0, 74, 34, -68, 4, 68, 28, -44, 44, -58]
    
    var body: some View {
        let currentSituationID = situations.first(where: { state.progress(for: $0) == .available })?.id
        
        VStack(spacing: 0) {
            ForEach(Array(situations.enumerated()), id: \.element.id) { index, situation in
                MapRoadNode(
                    situation: situation,
                    progress: state.progress(for: situation),
                    showsStartBadge: situation.id == currentSituationID,
                    horizontalOffset: offsets[index % offsets.count],
                    select: select
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MapRoadNode: View {
    let situation: Situation
    let progress: SituationProgress
    let showsStartBadge: Bool
    let horizontalOffset: CGFloat
    let select: (Situation) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            if showsStartBadge {
                StartCallout()
            }
            
            Button {
                guard progress != .locked else { return }
                select(situation)
            } label: {
                MapNodeMarker(progress: progress)
            }
            .buttonStyle(.plain)
            .disabled(progress == .locked)
        }
        .frame(maxWidth: .infinity)
        .frame(height: showsStartBadge ? 130 : 108)
        .offset(x: horizontalOffset)
    }
}

private struct StartCallout: View {
    var body: some View {
        Image("start_badge")
            .resizable()
            .scaledToFit()
            .frame(width: 82, height: 55)
    }
}

private struct MapNodeMarker: View {
    let progress: SituationProgress
    
    var body: some View {
        ZStack {
            if progress == .locked {
                // Cover phần mặt của lock icon — circle to hơn và đẩy lên cao hơn
                Circle()
                    .fill(ThemeApp.Colors.canvas)
                    .frame(width: 56, height: 56)
                    .offset(y: -8)  // đẩy lên để che đúng phần mặt, không che phần đế 3D
            }
            
            Image(progress == .locked ? "situation_lock" : "situation_unlock")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 65)
            
            if progress != .locked {
                Image(systemName: "star.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 70, height: 65)
    }
}

private struct GoalPreviewOverlay: View {
    let situation: Situation
    let start: () -> Void
    
    var body: some View {
        VStack {
            VStack(spacing: 6) {
                Text("Goal")
                    .font(ThemeApp.Fonts.gameTitle(size: 30))
                    .foregroundStyle(Color(hex: "#2D7740"))
                
                Text("“\(situation.title)”")
                    .font(ThemeApp.Fonts.bodyText(size: 19))
                    .foregroundStyle(ThemeApp.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: start) {
                    Text("Ready to play")
                        .font(ThemeApp.Fonts.ctaButton(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(ThemeApp.Colors.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .frame(height: 169)
            .background(ThemeApp.Colors.primaryLight, in: RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32).stroke(ThemeApp.Colors.border, lineWidth: 1.5)
            )
            .padding(.horizontal, 42)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MapChapterNavigator: View {
    let chapter: AdventureChapter?
    let index: Int
    let count: Int
    let previous: () -> Void
    let next: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            navigationButton(icon: "chevron.left", enabled: index > 0, action: previous)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("CHAPTER \(index + 1)/\(count)")
                    .font(ThemeApp.Fonts.ctaButton(size: 14))
                Text(chapter?.title ?? "Building your path")
                    .font(ThemeApp.Fonts.bodyText(size: 17))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .frame(height: 62)
            .background(Color(hex: "#75BF20"), in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24).stroke(ThemeApp.Colors.border, lineWidth: 1.5)
            )
            
            navigationButton(icon: "chevron.right", enabled: index < count - 1, action: next)
        }
    }
    
    private func navigationButton(icon: String, enabled: Bool, action: @escaping () -> Void)
    -> some View
    {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeApp.Colors.textPrimary)
                .frame(width: 42, height: 42)
                .background(Color(hex: "#F48B8A"), in: Circle())
                .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
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
                VStack(spacing: 0) {
                    missionHeader
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 26) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(situation.title)
                                    .font(ThemeApp.Fonts.gameTitle(size: 30))
                                    .foregroundStyle(ThemeApp.Colors.textPrimary)
                                Text(situation.subtitle)
                                    .font(ThemeApp.Fonts.bodyText(size: 17))
                                    .foregroundStyle(ThemeApp.Colors.textSecondary)
                            }
                            
                            aiGuideCard
                            keywordCard
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 18)
                    }
                    
                    MissionPrimaryButton(
                        title: missionButtonTitle,
                        icon: missionButtonIcon,
                        isLoading: isMissionButtonLoading
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
                    .allowsHitTesting(!isMissionButtonLoading)
                    .padding(.horizontal, 30)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                }
            }
            .task {
                narrativeViewModel.configure(
                    userName: state.learnerName,
                    level: state.level,
                    situation: situation,
                    useCachedGuidance: true)
                async let guidance = narrativeViewModel.requestGuidance(
                    preferCached: true)
                async let scene = sceneViewModel.prepare(for: situation, character: existingCharacter)
                _ = await (guidance, scene)
            }
            .navigationDestination(isPresented: $showsCharacterSetup) {
                CharacterSetupNameView(situation: situation, onHome: { dismiss() })
            }
        }
        .presentationDetents([.height(max(560, UIScreen.main.bounds.height - 210))])
    }
    
    private var missionHeader: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeApp.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Color(hex: "#F48B8A"), in: Circle())
                    .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var aiGuideCard: some View {
        MissionPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label("Your AI Guide", systemImage: "sparkles")
                    .font(ThemeApp.Fonts.ctaButton(size: 18))
                    .foregroundStyle(ThemeApp.Colors.primary)
                
                if narrativeViewModel.isLoading {
                    HStack(spacing: 9) {
                        ProgressView().tint(ThemeApp.Colors.primary)
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
                        .font(ThemeApp.Fonts.bodyText(size: 16))
                        .foregroundStyle(ThemeApp.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var keywordCard: some View {
        MissionPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("Mission Keywords", systemImage: "checkmark.seal.fill")
                    .font(ThemeApp.Fonts.ctaButton(size: 18))
                    .foregroundStyle(ThemeApp.Colors.textPrimary)
                
                if narrativeViewModel.isLoading {
                    KeywordLoadingGrid()
                } else if let errorMessage = narrativeViewModel.errorMessage {
                    Label("Keywords will appear after retrying.", systemImage: "arrow.clockwise")
                        .font(ThemeApp.Fonts.bodyText(size: 13))
                        .foregroundStyle(ThemeApp.Colors.textSecondary)
                        .accessibilityLabel(errorMessage)
                } else {
                    MissionKeywordPills(tags: narrativeViewModel.context?.targetKeywords ?? [])
                }
                
                Divider().overlay(ThemeApp.Colors.border)
                
                Label(
                    "+\(situation.reward) XP · Unlock \(situation.unlock)",
                    systemImage: "gift.fill"
                )
                .font(ThemeApp.Fonts.ctaButton(size: 15))
                .foregroundStyle(ThemeApp.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var missionButtonTitle: String {
        if existingCharacter == nil { return "Meet your character" }
        return sceneViewModel.isPreparing ? "Preparing your scene…" : "Start speaking"
    }
    
    private var missionButtonIcon: String {
        if existingCharacter == nil { return "arrow.right" }
        return sceneViewModel.isPreparing ? "hourglass" : "mic.fill"
    }
    
    private var isMissionButtonLoading: Bool {
        narrativeViewModel.isLoading || (existingCharacter != nil && sceneViewModel.isPreparing)
    }
}

private struct MissionPanel<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(26)
            .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(ThemeApp.Colors.border, lineWidth: 1.5))
    }
}

private struct MissionPrimaryButton: View {
    let title: String
    let icon: String
    var isLoading = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                Image(systemName: icon)
            }
            .font(ThemeApp.Fonts.ctaButton(size: 18))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(ThemeApp.Colors.primary.opacity(isLoading ? 0.48 : 1), in: Capsule())
            .overlay(
                Capsule().stroke(ThemeApp.Colors.border.opacity(isLoading ? 0.48 : 1), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MissionKeywordPills: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(ThemeApp.Fonts.bodyText(size: 14))
                        .foregroundStyle(ThemeApp.Colors.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
                }
            }
        }
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
