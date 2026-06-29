import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(
        filter: #Predicate<GroceryList> { !$0.isArchived },
        sort: [SortDescriptor(\GroceryList.sortOrder), SortDescriptor(\GroceryList.name)]
    )
    private var lists: [GroceryList]

    @AppStorage(AppSettings.Keys.enableHaptics) private var enableHaptics = true
    @AppStorage(AppSettings.Keys.preferredColorScheme) private var colorSchemeRaw = AppColorSchemePreference.system.rawValue
    @AppStorage(AppSettings.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding = true

    @State private var showAbout = false
    @State private var showFeedback = false
    @State private var showPrivacyPolicy = false
    @State private var statusMessage: String?

    private var activeList: GroceryList? {
        ActiveListResolver.resolve(from: lists)
    }

    private var colorSchemePreference: Binding<AppColorSchemePreference> {
        Binding(
            get: { AppColorSchemePreference(rawValue: colorSchemeRaw) ?? .system },
            set: { colorSchemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            TopLevelTabScreen(
                title: "More",
                subtitle: "Preferences, sharing, and app info"
            ) {
                ScrollView {
                    VStack(spacing: AppSpacing.sectionSpacing) {
                        preferencesSection
                        sharingSection
                        backupSection
                        customizationSection
                        helpSection
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("Settings", isPresented: Binding(
                get: { statusMessage != nil },
                set: { if !$0 { statusMessage = nil } }
            )) {
                Button("OK", role: .cancel) { statusMessage = nil }
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }

    private var preferencesSection: some View {
        SettingsCard(title: "Preferences") {
            SettingsRow(
                title: "Haptic Feedback",
                icon: "hand.tap.fill",
                iconColor: AppColors.accentSuccess,
                isOn: $enableHaptics
            )
            SettingsDivider()
            NavigationLink {
                appearancePicker
            } label: {
                SettingsRow(
                    title: "Appearance",
                    value: colorSchemePreference.wrappedValue.label,
                    icon: "moon.circle.fill",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
        }
    }

    private var sharingSection: some View {
        SettingsCard(title: "Sharing") {
            if let list = activeList {
                NavigationLink {
                    ShareActiveListView(list: list)
                } label: {
                    SettingsRow(
                        title: "Share Active List",
                        subtitle: "Show a QR code for your current list.",
                        icon: "square.and.arrow.up.fill",
                        iconColor: AppColors.accentPrimary
                    )
                }
            } else {
                SettingsRow(
                    title: "Share Active List",
                    subtitle: "Create a list first to share it.",
                    icon: "square.and.arrow.up.fill",
                    iconColor: AppColors.inkSecondary,
                    showsChevron: false
                )
                .opacity(0.55)
            }

            SettingsDivider()

            NavigationLink {
                ImportSharedListView()
            } label: {
                SettingsRow(
                    title: "Import Shared List",
                    subtitle: "Scan a QR code or paste shared text.",
                    icon: "square.and.arrow.down.fill",
                    iconColor: AppColors.accentSuccess
                )
            }
        }
    }

    private var backupSection: some View {
        SettingsCard(title: "Backup") {
            NavigationLink {
                BackupRestoreView(mode: .backup)
            } label: {
                SettingsRow(
                    title: "Back Up All Data",
                    subtitle: "Save all lists to a backup file.",
                    icon: "externaldrive.fill",
                    iconColor: AppColors.accentPrimary
                )
            }
            SettingsDivider()
            NavigationLink {
                BackupRestoreView(mode: .restore)
            } label: {
                SettingsRow(
                    title: "Restore Backup",
                    subtitle: "Import a saved backup file.",
                    icon: "arrow.clockwise.circle.fill",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
        }
    }

    private var customizationSection: some View {
        SettingsCard(title: "Customization") {
            if AppIconService.supportsAlternateIcons {
                NavigationLink {
                    AppIconPickerView()
                } label: {
                    SettingsRow(
                        title: "App Icon",
                        subtitle: "Choose your Home Screen icon.",
                        value: AppIconService.currentOption.label,
                        icon: "app.fill",
                        iconColor: AppColors.accentPrimary
                    )
                }
                SettingsDivider()
            }

            NavigationLink {
                CategoryOrderView()
            } label: {
                SettingsRow(
                    title: "Reorder Categories",
                    subtitle: "Drag categories to match your shopping route.",
                    icon: "arrow.up.arrow.down",
                    iconColor: AppColors.accentSuccess
                )
            }
        }
    }

    private var helpSection: some View {
        SettingsCard(title: "Help") {
            Button {
                showFeedback = true
            } label: {
                SettingsRow(
                    title: "Send Feedback",
                    subtitle: "Help improve Grocery List.",
                    icon: "envelope.fill",
                    iconColor: AppColors.accentPrimary
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            RateAppButton(
                icon: "star.fill",
                subtitle: "Share a quick rating if you're enjoying the app."
            )

            SettingsDivider()

            Button {
                openPrivacyPolicy()
            } label: {
                SettingsRow(
                    title: "Privacy Policy",
                    subtitle: "How your data is handled.",
                    icon: "hand.raised.fill",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            Button {
                showAbout = true
            } label: {
                SettingsRow(
                    title: "About Grocery List",
                    subtitle: "Version \(AppSupport.appVersion)",
                    icon: "info.circle.fill",
                    iconColor: AppColors.inkSecondary
                )
            }
            .buttonStyle(.plain)

            #if DEBUG
            SettingsDivider()
            Button {
                hasCompletedOnboarding = false
                statusMessage = "Onboarding will show on next launch."
            } label: {
                SettingsRow(
                    title: "Reset Onboarding",
                    icon: "arrow.clockwise",
                    iconColor: AppColors.inkSecondary
                )
            }
            .buttonStyle(.plain)
            #endif
        }
    }

    private func openPrivacyPolicy() {
        guard AppConfig.privacyPolicyURL != nil else {
            statusMessage = "Privacy policy link isn't available yet."
            return
        }
        showPrivacyPolicy = true
    }

    private var appearancePicker: some View {
        List {
            ForEach(AppColorSchemePreference.allCases) { pref in
                Button {
                    colorSchemePreference.wrappedValue = pref
                } label: {
                    HStack {
                        Text(pref.label)
                        Spacer()
                        if colorSchemePreference.wrappedValue == pref {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.accentPrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .settingsSubpageStyle()
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! ModelContainerSetup.makeContainer(inMemory: true))
}
