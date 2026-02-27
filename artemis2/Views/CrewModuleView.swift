//
//  CrewModuleView.swift
//  artemis2
//
//  Crew module showing the Artemis II crew manifest with chat access.
//

import SwiftUI

struct CrewModuleView: View {
    let viewModel: MissionViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isWide: Bool { sizeClass == .regular }

    private var gridColumns: [GridItem] {
        if isWide {
            return Array(repeating: GridItem(.flexible(), spacing: 20), count: 4)
        }
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: isWide ? 28 : 16) {
                        VStack(spacing: isWide ? 12 : 8) {
                            Text("ORION CREW MODULE")
                                .font(.system(size: isWide ? 14 : 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                                .tracking(4)

                            Text("Crew of Artemis II")
                                .font(.system(size: isWide ? 28 : 22, weight: .bold))
                                .foregroundStyle(.white)

                            if isWide {
                                Text("Tap any crew member to start a conversation powered by on-device AI")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                        .padding(.top, isWide ? 32 : 16)

                        VStack(spacing: isWide ? 16 : 12) {
                            Text("CREW MANIFEST")
                                .font(.system(size: isWide ? 11 : 10, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                                .tracking(2)

                            let crew = CrewMember.artemisIICrew
                            LazyVGrid(columns: gridColumns, spacing: isWide ? 20 : 16) {
                                ForEach(crew) { member in
                                    CrewCircleCard(member: member, isWide: isWide)
                                }
                            }
                        }
                        .padding(.horizontal, isWide ? 40 : 16)
                        .frame(maxWidth: isWide ? 900 : .infinity)

                        Spacer(minLength: 100)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Crew Circle Card (2x2 grid item)

struct CrewCircleCard: View {
    let member: CrewMember
    var isWide: Bool = false

    private var initials: String {
        member.name.components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .joined()
    }

    private var roleColor: Color {
        switch member.role {
        case "Commander": return .orange
        case "Pilot": return .cyan
        case "Mission Specialist 1": return .purple
        case "Mission Specialist 2": return .green
        default: return .cyan
        }
    }

    private var avatarSize: CGFloat { isWide ? 100 : 88 }
    private var innerSize: CGFloat { isWide ? 94 : 82 }

    var body: some View {
        VStack(spacing: isWide ? 14 : 10) {
            ZStack {
                Circle()
                    .stroke(roleColor.opacity(0.3), lineWidth: isWide ? 2.5 : 2)
                    .frame(width: avatarSize, height: avatarSize)

                Image(member.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: innerSize, height: innerSize)
                    .clipShape(Circle())

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(member.agency)
                            .font(.system(size: isWide ? 8 : 7, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(roleColor.opacity(0.8)))
                    }
                }
                .frame(width: avatarSize, height: avatarSize)
            }

            VStack(spacing: 4) {
                Text(isWide ? member.name : (member.name.components(separatedBy: " ").first ?? member.name))
                    .font(.system(size: isWide ? 16 : 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(member.role)
                    .font(.system(size: isWide ? 12 : 10, weight: .medium))
                    .foregroundStyle(roleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if isWide {
                Text(member.bio)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            NavigationLink(destination: CrewChatView(crewMember: member)) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: isWide ? 11 : 10))
                    Text("Chat")
                        .font(.system(size: isWide ? 12 : 10, weight: .semibold))
                }
                .foregroundStyle(.cyan)
                .padding(.horizontal, isWide ? 18 : 14)
                .padding(.vertical, isWide ? 8 : 6)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(0.1))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.25), lineWidth: 1))
                )
            }
            .simultaneousGesture(TapGesture().onEnded {
                HapticManager.shared.openCommChannel()
            })
            .accessibilityLabel("Chat with \(member.name)")
            .accessibilityHint("Double tap to open a conversation with \(member.name)")
        }
        .padding(.vertical, isWide ? 20 : 14)
        .padding(.horizontal, isWide ? 12 : 8)
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(member.name), \(member.role), \(member.agency)")
    }
}

#Preview {
    CrewModuleView(viewModel: MissionViewModel())
        .environment(AccessibilitySettings())
}
