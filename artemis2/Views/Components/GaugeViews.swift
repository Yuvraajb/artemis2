//
//  GaugeViews.swift
//  artemis2
//
//  Custom gauge and telemetry display components with a space-themed aesthetic.
//

import SwiftUI

// MARK: - Circular Gauge

struct CircularGauge: View {
    let value: Double
    let maxValue: Double
    let label: String
    let unit: String
    let icon: String
    var color: Color = .cyan
    var showDecimal: Bool = true

    private var progress: Double {
        min(1, max(0, value / maxValue))
    }

    private var displayValue: String {
        if value > 9999 {
            return String(format: "%.0f", value)
        }
        return showDecimal ? String(format: "%.1f", value) : String(format: "%.0f", value)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 4)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.5), color],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * progress)
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(color)

                    Text(displayValue)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text(unit)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 70, height: 70)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Linear Telemetry Bar

struct TelemetryBar: View {
    let label: String
    let value: String
    let progress: Double
    var color: Color = .cyan

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * min(1, max(0, progress))))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Data Readout

struct DataReadout: View {
    let label: String
    let value: String
    var icon: String? = nil
    var color: Color = .white

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(color.opacity(0.7))
                    .frame(width: 16)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Mission Phase Badge

struct PhaseBadge: View {
    let phase: MissionPhase
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: phase.icon)
                .font(.system(size: 12))
            Text(phase.shortName)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(isActive ? phase.color.opacity(0.3) : Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .stroke(isActive ? phase.color : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .foregroundStyle(isActive ? phase.color : .white.opacity(0.5))
    }
}

// MARK: - G-Force Indicator

struct GForceIndicator: View {
    let gForce: Double

    private var color: Color {
        if gForce < 1.5 { return .green }
        if gForce < 3.0 { return .yellow }
        if gForce < 4.0 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: min(1, gForce / 5.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(String(format: "%.1f", gForce))
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(color)
                    Text("G")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(color.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Speed Tape

struct SpeedTape: View {
    let speed: Double
    let maxSpeed: Double

    var body: some View {
        VStack(spacing: 2) {
            Text("SPEED")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 30, height: 80)

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.5), .cyan],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 30, height: max(2, 80 * min(1, speed / maxSpeed)))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )

            Text(String(format: "%.1f", speed))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.cyan)

            Text("km/s")
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Countdown Display

struct CountdownDisplay: View {
    let timeString: String
    let phase: MissionPhase
    var isLarge: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(timeString)
                .font(.system(size: isLarge ? 32 : 18, weight: .bold, design: .monospaced))
                .foregroundStyle(phase == .prelaunch ? .orange : .green)
                .shadow(color: (phase == .prelaunch ? Color.orange : Color.green).opacity(0.5),
                        radius: 8, x: 0, y: 0)

            if isLarge {
                Text("MISSION ELAPSED TIME")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(2)
            }
        }
    }
}

// MARK: - Glowing Button Style

struct GlowingButtonStyle: ButtonStyle {
    var color: Color = .cyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.4 : 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.6), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var opacity: Double = 0.12

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(opacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(opacity: Double = 0.12) -> some View {
        modifier(GlassCard(opacity: opacity))
    }
}
