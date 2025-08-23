import SwiftUI
import SwiftData

/// Settings view for managing reminder preferences and notifications
struct ReminderSettingsView: View {
    @EnvironmentObject private var dependencyContainer: DependencyContainer

    var body: some View {
        ReminderSettingsViewBody(dependencyContainer: dependencyContainer)
    }
}

private struct ReminderSettingsViewBody: View {
    private let dependencyContainer: DependencyContainer
    @State private var viewModel: ReminderSettingsViewModel
    @Environment(\.openURL) private var openURL

    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        _viewModel = State(wrappedValue: ReminderSettingsViewModel(dependencyContainer: dependencyContainer))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    settingsForm
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasUnsavedChanges {
                        Button("Save") {
                            Task {
                                _ = await viewModel.savePreferences() // view model will handle showing errors
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .refreshable {
                await viewModel.refreshAll()
            }
        }
    }

    private var settingsForm: some View {
        Form {
            backgroundModeSection
            notificationSection
            reminderSection
            actionsSection
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(AppConstants.UI.opacity))
            }
        }
    }

    private var backgroundModeSection: some View {
        Section {
            InlineBackgroundModeStatusView(dependencyContainer: dependencyContainer)
        } header: {
            Text("Background Refresh")
        } footer: {
            Text("Background App Refresh allows the app to schedule notifications even when not actively running")
        }
    }

    private var notificationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.medium) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.blue)
                    Text("Daily Notification Time")
                        .font(.headline)
                }

                if viewModel.notificationPermission == .granted {
                    HStack {
                        Picker("Hour", selection: $viewModel.selectedHour) {
                            ForEach(Array(AppConstants.Validation.hourRange), id: \.self) { hour in
                                Text(String(format: "%02d", hour)).tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: AppConstants.UI.wheelPickerMaxWidth)
                        .accessibilityLabel("Notification Hour")

                        Text(":")
                            .font(.title2)

                        Picker("Minute", selection: $viewModel.selectedMinute) {
                            ForEach(Array(AppConstants.Validation.minuteRange), id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: AppConstants.UI.wheelPickerMaxWidth)
                        .accessibilityLabel("Notification Minute")
                    }
                    .frame(height: AppConstants.UI.formHeight)

                    Text("You'll receive a daily summary at \(viewModel.notificationTimeText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                        Text("Notifications are disabled")
                            .foregroundColor(.orange)

                        Button("Enable Notifications") {
                            viewModel.requestNotificationPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Receive daily summaries of expiring resources and reminders")
        }
        .alert("Enable Notifications", isPresented: $viewModel.showSettingsAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive notifications, go to Settings and enable notifications for ReadyKit.")
        }
    }

    private var reminderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.medium) {
                VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("Expiration Reminder")
                            .font(.headline)
                    }

                    Stepper(
                        value: $viewModel.expiryReminderLeadDays,
                        in: AppConstants.Validation.expiryReminderLeadDaysRange,
                        step: 1
                    ) {
                        Text("\(viewModel.expiryReminderLeadDays) days before expiration")
                    }
                    .accessibilityLabel("Days before expiration")

                    Text(viewModel.expiryReminderDescription())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.green)
                        Text("Regular Check Frequency")
                            .font(.headline)
                    }

                    Picker("Frequency", selection: $viewModel.regularCheckFrequency) {
                        ForEach([RegularCheckFrequency.quarterly, .halfYearly, .yearly], id: \.self) { frequency in
                            Text(viewModel.regularCheckFrequencyDescription(frequency))
                                .tag(frequency)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Text("""
                    How often you will be reminded to check resources without expiration dates:
                    
                    • Quarterly: the first day of January, April, July, and October.
                    • Half-Yearly: the first day of January and July.
                    • Yearly: the first day of January.
                    """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Reminder Settings")
        } footer: {
            Text("Customize when and how often you receive reminders about your emergency resources")
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
            .foregroundColor(.blue)
        } footer: {
            Text("Reset all settings to their default values")
        }
    }
}

#Preview {
    let schema = Schema([
        EmergencyKitModel.self,
        ItemModel.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    let dependencyContainer = DependencyContainer(modelContext: ModelContext(container))
    
    ReminderSettingsView()
        .modelContainer(container)
        .environmentObject(dependencyContainer)
}
