//
//  CrewChatView.swift
//  artemis2
//
//  Chat interface for conversing with individual Artemis II crew members.
//  Uses Apple's Foundation Models framework for on-device AI responses.
//

import SwiftUI

struct CrewChatView: View {
    @State var viewModel: CrewChatViewModel
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(crewMember: CrewMember) {
        _viewModel = State(initialValue: CrewChatViewModel(crewMember: crewMember))
    }

    /// Whether to show the bouncing-dots indicator:
    /// only while generating AND the placeholder bubble is still empty (no tokens yet).
    private var showTypingDots: Bool {
        guard viewModel.isGenerating,
              let last = viewModel.messages.last,
              last.role == .astronaut else { return false }
        return last.text.isEmpty
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()

            if viewModel.isModelAvailable {
                chatContent
            } else {
                unavailableView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                astronautHeader
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.resetChat() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            // Hide the placeholder bubble while it's still empty
                            if !(message.text.isEmpty && message.role == .astronaut) {
                                ChatBubble(
                                    message: message,
                                    astronautName: viewModel.crewMember.name,
                                    isStreaming: viewModel.isGenerating && message.id == viewModel.messages.last?.id && message.role == .astronaut
                                )
                                .id(message.id)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }

                        // Bouncing dots — only before first token arrives
                        if showTypingDots {
                            TypingDotsIndicator()
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                                .id("typing-dots")
                        }

                        // Invisible scroll anchor
                        Color.clear.frame(height: 1).id("scroll-bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .animation(.easeOut(duration: 0.25), value: viewModel.messages.count)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.messages.last?.text) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: showTypingDots) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            // Input bar
            chatInputBar
        }
    }

    // MARK: - Input Bar

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about the mission...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .lineLimit(1...4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .focused($isInputFocused)
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }

            // Send button
            Button(action: {
                Task { await viewModel.sendMessage() }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? .white.opacity(0.2)
                        : .cyan
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.white.opacity(0.08)),
                    alignment: .top
                )
        )
    }

    // MARK: - Header

    private var astronautHeader: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.crewMember.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(viewModel.crewMember.role)
                    .font(.system(size: 10))
                    .foregroundStyle(.cyan.opacity(0.8))
            }
        }
    }

    // MARK: - Astronaut Avatar (reusable)

    private var astronautAvatarSmall: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 28, height: 28)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))

            Text("On-Device AI Required")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Chatting with the crew requires Apple Intelligence and the Foundation Models framework. This feature is available on iPhone 15 Pro or later running iOS 26.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Typing Dots Indicator (self-contained animation)

struct TypingDotsIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(animating ? 0.6 : 0.25))
                        .frame(width: 7, height: 7)
                        .scaleEffect(animating ? 1.0 : 0.6)
                        .offset(y: animating ? -5 : 1)
                        .animation(
                            .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.18),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )

            Spacer()
        }
        .padding(.leading, 4)
        .onAppear {
            // Trigger the animation on next run-loop tick so SwiftUI sees the transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animating = true
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    let astronautName: String
    var isStreaming: Bool = false

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 50)
            } else {
                astronautAvatar
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser {
                    Text(astronautName.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.cyan.opacity(0.7))
                }

                HStack(alignment: .bottom, spacing: 0) {
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(isUser ? 1.0 : 0.9))

                    // Blinking cursor while streaming
                    if isStreaming && !message.text.isEmpty {
                        StreamingCursor()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .textSelection(.enabled)
                .animation(.easeOut(duration: 0.15), value: message.text)
            }

            if !isUser {
                Spacer(minLength: 50)
            }
        }
    }

    private var bubbleBackground: some View {
        Group {
            if isUser {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cyan.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            }
        }
    }

    private var astronautAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 28, height: 28)
            Image(systemName: "person.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Streaming Cursor (blinking bar while tokens arrive)

struct StreamingCursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Color.cyan)
            .frame(width: 2, height: 14)
            .opacity(visible ? 1 : 0)
            .padding(.leading, 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CrewChatView(crewMember: CrewMember.artemisIICrew[0])
    }
    .preferredColorScheme(.dark)
}
