//
//  MissionData.swift
//  artemis2
//
//  Artemis II: Journey to the Moon - Interactive Mission Simulator
//  Real mission data for the Artemis II crewed lunar flyby mission.
//

import Foundation
import SwiftUI

// MARK: - Mission Phase

enum MissionPhase: Int, CaseIterable, Identifiable {
    case prelaunch = 0
    case launch
    case earthOrbit
    case translunarInjection
    case translunarCoast
    case lunarFlyby
    case returnTransit
    case reentry

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .prelaunch: return "Pre-Launch"
        case .launch: return "Launch & Ascent"
        case .earthOrbit: return "Earth Orbit"
        case .translunarInjection: return "Trans-Lunar Injection"
        case .translunarCoast: return "Translunar Coast"
        case .lunarFlyby: return "Lunar Flyby"
        case .returnTransit: return "Return Transit"
        case .reentry: return "Reentry & Splashdown"
        }
    }

    var shortName: String {
        switch self {
        case .prelaunch: return "Pre-Launch"
        case .launch: return "Launch"
        case .earthOrbit: return "LEO"
        case .translunarInjection: return "TLI"
        case .translunarCoast: return "Coast"
        case .lunarFlyby: return "Flyby"
        case .returnTransit: return "Return"
        case .reentry: return "Reentry"
        }
    }

    var icon: String {
        switch self {
        case .prelaunch: return "clock.badge.checkmark"
        case .launch: return "flame.fill"
        case .earthOrbit: return "globe.americas.fill"
        case .translunarInjection: return "arrow.up.right.circle.fill"
        case .translunarCoast: return "moon.stars"
        case .lunarFlyby: return "moon.fill"
        case .returnTransit: return "arrow.turn.down.left"
        case .reentry: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .prelaunch: return .gray
        case .launch: return .orange
        case .earthOrbit: return .blue
        case .translunarInjection: return .purple
        case .translunarCoast: return .indigo
        case .lunarFlyby: return .white
        case .returnTransit: return .cyan
        case .reentry: return .red
        }
    }

    /// Duration of each phase in real seconds
    var durationSeconds: Double {
        switch self {
        case .prelaunch: return 600              // 10 minutes
        case .launch: return 510                 // 8.5 minutes to orbit
        case .earthOrbit: return 10_800          // ~2 orbits (~3 hours)
        case .translunarInjection: return 360    // ~6 min burn
        case .translunarCoast: return 345_600    // ~4 days outbound
        case .lunarFlyby: return 3600            // ~1 hour closest approach
        case .returnTransit: return 475_200      // ~5.5 days return
        case .reentry: return 1800               // 30 minutes reentry to splashdown
        }
    }

    /// Cumulative start time in mission seconds
    var startTime: Double {
        var total: Double = 0
        for phase in MissionPhase.allCases {
            if phase == self { return total }
            total += phase.durationSeconds
        }
        return total
    }

    var description: String {
        switch self {
        case .prelaunch:
            return "Final systems check at Launch Complex 39B, Kennedy Space Center. The Space Launch System (SLS) Block 1 rocket stands 322 feet tall, fueled with liquid hydrogen and liquid oxygen. Commander Reid Wiseman leads the crew of four aboard the Orion spacecraft."
        case .launch:
            return "The twin solid rocket boosters ignite, producing 8.8 million pounds of thrust — making the SLS the most powerful rocket NASA has ever flown. The crew experiences up to 2.5 Gs as the SLS accelerates through Max-Q and into the upper atmosphere. Booster separation occurs at T+2:12, followed by core stage separation and upper stage ignition."
        case .earthOrbit:
            return "Orion enters a low Earth orbit at approximately 185 km altitude. Over two orbits (~3 hours), the crew performs systems checks on the spacecraft, verifies solar array deployment, and prepares for the Trans-Lunar Injection burn. This orbit gives mission control time to verify all systems are nominal."
        case .translunarInjection:
            return "The Interim Cryogenic Propulsion Stage (ICPS) fires for approximately 6 minutes, accelerating Orion from 7.8 km/s to 10.8 km/s — the velocity needed to escape Earth's gravitational influence and enter a free-return trajectory to the Moon."
        case .translunarCoast:
            return "Orion cruises through cislunar space on its free-return trajectory. The crew conducts mission experiments, tests life support systems, and communicates with Mission Control. Earth shrinks behind them while the Moon grows larger ahead. Navigation corrections are performed using star trackers."
        case .lunarFlyby:
            return "The most dramatic moment: Orion passes approximately 100 km above the lunar far side — farther from Earth than any human has ever traveled (over 400,000 km). The crew photographs the lunar surface and experiences the awe of seeing the far side with their own eyes."
        case .returnTransit:
            return "Using the Moon's gravity as a slingshot, Orion is redirected back toward Earth. The crew performs final experiments and prepares for the reentry sequence. Communication delays decrease as Earth grows larger in the windows."
        case .reentry:
            return "Orion hits Earth's atmosphere at 40,000 km/h (Mach 32), performing a skip reentry — bouncing off the atmosphere once to reduce G-forces from 9G to a more survivable 4G. The heat shield reaches 2,760°C. Parachutes deploy at 7,600m, and Orion splashes down in the Pacific Ocean."
        }
    }

    /// The science/engineering concept highlighted in this phase
    var educationalTopic: String {
        switch self {
        case .prelaunch: return "Rocket Propulsion: How the SLS generates thrust using Newton's Third Law"
        case .launch: return "Staging: Why rockets shed mass to increase efficiency (Tsiolkovsky equation)"
        case .earthOrbit: return "Orbital Mechanics: Circular orbits and the balance of gravity and velocity"
        case .translunarInjection: return "Hohmann Transfers: Energy-efficient orbit changes using elliptical paths"
        case .translunarCoast: return "Three-Body Problem: Navigating Earth-Moon gravitational influences"
        case .lunarFlyby: return "Gravity Assist: Using the Moon's gravity to change trajectory"
        case .returnTransit: return "Free-Return Trajectory: A built-in safety path that guarantees return to Earth"
        case .reentry: return "Skip Reentry: Bouncing off the atmosphere to reduce extreme G-forces"
        }
    }

    var challengeDescription: String? {
        switch self {
        case .translunarInjection:
            return "Time the TLI burn precisely! Fire the engines within the correct window to achieve translunar trajectory."
        case .lunarFlyby:
            return "Adjust your trajectory to pass within the safe flyby corridor — between 80km and 120km above the lunar surface."
        case .reentry:
            return "Set the reentry angle between -5.5° and -7.5° for a safe skip reentry. Too shallow and you skip off into space. Too steep and the G-forces become dangerous."
        default:
            return nil
        }
    }
}

