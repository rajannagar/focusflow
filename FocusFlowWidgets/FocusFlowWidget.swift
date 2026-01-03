import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct FocusFlowWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetDataProvider.WidgetData
}

// MARK: - Widget Provider

struct FocusFlowWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> FocusFlowWidgetEntry {
        FocusFlowWidgetEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusFlowWidgetEntry) -> Void) {
        let entry = FocusFlowWidgetEntry(date: Date(), data: WidgetDataProvider.readData())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusFlowWidgetEntry>) -> Void) {
        let currentDate = Date()
        let data = WidgetDataProvider.readData()
        let entry = FocusFlowWidgetEntry(date: currentDate, data: data)
        
        let refreshInterval: TimeInterval = data.isSessionActive && !data.activeSessionIsPaused ? 60 : 5 * 60
        let refreshDate = currentDate.addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Main Widget View (Size Switcher)

struct FocusFlowWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: FocusFlowWidgetEntry
    
    var body: some View {
        Group {
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetContent(entry: entry)
            case .systemMedium:
                MediumWidgetContent(entry: entry)
            default:
                SmallWidgetContent(entry: entry)
            }
        }
    }
}

// MARK: - Theme

struct WidgetTheme {
    let top: Color
    let bottom: Color
    let accent: Color
    let accentSecondary: Color
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [top, bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func theme(for id: String) -> WidgetTheme {
        switch id {
        case "forest":
            return WidgetTheme(
                top: Color(red: 0.05, green: 0.11, blue: 0.09),
                bottom: Color(red: 0.13, green: 0.22, blue: 0.18),
                accent: Color(red: 0.55, green: 0.90, blue: 0.70),
                accentSecondary: Color(red: 0.42, green: 0.78, blue: 0.62)
            )
        case "neon":
            return WidgetTheme(
                top: Color(red: 0.02, green: 0.05, blue: 0.12),
                bottom: Color(red: 0.13, green: 0.02, blue: 0.24),
                accent: Color(red: 0.25, green: 0.95, blue: 0.85),
                accentSecondary: Color(red: 0.60, green: 0.40, blue: 1.00)
            )
        case "peach":
            return WidgetTheme(
                top: Color(red: 0.16, green: 0.08, blue: 0.11),
                bottom: Color(red: 0.31, green: 0.15, blue: 0.18),
                accent: Color(red: 1.00, green: 0.72, blue: 0.63),
                accentSecondary: Color(red: 1.00, green: 0.85, blue: 0.70)
            )
        case "cyber":
            return WidgetTheme(
                top: Color(red: 0.06, green: 0.04, blue: 0.18),
                bottom: Color(red: 0.18, green: 0.09, blue: 0.32),
                accent: Color(red: 0.80, green: 0.60, blue: 1.00),
                accentSecondary: Color(red: 0.38, green: 0.86, blue: 1.00)
            )
        case "ocean":
            return WidgetTheme(
                top: Color(red: 0.02, green: 0.08, blue: 0.15),
                bottom: Color(red: 0.03, green: 0.27, blue: 0.32),
                accent: Color(red: 0.48, green: 0.84, blue: 1.00),
                accentSecondary: Color(red: 0.23, green: 0.95, blue: 0.96)
            )
        case "sunrise":
            return WidgetTheme(
                top: Color(red: 0.10, green: 0.06, blue: 0.20),
                bottom: Color(red: 0.33, green: 0.17, blue: 0.24),
                accent: Color(red: 1.00, green: 0.62, blue: 0.63),
                accentSecondary: Color(red: 1.00, green: 0.80, blue: 0.55)
            )
        case "amber":
            return WidgetTheme(
                top: Color(red: 0.10, green: 0.06, blue: 0.04),
                bottom: Color(red: 0.30, green: 0.18, blue: 0.10),
                accent: Color(red: 1.00, green: 0.78, blue: 0.45),
                accentSecondary: Color(red: 1.00, green: 0.60, blue: 0.40)
            )
        case "mint":
            return WidgetTheme(
                top: Color(red: 0.02, green: 0.10, blue: 0.09),
                bottom: Color(red: 0.08, green: 0.30, blue: 0.26),
                accent: Color(red: 0.60, green: 0.96, blue: 0.78),
                accentSecondary: Color(red: 0.46, green: 0.88, blue: 0.92)
            )
        case "royal":
            return WidgetTheme(
                top: Color(red: 0.05, green: 0.05, blue: 0.16),
                bottom: Color(red: 0.11, green: 0.17, blue: 0.32),
                accent: Color(red: 0.65, green: 0.72, blue: 1.00),
                accentSecondary: Color(red: 0.50, green: 0.60, blue: 1.00)
            )
        case "slate":
            return WidgetTheme(
                top: Color(red: 0.06, green: 0.07, blue: 0.11),
                bottom: Color(red: 0.16, green: 0.18, blue: 0.24),
                accent: Color(red: 0.75, green: 0.82, blue: 0.96),
                accentSecondary: Color(red: 0.70, green: 0.76, blue: 0.90)
            )
        default:
            return WidgetTheme(
                top: Color(red: 0.05, green: 0.11, blue: 0.09),
                bottom: Color(red: 0.13, green: 0.22, blue: 0.18),
                accent: Color(red: 0.55, green: 0.90, blue: 0.70),
                accentSecondary: Color(red: 0.42, green: 0.78, blue: 0.62)
            )
        }
    }
}

// MARK: - Background

struct WidgetBackground: View {
    let theme: WidgetTheme
    
