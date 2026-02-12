//
//  AccessibilitySettings.swift
//  artemis2
//
//  In-app accessibility preferences with persistent storage.
//  Provides reduce motion, high contrast, larger text, and color blind mode.
//

import SwiftUI

@Observable
final class AccessibilitySettings {
    // MARK: - Persisted Preferences

    /// Reduces or removes animations throughout the app.
    var reduceMotion: Bool {
        didSet { UserDefaults.standard.set(reduceMotion, forKey: "a11y_reduceMotion") }
    }

    /// Increases contrast of text, borders, and backgrounds.
    var highContrast: Bool {
        didSet { UserDefaults.standard.set(highContrast, forKey: "a11y_highContrast") }
    }

    /// Scales up font sizes for better readability.
    var largerText: Bool {
        didSet { UserDefaults.standard.set(largerText, forKey: "a11y_largerText") }
    }

    /// Replaces red/green indicators with blue/orange for color blind users.
    var colorBlindMode: Bool {
        didSet { UserDefaults.standard.set(colorBlindMode, forKey: "a11y_colorBlindMode") }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.reduceMotion = defaults.bool(forKey: "a11y_reduceMotion")
        self.highContrast = defaults.bool(forKey: "a11y_highContrast")
        self.largerText = defaults.bool(forKey: "a11y_largerText")
        self.colorBlindMode = defaults.bool(forKey: "a11y_colorBlindMode")
    }

    // MARK: - Convenience Helpers

    /// Returns an appropriate animation, or nil if motion is reduced.
    func animation<V: Equatable>(_ base: Animation, value: V) -> Animation? {
        reduceMotion ? nil : base
    }

    /// Safe color: green normally, blue in color blind mode.
    var safeColor: Color {
        colorBlindMode ? .blue : .green
    }

    /// Danger color: red normally, orange in color blind mode.
    var dangerColor: Color {
        colorBlindMode ? .orange : .red
    }

    /// Warning color: always yellow (accessible for most color blindness types).
    var warningColor: Color {
        .yellow
    }

    /// Success color for passed results.
    var successColor: Color {
        colorBlindMode ? .blue : .green
    }

    /// Failure color for failed results.
    var failureColor: Color {
        colorBlindMode ? .orange : .red
    }

    /// Opacity boost for high contrast mode.
    var textOpacity: Double {
        highContrast ? 1.0 : 0.7
    }

    /// Secondary text opacity.
    var secondaryTextOpacity: Double {
        highContrast ? 0.8 : 0.5
    }

    /// Border opacity for glass cards and containers.
    var borderOpacity: Double {
        highContrast ? 0.25 : 0.08
    }

    /// Glass card fill opacity.
    var glassOpacity: Double {
        highContrast ? 0.25 : 0.12
    }

    /// Font size multiplier for larger text mode.
    var fontScale: CGFloat {
        largerText ? 1.2 : 1.0
    }

    /// Scaled font size helper.
    func scaled(_ size: CGFloat) -> CGFloat {
        size * fontScale
    }
}