// MARK: - Crew Member

struct CrewMember: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let agency: String
    let bio: String
    let imageName: String
    let nationality: String

    static let artemisIICrew: [CrewMember] = [
        CrewMember(
            name: "Reid Wiseman",
            role: "Commander",
            agency: "NASA",
            bio: "U.S. Navy Captain and former fighter pilot. Served aboard the ISS for 165 days on Expedition 41. Selected as an astronaut in 2009, he brings extensive spaceflight and leadership experience.",
            imageName: "person.circle.fill",
            nationality: "American"
        ),
        CrewMember(
            name: "Victor Glover",
            role: "Pilot",
            agency: "NASA",
            bio: "U.S. Navy Captain and test pilot. Served as pilot of SpaceX Crew-1 aboard the ISS. He will be the first person of color to fly on a lunar mission and will pilot Orion around the Moon.",
            imageName: "person.circle.fill",
            nationality: "American"
        ),
        CrewMember(
            name: "Christina Koch",
            role: "Mission Specialist 1",
            agency: "NASA",
            bio: "Electrical engineer and former station chief at American Samoa Observatory. Holds the record for the longest single spaceflight by a woman (328 days on the ISS). Conducted the first all-female spacewalk.",
            imageName: "person.circle.fill",
            nationality: "American"
        ),
        CrewMember(
            name: "Jeremy Hansen",
            role: "Mission Specialist 2",
            agency: "CSA",
            bio: "Colonel in the Canadian Armed Forces and former CF-18 fighter pilot. Selected by the Canadian Space Agency in 2009. He will be the first non-American to fly on a lunar mission.",
            imageName: "person.circle.fill",
            nationality: "Canadian"
        )
    ]
}

