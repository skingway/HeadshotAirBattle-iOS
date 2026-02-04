import SwiftUI

/// 3-2-1 countdown animation before battle starts
struct CountdownView: View {
    let onComplete: () -> Void

    @State private var count = 3
    @State private var scale: CGFloat = 2.0
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text(count > 0 ? "\(count)" : "GO!")
                .font(.system(size: 80, weight: .black))
                .foregroundColor(count > 0 ? .white : .green)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        animateNumber()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            count = 2
            animateNumber()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            count = 1
            animateNumber()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            count = 0
            animateNumber()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            onComplete()
        }
    }

    private func animateNumber() {
        scale = 2.0
        opacity = 1.0
        withAnimation(.easeOut(duration: 0.5)) {
            scale = 1.0
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.6)) {
            opacity = 0.3
        }
    }
}
