import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @State private var stepIndex = 0
    @State private var roleIntent: RoleIntent = .guest
    @State private var displayName = ""
    @State private var bio = ""
    @State private var weddingTitle = ""
    @State private var venueName = ""
    @State private var inviteCode = ""
    @State private var createdWedding: Wedding?
    @State private var requiresSubscription = false
    @State private var isBusy = false
    @State private var errorMessage: String?

    private let onboardingService = OnboardingService()
    private let weddingService = WeddingService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ProgressView(value: Double(stepIndex + 1), total: Double(steps.count))
                    .padding(.horizontal)

                TabView(selection: $stepIndex) {
                    roleStep.tag(0)
                    profileStep.tag(1)
                    weddingStep.tag(2)
                    if requiresSubscription {
                        subscriptionStep.tag(3)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: stepIndex)

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("Onboarding")
            .task {
                await markWelcomeSeenIfNeeded()
                if let intent = appState.onboarding?.roleIntent,
                   let role = RoleIntent(rawValue: intent) {
                    roleIntent = role
                }
            }
        }
    }

    private var steps: [String] {
        requiresSubscription
            ? ["role", "profile", "wedding", "paywall"]
            : ["role", "profile", "wedding"]
    }

    private var roleStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you joining?").font(.title2.bold())
            ForEach(RoleIntent.allCases) { role in
                Button {
                    roleIntent = role
                } label: {
                    HStack {
                        Text(role.title)
                        Spacer()
                        if roleIntent == role {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(roleIntent == role ? Color.pink.opacity(0.15) : Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            primaryButton("Continue") { await completeRole() }
        }
        .padding()
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your profile").font(.title2.bold())
            TextField("Display name", text: $displayName)
                .textFieldStyle(.roundedBorder)
            TextField("Bio (optional)", text: $bio, axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
            Spacer()
            primaryButton("Continue") { await completeProfile() }
        }
        .padding()
    }

    private var weddingStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(roleIntent == .couple ? "Create your wedding" : "Join a wedding")
                .font(.title2.bold())
            if roleIntent == .couple {
                TextField("Wedding title", text: $weddingTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("Venue (optional)", text: $venueName)
                    .textFieldStyle(.roundedBorder)
                primaryButton("Create wedding") { await createWedding() }
            } else {
                TextField("6-character invite code", text: $inviteCode)
                    .textInputAutocapitalization(.characters)
                    .textFieldStyle(.roundedBorder)
                primaryButton("Join wedding") { await joinWedding() }
            }
            Spacer()
        }
        .padding()
    }

    private var subscriptionStep: some View {
        VStack(spacing: 16) {
            Text("WeddingHQ for couples").font(.title2.bold())
            Text("One-time purchase ($149) unlocks your wedding hub. Payments coming soon — use dev unlock below.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let wedding = createdWedding {
                Text("Invite code: \(wedding.inviteCode)")
                    .font(.headline.monospaced())
            }
            primaryButton("Unlock (dev stub)") { await grantSubscription() }
            Button("Skip for now") {
                Task { await finishOnboarding() }
            }
        }
        .padding()
    }

    private func primaryButton(_ title: String, action: @escaping () async -> Void) -> some View {
        Button(title) { Task { await action() } }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            .disabled(isBusy)
    }

    private func markWelcomeSeenIfNeeded() async {
        guard !(appState.onboarding?.completedSteps.contains(OnboardingStep.welcomeSeen.rawValue) ?? false) else {
            return
        }
        do {
            let updated = try await onboardingService.completeStep(.welcomeSeen)
            appState.onboarding = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func completeRole() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let updated = try await onboardingService.completeStep(
                .roleSelected,
                roleIntent: roleIntent
            )
            appState.onboarding = updated
            stepIndex = 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func completeProfile() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let updated = try await onboardingService.completeStep(
                .profileBasics,
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio
            )
            appState.onboarding = updated
            appState.profile = try? await ProfileService().fetchProfile()
            stepIndex = 2
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createWedding() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let response = try await weddingService.createWedding(
                title: weddingTitle,
                weddingDate: nil,
                venueName: venueName.isEmpty ? nil : venueName
            )
            createdWedding = response.wedding
            requiresSubscription = response.requiresSubscription ?? false
            if requiresSubscription {
                stepIndex = 3
            } else {
                await finishOnboarding()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func joinWedding() async {
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await weddingService.joinWedding(code: inviteCode, roleIntent: roleIntent)
            await finishOnboarding()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func grantSubscription() async {
        guard let id = createdWedding?.id else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            _ = try await weddingService.grantStubSubscription(weddingId: id)
            await finishOnboarding()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finishOnboarding() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let updated = try await onboardingService.completeStep(.completed)
            appState.onboarding = updated
            appState.route = .main
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