// MARK: - Telemetry Data

struct TelemetryData {
    var altitude: Double          // km above Earth's surface
    var speed: Double             // km/s
    var distanceFromEarth: Double // km from Earth center
    var distanceFromMoon: Double  // km from Moon center
    var gForce: Double            // current G-force
    var missionElapsedTime: Double // seconds since launch
    var fuelRemaining: Double     // percentage 0-100

    static let initial = TelemetryData(
        altitude: 0,
        speed: 0,
        distanceFromEarth: 6371,
        distanceFromMoon: 384_400,
        gForce: 1.0,
        missionElapsedTime: 0,
        fuelRemaining: 100
    )

    var formattedSpeed: String {
        String(format: "%.1f km/s", speed)
    }

    var formattedSpeedMPH: String {
        let mph = speed * 2236.936
        if mph > 10000 {
            return String(format: "%.0f mph", mph)
        }
        return String(format: "%.1f mph", mph)
    }

    var formattedAltitude: String {
        if altitude > 10000 {
            return String(format: "%.0f km", altitude)
        }
        return String(format: "%.1f km", altitude)
    }

    var formattedDistanceFromEarth: String {
        let distance = distanceFromEarth - 6371 // surface distance
        if distance > 1000 {
            return String(format: "%.0f km", distance)
        }
        return String(format: "%.1f km", distance)
    }

    var formattedDistanceFromMoon: String {
        let distance = distanceFromMoon - 1737 // surface distance
        if distance > 1000 {
            return String(format: "%.0f km", distance)
        }
        return String(format: "%.1f km", distance)
    }

