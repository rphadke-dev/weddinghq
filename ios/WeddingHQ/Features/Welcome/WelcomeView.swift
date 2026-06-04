import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.15), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            FallingHeartsView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.pink)
                Text("WeddingHQ")
                    .font(.largeTitle.bold())
                Text("Your wedding day, coordinated in real time.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
                Spacer()
                Button("Get started") {
                    appState.finishWelcome()
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .padding(.bottom, 40)
            }
        }
    }
}