    var body: some View {
        ZStack {
            theme.backgroundGradient
            
            RadialGradient(
                colors: [theme.accent.opacity(0.15), theme.accent.opacity(0.03), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 140
            )
            
            RadialGradient(
                colors: [theme.accentSecondary.opacity(0.10), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 120
            )
        }
    }
}

// MARK: - Small Widget Content

struct SmallWidgetContent: View {
    let entry: FocusFlowWidgetEntry
    
    private var theme: WidgetTheme {
        WidgetTheme.theme(for: entry.data.selectedTheme)
    }
    
    var body: some View {
        ZStack {
            WidgetBackground(theme: theme)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    if entry.data.isSessionActive {
                        Circle()
                            .fill(entry.data.activeSessionIsPaused ? Color.orange : theme.accent)
                            .frame(width: 6, height: 6)
                        Text(entry.data.activeSessionIsPaused ? "PAUSED" : "FOCUS")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(theme.accent)
                        Text("TODAY")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    if !entry.data.isSessionActive && entry.data.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(entry.data.currentStreak)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(theme.accent.opacity(0.9))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                
                Spacer()
                
                // Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: [theme.accent, theme.accentSecondary, theme.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        if entry.data.isSessionActive {
                            if let endDate = entry.data.activeSessionEndDate, !entry.data.activeSessionIsPaused {
                                Text(timerInterval: Date()...endDate, countsDown: true)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                            } else {
                                Text(formatTime(entry.data.activeSessionRemainingSeconds))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        } else if entry.data.selectedPresetDuration > 0 {
                            Text("\(entry.data.selectedPresetDuration)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("min")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(theme.accent.opacity(0.8))
                        } else {
                            Text(formatMinutes(Int(entry.data.todayFocusSeconds / 60)))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("/ \(entry.data.dailyGoalMinutes)m")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(theme.accent.opacity(0.8))
                        }
                    }
                    .frame(width: 80, height: 80)
                }
                
                Spacer()
                Spacer().frame(height: 12)
            }
        }
        .widgetURL(URL(string: "focusflow://open"))
    }
    
    private var ringProgress: Double {
        if entry.data.isSessionActive {
            return entry.data.sessionProgress
        } else if entry.data.selectedPresetDuration > 0 {
            return 0
        } else {
            return entry.data.todayProgress
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h\(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Medium Widget Content

struct MediumWidgetContent: View {
    let entry: FocusFlowWidgetEntry
    
    private var theme: WidgetTheme {
        WidgetTheme.theme(for: entry.data.selectedTheme)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                WidgetBackground(theme: theme)
                
                HStack(spacing: 0) {
                    // LEFT: Timer Ring (same as small widget)
                    leftPanel
                        .frame(width: geo.size.width * 0.42)
                    
                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.12), .white.opacity(0.12), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                        .padding(.vertical, 14)
                    
                    // RIGHT: Presets + Control
                    rightPanel
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .widgetURL(URL(string: "focusflow://open"))
    }
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if entry.data.isSessionActive {
                    Circle()
                        .fill(entry.data.activeSessionIsPaused ? Color.orange : theme.accent)
                        .frame(width: 6, height: 6)
                    Text(entry.data.activeSessionIsPaused ? "PAUSED" : "FOCUS")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.accent)
                    Text("TODAY")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                if !entry.data.isSessionActive && entry.data.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(entry.data.currentStreak)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(theme.accent.opacity(0.9))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 11)
            
            Spacer()
            
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                    .frame(width: 94, height: 94)
                
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(
                            colors: [theme.accent, theme.accentSecondary, theme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 94, height: 94)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    if entry.data.isSessionActive {
                        if let endDate = entry.data.activeSessionEndDate, !entry.data.activeSessionIsPaused {
                            Text(timerInterval: Date()...endDate, countsDown: true)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .foregroundStyle(.white)
                        } else {
                            Text(formatTime(entry.data.activeSessionRemainingSeconds))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    } else if entry.data.selectedPresetDuration > 0 {
                        Text("\(entry.data.selectedPresetDuration)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("min")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.accent.opacity(0.8))
                    } else {
                        Text(formatMinutes(Int(entry.data.todayFocusSeconds / 60)))
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ \(entry.data.dailyGoalMinutes)m")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.accent.opacity(0.8))
                    }
                }
                .frame(width: 74, height: 74)
            }
            
            Spacer()
            Spacer().frame(height: 11)
        }
    }
    
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ✅ Show upgrade message for free users
            if !entry.data.isPro {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(theme.accent)
                    
                    Text("Upgrade for controls")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Unlock interactive widgets")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Text("PRESETS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.leading, 8)
                    .padding(.top, 11)
                
                Spacer().frame(height: 6)
                
                let presetsToShow = Array(entry.data.presets.prefix(3))
                
                if presetsToShow.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(theme.accent.opacity(0.4))
                            Text("Add presets")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(spacing: 5) {
                        ForEach(presetsToShow) { preset in
                            presetRow(preset)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                Spacer(minLength: 6)
                
                // Control buttons (only for Pro users)
                HStack(spacing: 5) {
                    mainActionButton
                    if entry.data.isSessionActive || entry.data.selectedPresetDuration > 0 {
                        resetButton
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 11)
            }
        }
    }
    
    @ViewBuilder
    private func presetRow(_ preset: WidgetDataProvider.WidgetPreset) -> some View {
        let isSelected = entry.data.selectedPresetID == preset.id
        
        // ✅ Only allow interactions for Pro users
        if !entry.data.isPro {
            // Free users see presets but can't interact
            presetRowContent(preset, isSelected: isSelected)
                .opacity(0.5)
        } else if entry.data.isSessionActive && !isSelected {
            Link(destination: URL(string: "focusflow://switchpreset/\(preset.id)")!) {
                presetRowContent(preset, isSelected: isSelected)
            }
        } else {
            Button(intent: SelectPresetIntent(presetID: preset.id, durationMinutes: preset.durationMinutes)) {
                presetRowContent(preset, isSelected: isSelected)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func presetRowContent(_ preset: WidgetDataProvider.WidgetPreset, isSelected: Bool) -> some View {
        HStack(spacing: 5) {
            if let emoji = preset.emoji {
                Text(emoji)
                    .font(.system(size: 12))
            }
            
            Text(preset.name)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.85))
                .lineLimit(1)
            
            Spacer()
            
            Text(preset.durationFormatted)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? theme.accent.opacity(0.25) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(isSelected ? theme.accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
    }
    
    @ViewBuilder
    private var mainActionButton: some View {
        // ✅ Only show controls for Pro users
        if !entry.data.isPro {
            // Free users see disabled button
            buttonContent(icon: "lock.fill", text: "Pro")
                .opacity(0.5)
        } else if entry.data.isSessionActive {
            if entry.data.activeSessionIsPaused {
                Link(destination: URL(string: "focusflow://resume")!) {
                    buttonContent(icon: "play.fill", text: "Resume")
                }
            } else {
                Link(destination: URL(string: "focusflow://pause")!) {
                    buttonContent(icon: "pause.fill", text: "Pause")
                }
            }
        } else {
            Link(destination: URL(string: "focusflow://startfocus")!) {
                buttonContent(icon: "play.fill", text: "Start")
            }
        }
    }
    
    private func buttonContent(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.black.opacity(0.85))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [theme.accent, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
    
    private var resetButton: some View {
        Group {
            // ✅ Only allow reset for Pro users
            if !entry.data.isPro {
                resetButtonContent
                    .opacity(0.5)
            } else if entry.data.isSessionActive {
                Link(destination: URL(string: "focusflow://resetconfirm")!) {
                    resetButtonContent
                }
            } else {
                Button(intent: ResetWidgetIntent()) {
                    resetButtonContent
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var resetButtonContent: some View {
        Image(systemName: "arrow.counterclockwise")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 30, height: 30)
            .background(Circle().fill(Color.white.opacity(0.1)))
    }
    
    private var ringProgress: Double {
        if entry.data.isSessionActive {
            return entry.data.sessionProgress
        } else if entry.data.selectedPresetDuration > 0 {
            return 0
        } else {
            return entry.data.todayProgress
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h\(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - App Intents

struct SelectPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Focus Preset"
    static var description = IntentDescription("Select a preset to configure focus duration")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Preset ID")
    var presetID: String
    
    @Parameter(title: "Duration Minutes")
    var durationMinutes: Int
    
    init() {
        self.presetID = ""
        self.durationMinutes = 25
    }
    
    init(presetID: String, durationMinutes: Int) {
        self.presetID = presetID
        self.durationMinutes = durationMinutes
    }
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow")
        defaults?.set(presetID, forKey: "widget.selectedPresetID")
        defaults?.set(durationMinutes, forKey: "widget.selectedPresetDuration")
        defaults?.synchronize()
        
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowWidget")
        
        return .result()
    }
}

struct ResetWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Widget"
    static var description = IntentDescription("Clear preset selection and reset widget to idle")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.ca.softcomputers.FocusFlow")
        defaults?.removeObject(forKey: "widget.selectedPresetID")
        defaults?.removeObject(forKey: "widget.selectedPresetDuration")
        defaults?.synchronize()
        
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusFlowWidget")
        
        return .result()
    }
}

// MARK: - Widget Definition

struct FocusFlowWidget: Widget {
    let kind: String = "FocusFlowWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusFlowWidgetProvider()) { entry in
            FocusFlowWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("FocusFlow")
        .description("Track your focus time and start sessions quickly.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    FocusFlowWidget()
} timeline: {
    FocusFlowWidgetEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    FocusFlowWidget()
} timeline: {
    FocusFlowWidgetEntry(date: .now, data: .placeholder)
}
