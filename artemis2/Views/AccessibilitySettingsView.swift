//
//  AccessibilitySettingsView.swift
//  artemis2
//
//  In-app accessibility settings panel with live previews.
//  Users can toggle visual accessibility features without leaving the app.
//

import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(AccessibilitySettings.self) private var a11y

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.02, green: 0.02, blue: 0.08)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    settingsHeader

                    // Settings toggles
                    settingsToggles

                    // Live preview
                    livePreviewSection

                    // Info footer
                    infoFooter

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "accessibility")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 16)

            Text("ACCESSIBILITY")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))
                .tracking(4)

            Text("Customize Your Experience")
                .font(.system(size: a11y.scaled(18), weight: .bold))
                .foregroundStyle(.white)

            Text("These settings are saved automatically\nand persist between sessions.")
                .font(.system(size: a11y.scaled(12)))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Settings Toggles

    private var settingsToggles: some View {
        @Bindable var settings = a11y
        return VStack(spacing: 12) {
            AccessibilityToggleRow(
                icon: "figure.walk.motion",
                title: "Reduce Motion",
                subtitle: "Minimizes animations and transitions throughout the app",
                isOn: $settings.reduceMotion,
                accentColor: .orange
            )

            AccessibilityToggleRow(
                icon: "circle.lefthalf.filled",
                title: "High Contrast",
                subtitle: "Increases text brightness and border visibility",
                isOn: $settings.highContrast,
                accentColor: .cyan
            )

            AccessibilityToggleRow(
                icon: "textformat.size.larger",
                title: "Larger Text",
                subtitle: "Scales up text for improved readability",
                isOn: $settings.largerText,
                accentColor: .green
            )

            AccessibilityToggleRow(
                icon: "eye.trianglebadge.exclamationmark",
                title: "Color Blind Mode",
                subtitle: "Uses blue/orange instead of red/green indicators",
                isOn: $settings.colorBlindMode,
                accentColor: .purple
            )
        }
    }

    // MARK: - Live Preview

    private var livePreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan)
                Text("LIVE PREVIEW")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))
                    .tracking(2)
                Spacer()
            }

            // Color preview
            colorPreview

            // Text preview
            textPreview

            // Gauge preview
            gaugePreview
        }
    }

    private var colorPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status Indicators")
                .font(.system(size: a11y.scaled(12), weight: .bold))
                .foregroundStyle(.white.opacity(a11y.textOpacity))

            HStack(spacing: 12) {
                statusPill(label: "Safe", color: a11y.safeColor)
                statusPill(label: "Warning", color: a11y.warningColor)
                statusPill(label: "Danger", color: a11y.dangerColor)
                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(a11y.glassOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(a11y.borderOpacity), lineWidth: a11y.highContrast ? 1.5 : 1)
                )
        )
    }

    private func statusPill(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: a11y.scaled(11), weight: .medium))
                .foregroundStyle(.white.opacity(a11y.textOpacity))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(a11y.highContrast ? 0.5 : 0.2), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) status indicator, color: \(a11y.colorBlindMode ? (color == a11y.safeColor ? "blue" : (color == a11y.dangerColor ? "orange" : "yellow")) : (color == .green ? "green" : (color == .red ? "red" : "yellow")))")
    }

    private var textPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Text Readability")
                .font(.system(size: a11y.scaled(12), weight: .bold))
                .foregroundStyle(.white.opacity(a11y.textOpacity))

            Text("Primary text appears at this brightness and size.")
                .font(.system(size: a11y.scaled(13)))
                .foregroundStyle(.white.opacity(a11y.textOpacity))

            Text("Secondary text is dimmer — this is how labels and captions look.")
                .font(.system(size: a11y.scaled(11)))
                .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))

            Text("T+ 00:04:32:15")
                .font(.system(size: a11y.scaled(16), weight: .bold, design: .monospaced))
                .foregroundStyle(.green)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(a11y.glassOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(a11y.borderOpacity), lineWidth: a11y.highContrast ? 1.5 : 1)
                )
        )
    }

    private var gaugePreview: some View {
        HStack(spacing: 16) {
            // Safe gauge
            previewGauge(value: 0.7, label: "Safe", color: a11y.safeColor)
            // Warning gauge
            previewGauge(value: 0.5, label: "Caution", color: a11y.warningColor)
            // Danger gauge
            previewGauge(value: 0.9, label: "Danger", color: a11y.dangerColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(a11y.glassOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(a11y.borderOpacity), lineWidth: a11y.highContrast ? 1.5 : 1)
                )
        )
    }

    private func previewGauge(value: Double, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(a11y.highContrast ? 0.3 : 0.15), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f%%", value * 100))
                    .font(.system(size: a11y.scaled(12), weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.system(size: a11y.scaled(9), weight: .medium))
                .foregroundStyle(.white.opacity(a11y.textOpacity))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) preview gauge, \(Int(value * 100)) percent")
    }

    // MARK: - Info Footer

    private var infoFooter: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.06), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))

                Text("VoiceOver support is always active. Enable VoiceOver in iOS Settings > Accessibility for full screen reader support.")
                    .font(.system(size: a11y.scaled(10)))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 4)

            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))

                Text("This app also respects your system-level Reduce Motion preference from iOS Settings.")
                    .font(.system(size: a11y.scaled(10)))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Toggle Row Component

struct AccessibilityToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var accentColor: Color = .cyan

    @Environment(AccessibilitySettings.self) private var a11y

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(isOn ? accentColor : .white.opacity(0.4))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? accentColor.opacity(0.15) : Color.white.opacity(0.05))
                )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: a11y.scaled(14), weight: .semibold))
                    .foregroundStyle(.white.opacity(a11y.textOpacity))

                Text(subtitle)
                    .font(.system(size: a11y.scaled(11)))
                    .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))
                    .lineLimit(2)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(a11y.glassOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isOn ? accentColor.opacity(a11y.highContrast ? 0.4 : 0.2)
                                 : Color.white.opacity(a11y.borderOpacity),
                            lineWidth: a11y.highContrast ? 1.5 : 1
                        )
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityValue(isOn ? "Enabled" : "Disabled")
        .accessibilityHint("Double tap to \(isOn ? "disable" : "enable")")
    }
}

#Preview {
    AccessibilitySettingsView()
        .environment(AccessibilitySettings())
}
