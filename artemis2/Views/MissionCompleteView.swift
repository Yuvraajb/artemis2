//
//  MissionCompleteView.swift
//  artemis2
//
//  Celebratory mission completion screen with stats,
//  challenge scores, and a shareable mission summary.
//

import SwiftUI

struct MissionCompleteView: View {
    let viewModel: MissionViewModel
    let onDismiss: () -> Void
    @Environment(AccessibilitySettings.self) private var a11y
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isWide: Bool { sizeClass == .regular }

    @State private var showContent = false
    @State private var showStats = false
    @State private var showChallenges = false
    @State private var showActions = false
    @State private var patchRotation: Double = 0

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: isWide ? 32 : 24) {
                    missionPatch
                        .padding(.top, isWide ? 60 : 40)

                    congratsHeader
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    statsGrid
                        .opacity(showStats ? 1 : 0)
                        .offset(y: showStats ? 0 : 20)

                    if !viewModel.challengeResults.isEmpty {
                        challengeResults
                            .opacity(showChallenges ? 1 : 0)
                            .offset(y: showChallenges ? 0 : 20)
                    }

                    ratingBadge
                        .opacity(showChallenges ? 1 : 0)
                        .scaleEffect(showChallenges ? 1 : 0.8)

                    actionButtons
                        .opacity(showActions ? 1 : 0)
                        .offset(y: showActions ? 0 : 20)

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, isWide ? 32 : 20)
                .frame(maxWidth: isWide ? 680 : .infinity)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { animateEntrance() }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.06),
                    Color(red: 0.02, green: 0.01, blue: 0.12),
                    Color(red: 0.01, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Canvas { context, size in
                for i in 0..<100 {
                    let x = CGFloat((i * 41 + 17) % Int(size.width))
                    let y = CGFloat((i * 67 + 23) % Int(size.height))
                    let starSize = CGFloat.random(in: 0.5...2.0)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                        with: .color(.white.opacity(Double.random(in: 0.2...0.7)))
                    )
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }

    // MARK: - Mission Patch

    private var missionPatch: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.cyan, .blue, .purple, .orange, .yellow, .cyan],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(patchRotation))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 65
                    )
                )
                .frame(width: 130, height: 130)

            VStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("COMPLETE")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mission complete badge")
    }

    // MARK: - Header

    private var congratsHeader: some View {
        VStack(spacing: 8) {
            Text("MISSION ACCOMPLISHED")
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(3)

            Text("Artemis II Has Returned Safely")
                .font(.system(size: a11y.scaled(22), weight: .bold))
                .foregroundStyle(.white)

            Text("The crew of Orion has completed humanity's return to the Moon — flying farther from Earth than anyone in over 50 years.")
                .font(.system(size: a11y.scaled(13)))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan)
                Text("MISSION STATISTICS")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))
                    .tracking(2)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(
                    icon: "clock.fill",
                    label: "Mission Duration",
                    value: viewModel.missionDurationFormatted,
                    color: .cyan
                )
                StatCard(
                    icon: "gauge.with.dots.needle.33percent",
                    label: "Peak Speed",
                    value: String(format: "%.1f km/s", viewModel.peakSpeed),
                    color: .orange
                )
                StatCard(
                    icon: "arrow.up.to.line",
                    label: "Max Distance",
                    value: formatLargeDistance(viewModel.peakAltitude),
                    color: .green
                )
                StatCard(
                    icon: "arrow.down.circle.fill",
                    label: "Peak G-Force",
                    value: String(format: "%.1f G", viewModel.peakGForce),
                    color: .red
                )
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Challenge Results

    private var challengeResults: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
                Text("CHALLENGE PERFORMANCE")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))
                    .tracking(2)
                Spacer()
            }

            ForEach(viewModel.challengeResults) { result in
                HStack(spacing: 12) {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(result.passed ? a11y.successColor : a11y.warningColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.phase.name)
                            .font(.system(size: a11y.scaled(13), weight: .semibold))
                            .foregroundStyle(.white)
                        Text(result.message)
                            .font(.system(size: a11y.scaled(10)))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(2)
                    }

                    Spacer()

                    Text(String(format: "%.0f", result.score))
                        .font(.system(size: a11y.scaled(18), weight: .heavy, design: .monospaced))
                        .foregroundStyle(.yellow)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.03))
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(result.phase.name): \(result.passed ? "passed" : "needs improvement"), score \(String(format: "%.0f", result.score))")
            }

            HStack {
                Text("Total Score")
                    .font(.system(size: a11y.scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(viewModel.totalScore)")
                    .font(.system(size: a11y.scaled(24), weight: .heavy, design: .monospaced))
                    .foregroundStyle(.yellow)
                Text("/ \(viewModel.challengeResults.count * 100)")
                    .font(.system(size: a11y.scaled(14), weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.top, 4)
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Rating Badge

    private var ratingBadge: some View {
        VStack(spacing: 8) {
            Image(systemName: ratingIcon)
                .font(.system(size: 32))
                .foregroundStyle(ratingColor)

            Text(viewModel.missionRating.uppercased())
                .font(.system(size: a11y.scaled(18), weight: .heavy, design: .monospaced))
                .foregroundStyle(ratingColor)
                .tracking(3)

            Text("Mission Rating")
                .font(.system(size: a11y.scaled(11)))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(20)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mission rating: \(viewModel.missionRating)")
    }

    private var ratingIcon: String {
        switch viewModel.missionRating {
        case "Outstanding": return "star.circle.fill"
        case "Excellent": return "hands.clap.fill"
        case "Good": return "hand.thumbsup.fill"
        default: return "flag.checkered"
        }
    }

    private var ratingColor: Color {
        switch viewModel.missionRating {
        case "Outstanding": return .yellow
        case "Excellent": return .cyan
        case "Good": return .green
        default: return .orange
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ShareLink(item: missionSummaryText) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Mission Report")
                }
                .font(.system(size: a11y.scaled(14), weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.cyan.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .accessibilityLabel("Share mission report")

            Button(action: {
                viewModel.resetMission()
                onDismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Fly Again")
                }
                .font(.system(size: a11y.scaled(14), weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .accessibilityLabel("Restart mission")
            .accessibilityHint("Double tap to reset and fly the mission again")
        }
    }

    // MARK: - Share Text

    private var missionSummaryText: String {
        var text = """
        🚀 ARTEMIS II — MISSION COMPLETE

        I just completed the Artemis II mission simulation!

        📊 Mission Stats:
        • Duration: \(viewModel.missionDurationFormatted)
        • Peak Speed: \(String(format: "%.1f km/s", viewModel.peakSpeed))
        • Max Distance: \(formatLargeDistance(viewModel.peakAltitude))
        • Peak G-Force: \(String(format: "%.1f G", viewModel.peakGForce))
        """

        if !viewModel.challengeResults.isEmpty {
            text += "\n\n🎯 Challenges: \(viewModel.challengesPassed)/\(viewModel.challengeResults.count) passed"
            text += "\n⭐ Total Score: \(viewModel.totalScore)/\(viewModel.challengeResults.count * 100)"
            text += "\n🏅 Rating: \(viewModel.missionRating)"
        }

        text += "\n\n#Artemis2 #SwiftStudentChallenge"
        return text
    }

    // MARK: - Animation

    private func animateEntrance() {
        if a11y.reduceMotion {
            showContent = true
            showStats = true
            showChallenges = true
            showActions = true
            return
        }

        withAnimation(.easeOut(duration: 0.8)) { showContent = true }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) { showStats = true }
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) { showChallenges = true }
        withAnimation(.easeOut(duration: 0.8).delay(0.9)) { showActions = true }
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            patchRotation = 360
        }
    }

    // MARK: - Helpers

    private func formatLargeDistance(_ km: Double) -> String {
        if km > 1000 {
            return String(format: "%.0f km", km)
        }
        return String(format: "%.1f km", km)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    @Environment(AccessibilitySettings.self) private var a11y

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: a11y.scaled(14), weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: a11y.scaled(9), weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.12), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    MissionCompleteView(viewModel: MissionViewModel(), onDismiss: {})
        .environment(AccessibilitySettings())
        .preferredColorScheme(.dark)
}
