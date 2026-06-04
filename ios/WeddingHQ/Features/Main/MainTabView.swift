import SwiftUI

struct MainTabView: View {
    @State private var unreadAlerts = 0
    @State private var unreadChat = 0

    var body: some View {
        TabView {
            TimelinePlaceholderView()
                .tabItem {
                    Label("Timeline", systemImage: "clock")
                }

            NavigationStack {
                Text("Chat — Phase 2")
                    .navigationTitle("Chat")
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .badge(unreadChat)

            NavigationStack {
                Text("Alerts — Phase 2")
                    .navigationTitle("Alerts")
            }
            .tabItem {
                Label("Alerts", systemImage: "bell")
            }
            .badge(unreadAlerts)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(.pink)
    }
}

struct TimelinePlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.pink)
                Text("Timeline coming in Phase 2")
                    .font(.headline)
                Text("Live countdowns and day-of events will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Timeline")
        }
    }
}
