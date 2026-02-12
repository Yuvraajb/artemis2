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

        // Add user message
        let userMessage = ChatMessage(role: .user, text: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isGenerating = true
        errorMessage = nil

        // Create a placeholder for the astronaut response
        let placeholderIndex = messages.count
        messages.append(ChatMessage(role: .astronaut, text: "", timestamp: Date()))

        do {
            guard let session = session else {
                throw CrewChatError.sessionUnavailable
            }

            // Use streaming for a responsive typing effect
            let stream = session.streamResponse(to: text)
            for try await snapshot in stream {
                if placeholderIndex < messages.count {
                    messages[placeholderIndex].text = snapshot.content
                }
            }

            // If response ended up empty, show a fallback
            if placeholderIndex < messages.count && messages[placeholderIndex].text.isEmpty {
                messages[placeholderIndex].text = "I'm having trouble responding right now. Could you try asking again?"
            }
        } catch {
            if placeholderIndex < messages.count {
                messages[placeholderIndex].text = "Sorry, I couldn't process that. Please try again."
            }
            errorMessage = error.localizedDescription
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
