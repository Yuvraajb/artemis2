//
//  ChallengeView.swift
//  artemis2
//
//  Interactive mini-challenges at key mission milestones.
//  Players must make real engineering decisions with visual feedback.
//

import SwiftUI

struct ChallengeView: View {
    let viewModel: MissionViewModel
    let phase: MissionPhase
    @State private var challengeValue: Double = 0.5
    @State private var hasSubmitted: Bool = false
    @State private var result: ChallengeResult? = nil
    @State private var isAnimating: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.1)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                challengeHeader

                Spacer()

                // Challenge content based on phase
                switch phase {
                case .translunarInjection:
                    TLIBurnChallenge(
                        burnValue: $challengeValue,
                        hasSubmitted: hasSubmitted
                    )
                case .lunarFlyby:
                    FlybyChallenge(
                        altitudeValue: $challengeValue,
                        hasSubmitted: hasSubmitted
                    )
                case .reentry:
                    ReentryChallenge(
                        angleValue: $challengeValue,
                        hasSubmitted: hasSubmitted
                    )
                default:
                    Text("No challenge for this phase")
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Result display
                if let result = result {
                    resultDisplay(result)
                        .transition(.scale.combined(with: .opacity))
                }

                // Action buttons
                actionButtons
            }
            .padding(24)
        }
    }

    // MARK: - Components

    private var challengeHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 24))
                .foregroundStyle(phase.color)

            Text("MISSION CHALLENGE")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(3)

            Text(phase.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            if let desc = phase.challengeDescription {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    private func resultDisplay(_ result: ChallengeResult) -> some View {
        VStack(spacing: 8) {
            Image(systemName: result.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(result.passed ? .green : .red)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatCount(3), value: isAnimating)

            Text(result.passed ? "SUCCESS!" : "CORRECTED")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundStyle(result.passed ? .green : .orange)

            Text(result.message)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Text("Score:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text(String(format: "%.0f", result.score))
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.yellow)
                Text("/ 100")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(16)
        .glassCard()
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            if !hasSubmitted {
                Button(action: { skip() }) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Button(action: { submit() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Execute")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(phase.color)
                    )
                }
            } else {
                Button(action: { continueAfterChallenge() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                        Text("Continue Mission")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.3))
                            .overlay(Capsule().stroke(Color.green, lineWidth: 1))
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func submit() {
        let challengeResult = evaluateChallenge()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            result = challengeResult
            hasSubmitted = true
            isAnimating = true
        }
    }

    private func skip() {
        viewModel.skipChallenge()
        dismiss()
    }

    private func continueAfterChallenge() {
        if let result = result {
            viewModel.submitChallengeResult(result)
        }
        dismiss()
    }

    private func evaluateChallenge() -> ChallengeResult {
        switch phase {
        case .translunarInjection:
            // Optimal burn is at 0.5 (center of window)
            let accuracy = 1.0 - abs(challengeValue - 0.5) * 2
            let score = max(0, accuracy * 100)
            let passed = accuracy > 0.6
            return ChallengeResult(
                phase: phase,
                score: score,
                accuracy: accuracy,
                passed: passed,
                message: passed
                    ? "Excellent TLI burn! Delta-V achieved: \(String(format: "%.1f", 3.0 + accuracy * 0.2)) km/s. You're on course for the Moon!"
                    : "TLI burn was off-nominal. Ground control has corrected course, but you used extra fuel."
            )

        case .lunarFlyby:
            // Optimal altitude: 0.5 maps to 100km (ideal), range 80-120km
            let altitude = 60 + challengeValue * 80 // 60-140 km
            let idealDeviation = abs(altitude - 100)
            let accuracy = max(0, 1.0 - idealDeviation / 40)
            let score = max(0, accuracy * 100)
            let passed = idealDeviation < 20
            return ChallengeResult(
                phase: phase,
                score: score,
                accuracy: accuracy,
                passed: passed,
                message: passed
                    ? "Perfect flyby at \(String(format: "%.0f", altitude)) km! Closest approach to the lunar surface captured incredible data."
                    : "Flyby altitude of \(String(format: "%.0f", altitude)) km was outside optimal range. Trajectory has been adjusted."
            )

        case .reentry:
            // Optimal angle: 0.5 maps to -6.5° (ideal), range -5.5 to -7.5
            let angle = -5.0 - challengeValue * 3.0 // -5 to -8
            let idealDeviation = abs(angle - (-6.5))
            let accuracy = max(0, 1.0 - idealDeviation / 1.5)
            let score = max(0, accuracy * 100)
            let passed = idealDeviation < 1.0
            return ChallengeResult(
                phase: phase,
                score: score,
                accuracy: accuracy,
                passed: passed,
                message: passed
                    ? "Reentry angle of \(String(format: "%.1f", angle))° is within tolerance! Skip reentry executed. Max G-force: \(String(format: "%.1f", 2.5 + (1.0 - accuracy) * 2))G"
                    : "Reentry angle of \(String(format: "%.1f", angle))° required correction. The crew experienced higher G-forces."
            )

        default:
            return ChallengeResult(phase: phase, score: 50, accuracy: 0.5, passed: true, message: "Phase completed.")
        }
    }
}

// MARK: - TLI Burn Challenge

struct TLIBurnChallenge: View {
    @Binding var burnValue: Double
    let hasSubmitted: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Visual: Engine burn indicator
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 8)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: burnValue)
                    .stroke(
                        AngularGradient(
                            colors: [.yellow, .orange, .red],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", burnValue * 100))
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.orange)
                    Text("BURN TIMING")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Slider
            VStack(spacing: 4) {
                Text("Adjust burn timing within the TLI window")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))

                ZStack {
                    // Optimal zone indicator
                    GeometryReader { geometry in
                        let optimalStart = geometry.size.width * 0.35
                        let optimalWidth = geometry.size.width * 0.3
                        Rectangle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: optimalWidth, height: 30)
                            .offset(x: optimalStart)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    .frame(width: optimalWidth, height: 30)
                                    .offset(x: optimalStart)
                            )
                    }
                    .frame(height: 30)

                    Slider(value: $burnValue, in: 0...1)
                        .tint(.orange)
                        .disabled(hasSubmitted)
                }

                HStack {
                    Text("Too Early")
                        .font(.system(size: 9))
                        .foregroundStyle(.red.opacity(0.6))
                    Spacer()
                    Text("OPTIMAL")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green.opacity(0.8))
                    Spacer()
                    Text("Too Late")
                        .font(.system(size: 9))
                        .foregroundStyle(.red.opacity(0.6))
                }
            }

            // Delta-V readout
            HStack(spacing: 20) {
                DataReadout(label: "Delta-V", value: String(format: "%.2f km/s", 2.8 + burnValue * 0.4), icon: "arrow.up.right", color: .orange)
                DataReadout(label: "Fuel Used", value: String(format: "%.0f%%", 15 + burnValue * 10), icon: "fuelpump.fill", color: .yellow)
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Flyby Challenge

struct FlybyChallenge: View {
    @Binding var altitudeValue: Double
    let hasSubmitted: Bool

    private var altitude: Double {
        60 + altitudeValue * 80
    }

    private var isInSafeZone: Bool {
        altitude >= 80 && altitude <= 120
    }

    var body: some View {
        VStack(spacing: 16) {
            // Visual: Moon with altitude indicator
            ZStack {
                // Moon surface
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.7), Color(white: 0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // Safe zone ring
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 12)
                    .frame(width: 170, height: 170)

                // Current altitude ring
                let ring = 120 + (altitude - 60) / 80 * 80
                Circle()
                    .stroke(isInSafeZone ? Color.green : Color.red, lineWidth: 2)
                    .frame(width: ring, height: ring)

                // Spacecraft dot
                Circle()
                    .fill(isInSafeZone ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .offset(y: -ring / 2)
            }
            .frame(height: 200)

            // Altitude readout
            HStack {
                Text("Flyby Altitude:")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                Text(String(format: "%.0f km", altitude))
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundStyle(isInSafeZone ? .green : .red)
            }

            // Slider
            VStack(spacing: 4) {
                Slider(value: $altitudeValue, in: 0...1)
                    .tint(isInSafeZone ? .green : .red)
                    .disabled(hasSubmitted)

                HStack {
                    Text("60 km")
                        .font(.system(size: 9))
                        .foregroundStyle(.red.opacity(0.6))
                    Spacer()
                    Text("80-120 km SAFE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green.opacity(0.8))
                    Spacer()
                    Text("140 km")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.6))
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Reentry Challenge

struct ReentryChallenge: View {
    @Binding var angleValue: Double
    let hasSubmitted: Bool

    private var angle: Double {
        -5.0 - angleValue * 3.0
    }

    private var isInTolerance: Bool {
        angle >= -7.5 && angle <= -5.5
    }

    var body: some View {
        VStack(spacing: 16) {
            // Visual: Reentry angle diagram
            ZStack {
                // Earth atmosphere arc
                Path { path in
                    path.addArc(center: CGPoint(x: 150, y: 200),
                               radius: 160,
                               startAngle: .degrees(200),
                               endAngle: .degrees(340),
                               clockwise: false)
                }
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .cyan.opacity(0.3), .orange.opacity(0.5), .red.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 30
                )

                // Safe corridor
                let safeAngleStart = -5.5
                let safeAngleEnd = -7.5
                let _ = safeAngleStart
                let _ = safeAngleEnd

                // Spacecraft entry line
                let entryAngle = angle
                let startX = 280.0
                let startY = 40.0
                let lineLength = 200.0
                let endX = startX + lineLength * cos(entryAngle * .pi / 180 + .pi)
                let endY = startY - lineLength * sin(entryAngle * .pi / 180 + .pi)

                Path { path in
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(isInTolerance ? Color.green : Color.red, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))

                // Spacecraft
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(isInTolerance ? .green : .red)
                    .position(x: startX, y: startY)
                    .rotationEffect(.degrees(180 + angle))
            }
            .frame(height: 160)

            // Angle readout
            HStack {
                Text("Reentry Angle:")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                Text(String(format: "%.1f°", angle))
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundStyle(isInTolerance ? .green : .red)
            }

            // Warning text
            Text(angle > -5.5 ? "Too shallow — risk of skipping off into space!" :
                 (angle < -7.5 ? "Too steep — dangerous G-forces!" : "Within safe corridor"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isInTolerance ? .green : .red)

            // Slider
            VStack(spacing: 4) {
                Slider(value: $angleValue, in: 0...1)
                    .tint(isInTolerance ? .green : .red)
                    .disabled(hasSubmitted)

                HStack {
                    Text("-5.0° Skip off")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.6))
                    Spacer()
                    Text("-5.5° to -7.5° SAFE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green.opacity(0.8))
                    Spacer()
                    Text("-8.0° Too steep")
                        .font(.system(size: 9))
                        .foregroundStyle(.red.opacity(0.6))
                }
            }

            // G-Force preview
            let estimatedG = 2.0 + abs(angle + 6.5) * 1.5
            HStack(spacing: 20) {
                DataReadout(label: "Est. Max G", value: String(format: "%.1f G", estimatedG),
                           icon: "arrow.down.circle", color: estimatedG > 4 ? .red : .green)
                DataReadout(label: "Heat Shield", value: String(format: "%.0f°C", 2500 + abs(angle + 6.5) * 200),
                           icon: "flame.fill", color: .orange)
            }
        }
        .padding(16)
        .glassCard()
    }
}

#Preview {
    ChallengeView(viewModel: MissionViewModel(), phase: .translunarInjection)
}
