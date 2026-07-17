import SwiftUI

@main
struct EnglishLifeApp: App {
  @StateObject private var state = AppViewModel()
  var body: some Scene {
    WindowGroup { AppRouter().environmentObject(state).preferredColorScheme(.dark) }
  }
}

struct AppRouter: View {
  @EnvironmentObject private var state: AppViewModel
  var body: some View {
    Group {
      if state.hasCompletedOnboarding { MainTabView() } else { OnboardingFlow() }
    }
  }
}
