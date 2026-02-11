//
//  OrbitalMechanics.swift
//  artemis2
//
//  Orbital mechanics engine for computing spacecraft position,
//  velocity, and trajectory throughout the Artemis II mission.
//

import Foundation
import simd

// MARK: - Orbital Mechanics Engine

struct OrbitalMechanics {

    // MARK: - Position Computation

    /// Compute spacecraft position along the Artemis II free-return trajectory.
    /// Returns a normalized 3D position (scaled for visualization, not real-km).
    /// The trajectory is modeled as:
    ///   - Phase 1: Launch (surface to LEO) - vertical then curved
    ///   - Phase 2: Parking orbit (circular around Earth)
    ///   - Phase 3: TLI + outbound (elliptical transfer to Moon)
    ///   - Phase 4: Lunar flyby (hyperbolic around Moon)
    ///   - Phase 5: Return (elliptical back to Earth)
    ///   - Phase 6: Reentry (approach and entry)
    static func spacecraftPosition(missionTime: Double) -> SIMD3<Float> {
        let phase = currentPhase(at: missionTime)
        let phaseProgress = phaseProgress(at: missionTime)

        switch phase {
        case .prelaunch:
            // On the launch pad
            return SIMD3<Float>(0, -5.0, 0)

        case .launch:
            // Ascent: move from surface upward and start curving
            let altitude = Float(phaseProgress * 0.3) // rise to near-orbit
            let curve = Float(sin(phaseProgress * .pi * 0.5) * 0.2)
            return SIMD3<Float>(curve, -5.0 + altitude + 5.0 * Float(phaseProgress), 0)

        case .earthOrbit:
            // Circular parking orbit around Earth
            let angle = Float(phaseProgress * 2.0 * .pi * 1.5) // 1.5 orbits
            let orbitRadius: Float = 1.3 // visual radius
            return SIMD3<Float>(
                cos(angle) * orbitRadius,
                sin(angle) * orbitRadius,
                sin(angle * 0.3) * 0.1
            )

        case .translunarInjection:
            // TLI burn - spiral outward from parking orbit
            let startAngle = Float(1.5 * 2.0 * .pi * 1.5) // where parking orbit ended
            let angle = startAngle + Float(phaseProgress * .pi * 0.3)
            let radius: Float = 1.3 + Float(phaseProgress) * 0.5
            return SIMD3<Float>(
                cos(angle) * radius,
                sin(angle) * radius,
                Float(phaseProgress) * 0.2
            )

        case .translunarCoast:
            // Outbound transfer - curved path toward the Moon
            let t = Float(phaseProgress)
            // Bezier curve from near-Earth to near-Moon
            let p0 = SIMD3<Float>(1.5, 1.0, 0.2)    // post-TLI position
            let p1 = SIMD3<Float>(4.0, 3.0, 1.0)     // control point
            let p2 = SIMD3<Float>(7.0, 1.0, -0.5)     // control point
            let p3 = SIMD3<Float>(10.0, 0.0, 0.0)     // near Moon
            return cubicBezier(t: t, p0: p0, p1: p1, p2: p2, p3: p3)

        case .lunarFlyby:
            // Hyperbolic flyby around the Moon
            let angle = Float(.pi * 0.8 + phaseProgress * .pi * 1.2) // sweep around far side
            let moonPos = SIMD3<Float>(10.0, 0.0, 0.0)
            let flybyRadius: Float = 0.5
            let offset = SIMD3<Float>(
                cos(angle) * flybyRadius,
                sin(angle) * flybyRadius * 0.8,
                sin(angle) * 0.2
            )
            return moonPos + offset

        case .returnTransit:
            // Return transfer - curved path back to Earth
            let t = Float(phaseProgress)
            let p0 = SIMD3<Float>(10.0 + cos(Float(.pi * 2.0)) * 0.5,
                                   sin(Float(.pi * 2.0)) * 0.4, 0.1)
            let p1 = SIMD3<Float>(7.0, -2.0, 0.5)
            let p2 = SIMD3<Float>(4.0, -3.0, -0.5)
            let p3 = SIMD3<Float>(0.5, -0.5, 0.0)
            return cubicBezier(t: t, p0: p0, p1: p1, p2: p2, p3: p3)

        case .reentry:
            // Reentry approach
            let t = Float(phaseProgress)
            let startPos = SIMD3<Float>(0.5, -0.5, 0.0)
            let endPos = SIMD3<Float>(0.0, -5.0, 0.0)
            return mix(startPos, endPos, t: t)
        }
    }

    /// Generate the full trajectory path as an array of points for visualization
    static func generateTrajectoryPoints(count: Int = 500) -> [SIMD3<Float>] {
        var points: [SIMD3<Float>] = []
        let totalDuration = MissionConstants.totalMissionDuration

        for i in 0..<count {
            let t = Double(i) / Double(count - 1) * totalDuration
            let pos = spacecraftPosition(missionTime: t)
            points.append(pos)
        }

        return points
    }

    /// Generate trajectory points for a specific phase
    static func phaseTrajectoryPoints(phase: MissionPhase, count: Int = 100) -> [SIMD3<Float>] {
        var points: [SIMD3<Float>] = []
        let startTime = phase.startTime
        let duration = phase.durationSeconds

        for i in 0..<count {
            let t = startTime + Double(i) / Double(count - 1) * duration
            let pos = spacecraftPosition(missionTime: t)
            points.append(pos)
        }

        return points
    }

    // MARK: - Telemetry Computation

