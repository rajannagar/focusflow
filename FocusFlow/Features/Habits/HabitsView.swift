import SwiftUI
import UIKit    // for UITableViewCell appearance

// MARK: - Glass card container (local to this file)
private struct GlassCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @StateObject private var viewModel = HabitsViewModel()
    @ObservedObject private var appSettings = AppSettings.shared

    // MARK: - Sheet State
    @State private var showingAddHabitSheet = false
    
    // Tracks which habit we are currently editing (nil = creating new)
    @State private var habitToEdit: Habit?

    // Temporary form data
    @State private var newHabitName: String = ""
    @State private var newHabitDate: Date = Date()
    @State private var newHabitTime: Date = Date()
    @State private var newHabitRepeat: HabitRepeat = .none
    @State private var durationHours: Int = 0
    @State private var durationMinutesComponent: Int = 30

    // Sub-sheets for pickers
    @State private var showingDatePickerSheet = false
    @State private var showingTimePickerSheet = false
    @State private var showingDurationPickerSheet = false
    @State private var showingRepeatPickerSheet = false

    // Header icon animation
    @State private var iconPulse = false

    init() {
        // Remove default row highlight & background
        UITableViewCell.appearance().selectionStyle = .none
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().tintColor = UIColor(white: 0.08, alpha: 1.0)
    }

    // MARK: - Derived values

    private var completedCount: Int {
        viewModel.habits.filter { $0.isDoneToday }.count
    }

    private var progress: Double {
        guard !viewModel.habits.isEmpty else { return 0 }
        return Double(completedCount) / Double(viewModel.habits.count)
    }

    private var theme: AppTheme { appSettings.selectedTheme }

    private var hasHabits: Bool {
        !viewModel.habits.isEmpty
    }

    private var totalDurationMinutes: Int {
        durationHours * 60 + durationMinutesComponent
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let accentPrimary = theme.accentPrimary
            let accentSecondary = theme.accentSecondary

            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Blurred halos
                Circle()
                    .fill(accentPrimary.opacity(0.5))
                    .blur(radius: 90)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.45, y: -size.height * 0.55)

                Circle()
                    .fill(accentSecondary.opacity(0.35))
                    .blur(radius: 100)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: size.width * 0.45, y: size.height * 0.5)

                VStack(spacing: 18) {
                    header
                        .padding(.horizontal, 22)
                        .padding(.top, 18)

                    summaryCard
                        .padding(.horizontal, 22)

                    sectionHeader
                        .padding(.horizontal, 22)

                    if viewModel.habits.isEmpty {
                        emptyState
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                        Spacer(minLength: 0)
                    } else {
                        habitsList
                            .padding(.horizontal, 22)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        // Add/Edit Habit Sheet
        .sheet(isPresented: $showingAddHabitSheet) {
            addHabitSheet
        }
        .onAppear {
            iconPulse = true
        }
    }

    // MARK: - Header & Summary (Unchanged)

    private var header: some View {
        let accentPrimary = theme.accentPrimary
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image("Focusflow_Logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .scaleEffect(iconPulse ? 1.06 : 0.94)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: iconPulse)

                    Text("Habits")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    if hasHabits {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(progress >= 1 ? accentPrimary : Color.white.opacity(0.35))
                                .frame(width: 8, height: 8)
                            Text(progress >= 1 ? "All done" : "In progress")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                Text("Tiny rituals that support your focus.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            HStack(spacing: 10) {
                Button {
                    simpleTap()
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.resetAll() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .imageScale(.medium)
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.20))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today’s habit loop")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Text("Tap to complete. Swipe to edit or delete.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            if hasHabits {
                HStack(spacing: 6) {
                    Image(systemName: "clock").imageScale(.small)
                    Text("\(completedCount)/\(viewModel.habits.count)")
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
                .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily habits")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    if viewModel.habits.isEmpty {
                        Text("Create a few anchors that support your deep work.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("\(completedCount) of \(viewModel.habits.count) completed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                        Text(completedCount == 0 ? "Start with just one tiny win." : (progress >= 1 ? "Beautiful. You’ve closed your loop for today." : "Keep going — stack one more small action."))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        // Create New
                        prepareSheetForCreation()
                        simpleTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                            Text("Add habit").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LinearGradient(gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]), startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                    }
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
                donutProgress
            }
        }
    }

    private var donutProgress: some View {
        let percentage = Int((progress * 100).rounded())
        return ZStack {
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(AngularGradient(gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary, theme.accentPrimary]), center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: progress)
            VStack(spacing: 2) {
                Text(viewModel.habits.isEmpty ? "--" : "\(percentage)%").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                Text("Done").font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 70, height: 70)
        .padding(.leading, 4)
    }

    // MARK: - Habits list

    private var habitsList: some View {
        List {
            ForEach(viewModel.habits) { habit in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        viewModel.toggle(habit)
                    }
                    simpleTap()
                } label: {
                    habitRow(habit)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .contentShape(Rectangle())
                
                // MARK: Swipe Actions
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.delete(habit: habit)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                // EDIT ACTION (Swipe Right)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        prepareSheetForEditing(habit)
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .tint(theme.accentPrimary) // Use app theme color for edit
                }
            }
            .onMove(perform: viewModel.move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                        Image(systemName: "sparkles").foregroundColor(.white).imageScale(.medium)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No habits yet").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Text("Add 3–5 small habits that pair well with your Focus capsules.").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button {
                        prepareSheetForCreation()
                        simpleTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill").imageScale(.small)
                            Text("Create first habit").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LinearGradient(gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]), startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Add / Edit Sheet

    private var addHabitSheet: some View {
        let theme = appSettings.selectedTheme
        let accentPrimary = theme.accentPrimary
        let accentSecondary = theme.accentSecondary
        let canSave = !newHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Title based on mode
        let sheetTitle = (habitToEdit == nil) ? "Add habit" : "Edit habit"

        return GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                Circle().fill(accentPrimary.opacity(0.5)).blur(radius: 90).frame(width: size.width * 0.9, height: size.width * 0.9).offset(x: -size.width * 0.45, y: -size.height * 0.55)
                Circle().fill(accentSecondary.opacity(0.35)).blur(radius: 100).frame(width: size.width * 0.9, height: size.width * 0.9).offset(x: size.width * 0.45, y: size.height * 0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Button { showingAddHabitSheet = false } label: {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.16))
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            Spacer()
                            Text(sheetTitle).font(.system(size: 20, weight: .semibold)).foregroundColor(.white)
                            Spacer()

                            Button { saveHabit() } label: {
                                Text("Save")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(LinearGradient(gradient: Gradient(colors: [accentPrimary, accentSecondary]), startPoint: .leading, endPoint: .trailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .shadow(radius: 12)
                            }
                            .buttonStyle(.plain)
                            .disabled(!canSave)
                            .opacity(canSave ? 1.0 : 0.5)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shape how this habit shows up.")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Give it a clear name and optional reminder so it fits into your FocusFlow rhythm.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)

                        // Name Input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Habit name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("e.g. Plan tomorrow", text: $newHabitName)
                                .foregroundColor(.white)
                                .tint(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))

                        // Reminders Card
                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminders")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 10)

                            Group {
                                settingRow(title: "Date", value: formattedDate(newHabitDate)) { showingDatePickerSheet = true }
                                Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)
                                settingRow(title: "Time of day", value: formattedTime(newHabitTime)) { showingTimePickerSheet = true }
                                Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)
                                settingRow(title: "Duration", value: formattedDuration()) { showingDurationPickerSheet = true }
                                Divider().background(Color.white.opacity(0.18)).padding(.leading, 18)
                                settingRow(title: "Repeat", value: newHabitRepeat.displayName) { showingRepeatPickerSheet = true }
                            }
                            Text("Leave these blank if you just want the habit in your list without alerts.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(18)
                        }
                        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingDatePickerSheet) { datePickerSheet(theme: theme) }
        .sheet(isPresented: $showingTimePickerSheet) { timePickerSheet(theme: theme) }
        .sheet(isPresented: $showingDurationPickerSheet) { durationPickerSheet(theme: theme) }
        .sheet(isPresented: $showingRepeatPickerSheet) { repeatPickerSheet(theme: theme) }
    }

    private func settingRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(.white)
                Spacer()
                Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Image(systemName: "chevron.right").imageScale(.small).foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Picker Sheets (Clean Design)

    private func datePickerSheet(theme: AppTheme) -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer().frame(height: 40)
                Text("Pick a date").font(.title3.bold()).foregroundColor(.white)
                DatePicker("", selection: $newHabitDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical).tint(.white).padding(.horizontal, 22)
                HStack {
                    Button("Cancel") { showingDatePickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Done") { showingDatePickerSheet = false }.font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }.padding(.horizontal, 30)
                Spacer(minLength: 24)
            }
        }.presentationDetents([.fraction(0.6)]).presentationDragIndicator(.visible)
    }

    private func timePickerSheet(theme: AppTheme) -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer().frame(height: 40)
                Text("Time of day").font(.title3.bold()).foregroundColor(.white)
                DatePicker("", selection: $newHabitTime, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel).labelsHidden().tint(.white).colorScheme(.dark).padding(.horizontal, 22)
                HStack {
                    Button("Cancel") { showingTimePickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Done") { showingTimePickerSheet = false }.font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }.padding(.horizontal, 30)
                Spacer(minLength: 24)
            }
        }.presentationDetents([.fraction(0.40)]).presentationDragIndicator(.visible)
    }

    private func durationPickerSheet(theme: AppTheme) -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 40)
                Text("Duration").font(.title3.bold()).foregroundColor(.white)
                Text("Roughly how long this habit takes.").font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                HStack(spacing: 0) {
                    VStack {
                        Text("Hours").font(.headline).foregroundColor(.white.opacity(0.85))
                        Picker("Hours", selection: $durationHours) { ForEach(0..<13) { h in Text("\(h)").tag(h) } }.pickerStyle(.wheel)
                    }.frame(maxWidth: .infinity).clipped()
                    VStack {
                        Text("Minutes").font(.headline).foregroundColor(.white.opacity(0.85))
                        Picker("Minutes", selection: $durationMinutesComponent) { ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in Text("\(m)").tag(m) } }.pickerStyle(.wheel)
                    }.frame(maxWidth: .infinity).clipped()
                }.colorScheme(.dark).padding(.horizontal, 22).frame(height: 150)
                HStack {
                    Button("Cancel") { showingDurationPickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Set length") { showingDurationPickerSheet = false }.font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }.padding(.horizontal, 30)
                Spacer(minLength: 24)
            }
        }.presentationDetents([.fraction(0.45)]).presentationDragIndicator(.visible)
    }

    private func repeatPickerSheet(theme: AppTheme) -> some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: theme.backgroundColors), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer().frame(height: 40)
                Text("Repeat").font(.title3.bold()).foregroundColor(.white)
                Picker("Repeat", selection: $newHabitRepeat) {
                    Text("No repeat").tag(HabitRepeat.none)
                    Text("Daily").tag(HabitRepeat.daily)
                    Text("Weekly").tag(HabitRepeat.weekly)
                    Text("Monthly").tag(HabitRepeat.monthly)
                    Text("Yearly").tag(HabitRepeat.yearly)
                }
                .pickerStyle(.wheel).labelsHidden().colorScheme(.dark).padding(.horizontal, 22)
                HStack {
                    Button("Cancel") { showingRepeatPickerSheet = false }.foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Button("Done") { showingRepeatPickerSheet = false }.font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }.padding(.horizontal, 30)
                Spacer(minLength: 24)
            }
        }.presentationDetents([.fraction(0.40)]).presentationDragIndicator(.visible)
    }

    // MARK: - Row View

    private func habitRow(_ habit: Habit) -> some View {
        let isDone = habit.isDoneToday
        let iconName = iconForHabit(name: habit.name)
        let statusText = isDone ? "Completed today" : "Tap to complete"
        let subtitleParts = [statusText, reminderDescription(for: habit), durationDescription(for: habit)].compactMap { $0 }
        let subtitle = subtitleParts.joined(separator: " • ")

        return HStack(spacing: 12) {
            ZStack {
                if isDone {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [theme.accentPrimary, theme.accentSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 30, height: 30)
                        .shadow(color: Color.white.opacity(0.35), radius: 5)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle().strokeBorder(Color.white.opacity(0.45), lineWidth: 2).frame(width: 28, height: 28)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let iconName {
                        Image(systemName: iconName).imageScale(.small).foregroundColor(theme.accentPrimary.opacity(isDone ? 1.0 : 0.9))
                    }
                    Text(habit.name).foregroundColor(.white).font(.system(size: 16, weight: .regular)).lineLimit(2).multilineTextAlignment(.leading)
                }
                if !subtitle.isEmpty {
                    Text(subtitle).font(.caption2).foregroundColor(.white.opacity(0.6)).lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(isDone ? 0.20 : 0.14), Color.white.opacity(isDone ? 0.10 : 0.07)]), startPoint: .topLeading, endPoint: .bottomTrailing)).overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.16), lineWidth: 1)))
        .scaleEffect(isDone ? 0.99 : 1.0)
    }

    // MARK: - Logic Helpers

    private func prepareSheetForCreation() {
        habitToEdit = nil
        resetAddHabitState()
        showingAddHabitSheet = true
    }

    private func prepareSheetForEditing(_ habit: Habit) {
        habitToEdit = habit
        
        // Populate fields
        newHabitName = habit.name
        newHabitRepeat = habit.repeatOption
        
        if let reminder = habit.reminderDate {
            newHabitDate = reminder
            newHabitTime = reminder
        } else {
            newHabitDate = Date()
            newHabitTime = Date()
        }
        
        if let mins = habit.durationMinutes, mins > 0 {
            durationHours = mins / 60
            durationMinutesComponent = mins % 60
        } else {
            durationHours = 0
            durationMinutesComponent = 30
        }
        
        showingAddHabitSheet = true
        simpleTap()
    }

    private func saveHabit() {
        let trimmed = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showingAddHabitSheet = false
            return
        }

        // Combine date components
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: newHabitDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newHabitTime)
        var merged = DateComponents()
        merged.year = dateComponents.year
        merged.month = dateComponents.month
        merged.day = dateComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        let finalDate = calendar.date(from: merged)

        let durationValue = totalDurationMinutes > 0 ? totalDurationMinutes : nil

        if let existingHabit = habitToEdit {
            // UPDATE EXISTING
             viewModel.updateHabit(
                 existingHabit,
                 name: trimmed,
                 reminderDate: finalDate,
                 repeatOption: newHabitRepeat,
                 durationMinutes: durationValue
             )
        } else {
            // CREATE NEW
            viewModel.addHabit(
                name: trimmed,
                reminderDate: finalDate,
                repeatOption: newHabitRepeat,
                durationMinutes: durationValue
            )
        }

        showingAddHabitSheet = false
    }

    private func resetAddHabitState() {
        newHabitName = ""
        newHabitDate = Date()
        newHabitTime = Date()
        newHabitRepeat = .none
        durationHours = 0
        durationMinutesComponent = 30
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedDuration() -> String {
        if totalDurationMinutes == 0 { return "None" }
        let hours = durationHours
        let mins = durationMinutesComponent
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        else if hours > 0 { return "\(hours)h" }
        else { return "\(mins)m" }
    }

    private func reminderDescription(for habit: Habit) -> String? {
        guard let date = habit.reminderDate else { return nil }
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: date)
        switch habit.repeatOption {
        case .none:
            let df = DateFormatter(); df.dateStyle = .medium
            return "On \(df.string(from: date)) at \(timeString)"
        case .daily: return "Daily at \(timeString)"
        case .weekly: return "Weekly at \(timeString)" // Simplified for brevity
        case .monthly: return "Monthly at \(timeString)"
        case .yearly: return "Yearly at \(timeString)"
        }
    }

    private func durationDescription(for habit: Habit) -> String? {
        guard let minutes = habit.durationMinutes, minutes > 0 else { return nil }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours)h \(mins)m" }
        else if hours > 0 { return "\(hours)h" }
        else { return "\(mins)m" }
    }

    private func iconForHabit(name: String) -> String? {
        let lower = name.lowercased()
        if lower.contains("read") || lower.contains("book") { return "book.closed" }
        else if lower.contains("journal") || lower.contains("write") { return "square.and.pencil" }
        else if lower.contains("workout") || lower.contains("gym") || lower.contains("run") { return "figure.strengthtraining.traditional" }
        else if lower.contains("water") || lower.contains("drink") { return "drop.fill" }
        else if lower.contains("study") || lower.contains("learn") { return "graduationcap" }
        else if lower.contains("meditate") || lower.contains("breath") { return "sparkles" }
        else if lower.contains("walk") { return "figure.walk" }
        else if lower.contains("email") || lower.contains("inbox") { return "tray.full" }
        else { return nil }
    }

    private func simpleTap() {
        Haptics.impact(.light)
    }
}

#Preview {
    HabitsView()
}
