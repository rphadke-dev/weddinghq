import AuthenticationServices
import Supabase
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sign in or create an account")
                        .font(.title2.bold())

                    Picker("Method", selection: $viewModel.mode) {
                        Text("Email").tag(AuthViewModel.Mode.email)
                        Text("Phone").tag(AuthViewModel.Mode.phone)
                    }
                    .pickerStyle(.segmented)

                    if viewModel.mode == .email {
                        emailFields
                    } else {
                        phoneFields
                    }

                    if let message = viewModel.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(message.contains("Check") ? .green : .red)
                    }

                    Button(viewModel.isSignUp ? "Create account" : "Sign in") {
                        Task { await viewModel.submit(appState: appState) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .disabled(viewModel.isBusy)

                    Toggle("New account", isOn: $viewModel.isSignUp)

                    Divider()

                    SignInWithAppleButton(.signIn) { request in
                        viewModel.configureAppleRequest(request)
                    } onCompletion: { result in
                        Task { await viewModel.handleApple(result, appState: appState) }
                    }
                    .frame(height: 48)

                    Button("Continue with Google") {
                        Task { await viewModel.signInWithGoogle() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { appState.route = .welcome }
                }
            }
            .onOpenURL { url in
                Task { await viewModel.handleOAuthCallback(url, appState: appState) }
            }
        }
    }

    private var emailFields: some View {
        Group {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            SecureField("Password", text: $viewModel.password)
        }
    }

    private var phoneFields: some View {
        Group {
            TextField("Phone (+1…)", text: $viewModel.phone)
                .keyboardType(.phonePad)
            if viewModel.otpSent {
                TextField("SMS code", text: $viewModel.otpCode)
                    .keyboardType(.numberPad)
            }
        }
    }
}

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode { case email, phone }

    @Published var mode: Mode = .email
    @Published var email = ""
    @Published var password = ""
    @Published var phone = ""
    @Published var otpCode = ""
    @Published var otpSent = false
    @Published var isSignUp = false
    @Published var isBusy = false
    @Published var message: String?

    private let auth = AuthService()
    private var appleNonce = ""

    func submit(appState: AppState) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let session: Session?
            switch mode {
            case .email:
                if isSignUp {
                    session = try await auth.signUp(email: email, password: password)
                    if session == nil {
                        message = "Check your email to confirm, then sign in."
                        return
                    }
                } else {
                    session = try await auth.signIn(email: email, password: password)
                }
            case .phone:
                if !otpSent {
                    try await auth.signInWithPhone(phone: phone)
                    otpSent = true
                    message = "Code sent. Enter it below."
                    return
                }
                session = try await auth.verifyPhoneOTP(phone: phone, token: otpCode)
            }
            if let session {
                await appState.signedIn(session: session)
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = UUID().uuidString
        appleNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = nonce
    }

    func handleApple(_ result: Result<ASAuthorization, Error>, appState: AppState) async {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            message = "Apple sign-in failed"
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let session = try await auth.signInWithApple(idToken: idToken, nonce: appleNonce)
            await appState.signedIn(session: session)
        } catch {
            message = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        do {
            let url = try await auth.signInWithGoogle()
            await UIApplication.shared.open(url)
        } catch {
            message = error.localizedDescription
        }
    }

    func handleOAuthCallback(_ url: URL, appState: AppState) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let session = try await auth.session(from: url)
            await appState.signedIn(session: session)
        } catch {
            message = error.localizedDescription
        }
    }
}