    var formattedMET: String {
        let hours = Int(missionElapsedTime) / 3600
        let minutes = (Int(missionElapsedTime) % 3600) / 60
        let seconds = Int(missionElapsedTime) % 60
        if hours > 0 {
            return String(format: "T+%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "T+%02d:%02d", minutes, seconds)
    }

    var formattedGForce: String {
        String(format: "%.1f G", gForce)
    }
}

// MARK: - Mission Milestone

struct MissionMilestone: Identifiable {
    let id = UUID()
    let name: String
    let missionTime: Double // seconds from launch
    let phase: MissionPhase
    let description: String
    let isInteractive: Bool

    static let milestones: [MissionMilestone] = [
        // Launch phase starts at T+600 (after 10-min prelaunch)
        MissionMilestone(name: "Engine Ignition", missionTime: 600, phase: .launch,
                        description: "RS-25 engines and solid rocket boosters ignite", isInteractive: false),
        MissionMilestone(name: "Max-Q", missionTime: 660, phase: .launch,
                        description: "Maximum dynamic pressure on the vehicle", isInteractive: false),
        MissionMilestone(name: "Booster Separation", missionTime: 732, phase: .launch,
                        description: "Solid rocket boosters separate at altitude", isInteractive: false),
        MissionMilestone(name: "Core Stage Separation", missionTime: 1_080, phase: .launch,
                        description: "Main stage separates, ICPS takes over", isInteractive: false),
        // Earth orbit starts at 1,110
        MissionMilestone(name: "Orbit Insertion", missionTime: 1_110, phase: .earthOrbit,
                        description: "Orion achieves stable Low Earth Orbit at ~185 km", isInteractive: false),
        // TLI starts at 11,910
        MissionMilestone(name: "TLI Burn", missionTime: 11_910, phase: .translunarInjection,
                        description: "Trans-Lunar Injection burn begins", isInteractive: true),
        // Translunar coast starts at 12,270
        MissionMilestone(name: "ICPS Separation", missionTime: 12_270, phase: .translunarCoast,
                        description: "Upper stage separates, Orion flies free", isInteractive: false),
        MissionMilestone(name: "Halfway to Moon", missionTime: 185_070, phase: .translunarCoast,
                        description: "Orion passes the halfway point to the Moon", isInteractive: false),
        // Lunar flyby starts at 357,870
        MissionMilestone(name: "Lunar Closest Approach", missionTime: 359_670, phase: .lunarFlyby,
                        description: "Closest pass over the lunar far side at ~100 km", isInteractive: true),
        MissionMilestone(name: "Farthest from Earth", missionTime: 360_170, phase: .lunarFlyby,
                        description: "Maximum distance from Earth: ~400,000+ km", isInteractive: false),
        // Reentry starts at 836,670
        MissionMilestone(name: "Entry Interface", missionTime: 836_670, phase: .reentry,
                        description: "Orion contacts Earth's atmosphere at 120 km altitude", isInteractive: true),
        MissionMilestone(name: "Skip Maneuver", missionTime: 836_970, phase: .reentry,
                        description: "Orion skips off the atmosphere to reduce G-forces", isInteractive: false),
        MissionMilestone(name: "Splashdown", missionTime: 838_240, phase: .reentry,
                        description: "Parachute deployment and Pacific Ocean splashdown", isInteractive: false)
    ]
}

// MARK: - Challenge Result

struct ChallengeResult: Identifiable {
    let id = UUID()
    let phase: MissionPhase
    let score: Double    // 0-100
    let accuracy: Double // 0-1
    let passed: Bool
    let message: String
}

// MARK: - Time Warp

enum TimeWarp: Double, CaseIterable, Identifiable {
    case realtime = 1
    case fast = 10
    case faster = 100
    case fastest = 1000
    case ludicrous = 10000

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .realtime: return "1x"
        case .fast: return "10x"
        case .faster: return "100x"
        case .fastest: return "1,000x"
        case .ludicrous: return "10,000x"
        }
    }

    var icon: String {
        switch self {
        case .realtime: return "play.fill"
        case .fast: return "forward.fill"
        case .faster: return "forward.end.fill"
        case .fastest: return "forward.end.alt.fill"
        case .ludicrous: return "bolt.fill"
        }
    }
}

// MARK: - View Mode

enum ViewMode: String, CaseIterable, Identifiable {
    case external = "External"
    case crew = "Crew"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .external: return "video.fill"
        case .crew: return "eye.fill"
        }
    }
}

// MARK: - Constants

enum MissionConstants {
    static let earthRadius: Double = 6_371       // km
    static let moonRadius: Double = 1_737        // km
    static let earthMoonDistance: Double = 384_400 // km average
    static let parkingOrbitAltitude: Double = 185  // km (Low Earth Orbit)
    static let lunarFlybyAltitude: Double = 100    // km above surface
    static let escapeVelocity: Double = 11.2       // km/s from Earth surface
    static let orbitalVelocityLEO: Double = 7.8    // km/s at ~185 km altitude
    static let tliVelocity: Double = 10.8          // km/s after TLI
    static let lunarFlybySpeed: Double = 1.5       // km/s at closest approach
    static let reentrySpeed: Double = 11.1         // km/s
    static let totalMissionDuration: Double = 838_470 // ~9.7 days in seconds

    // Gravitational parameters (km³/s²)
    static let earthMu: Double = 398_600
    static let moonMu: Double = 4_905

    // SLS specifications
    static let slsThrustN: Double = 39_144_000     // 8.8 million lbf in Newtons
    static let slsHeightM: Double = 98.1           // 322 feet
    static let orionMassKg: Double = 26_520        // Orion mass

    // Reentry parameters
    static let reentryAngleNominal: Double = -6.5  // degrees
    static let reentryAngleMin: Double = -7.5
    static let reentryAngleMax: Double = -5.5
    static let maxGForceReentry: Double = 4.0
    static let heatShieldTempC: Double = 2_760
}
