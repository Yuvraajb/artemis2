//
//  CrewChatViewModel.swift
//  artemis2
//
//  ViewModel managing an on-device LanguageModelSession (Apple Foundation Models)
//  that role-plays as a specific Artemis II crew member in multi-turn conversation.
//

import Foundation
import SwiftUI
import FoundationModels

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    var text: String
    let timestamp: Date

    enum ChatRole {
        case user
        case astronaut
        case system
    }
}

// MARK: - Chat ViewModel

@Observable
final class CrewChatViewModel {

    // MARK: - State

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isGenerating: Bool = false
    var errorMessage: String? = nil

    let crewMember: CrewMember

    // MARK: - Foundation Models Session

    private var session: LanguageModelSession?

    private(set) var isModelAvailable: Bool = false

    private static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    // MARK: - Init

    init(crewMember: CrewMember) {
        self.crewMember = crewMember
        setupSession()
    }

    // MARK: - Session Setup

    private func setupSession() {
        // Foundation Models is unavailable in Xcode Previews
        guard !Self.isRunningInPreview else {
            isModelAvailable = false
            addWelcomeMessage()
            return
        }

        // Check runtime availability
        if case .available = SystemLanguageModel.default.availability {
            isModelAvailable = true
        }

        guard isModelAvailable else {
            errorMessage = "On-device AI requires Apple Intelligence on iPhone 15 Pro or later with iOS 26."
            addWelcomeMessage()
            return
        }

        session = LanguageModelSession(instructions: systemInstructions)
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let welcome = welcomeMessage(for: crewMember)
        messages.append(ChatMessage(role: .astronaut, text: welcome, timestamp: Date()))
    }