    /// Compute telemetry data for a given mission time
    static func computeTelemetry(missionTime: Double) -> TelemetryData {
        let phase = currentPhase(at: missionTime)
        let progress = phaseProgress(at: missionTime)

        var telemetry = TelemetryData.initial
        telemetry.missionElapsedTime = max(0, missionTime)

        switch phase {
        case .prelaunch:
            telemetry.altitude = 0
            telemetry.speed = 0
            telemetry.gForce = 1.0
            telemetry.fuelRemaining = 100

        case .launch:
            // Exponential ascent profile
            telemetry.altitude = progress * progress * MissionConstants.parkingOrbitAltitude
            telemetry.speed = progress * MissionConstants.orbitalVelocityLEO
            telemetry.gForce = 1.0 + progress * 1.5 // peaks at ~2.5G
            telemetry.fuelRemaining = 100 - progress * 70 // boosters use most fuel

        case .earthOrbit:
            telemetry.altitude = MissionConstants.parkingOrbitAltitude
            telemetry.speed = MissionConstants.orbitalVelocityLEO
            telemetry.gForce = 0.0 // microgravity
            telemetry.fuelRemaining = 30

        case .translunarInjection:
            telemetry.altitude = MissionConstants.parkingOrbitAltitude + progress * 500
            telemetry.speed = MissionConstants.orbitalVelocityLEO + progress * (MissionConstants.tliVelocity - MissionConstants.orbitalVelocityLEO)
            telemetry.gForce = 0.5 + progress * 1.0
            telemetry.fuelRemaining = 30 - progress * 20

        case .translunarCoast:
            // Speed decreases as we climb out of Earth's gravity well, then increases near Moon
            let earthInfluence = 1.0 - progress
            let moonInfluence = progress * progress
            telemetry.speed = MissionConstants.tliVelocity * earthInfluence * 0.3 +
                             MissionConstants.lunarFlybySpeed * moonInfluence + 0.8
            telemetry.altitude = MissionConstants.parkingOrbitAltitude +
                                progress * (MissionConstants.earthMoonDistance - MissionConstants.parkingOrbitAltitude)
            telemetry.gForce = 0.0
            telemetry.fuelRemaining = 10

        case .lunarFlyby:
            // Speed increases during flyby due to lunar gravity
            let closestApproach = sin(progress * .pi)
            telemetry.speed = MissionConstants.lunarFlybySpeed + closestApproach * 0.5
            telemetry.altitude = MissionConstants.earthMoonDistance - MissionConstants.moonRadius +
                                MissionConstants.lunarFlybyAltitude
            telemetry.gForce = 0.0
            telemetry.fuelRemaining = 10

        case .returnTransit:
            let earthInfluence = progress * progress
            telemetry.speed = MissionConstants.lunarFlybySpeed + earthInfluence *
                             (MissionConstants.reentrySpeed - MissionConstants.lunarFlybySpeed)
            telemetry.altitude = MissionConstants.earthMoonDistance * (1.0 - progress) +
                                120 * progress
            telemetry.gForce = 0.0
            telemetry.fuelRemaining = 5

        case .reentry:
            telemetry.speed = MissionConstants.reentrySpeed * (1.0 - progress * 0.99)
            telemetry.altitude = 120 * (1.0 - progress)
            // Skip reentry G-force profile: peaks, drops, peaks again
            let skipPhase = sin(progress * .pi * 2)
            telemetry.gForce = 1.0 + max(0, skipPhase) * MissionConstants.maxGForceReentry
            telemetry.fuelRemaining = 2
        }

        // Compute distances
        telemetry.distanceFromEarth = MissionConstants.earthRadius + telemetry.altitude
        telemetry.distanceFromMoon = max(
            MissionConstants.moonRadius,
            MissionConstants.earthMoonDistance - telemetry.altitude
        )

        return telemetry
    }

    // MARK: - Phase Helpers

    static func currentPhase(at missionTime: Double) -> MissionPhase {
        var elapsed: Double = 0
        for phase in MissionPhase.allCases {
            elapsed += phase.durationSeconds
            if missionTime < elapsed {
                return phase
            }
        }
        return .reentry
    }

    static func phaseProgress(at missionTime: Double) -> Double {
        var elapsed: Double = 0
        for phase in MissionPhase.allCases {
            let phaseEnd = elapsed + phase.durationSeconds
            if missionTime < phaseEnd {
                return max(0, min(1, (missionTime - elapsed) / phase.durationSeconds))
            }
            elapsed = phaseEnd
        }
        return 1.0
    }

    static func overallProgress(at missionTime: Double) -> Double {
        return min(1.0, max(0.0, missionTime / MissionConstants.totalMissionDuration))
    }

    // MARK: - Math Helpers

    private static func cubicBezier(t: Float, p0: SIMD3<Float>, p1: SIMD3<Float>,
                                     p2: SIMD3<Float>, p3: SIMD3<Float>) -> SIMD3<Float> {
        let u = 1.0 - t
        let tt = t * t
        let uu = u * u
        let uuu = uu * u
        let ttt = tt * t

        return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3
    }

    /// Compute orbital velocity at a given altitude above Earth
    static func orbitalVelocity(altitudeKm: Double) -> Double {
        let r = MissionConstants.earthRadius + altitudeKm
        return sqrt(MissionConstants.earthMu / r)
    }

    /// Compute escape velocity at a given distance from Earth's center
    static func escapeVelocity(distanceKm: Double) -> Double {
        return sqrt(2.0 * MissionConstants.earthMu / distanceKm)
    }

    /// Compute the period of a circular orbit at given altitude
    static func orbitalPeriod(altitudeKm: Double) -> Double {
        let r = MissionConstants.earthRadius + altitudeKm
        return 2.0 * .pi * sqrt(pow(r, 3) / MissionConstants.earthMu)
    }
}
