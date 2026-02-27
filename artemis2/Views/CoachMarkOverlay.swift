//
//  CoachMarkOverlay.swift
//  artemis2
//
//  Small floating coach-mark cards that anchor to the corner of each section
//  during the progressive onboarding reveal. No full-screen dim — just a
//  compact card with a Next button.
//

import SwiftUI

struct CoachMarkCard: View {
    let title: String
    let message: String
    let icon: String
    let step: Int
    let totalSteps: Int
    let isLast: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.cyan)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            Text(message)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == step ? Color.cyan : Color.white.opacity(0.25))
                            .frame(width: 5, height: 5)
                    }
                }
                Spacer()
                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text(isLast ? "Done" : "Next")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: isLast ? "checkmark" : "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.cyan))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
        )
    }
}

// MARK: - Step definitions (used by ContentView / MissionControlView)

enum OnboardingStep: Int, CaseIterable {
    case orbitalView = 0
    case telemetry = 1
    case timeControls = 2
    case timeline = 3
    case crew = 4

    static var count: Int { allCases.count }

    var tab: AppTab {
        switch self {
        case .orbitalView, .telemetry, .timeControls: return .missionControl
        case .timeline: return .timeline
        case .crew: return .crew
        }
    }

    var title: String {
        switch self {
        case .orbitalView: return "3D Mission View"
        case .telemetry: return "Live Telemetry"
        case .timeControls: return "Time Controls"
        case .timeline: return "Timeline & Phases"
        case .crew: return "Chat with the Crew"
        }
    }

    var message: String {
        switch self {
        case .orbitalView: return "Pinch to zoom and drag to rotate. Watch Orion's trajectory from any angle."
        case .telemetry: return "Speed, altitude, G-force, and fuel. Charts track the full history."
        case .timeControls: return "Play, pause, and use time warp. The mission spans ~10 days."
        case .timeline: return "Every phase laid out. Tap for details or skip to key moments."
        case .crew: return "Talk to the astronauts — each has their own AI personality."
        }
    }

    var icon: String {
        switch self {
        case .orbitalView: return "globe.americas.fill"
        case .telemetry: return "gauge.with.dots.needle.33percent"
        case .timeControls: return "play.circle.fill"
        case .timeline: return "timeline.selection"
        case .crew: return "person.3.fill"
        }
    }

}
