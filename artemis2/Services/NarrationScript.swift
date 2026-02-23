//
//  NarrationScript.swift
//  artemis2
//
//  Complete narration script for the mission audio guide.
//  Every cue is written as calm, measured mission-commander prose.
//  Covers all mission phases, milestones, and app features.
//

import Foundation

struct TimedNarration {
    let time: Double
    let id: String
    let text: String
}

enum NarrationScript {

    // MARK: - Time-Based Cues (sorted by mission time)

    static let timeCues: [TimedNarration] = [

        // ── Prelaunch ──────────────────────────────────────────────

        TimedNarration(
            time: -550, id: "welcome",
            text: "Welcome aboard Orion. I'll be your guide for the Artemis II mission — humanity's return to the Moon. The three-D view in front of you shows our spacecraft at Kennedy Space Center. Pinch and rotate to explore the trajectory from any angle."
        ),

        TimedNarration(
            time: -420, id: "feat_telemetry",
            text: "The telemetry dashboard shows live speed, altitude, G-force, and fuel data. Below that, real-time charts track the full history of each metric throughout the flight."
        ),

        TimedNarration(
            time: -300, id: "feat_timeline",
            text: "Switch to the Timeline tab to see every phase of the mission laid out. Tap any phase for educational details, or use the skip button to jump ahead to key moments."
        ),

        TimedNarration(
            time: -180, id: "feat_crew",
            text: "The Crew tab shows our four astronauts — Commander Reid Wiseman, Pilot Victor Glover, and Mission Specialists Christina Koch and Jeremy Hansen. Tap any crew member to chat with them. Each conversation is powered by on-device AI with their own personality."
        ),

        TimedNarration(
            time: -70, id: "feat_timewarp",
            text: "Use the time controls at the bottom to speed up the simulation. The full mission takes nearly ten days, so time warp will be essential during the coast phases. Ready for launch."
        ),

        // ── Post-launch, pre-TLI ──────────────────────────────────

        TimedNarration(
            time: 620, id: "feat_charts",
            text: "Watch the telemetry charts update in real time. You can switch between speed, altitude, and G-force to see how each metric evolves through the flight."
        ),

        TimedNarration(
            time: 11700, id: "challenge_tli_prep",
            text: "Heads up — your first mission challenge is approaching. The Trans-Lunar Injection burn requires precise timing. When the challenge appears, move the slider into the green zone and tap Execute."
        ),

        // ── Translunar Coast ───────────────────────────────────────

        TimedNarration(
            time: 15000, id: "feat_crewchat",
            text: "This is a good time to visit the Crew tab. Ask Reid about commanding this historic mission, or talk to Jeremy about being the first Canadian on a lunar flight. Every astronaut has their own story."
        ),

        TimedNarration(
            time: 50000, id: "coast_timewarp",
            text: "The coast to the Moon takes about four days. Feel free to increase time warp to move through it faster — or stay at real-time and watch Earth slowly shrink behind us."
        ),

        TimedNarration(
            time: 100000, id: "coast_educational",
            text: "We're in a free-return trajectory — a path that guarantees we swing around the Moon and come back to Earth, even without firing the engines. It's a built-in safety feature, first used by Apollo eight."
        ),

        TimedNarration(
            time: 200000, id: "feat_accessibility",
            text: "The Settings tab has accessibility options — high contrast, color blind modes, text scaling, and reduced motion. This experience is designed to be enjoyed by everyone."
        ),

        TimedNarration(
            time: 300000, id: "coast_deep",
            text: "We've been traveling for about three and a half days. The Earth is now a small blue marble behind us. Radio signals take over a second to make the round trip."
        ),

        TimedNarration(
            time: 350000, id: "moon_approach",
            text: "We're entering the Moon's gravitational influence. The lunar surface is becoming visible ahead. Only twenty-four humans have ever seen this view with their own eyes."
        ),

        // ── Lunar Flyby ────────────────────────────────────────────

        TimedNarration(
            time: 357880, id: "flyby_start",
            text: "Beginning the lunar flyby sequence. We're about to fly closer to the Moon than any human in over fifty years. This is the peak of the Artemis II mission."
        ),

        TimedNarration(
            time: 359400, id: "challenge_flyby_prep",
            text: "Your next challenge — set the flyby altitude. Aim for the safe corridor between eighty and one hundred twenty kilometers above the lunar surface. Too low is dangerous. Too high wastes the science opportunity."
        ),

        // ── Return Transit ─────────────────────────────────────────

        TimedNarration(
            time: 361480, id: "return_start",
            text: "The Moon's gravity has redirected us back toward Earth. Five and a half days of coast ahead. The crew will run experiments and prepare for the most dangerous part of the mission — reentry."
        ),

        TimedNarration(
            time: 450000, id: "return_reflection",
            text: "Everything in this experience — the three-D models, the orbital physics, the procedural shaders, the crew conversations, even this ambient sound — is generated entirely from code. No pre-built assets. Just math and creativity."
        ),

        TimedNarration(
            time: 600000, id: "feat_missioncomplete",
            text: "When we reach splashdown, you'll see a full mission summary — your challenge scores, peak telemetry values, and an overall mission rating. You can share the results with anyone."
        ),

        TimedNarration(
            time: 830000, id: "earth_approach",
            text: "Earth is growing larger. We're almost home. The crew is preparing for reentry at forty thousand kilometers per hour — Mach thirty-two."
        ),

        TimedNarration(
            time: 836400, id: "challenge_reentry_prep",
            text: "Final challenge ahead. The reentry angle is critical — between minus five-point-five and minus seven-point-five degrees. Too shallow, you skip off into space forever. Too steep, the G-forces become lethal. This is the moment that matters."
        ),
    ]

