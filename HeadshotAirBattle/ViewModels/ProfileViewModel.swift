import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var showEditNickname = false
    @Published var newNickname = ""
}
