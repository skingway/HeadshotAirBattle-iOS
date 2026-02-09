import SwiftUI

struct ParticleData: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let angle: Double
    let speed: CGFloat
}

struct BombDropAnimationView: View {
    @Binding var isPlaying: Bool
    var targetPosition: CGPoint
    var resultType: String // "hit", "kill", "miss"
    var onComplete: () -> Void

    @State private var bombY: CGFloat = -100
    @State private var bombOpacity: Double = 1.0
    @State private var bombScale: CGFloat = 1.0
    @State private var bombRotation: Double = 0
    @State private var shadowScale: CGFloat = 0.3
    @State private var showExplosion: Bool = false
    @State private var flashOpacity: Double = 0
    @State private var particles: [ParticleData] = []
    @State private var headshotText: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var particleProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Screen flash
            if flashOpacity > 0 {
                Rectangle()
                    .fill(flashColor.opacity(flashOpacity))
                    .ignoresSafeArea()
            }

            // Bomb shadow on target
            if !showExplosion {
                Ellipse()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 20 * shadowScale, height: 8 * shadowScale)
                    .position(x: targetPosition.x, y: targetPosition.y + 10)
            }

            // Bomb
            if !showExplosion {
                BombShape()
                    .frame(width: 20, height: 30)
                    .rotationEffect(.degrees(bombRotation))
                    .scaleEffect(bombScale)
                    .opacity(bombOpacity)
                    .position(x: targetPosition.x, y: bombY)
            }

            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size * (1.0 - particleProgress * 0.5),
                           height: particle.size * (1.0 - particleProgress * 0.5))
                    .position(
                        x: particle.x + cos(particle.angle) * particle.speed * particleProgress * 80,
                        y: particle.y + sin(particle.angle) * particle.speed * particleProgress * 80 - particleProgress * 20
                    )
                    .opacity(1.0 - Double(particleProgress) * 0.8)
            }

            // HEADSHOT text for kill
            if headshotText {
                Text("HEADSHOT!")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.red)
                    .shadow(color: .orange, radius: 8)
                    .shadow(color: .red, radius: 4)
                    .scaleEffect(headshotText ? 1.2 : 0.1)
                    .opacity(headshotText ? 1.0 : 0.0)
                    .position(x: targetPosition.x, y: targetPosition.y - 50)
            }
        }
        .offset(x: shakeOffset)
        .allowsHitTesting(false)
        .onAppear {
            startAnimation()
        }
    }

    private var flashColor: Color {
        switch resultType {
        case "kill": return .red
        case "hit": return .orange
        default: return .blue
        }
    }

    private func startAnimation() {
        bombY = -100
        bombOpacity = 1.0
        bombScale = 1.0
        bombRotation = -5
        shadowScale = 0.3
        showExplosion = false
        flashOpacity = 0
        particles = []
        headshotText = false
        shakeOffset = 0
        particleProgress = 0

        // Phase 1: Bomb drops (0 - 0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            bombY = targetPosition.y
            shadowScale = 1.0
        }

        // Wobble rotation during drop
        withAnimation(.easeInOut(duration: 0.15).repeatCount(4, autoreverses: true)) {
            bombRotation = 5
        }

        // Phase 2: Impact (at 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showExplosion = true
            bombOpacity = 0

            // Generate particles
            generateParticles()

            // Flash
            withAnimation(.easeOut(duration: 0.1)) {
                flashOpacity = resultType == "kill" ? 0.5 : 0.3
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                flashOpacity = 0
            }

            // Double flash for kill
            if resultType == "kill" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        flashOpacity = 0.3
                    }
                    withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                        flashOpacity = 0
                    }
                }
            }

            // Shake
            applyShake()

            // Expand particles
            withAnimation(.easeOut(duration: 0.6)) {
                particleProgress = 1.0
            }

            // HEADSHOT text for kill
            if resultType == "kill" {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    headshotText = true
                }
            }
        }

        // Phase 3: Complete (at 1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isPlaying = false
            onComplete()
        }
    }

    private func generateParticles() {
        let count: Int
        let colors: [Color]

        switch resultType {
        case "kill":
            count = 25
            colors = [.red, .orange, .yellow, .white]
        case "hit":
            count = 12
            colors = [.orange, .yellow, .red]
        default:
            count = 10
            colors = [.blue, .cyan, .white]
        }

        particles = (0..<count).map { _ in
            ParticleData(
                x: targetPosition.x + CGFloat.random(in: -5...5),
                y: targetPosition.y + CGFloat.random(in: -5...5),
                color: colors.randomElement() ?? .orange,
                size: CGFloat.random(in: 3...8),
                angle: Double.random(in: 0...(2 * .pi)),
                speed: CGFloat.random(in: 0.5...1.5)
            )
        }
    }

    private func applyShake() {
        let intensity: CGFloat
        switch resultType {
        case "kill": intensity = 12
        case "hit": intensity = 6
        default: intensity = 3
        }

        let shakeSteps = 6
        for i in 0..<shakeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = (i % 2 == 0 ? intensity : -intensity) * (1.0 - CGFloat(i) / CGFloat(shakeSteps))
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(shakeSteps) * 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 0
            }
        }
    }
}

struct BombShape: View {
    var body: some View {
        ZStack {
            // Body
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.9))
                .frame(width: 12, height: 20)

            // Nose
            Ellipse()
                .fill(Color.red)
                .frame(width: 10, height: 6)
                .offset(y: 11)

            // Fins
            Triangle()
                .fill(Color.gray.opacity(0.7))
                .frame(width: 18, height: 8)
                .offset(y: -12)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
