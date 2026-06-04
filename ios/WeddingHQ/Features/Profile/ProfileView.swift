import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var settings: ProfileSettings?
    @State private var weddings: [Wedding] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let profileService = ProfileService()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        Section("You") {
                            if let profile = appState.profile {
                                LabeledContent("Name", value: profile.displayName ?? "—")
                                if let bio = profile.bio, !bio.isEmpty {
                                    Text(bio).font(.subheadline)
                                }
                            }
                            if let onboarding = appState.onboarding, let role = onboarding.roleIntent {
                                LabeledContent("Role", value: role.capitalized)
                            }
                        }

                        Section("Wedding") {
                            if weddings.isEmpty {
                                Text("No wedding yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(weddings) { wedding in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(wedding.title).font(.headline)
                                        if let venue = wedding.venueName {
                                            Text(venue).font(.subheadline)
                                        }
                                        Text("Invite: \(wedding.inviteCode)")
                                            .font(.caption.monospaced())
                                    }
                                }
                            }
                        }

                        Section("Settings") {
                            if let settings {
                                Toggle("Animations", isOn: .init(
                                    get: { settings.animationsEnabled },
                                    set: { updateSettings(settings) { $0.animationsEnabled = $1 } }
                                ))
                                Toggle("Push notifications", isOn: .init(
                                    get: { settings.pushNotificationsEnabled },
                                    set: { updateSettings(settings) { $0.pushNotificationsEnabled = $1 } }
                                ))
                                Toggle("Widgets", isOn: .init(
                                    get: { settings.widgetsEnabled },
                                    set: { updateSettings(settings) { $0.widgetsEnabled = $1 } }
                                ))
                            }
                        }

                        Section {
                            NavigationLink {
                                MenuView()
                            } label: {
                                Label("Menu", systemImage: "line.3.horizontal")
                            }
                        }

                        Section {
                            Button("Sign out", role: .destructive) {
                                Task { await appState.signedOut() }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func updateSettings(
        _ base: ProfileSettings,
        _ mutate: (inout ProfileSettings) -> Void
    ) {
        var copy = base
        mutate(&copy)
        Task { await saveSettings(copy) }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            settings = try await profileService.fetchSettings()
            weddings = try await profileService.fetchWeddings()
            appState.profile = try await profileService.fetchProfile()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveSettings(_ value: ProfileSettings) async {
        do {
            settings = try await profileService.updateSettings(value)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
