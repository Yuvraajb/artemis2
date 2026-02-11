//
//  ContentView.swift
//  artemis2
//
//  Created by Yuvraaj Bhatter on 2/10/26.
//
//  Main navigation hub for the Artemis II Mission Simulator.
//  Tab-based layout with Mission Control, Timeline, and Crew modules.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MissionViewModel()
    @State private var selectedTab: AppTab = .missionControl
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchScreenView {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showLaunchScreen = false
                    }
                }
                .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            MissionControlView(viewModel: viewModel)
                .tabItem {
                    Label("Mission", systemImage: "gauge.with.dots.needle.33percent")
                }
                .tag(AppTab.missionControl)

            MissionTimelineView(viewModel: viewModel)
                .tabItem {
                    Label("Timeline", systemImage: "timeline.selection")
                }
                .tag(AppTab.timeline)

            CrewModuleView(viewModel: viewModel)
                .tabItem {
                    Label("Crew", systemImage: "person.3.fill")
                }
                .tag(AppTab.crew)
        }
        .tint(.cyan)
    }
}

// MARK: - App Tabs

enum AppTab: String {
    case missionControl
    case timeline
    case crew
}

// MARK: - Launch Screen

struct LaunchScreenView: View {
    let onContinue: () -> Void
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var showButton: Bool = false

    var body: some View {
        ZStack {
            // Deep space background
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.01, blue: 0.05),
                    Color(red: 0.03, green: 0.01, blue: 0.1),
                    Color(red: 0.01, green: 0.03, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle star particles
            Canvas { context, size in
                for i in 0..<120 {
                    let x = CGFloat((i * 41 + 17) % Int(size.width))
                    let y = CGFloat((i * 67 + 23) % Int(size.height))
                    let starSize = CGFloat.random(in: 0.5...2.0)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                        with: .color(.white.opacity(Double.random(in: 0.2...0.8)))
                    )
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Mission patch / logo
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    VStack(spacing: 4) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("II")
                            .font(.system(size: 24, weight: .ultraLight, design: .serif))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Title text
                VStack(spacing: 8) {
                    Text("ARTEMIS II")
                        .font(.system(size: 36, weight: .heavy, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(6)

                    Text("JOURNEY TO THE MOON")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(4)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .cyan.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 200, height: 1)
                        .padding(.vertical, 8)

                    Text("Interactive Mission Simulator")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .offset(y: titleOffset)
                .opacity(logoOpacity)

                Spacer()

                // Begin button
                if showButton {
                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Text("BEGIN MISSION")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .tracking(3)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                titleOffset = 0
            }
            withAnimation(.easeIn(duration: 0.6).delay(1.2)) {
                showButton = true
            }
        }
    }
}

#Preview {
    ContentView()
}
