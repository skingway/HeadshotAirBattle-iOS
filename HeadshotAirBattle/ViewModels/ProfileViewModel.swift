import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var showEditNickname = false
    @Published var newNickname = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isUpdating = false

    func updateNickname(appViewModel: AppViewModel) async {
        guard !newNickname.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Nickname cannot be empty"
            return
        }

        isUpdating = true
        errorMessage = nil
        successMessage = nil

        defer { isUpdating = false }

        do {
            try await appViewModel.updateNickname(newNickname)
            successMessage = "Nickname updated successfully!"

            // 清除成功消息
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self.successMessage = nil
                }
            }

            showEditNickname = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
