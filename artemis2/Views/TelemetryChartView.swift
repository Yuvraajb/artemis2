//
//  TelemetryChartView.swift
//  artemis2
//
//  Live telemetry history charts using Swift Charts.
//  Displays speed, altitude, and G-force over mission time.
//

import SwiftUI
import Charts

// MARK: - Chart Metric Picker

enum TelemetryMetric: String, CaseIterable, Identifiable {
    case speed = "Speed"
    case altitude = "Altitude"
    case gForce = "G-Force"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .speed: return "km/s"
        case .altitude: return "km"
        case .gForce: return "G"
        }
    }

    var icon: String {
        switch self {
        case .speed: return "gauge.with.dots.needle.33percent"
        case .altitude: return "arrow.up.to.line"
        case .gForce: return "arrow.down.circle"
        }
    }

    var color: Color {
        switch self {
        case .speed: return .cyan
        case .altitude: return .green
        case .gForce: return .orange
        }
    }

    func value(from snapshot: TelemetrySnapshot) -> Double {
        switch self {
        case .speed: return snapshot.speed
        case .altitude: return snapshot.altitude
        case .gForce: return snapshot.gForce
        }
    }
}

// MARK: - Telemetry Chart View

struct TelemetryChartView: View {
    let viewModel: MissionViewModel
    @State private var selectedMetric: TelemetryMetric = .speed
    @Environment(AccessibilitySettings.self) private var a11y

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan)
                Text("TELEMETRY HISTORY")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(a11y.secondaryTextOpacity))
                    .tracking(2)
                Spacer()
            }

            // Metric picker
            Picker("Metric", selection: $selectedMetric) {
                ForEach(TelemetryMetric.allCases) { metric in
                    Label(metric.rawValue, systemImage: metric.icon)
                        .tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Telemetry metric selector")

            // Chart
            if viewModel.telemetryHistory.count >= 2 {
                chartView
                    .frame(height: 140)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(selectedMetric.rawValue) chart showing \(viewModel.telemetryHistory.count) data points")
            } else {
                emptyState
                    .frame(height: 140)
            }

            // Current value callout
            currentValueCallout
        }
        .padding(12)
        .glassCard()
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart(viewModel.telemetryHistory) { snapshot in
            let hours = snapshot.missionTime / 3600
            let value = selectedMetric.value(from: snapshot)

            LineMark(
                x: .value("Time (h)", hours),
                y: .value(selectedMetric.rawValue, value)
            )
            .foregroundStyle(selectedMetric.color.gradient)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time (h)", hours),
                y: .value(selectedMetric.rawValue, value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [selectedMetric.color.opacity(0.2), selectedMetric.color.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.5))
                    .font(.system(size: 8, design: .monospaced))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3]))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.5))
                    .font(.system(size: 8, design: .monospaced))
            }
        }
        .chartXAxisLabel(position: .bottom, alignment: .trailing) {
            Text("Hours")
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.4))
        }
        .chartYAxisLabel(position: .leading, alignment: .top) {
            Text(selectedMetric.unit)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.2))
            Text("Start the mission to see telemetry data")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Current Value

    private var currentValueCallout: some View {
        HStack(spacing: 16) {
            metricPill(metric: .speed, value: viewModel.telemetry.speed, peak: viewModel.peakSpeed)
            metricPill(metric: .altitude, value: viewModel.telemetry.altitude, peak: viewModel.peakAltitude)
            metricPill(metric: .gForce, value: viewModel.telemetry.gForce, peak: viewModel.peakGForce)
        }
    }

    private func metricPill(metric: TelemetryMetric, value: Double, peak: Double) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: metric.icon)
                    .font(.system(size: 8))
                    .foregroundStyle(metric.color.opacity(0.7))
                Text(formatValue(value, metric: metric))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            if peak > 0 {
                Text("Peak: \(formatValue(peak, metric: metric))")
                    .font(.system(size: 7))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.rawValue): \(formatValue(value, metric: metric)) \(metric.unit)")
    }

    private func formatValue(_ value: Double, metric: TelemetryMetric) -> String {
        switch metric {
        case .speed: return String(format: "%.1f", value)
        case .altitude:
            if value > 10000 { return String(format: "%.0f", value) }
            return String(format: "%.1f", value)
        case .gForce: return String(format: "%.1f", value)
        }
    }
}

#Preview {
    TelemetryChartView(viewModel: MissionViewModel())
        .environment(AccessibilitySettings())
        .preferredColorScheme(.dark)
}
