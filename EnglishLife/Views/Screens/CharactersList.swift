import SwiftUI

struct CharactersListView: View {
    @EnvironmentObject private var state: AppViewModel
    var body: some View {
        NavigationStack {
            ZStack {
                AdventureBackground()
                if state.characters.isEmpty { emptyState } else { list }
            }.navigationBarHidden(true)
        }
    }
    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.2.fill").font(.system(size: 64, weight: .black)).foregroundStyle(
                ThemeApp.Colors.accentPink)
            Text("Your character book is empty").font(ThemeApp.Fonts.gameTitle(size: 25)).foregroundStyle(
                .white
            ).multilineTextAlignment(.center)
            Text("Complete a map situation to create your first conversation partner.").font(
                ThemeApp.Fonts.bodyText()
            ).foregroundStyle(.white.opacity(0.72)).multilineTextAlignment(.center).padding(
                .horizontal, 38)
            GameButton(title: "Explore the map", icon: "map.fill") { state.selectedTab = 0 }.padding(
                .horizontal, 35)
        }
    }
    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle("Your characters", subtitle: "Talk freely with friends you have met.")
                ForEach(state.characters) { character in
                    NavigationLink(
                        destination: ChatView(
                            character: character, situation: nil, onHome: { state.selectedTab = 1 })
                    ) {
                        GlassCard {
                            HStack(spacing: 14) {
                                AvatarView(character: character, size: 60)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(character.name).font(ThemeApp.Fonts.ctaButton()).foregroundStyle(.white)
                                    Text(character.situationTitle).font(ThemeApp.Fonts.bodyText(size: 13))
                                        .foregroundStyle(.white.opacity(0.68))
                                    Text("Free chat available").font(ThemeApp.Fonts.bodyText(size: 12))
                                        .foregroundStyle(ThemeApp.Colors.roadmapLine)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.65))
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }
    }
}
