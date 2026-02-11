//
//  CrewModuleView.swift
//  artemis2
//
//  Crew perspective module showing what the astronauts see from
//  inside the Orion capsule, with crew bios and telemetry displays.
//

import SwiftUI

struct CrewModuleView: View {
    let viewModel: MissionViewModel
    @State private var selectedCrew: CrewMember? = nil
    @State private var showCrewDetail: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Text("ORION CREW MODULE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(4)

                        Text("Crew of Artemis II")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 16)

                    // Capsule Window View
                    CapsuleWindowView(viewModel: viewModel)
                        .frame(height: 220)
                        .padding(.horizontal, 16)

                    // Interior status panel
                    InteriorStatusPanel(viewModel: viewModel)
                        .padding(.horizontal, 16)

                    // Crew cards
                    VStack(spacing: 8) {
                        Text("CREW MANIFEST")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)

                        ForEach(CrewMember.artemisIICrew) { member in
                            CrewCard(member: member) {
                                selectedCrew = member
                                showCrewDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Current activity
                    CurrentActivityCard(viewModel: viewModel)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showCrewDetail) {
            if let crew = selectedCrew {
                CrewDetailSheet(member: crew)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Capsule Window View

struct CapsuleWindowView: View {
    let viewModel: MissionViewModel

    var body: some View {
        ZStack {
            // Window frame
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color(white: 0.3), Color(white: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )

            // Window content - what the crew sees
            windowContent
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(4)

            // Window frame overlay (bolts, etc.)
            windowFrameOverlay

            // Caption
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                    Text("CREW PERSPECTIVE")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(2)
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(.black.opacity(0.6)))
                .padding(.bottom, 12)
            }
        }
    }

    @ViewBuilder
    private var windowContent: some View {
        switch viewModel.currentPhase {
        case .prelaunch:
            // View from the pad - blue sky
            LinearGradient(colors: [.blue, .cyan.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .overlay(
                    VStack {
                        Spacer()
                        Text("Launch Complex 39B")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Kennedy Space Center")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.bottom, 30)
                )

        case .launch:
            // Fire and clouds
            LinearGradient(
                colors: [.orange, .red.opacity(0.8), .black],
                startPoint: .bottom,
                endPoint: .top
            )
            .overlay(
                VStack {
                    Text("MAX Q")
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.orange)
                        .opacity(viewModel.phaseProgressValue > 0.1 && viewModel.phaseProgressValue < 0.25 ? 1 : 0)
                    Spacer()
                }
                .padding(.top, 20)
            )

        case .earthOrbit:
            // Earth below, stars above
            ZStack {
                Color.black
                // Stars
                starsOverlay
                // Earth horizon at bottom
                earthHorizon
            }

        case .translunarInjection, .translunarCoast:
            // Earth getting smaller, stars everywhere
            ZStack {
                Color.black
                starsOverlay

                // Small Earth
                let earthSize = max(20, 80 * (1.0 - viewModel.phaseProgressValue))
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.1, green: 0.3, blue: 0.8), Color(red: 0.05, green: 0.15, blue: 0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: earthSize / 2
                        )
                    )
                    .frame(width: earthSize, height: earthSize)
                    .offset(x: -50, y: 40)

                // Moon getting larger
                if viewModel.currentPhase == .translunarCoast {
                    let moonSize = max(10, 60 * viewModel.phaseProgressValue)
                    Circle()
                        .fill(Color(white: 0.65))
                        .frame(width: moonSize, height: moonSize)
                        .offset(x: 60, y: -30)
                }
            }

        case .lunarFlyby:
            // Moon surface filling the view
            ZStack {
                Color.black
                // Large moon surface
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.7), Color(white: 0.3)],
                            center: .init(x: 0.3, y: 0.7),
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(y: 120)

                VStack {
                    Text("LUNAR FAR SIDE")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 10)
                    Text("Farthest humans have ever traveled")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 20)
            }

        case .returnTransit:
            // Moon getting smaller, Earth growing
            ZStack {
                Color.black
                starsOverlay

                // Growing Earth
                let earthSize = max(30, 100 * viewModel.phaseProgressValue)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.1, green: 0.3, blue: 0.8), Color(red: 0.05, green: 0.15, blue: 0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: earthSize / 2
                        )
                    )
                    .frame(width: earthSize, height: earthSize)
                    .offset(x: 30, y: 20)
            }

        case .reentry:
            // Plasma and fire during reentry
            LinearGradient(
                colors: [.red, .orange, .yellow, .white],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.8)
            .overlay(
                VStack {
                    Text(String(format: "%.0f°C", 2760 * viewModel.phaseProgressValue))
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("HEAT SHIELD TEMPERATURE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            )
        }
    }

    private var starsOverlay: some View {
        Canvas { context, size in
            for i in 0..<80 {
                let x = CGFloat((i * 37 + 13) % Int(size.width))
                let y = CGFloat((i * 53 + 7) % Int(size.height))
                let starSize = CGFloat.random(in: 1...3)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                    with: .color(.white.opacity(Double.random(in: 0.3...1.0)))
                )
            }
        }
    }

    private var earthHorizon: some View {
        VStack {
            Spacer()
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.3, blue: 0.8),
                            Color(red: 0.0, green: 0.1, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 100)
                .overlay(
                    Ellipse()
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var windowFrameOverlay: some View {
        GeometryReader { geo in
            ZStack {
                // Corner bolts
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(Color(white: 0.25))
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color(white: 0.35), lineWidth: 1))
                        .position(
                            x: i % 2 == 0 ? 18 : geo.size.width - 18,
                            y: i < 2 ? 18 : geo.size.height - 18
                        )
                }
            }
        }
    }
}

