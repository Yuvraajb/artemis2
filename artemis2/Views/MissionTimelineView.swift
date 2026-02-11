//
//  MissionTimelineView.swift
//  artemis2
//
//  Interactive scrollable timeline of the Artemis II mission phases,
//  with educational content and milestone tracking.
//

import SwiftUI

struct MissionTimelineView: View {
    @Bindable var viewModel: MissionViewModel
    @State private var expandedPhase: MissionPhase? = nil

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 8) {
                            Text("MISSION TIMELINE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(4)

                            CountdownDisplay(
                                timeString: viewModel.countdownString,
                                phase: viewModel.currentPhase,
                                isLarge: true
                            )

                            Text("Total Duration: ~10 days")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                        // Timeline phases
                        ForEach(MissionPhase.allCases) { phase in
                            TimelinePhaseCard(
                                phase: phase,
                                currentPhase: viewModel.currentPhase,
                                missionTime: viewModel.missionTime,
                                isExpanded: expandedPhase == phase,
                                onTap: { togglePhase(phase) },
                                onSkip: { viewModel.skipToPhase(phase) }
                            )
                            .id(phase)
                        }

                        // Score summary
                        if !viewModel.challengeResults.isEmpty {
                            ScoreSummaryCard(results: viewModel.challengeResults)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }

                        Spacer(minLength: 100)
                    }
                }
                .onChange(of: viewModel.currentPhase) { _, newPhase in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newPhase, anchor: .center)
                    }
                }
            }
        }
    }

    private func togglePhase(_ phase: MissionPhase) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expandedPhase = expandedPhase == phase ? nil : phase
        }
    }
}

// MARK: - Timeline Phase Card

struct TimelinePhaseCard: View {
    let phase: MissionPhase
    let currentPhase: MissionPhase
    let missionTime: Double
    let isExpanded: Bool
    let onTap: () -> Void
    let onSkip: () -> Void

    private var status: PhaseStatus {
        if phase.rawValue < currentPhase.rawValue { return .completed }
        if phase == currentPhase { return .active }
        return .upcoming
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            timelineConnector
            contentCard
        }
        .padding(.leading, 16)
    }

    // MARK: - Timeline Connector

    private var timelineConnector: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(status == .upcoming ? Color.white.opacity(0.1) : phase.color.opacity(0.5))
                .frame(width: 2)

            connectorDot
                .frame(height: 24)

            Rectangle()
                .fill(status == .completed ? phase.color.opacity(0.5) : Color.white.opacity(0.1))
                .frame(width: 2)
        }
        .frame(width: 24)
    }

    private var connectorDot: some View {
        ZStack {
            let dotColor: Color = status == .active ? phase.color : (status == .completed ? phase.color.opacity(0.6) : Color.white.opacity(0.15))
            let dotSize: CGFloat = status == .active ? 16 : 10
            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)

            if status == .active {
                Circle()
                    .stroke(phase.color.opacity(0.4), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }

            if status == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
    }

    // MARK: - Content Card

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(cardBackground)
        .padding(.trailing, 16)
    }

    private var cardBackground: some View {
        let fillColor: Color = status == .active ? phase.color.opacity(0.06) : Color.white.opacity(0.02)
        let strokeColor: Color = status == .active ? phase.color.opacity(0.2) : Color.white.opacity(0.05)
        return RoundedRectangle(cornerRadius: 12)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }

    private var cardHeader: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: phase.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(phase.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(phase.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(status == .upcoming ? .white.opacity(0.5) : .white)
                    Text(formatDuration(phase.durationSeconds))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                if status == .active {
                    activeBadge
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    private var activeBadge: some View {
        Text("ACTIVE")
            .font(.system(size: 8, weight: .heavy, design: .monospaced))
            .foregroundStyle(phase.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(phase.color.opacity(0.15))
                    .overlay(Capsule().stroke(phase.color.opacity(0.3), lineWidth: 1))
            )
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(phase.description)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(4)

            educationalTopicCard
            challengeCard
            milestonesSection
            skipButton
        }
    }

    private var educationalTopicCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundStyle(.yellow)
            Text(phase.educationalTopic)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.yellow.opacity(0.9))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var challengeCard: some View {
        if let challenge = phase.challengeDescription {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("INTERACTIVE CHALLENGE")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.8))
                    Text(challenge)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    @ViewBuilder
    private var milestonesSection: some View {
        let phaseMilestones = MissionMilestone.milestones.filter { $0.phase == phase }
        if !phaseMilestones.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("MILESTONES")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                ForEach(phaseMilestones) { milestone in
                    milestoneRow(milestone)
                }
            }
        }
    }

    private func milestoneRow(_ milestone: MissionMilestone) -> some View {
        let isReached = missionTime >= milestone.missionTime
        return HStack(spacing: 8) {
            Circle()
                .fill(isReached ? phase.color : Color.white.opacity(0.2))
                .frame(width: 6, height: 6)
            Text(milestone.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isReached ? .white : .white.opacity(0.5))
            Spacer()
            if milestone.isInteractive {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.green.opacity(0.6))
            }
        }
    }

    @ViewBuilder
    private var skipButton: some View {
        if status == .upcoming {
            Button(action: onSkip) {
                HStack {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10))
                    Text("Skip to this phase")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(phase.color)
            }
            .buttonStyle(GlowingButtonStyle(color: phase.color))
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 { return String(format: "%.0fs", seconds) }
        if seconds < 3600 { return String(format: "%.0f min", seconds / 60) }
        if seconds < 86400 { return String(format: "%.1f hours", seconds / 3600) }
        return String(format: "%.1f days", seconds / 86400)
    }
}

private enum PhaseStatus {
    case completed, active, upcoming
}

// MARK: - Score Summary

struct ScoreSummaryCard: View {
    let results: [ChallengeResult]

    var totalScore: Double {
        results.reduce(0) { $0 + $1.score }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("CHALLENGE RESULTS")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            Text(String(format: "%.0f", totalScore))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.yellow)

            Text("TOTAL SCORE")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))

            ForEach(results) { result in
                HStack {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.passed ? .green : .red)

                    Text(result.phase.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Text(String(format: "%.0f", result.score))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

#Preview {
    MissionTimelineView(viewModel: MissionViewModel())
}
