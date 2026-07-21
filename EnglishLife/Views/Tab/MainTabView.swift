import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var state: AppViewModel
    
    var body: some View {
        NavigationStack {
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
            .toolbar(.hidden, for: .navigationBar)
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