// MARK: - Interior Status Panel

struct InteriorStatusPanel: View {
    let viewModel: MissionViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("CAPSULE ENVIRONMENT")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)

            HStack(spacing: 12) {
                EnvironmentReadout(icon: "thermometer.medium", label: "Cabin Temp", value: "21.5°C", color: .green)
                EnvironmentReadout(icon: "aqi.medium", label: "O₂ Level", value: "20.9%", color: .cyan)
                EnvironmentReadout(icon: "humidity.fill", label: "Humidity", value: "45%", color: .blue)
                EnvironmentReadout(icon: "gauge.with.dots.needle.67percent", label: "Pressure", value: "101 kPa", color: .orange)
            }
        }
        .padding(12)
        .glassCard()
    }
}

struct EnvironmentReadout: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Crew Card

struct CrewCard: View {
    let member: CrewMember
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: member.imageName)
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text(member.role)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.cyan)

                    HStack(spacing: 4) {
                        Text(member.agency)
                            .font(.system(size: 9, weight: .medium))
                        Text("•")
                        Text(member.nationality)
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(12)
            .glassCard()
        }
    }
}

// MARK: - Crew Detail Sheet

struct CrewDetailSheet: View {
    let member: CrewMember
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.1)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 80, height: 80)

                    Image(systemName: member.imageName)
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 4) {
                    Text(member.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text(member.role)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.cyan)

                    Text("\(member.agency) • \(member.nationality)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(member.bio)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 24)
        }
    }
}

// MARK: - Current Activity Card

struct CurrentActivityCard: View {
    let viewModel: MissionViewModel

    private var activity: (String, String) {
        switch viewModel.currentPhase {
        case .prelaunch: return ("Pre-flight checks", "Crew strapped into seats, reviewing launch procedures with Mission Control.")
        case .launch: return ("Launch sequence active", "All crew experiencing acceleration forces. Systems nominal.")
        case .earthOrbit: return ("Orbital operations", "Crew performing spacecraft checkout, testing systems, and preparing for TLI.")
        case .translunarInjection: return ("TLI burn in progress", "ICPS engine firing. Crew monitoring Delta-V and trajectory.")
        case .translunarCoast: return ("Outbound cruise", "Crew conducting experiments, photography, and communication sessions.")
        case .lunarFlyby: return ("Lunar operations", "All crew at windows photographing the lunar surface and far side.")
        case .returnTransit: return ("Homebound cruise", "Final experiments, data review, and reentry preparation.")
        case .reentry: return ("Reentry sequence", "Crew in landing configuration. Heat shield facing forward.")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.cyan)
                Text("CURRENT ACTIVITY")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
            }

            Text(activity.0)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Text(activity.1)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

#Preview {
    CrewModuleView(viewModel: MissionViewModel())
}
