import SwiftUI

struct SettingsView: View {
    let keychain: KeychainService

    @State private var showTokenSetup = false
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                if keychain.hasToken {
                    LabeledContent("Token") {
                        Label("Configured", systemImage: "checkmark.circle.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.success)
                    }
                    Button("Replace Token\u{2026}", role: .destructive) {
                        showTokenSetup = true
                    }
                } else {
                    Button("Set Bearer Token\u{2026}") {
                        showTokenSetup = true
                    }
                }
            } header: {
                Text("Gateway Auth")
            } footer: {
                Text("Token is stored in the device Keychain and is never written to UserDefaults or iCloud.")
                    .font(AppTypography.micro)
            }

            Section("Gateway") {
                LabeledContent("URL", value: "api.appwebdev.co.uk")
                LabeledContent("TLS", value: "Let\u{2019}s Encrypt (auto-renewal)")
            }

            Section {
                Button(action: runConnectionTest) {
                    HStack {
                        Label("Test Connection", systemImage: "network")
                        Spacer()
                        if isTesting { ProgressView().scaleEffect(0.8) }
                    }
                }
                .disabled(isTesting || !keychain.hasToken)

                if let result = testResult {
                    Label(result.message, systemImage: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(AppTypography.captionMono)
                        .foregroundStyle(result.isSuccess ? AppColors.success : AppColors.danger)
                        .textSelection(.enabled)
                }
            } header: {
                Text("Diagnostics")
            } footer: {
                Text("Fires a live system-stats request and shows the raw server response.")
                    .font(AppTypography.micro)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTokenSetup) {
            TokenSetupView(keychain: keychain) {
                showTokenSetup = false
            }
        }
    }

    private func runConnectionTest() {
        isTesting = true
        testResult = nil
        let client = GatewayClient(keychain: keychain)
        Task {
            do {
                let stats: SystemStats = try await client.stats("stats/system")
                testResult = TestResult(
                    isSuccess: true,
                    message: "OK — CPU \(String(format: "%.1f", stats.cpuPercent))%  RAM \(stats.ramPercent)%"
                )
            } catch {
                testResult = TestResult(isSuccess: false, message: error.localizedDescription)
            }
            isTesting = false
        }
    }
}

private struct TestResult {
    let isSuccess: Bool
    let message: String
}
