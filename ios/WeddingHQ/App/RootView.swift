import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView("Loading…")
            } else {
                switch appState.route {
                case .welcome:
                    WelcomeView()
                case .auth:
                    AuthView()
                case .onboarding:
                    OnboardingFlowView()
                case .main:
                    MainTabView()
                }
            }
        }
        .animation(.easeInOut, value: appState.route)
    }
}
