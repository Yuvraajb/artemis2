//
//  MissionControlView.swift
//  artemis2
//
//  Main mission control dashboard combining the 3D orbital view,
//  telemetry readouts, time controls, and phase information.
//

import SwiftUI

struct MissionControlView: View {
    @Bindable var viewModel: MissionViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.02, blue: 0.12),
                    Color(red: 0.02, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 3D Scene View - takes upper portion
                ZStack(alignment: .topLeading) {
                    GeometryReader { geo in
                        OrbitSceneView(viewModel: viewModel)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .frame(height: 340)

                    // Overlay: Phase banner & MET
                    VStack {
                        HStack {
                            PhaseBadge(phase: viewModel.currentPhase, isActive: true)

                            Spacer()

                            CountdownDisplay(
                                timeString: viewModel.countdownString,
                                phase: viewModel.currentPhase
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Spacer()

                        // Bottom overlay: quick telemetry
                        HStack(spacing: 16) {
                            DataReadout(
                                label: "SPEED",
                                value: viewModel.telemetry.formattedSpeed,
                                icon: "gauge.with.dots.needle.33percent",
                                color: .cyan
                            )

                            DataReadout(
                                label: "ALTITUDE",
                                value: viewModel.telemetry.formattedAltitude,
                                icon: "arrow.up.to.line",
                                color: .green
                            )

                            Spacer()

                            GForceIndicator(gForce: viewModel.telemetry.gForce)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .padding(.top, 4)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }

                // Mission progress bar
                MissionProgressBar(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Telemetry dashboard
                TelemetryDashboard(viewModel: viewModel)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Spacer(minLength: 4)

                // Time controls
                TimeControlPanel(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $viewModel.showChallengeSheet) {
            if let phase = viewModel.activeChallengePhase {
                ChallengeView(viewModel: viewModel, phase: phase)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Mission Progress Bar

struct MissionProgressBar: View {
    let viewModel: MissionViewModel

    var body: some View {
        VStack(spacing: 4) {
            // Phase indicators
            HStack(spacing: 0) {
                ForEach(MissionPhase.allCases) { phase in
                    let isActive = viewModel.currentPhase == phase
                    let isPast = phase.rawValue < viewModel.currentPhase.rawValue

                    VStack(spacing: 2) {
                        Circle()
                            .fill(isPast ? phase.color : (isActive ? phase.color : Color.white.opacity(0.2)))
                            .frame(width: isActive ? 8 : 5, height: isActive ? 8 : 5)
                            .shadow(color: isActive ? phase.color.opacity(0.6) : .clear, radius: 4)

                        if isActive {
                            Text(phase.shortName)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(phase.color)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [viewModel.currentPhase.color.opacity(0.7),
                                         viewModel.currentPhase.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * viewModel.overallProgress))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.overallProgress)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Telemetry Dashboard

struct TelemetryDashboard: View {
    let viewModel: MissionViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Top row: circular gauges
            HStack(spacing: 8) {
                CircularGauge(
                    value: viewModel.telemetry.speed,
                    maxValue: MissionConstants.reentrySpeed,
                    label: "Speed",
                    unit: "km/s",
                    icon: "gauge.with.dots.needle.33percent",
                    color: .cyan
                )

                CircularGauge(
                    value: min(viewModel.telemetry.altitude, MissionConstants.earthMoonDistance),
                    maxValue: MissionConstants.earthMoonDistance,
                    label: "Altitude",
                    unit: "km",
                    icon: "arrow.up.to.line",
                    color: .green,
                    showDecimal: viewModel.telemetry.altitude < 1000
                )

                CircularGauge(
                    value: viewModel.telemetry.fuelRemaining,
                    maxValue: 100,
                    label: "Fuel",
                    unit: "%",
                    icon: "fuelpump.fill",
                    color: viewModel.telemetry.fuelRemaining < 15 ? .red : .orange
                )

                SpeedTape(
                    speed: viewModel.telemetry.speed,
                    maxSpeed: MissionConstants.reentrySpeed
                )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .glassCard()

            // Bottom row: distance bars
            HStack(spacing: 8) {
                VStack(spacing: 6) {
                    TelemetryBar(
                        label: "Earth Distance",
                        value: viewModel.telemetry.formattedDistanceFromEarth,
                        progress: min(1, (viewModel.telemetry.distanceFromEarth - MissionConstants.earthRadius) / MissionConstants.earthMoonDistance),
                        color: .blue
                    )

                    TelemetryBar(
                        label: "Moon Distance",
                        value: viewModel.telemetry.formattedDistanceFromMoon,
                        progress: 1.0 - min(1, (viewModel.telemetry.distanceFromMoon - MissionConstants.moonRadius) / MissionConstants.earthMoonDistance),
                        color: .white
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text("Next:")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Text(viewModel.nextMilestone?.name ?? "Complete")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.orange)
                        .lineLimit(1)

                    Text(viewModel.distanceToNextMilestone)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 90)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .glassCard()
        }
    }
}

// MARK: - Time Control Panel

struct TimeControlPanel: View {
    @Bindable var viewModel: MissionViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: { viewModel.togglePlayPause() }) {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.isRunning ? Color.orange.opacity(0.3) : Color.green.opacity(0.3))
                            .overlay(
                                Circle().stroke(viewModel.isRunning ? Color.orange : Color.green, lineWidth: 1)
                            )
                    )
            }

            // Time warp selector
            HStack(spacing: 4) {
                ForEach(TimeWarp.allCases) { warp in
                    Button(action: { viewModel.setTimeWarp(warp) }) {
                        VStack(spacing: 2) {
                            Image(systemName: warp.icon)
                                .font(.system(size: 10))
                            Text(warp.label)
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundStyle(viewModel.timeWarp == warp ? .white : .white.opacity(0.4))
                        .frame(width: 44, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(viewModel.timeWarp == warp
                                      ? Color.cyan.opacity(0.25)
                                      : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(viewModel.timeWarp == warp
                                                ? Color.cyan.opacity(0.5)
                                                : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
            }

            Spacer()

            // Reset button
            Button(action: { viewModel.resetMission() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .glassCard()
    }
}

#Preview {
    MissionControlView(viewModel: MissionViewModel())
}
