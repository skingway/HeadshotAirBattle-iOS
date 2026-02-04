import SwiftUI

struct SettingsView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Audio
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Audio")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        Toggle("Sound Effects", isOn: $viewModel.audioEnabled)
                            .foregroundColor(.white)
                            .tint(.cyan)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("BGM Volume: \(Int(viewModel.bgmVolume * 100))%")
                                .foregroundColor(.gray)
                            Slider(value: $viewModel.bgmVolume, in: 0...1)
                                .tint(.cyan)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("SFX Volume: \(Int(viewModel.sfxVolume * 100))%")
                                .foregroundColor(.gray)
                            Slider(value: $viewModel.sfxVolume, in: 0...1)
                                .tint(.cyan)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // About
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.cyan)

                        InfoRow(label: "Version", value: "1.0.0")
                        InfoRow(label: "Platform", value: "iOS")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
