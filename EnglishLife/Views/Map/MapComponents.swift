import SwiftUI
import UIKit

struct MainTabHeader: View {
  let title: String

  var body: some View {
    HStack(spacing: 12) {
      Image("logo_header")
        .resizable()
        .scaledToFit()
        .frame(width: 50, height: 40)

      Text(title)
        .font(ThemeApp.Fonts.gameTitle(size: 24))
        .foregroundStyle(ThemeApp.Colors.textPrimary)

      Spacer()
    }
  }
}

struct ChapterMapRoad: View {
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

struct GoalPreviewOverlay: View {
  let situation: Situation
  let cancel: () -> Void
  let start: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 14) {
        Text("Goal")
          .font(ThemeApp.Fonts.gameTitle(size: 36))
          .foregroundStyle(Color(hex: "#2D7740"))

        Text("“\(situation.title)”")
          .font(ThemeApp.Fonts.bodyText(size: 22))
          .foregroundStyle(ThemeApp.Colors.textSecondary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)

        Button(action: start) {
          Text("Ready to Play")
            .font(ThemeApp.Fonts.ctaButton(size: 17))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 41)
            .background(ThemeApp.Colors.primary, in: Capsule())
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 32)
      .frame(maxWidth: .infinity)
      .frame(height: 170)
      .background(ThemeApp.Colors.surface, in: RoundedRectangle(cornerRadius: 32))
      .overlay(
        RoundedRectangle(cornerRadius: 32).stroke(ThemeApp.Colors.border, lineWidth: 1.5)
      )

      Button(action: cancel) {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(ThemeApp.Colors.textPrimary)
          .frame(width: 30, height: 30)
          .background(Color(hex: "#F48B8A"), in: Circle())
          .overlay(Circle().stroke(ThemeApp.Colors.border, lineWidth: 1.5))
      }
      .buttonStyle(.plain)
      .offset(x: 8, y: -8)
    }
    .padding(.horizontal, 46)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct MapChapterNavigator: View {
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
