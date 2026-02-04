import SwiftUI

/// Scrollable game log showing attack history
struct GameLogView: View {
    let logs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Battle Log")
                .font(.caption.bold())
                .foregroundColor(.gray)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(logs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(logColor(log))
                                .id(index)
                        }
                    }
                }
                .frame(height: 60)
                .onChange(of: logs.count) { _, _ in
                    if let last = logs.indices.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func logColor(_ log: String) -> Color {
        if log.contains("KILL") { return .red }
        if log.contains("HIT") { return .orange }
        if log.contains("MISS") { return .gray }
        return .white
    }
}