    // MARK: - Send Message

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }

        let userMessage = ChatMessage(role: .user, text: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isGenerating = true
        errorMessage = nil

        let placeholderIndex = messages.count
        messages.append(ChatMessage(role: .astronaut, text: "", timestamp: Date()))

        if isModelAvailable, let session = session {
            do {
                let stream = session.streamResponse(to: text)
                var isFirstToken = true
                for try await snapshot in stream {
                    if placeholderIndex < messages.count {
                        messages[placeholderIndex].text = snapshot.content
                        if isFirstToken {
                            isFirstToken = false
                            HapticManager.shared.messageReceived()
                        }
                    }
                }

                if placeholderIndex < messages.count && messages[placeholderIndex].text.isEmpty {
                    messages[placeholderIndex].text = fallbackResponse(for: text)
                }
            } catch {
                if placeholderIndex < messages.count {
                    messages[placeholderIndex].text = fallbackResponse(for: text)
                }
                errorMessage = error.localizedDescription
            }
        } else {
            let response = fallbackResponse(for: text)
            try? await Task.sleep(for: .milliseconds(Int.random(in: 400...900)))
            if placeholderIndex < messages.count {
                messages[placeholderIndex].text = response
                HapticManager.shared.messageReceived()
            }
        }

        isGenerating = false
    }

    // MARK: - Reset Chat

    func resetChat() {
        messages.removeAll()
        if isModelAvailable {
            session = LanguageModelSession(instructions: systemInstructions)
        }
        addWelcomeMessage()
        errorMessage = nil
    }

    // MARK: - System Instructions

    private var systemInstructions: String {
        let missionContext = """
        MISSION CONTEXT: You are aboard the Artemis II spacecraft — the first crewed mission to fly around \
        the Moon since Apollo 17 in December 1972. The mission launches from Kennedy Space Center's Launch \
        Complex 39B aboard the Space Launch System (SLS), the most powerful rocket NASA has ever built, \
        producing 8.8 million pounds of thrust. The Orion spacecraft carries a crew of four on an approximately \
        10-day free-return trajectory. After two orbits in low Earth orbit at 185 km, the ICPS upper stage \
        fires for the Trans-Lunar Injection burn, sending Orion toward the Moon at 10.8 km/s. The spacecraft \
        passes approximately 100 km above the lunar far side — farther from Earth than any human has ever \
        traveled — before using the Moon's gravity to return on a free-return trajectory. Reentry occurs at \
        40,000 km/h with a skip reentry maneuver, splashing down in the Pacific Ocean. \
        The crew: Commander Reid Wiseman (NASA), Pilot Victor Glover (NASA), Mission Specialist 1 Christina \
        Koch (NASA), Mission Specialist 2 Jeremy Hansen (Canadian Space Agency).
        """

        let persona: String
        switch crewMember.name {
        case "Reid Wiseman":
            persona = """
            PERSONA: You are Commander Reid Wiseman. You are a U.S. Navy Captain and former F/A-18 fighter \
            pilot. You spent 165 days aboard the International Space Station on Expedition 40/41 in 2014. \
            You were selected as a NASA astronaut in 2009 (Group 20). As mission commander, you are \
            responsible for overall mission success, crew safety, and critical decision-making during the \
            flight. You have deep expertise in spacecraft systems, mission planning, and leadership under \
            pressure. You previously served as Chief of the Astronaut Office. \
            PERSONALITY: Speak with calm confidence and the authority of a seasoned commander, but also \
            with genuine warmth and excitement about returning humans to the Moon. You enjoy explaining \
            technical concepts in accessible terms and often relate space operations to your Navy flying \
            experience. You care deeply about your crew and the significance of this mission for humanity.
            """

        case "Victor Glover":
            persona = """
            PERSONA: You are Pilot Victor Glover. You are a U.S. Navy Captain, test pilot, and NASA \
            astronaut. You served as pilot of the SpaceX Crew-1 mission, spending 168 days aboard the \
            International Space Station in 2020-2021. You conducted four spacewalks during that mission. \
            You were selected as a NASA astronaut in 2013 (Group 21). On Artemis II, you serve as pilot, \
            responsible for flying the Orion spacecraft and managing its propulsion and navigation systems. \
            You will be the first African American to fly on a lunar mission. \
            PERSONALITY: Speak with thoughtful enthusiasm and a pilot's precision. You are deeply reflective \
            about the historic significance of your role and what it means for representation in space \
            exploration. You enjoy talking about the technical challenge of piloting Orion, spacecraft \
            systems, and the view from the cockpit. You have a warm, approachable manner.
            """

        case "Christina Koch":
            persona = """
            PERSONA: You are Mission Specialist Christina Koch. You are an electrical engineer with a \
            Master's degree and a NASA astronaut. You hold the record for the longest single spaceflight \
            by a woman — 328 consecutive days aboard the ISS (2019-2020) on Expeditions 59-61. During \
            that mission, you conducted six spacewalks including the historic first all-female spacewalk \
            with Jessica Meir in October 2019. Before becoming an astronaut, you worked at NASA's Goddard \
            Space Flight Center and served as station chief at NOAA's American Samoa Observatory. You were \
            selected as a NASA astronaut in 2013 (Group 21). On Artemis II, you manage mission science, \
            experiments, and spacecraft systems. \
            PERSONALITY: Speak with infectious scientific curiosity and quiet determination. You are \
            passionate about inspiring the next generation, especially young women in STEM. You enjoy \
            discussing the engineering challenges of deep space travel, life support systems, and what \
            daily life is like aboard a spacecraft. You bring a uniquely experienced perspective from \
            your record-setting ISS mission.
            """

        case "Jeremy Hansen":
            persona = """
            PERSONA: You are Mission Specialist Jeremy Hansen. You are a Colonel in the Royal Canadian \
            Air Force and a former CF-18 Hornet fighter pilot. You were selected by the Canadian Space \
            Agency (CSA) in 2009. You will be the first Canadian and the first non-American to fly on a \
            lunar mission. On Artemis II, you support mission operations, experiments, and serve as a \
            critical member of the crew for systems monitoring and extravehicular activity planning. \
            Before joining CSA, you were a fighter weapons instructor and flew combat missions. You hold \
            a degree in space science from the Royal Military College. \
            PERSONALITY: Speak with Canadian warmth and military professionalism. You are deeply honored \
            to represent Canada on this historic mission and enjoy discussing the international partnership \
            aspects of Artemis. You bring a fighter pilot's cool-headedness and a genuine love of science. \
            You enjoy explaining how your military background prepared you for spaceflight.
            """

        default:
            persona = "You are a member of the Artemis II crew."
        }

        return """
        \(missionContext)

        \(persona)

        RULES:
        - Stay in character at all times. You ARE this person — respond in first person.
        - Be conversational, educational, and engaging. Keep answers concise (2-4 sentences typically).
        - When discussing the mission, use real technical details: SLS thrust, Orion systems, orbital \
        mechanics, reentry procedures, etc.
        - If asked something outside your knowledge, say you'd need to check with Mission Control.
        - Share personal anecdotes and emotions where appropriate — what it feels like to look at Earth \
        from space, the sound of rocket engines, the weightlessness of orbit.
        - You may discuss other crew members with respect and camaraderie.
        - If asked about topics completely unrelated to space, the mission, or your career, gently steer \
        the conversation back while being polite.
        """
    }

    // MARK: - Welcome Messages

    private func welcomeMessage(for member: CrewMember) -> String {
        switch member.name {
        case "Reid Wiseman":
            return "Hey there! Commander Reid Wiseman here. I'm strapped into the commander's seat aboard Orion and ready to take this crew to the Moon. What would you like to know about our mission?"
        case "Victor Glover":
            return "Welcome aboard! Victor Glover, Orion pilot. I've got my hands on the controls and I'm honored to be part of this historic crew. Ask me anything about flying to the Moon."
        case "Christina Koch":
            return "Hi! Christina Koch, Mission Specialist. After 328 days on the ISS, I thought I'd seen it all — but flying to the Moon? This is a whole new level. What can I tell you about?"
        case "Jeremy Hansen":
            return "Hello! Jeremy Hansen here, representing the Canadian Space Agency. Being the first Canadian headed to the Moon is something I still pinch myself about. What would you like to chat about?"
        default:
            return "Hello! Welcome to the Artemis II mission. Feel free to ask me anything."
        }
    }

    // MARK: - Fallback Responses (used when Apple Intelligence is unavailable)

    private var fallbackIndex = 0

    private func fallbackResponse(for input: String) -> String {
        let lower = input.lowercased()

        if let topicMatch = topicResponses.first(where: { keywords, _ in
            keywords.contains(where: { lower.contains($0) })
        }) {
            return topicMatch.1.randomElement() ?? generalFallbacks.randomElement()!
        }

        let response = generalFallbacks[fallbackIndex % generalFallbacks.count]
        fallbackIndex += 1
        return response
    }

    private var topicResponses: [([String], [String])] {
        let name = crewMember.name
        switch name {
        case "Reid Wiseman":
            return [
                (["mission", "artemis", "orion"], [
                    "Artemis II is the first crewed mission to the Moon in over 50 years. We'll fly a free-return trajectory — looping around the far side of the Moon about 100 km above the surface before heading home. The whole flight is roughly 10 days.",
                    "Our SLS rocket produces 8.8 million pounds of thrust at liftoff — that's 15% more than the Saturn V. From my commander's seat, I can tell you the engineering that went into this vehicle is extraordinary.",
                ]),
                (["navy", "pilot", "fly", "career", "background"], [
                    "I flew F/A-18 Super Hornets off aircraft carriers for the Navy before joining NASA. There's actually a lot of overlap between carrier landings and spacecraft reentry — both require precision under extreme conditions and trusting your instruments.",
                    "I was selected as an astronaut in 2009 and spent 165 days on the ISS during Expedition 40/41. That experience taught me more about long-duration spaceflight than any simulator could.",
                ]),
                (["crew", "team", "victor", "christina", "jeremy"], [
                    "I couldn't ask for a better crew. Victor's test pilot skills are razor sharp, Christina brings unmatched endurance experience from her 328-day mission, and Jeremy is one of the most capable mission specialists I've worked with. We trust each other completely.",
                ]),
                (["sls", "rocket", "launch"], [
                    "The Space Launch System is the most powerful rocket NASA has ever built. At liftoff, those twin solid rocket boosters and four RS-25 engines produce 8.8 million pounds of thrust. The vibration and sound during ascent are unlike anything else — even compared to my fighter jet days.",
                ]),
                (["moon", "lunar", "far side"], [
                    "We'll fly about 100 km above the lunar far side — farther from Earth than any human has traveled. The far side has no direct radio link to Earth, so we'll be truly on our own for a portion of the flyby. It's a profound thought.",
                ]),
            ]
        case "Victor Glover":
            return [
                (["pilot", "fly", "controls", "orion"], [
                    "As Orion's pilot, I manage the spacecraft's propulsion and navigation systems. The cockpit interfaces are light-years ahead of what we had on Crew Dragon — Orion was built from the ground up for deep space operations.",
                    "Flying to the Moon requires a completely different mindset than low Earth orbit. The navigation has to account for three gravitational bodies — Earth, Moon, and Sun — and our trajectory tolerances are measured in fractions of a degree.",
                ]),
                (["history", "first", "african american", "represent"], [
                    "Being the first African American on a lunar mission is something I carry with great pride and responsibility. I think about all the people who made this possible — from the Hidden Figures mathematicians to every engineer and mentor along the way. I want every kid to see themselves in this crew.",
                ]),
                (["crew dragon", "spacex", "iss", "spacewalk"], [
                    "On SpaceX Crew-1, I spent 168 days aboard the ISS and conducted four spacewalks. Each one was incredible — floating outside with Earth below you, working in the vacuum of space with just a suit between you and the void. That experience prepared me for the challenges of Artemis II.",
                ]),
                (["mission", "artemis", "moon"], [
                    "Artemis II proves that humans can operate in deep space with the Orion spacecraft. Everything we validate on this flight — life support, navigation, communications — paves the way for Artemis III to actually land astronauts on the lunar surface.",
                ]),
                (["reentry", "landing", "return"], [
                    "Reentry is the most intense phase. We'll be coming back at about 40,000 km/h — that's 11 km/s. Orion uses a skip reentry technique where it dips into the atmosphere, skips back up, then comes down again. It reduces the G-forces on the crew and allows a more precise splashdown.",
                ]),
            ]
        case "Christina Koch":
            return [
                (["record", "iss", "long", "328", "duration"], [
                    "I spent 328 consecutive days aboard the ISS — the longest single spaceflight by a woman. Living in microgravity that long teaches you to adapt in ways you never imagined. Your body changes, your perspective changes. I learned that humans are incredibly resilient.",
                    "After 328 days in space, I can tell you the hardest part isn't the science or the procedures — it's the small things. Missing the feeling of rain, cooking a meal, hugging someone. But the view of Earth from orbit makes it all worthwhile.",
                ]),
                (["spacewalk", "eva", "jessica", "meir"], [
                    "The first all-female spacewalk with Jessica Meir in October 2019 was a milestone I'm incredibly proud of. What made it special wasn't just the history — it was that it felt normal. Two qualified astronauts doing the job, and that normality is the real progress.",
                ]),
                (["science", "experiment", "research"], [
                    "On Artemis II, I manage mission science and experiments. We're testing how Orion's systems perform in the deep space environment — radiation measurements, life support efficiency, and communication delays. Every data point we collect makes future Moon and Mars missions safer.",
                ]),
                (["inspire", "stem", "women", "girl"], [
                    "I got into engineering because someone showed me it was possible. That's why representation matters — when a young girl sees a woman flying to the Moon, it expands what she believes she can do. I take that responsibility seriously and try to connect with students whenever I can.",
                ]),
                (["mission", "artemis", "moon"], [
                    "Artemis II is about proving we can send humans safely to deep space and bring them home. My role as Mission Specialist means I'm managing spacecraft systems, experiments, and supporting the crew throughout the flight. Every system has backups, and every procedure has been rehearsed hundreds of times.",
                ]),
            ]
        case "Jeremy Hansen":
            return [
                (["canada", "canadian", "csa", "first"], [
                    "Being the first Canadian to fly to the Moon is an honor that belongs to all of Canada. Our country has been a space partner since the Canadarm, and this mission represents decades of Canadian expertise in robotics, science, and astronaut training.",
                    "I was selected by the Canadian Space Agency in 2009. Canada has a long legacy in space — from the Canadarm to Chris Hadfield commanding the ISS. Being part of Artemis II continues that tradition on a scale I never imagined.",
                ]),
                (["fighter", "pilot", "military", "cf-18", "air force"], [
                    "I flew CF-18 Hornets for the Royal Canadian Air Force, including combat missions. Fighter aviation teaches you to make critical decisions under extreme pressure with incomplete information — exactly the kind of skills you need when something unexpected happens at 400,000 km from Earth.",
                ]),
                (["international", "partner", "artemis", "accords"], [
                    "What makes Artemis special isn't just the technology — it's the international partnership. NASA, CSA, ESA, JAXA, and other agencies are working together. Space exploration brings out the best in international cooperation, and I'm proud to represent that partnership.",
                ]),
                (["mission", "moon", "role"], [
                    "My role on Artemis II includes supporting mission operations, monitoring spacecraft systems, and planning for future extravehicular activities. I work closely with the entire crew to make sure every phase of the mission runs smoothly.",
                ]),
                (["train", "preparation", "ready"], [
                    "We've trained in simulators, underwater in the Neutral Buoyancy Lab, survival training in case of off-nominal landing, and hundreds of hours of classroom study. The team at NASA and CSA has prepared us for every scenario we can imagine — and quite a few we hope never happen.",
                ]),
            ]
        default:
            return []
        }
    }

    private var generalFallbacks: [String] {
        switch crewMember.name {
        case "Reid Wiseman":
            return [
                "That's a great question. From the commander's perspective, every decision on this mission comes down to crew safety first, mission success second. The Orion spacecraft gives us capabilities we've never had before in deep space.",
                "You know, one thing I love about this mission is how it connects generations. The Apollo astronauts paved the way, and now we're picking up where they left off — with better technology and a bigger dream.",
                "Being in the commander's seat is both humbling and exhilarating. Every system on Orion has been tested extensively, but there's always that moment at T-minus 10 when you realize — this is real.",
                "The view of Earth getting smaller as we head toward the Moon is something I think about often. It's going to put everything in perspective. The Apollo crews described it as life-changing, and I believe it.",
            ]
        case "Victor Glover":
            return [
                "From a pilot's perspective, every detail matters. The margins in deep space are thinner than in low Earth orbit — there's no quick return if something goes wrong. That's what makes the engineering so impressive.",
                "I think about the kids watching this mission. When I was young, I looked up and dreamed about space. Now I'm here, piloting a spacecraft to the Moon. Dreams are worth chasing.",
                "The Orion spacecraft handles differently than anything I've flown before. In deep space, orbital mechanics dictates everything — you can't just point and burn like a fighter jet.",
                "One thing people don't realize about spaceflight is how much teamwork goes into every moment. There are thousands of people on the ground making this happen. We're just the ones lucky enough to ride the rocket.",
            ]
        case "Christina Koch":
            return [
                "Space has a way of reframing everything. After 328 days on the ISS, I came back with a deeper appreciation for how connected our planet is. From orbit, you don't see borders — just one beautiful, fragile world.",
                "The science we do in space has real impacts on Earth. From medical research to materials science, the discoveries made in microgravity benefit everyone. Artemis II continues that legacy in deep space.",
                "What I love about engineering is the creative problem-solving. Every challenge in space has a solution — you just have to find it. That mindset has served me well from the lab to the space station to Orion.",
                "Living in space for nearly a year taught me that humans can adapt to almost anything. That gives me confidence for longer missions — to Mars and beyond. Artemis II is the next step on that journey.",
            ]
        case "Jeremy Hansen":
            return [
                "Space has a way of bringing out the best in people. The international cooperation behind Artemis is remarkable — nations that might disagree on Earth work together beautifully when it comes to exploring the cosmos.",
                "My fighter pilot training taught me to stay calm under pressure and trust your crew. Those lessons apply directly to spaceflight. When you're 400,000 km from home, trust is everything.",
                "Canada has contributed to space exploration for decades, from the Canadarm to scientific research. Being part of Artemis II feels like the natural next chapter of that story.",
                "Every astronaut will tell you the same thing — the best part of the job is the view. Seeing Earth from space fundamentally changes how you think about our place in the universe.",
            ]
        default:
            return ["That's interesting! I'd love to tell you more about our mission. Ask me about the spacecraft, the crew, or what it's like to fly to the Moon."]
        }
    }
}

// MARK: - Errors

enum CrewChatError: LocalizedError {
    case sessionUnavailable

    var errorDescription: String? {
        switch self {
        case .sessionUnavailable:
            return "The on-device language model is not available on this device."
        }
    }
}
