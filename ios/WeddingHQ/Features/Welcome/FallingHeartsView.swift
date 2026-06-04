import SwiftUI

struct HeartParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var scale: CGFloat
}

struct FallingHeartsView: View {
    @State private var particles: [HeartParticle] = []
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14 * particle.scale))
                        .foregroundStyle(.pink.opacity(0.75))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear { seed(in: geo.size) }
            .onReceive(timer) { _ in
                tick(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func seed(in size: CGSize) {
        particles = (0..<24).map { _ in
            HeartParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                speed: CGFloat.random(in: 1.2...3.5),
                scale: CGFloat.random(in: 0.8...1.4)
            )
        }
    }

    private func tick(in size: CGSize) {
        particles = particles.map { p in
            var next = p
            next.y += next.speed
            if next.y > size.height + 20 {
                next.y = -20
                next.x = CGFloat.random(in: 0...size.width)
            }
            return next
        }
    }
}