    // MARK: - Milestone-Based Cues

    static func milestoneCue(for name: String) -> (id: String, text: String)? {
        milestoneCues[name]
    }

    private static let milestoneCues: [String: (id: String, text: String)] = [
        "Engine Ignition": (
            id: "m_ignition",
            text: "Liftoff. Artemis II is go. Eight-point-eight million pounds of thrust from the most powerful rocket NASA has ever built, carrying four astronauts toward the Moon."
        ),
        "Max-Q": (
            id: "m_maxq",
            text: "Max Q — maximum aerodynamic pressure. The vehicle is pushing through the densest part of the atmosphere. This is the moment of peak structural stress."
        ),
        "Booster Separation": (
            id: "m_booster",
            text: "Solid rocket boosters separated after two minutes of burn. The ride just got much smoother."
        ),
        "Core Stage Separation": (
            id: "m_corestage",
            text: "Core stage separation confirmed. The Interim Cryogenic Propulsion Stage is now in control, guiding us toward orbit."
        ),
        "Orbit Insertion": (
            id: "m_orbit",
            text: "Orbit achieved. One hundred eighty-five kilometers above Earth, traveling at seven-point-eight kilometers per second. The crew is in stable Low Earth Orbit."
        ),
        "TLI Burn": (
            id: "m_tli",
            text: "Trans-Lunar Injection burn is underway. Accelerating from orbital velocity to escape velocity — ten-point-eight kilometers per second. Next stop, the Moon."
        ),
        "ICPS Separation": (
            id: "m_icps",
            text: "ICPS separated. Orion is flying free on a four-day coast through cislunar space."
        ),
        "Halfway to Moon": (
            id: "m_halfway",
            text: "Halfway to the Moon. Earth and the Moon are roughly equidistant now. We're deep in cislunar space, farther from home than almost anyone has ever been."
        ),
        "Lunar Closest Approach": (
            id: "m_closest",
            text: "Closest approach — one hundred kilometers above the lunar far side. We are now farther from Earth than any human has ever traveled. Over four hundred thousand kilometers from home."
        ),
        "Farthest from Earth": (
            id: "m_farthest",
            text: "Maximum distance from Earth. Take a moment to let that settle. The entire history of human civilization is on that small blue dot behind us."
        ),
        "Entry Interface": (
            id: "m_entry",
            text: "Entry interface. Orion has contacted Earth's atmosphere at Mach thirty-two. The heat shield is absorbing twenty-seven hundred degrees Celsius."
        ),
        "Skip Maneuver": (
            id: "m_skip",
            text: "Skip maneuver complete. Orion bounced off the upper atmosphere, reducing peak G-forces from nine G down to a survivable four. A technique never used on a crewed vehicle before Artemis."
        ),
        "Splashdown": (
            id: "m_splash",
            text: "Splashdown. Orion is in the Pacific Ocean. The crew of Artemis II has returned safely to Earth. Welcome home."
        ),
    ]
}
