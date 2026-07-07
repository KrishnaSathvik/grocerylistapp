import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(AppSettings.Keys.enableHaptics) private var enableHaptics = true
    @AppStorage(AppSettings.Keys.preferredColorScheme) private var colorSchemeRaw = AppColorSchemePreference.system.rawValue

    @State private var showAbout = false
    @State private var showFeedback = false
    @State private var showImportSheet = false
    @State private var showPrivacyPolicySafari = false
    @State private var statusMessage: String?

    private var colorSchemePreference: Binding<AppColorSchemePreference> {
        Binding(
            get: { AppColorSchemePreference(rawValue: colorSchemeRaw) ?? .system },
            set: { colorSchemeRaw = $0.rawValue }
        )
    }

    private var sectionGap: some View {
        Spacer(minLength: AppSpacing.settingsSectionSpacing)
    }

    var body: some View {
        NavigationStack {
            TopLevelTabScreen(
                title: "More",
                subtitle: "Customize your app, share lists, and get help.",
                layout: .settings
            ) {
                ScrollView {
                    VStack(spacing: 0) {
                        preferencesSection

                        sectionGap

                        sharingSection

                        sectionGap

                        customizationSection

                        sectionGap

                        helpSection
                    }
                    .adaptiveHorizontalPadding()
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .adaptiveSheet(isPresented: $showAbout) {
                AboutView()
            }
            .adaptiveSheet(isPresented: $showFeedback) {
                FeedbackView()
            }
            .adaptiveSheet(isPresented: $showImportSheet) {
                NavigationStack {
                    ImportSharedListView()
                }
            }
            .sheet(isPresented: $showPrivacyPolicySafari) {
                if let url = AppConfig.privacyPolicyURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
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
                icon: "hand.tap",
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
                    icon: "circle.lefthalf.filled",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var sharingSection: some View {
        SettingsCard(title: "Sharing") {
            Button {
                showImportSheet = true
            } label: {
                SettingsRow(
                    title: "Import a Shared List",
                    subtitle: "Scan a QR code or paste a share link.",
                    icon: "square.and.arrow.down",
                    iconColor: AppColors.accentSuccess
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var customizationSection: some View {
        SettingsCard(title: "Customization") {
            NavigationLink {
                ManageStoresView()
            } label: {
                SettingsRow(
                    title: "Manage Stores",
                    subtitle: "View default and custom stores.",
                    icon: "storefront.fill",
                    iconColor: AppColors.accentPrimary
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            NavigationLink {
                ManageCategoriesView()
            } label: {
                SettingsRow(
                    title: "Manage Categories",
                    subtitle: "View default and custom categories.",
                    icon: "square.grid.2x2.fill",
                    iconColor: AppColors.colorHex("#C4883C")
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            NavigationLink {
                AppIconPickerView()
            } label: {
                SettingsRow(
                    title: "App Icon",
                    subtitle: "Choose your Home Screen icon.",
                    value: AppIconService.currentOption.label,
                    icon: "app.badge",
                    iconColor: AppColors.accentPrimary
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var helpSection: some View {
        SettingsCard(title: "Help") {
            Button {
                showFeedback = true
            } label: {
                SettingsRow(
                    title: "Send Feedback",
                    subtitle: AppConfig.feedbackEmail,
                    icon: "envelope",
                    iconColor: AppColors.accentSuccess
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
                    icon: "lock.shield",
                    iconColor: AppColors.colorHex("#8B6F8E")
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            Button {
                showAbout = true
            } label: {
                SettingsRow(
                    title: "About Groceries — Smart Lists",
                    subtitle: "Version \(AppSupport.appVersion)",
                    icon: "info.circle",
                    iconColor: AppColors.inkSecondary
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func openPrivacyPolicy() {
        guard AppConfig.privacyPolicyURL != nil else {
            statusMessage = "Privacy policy link isn't available yet."
            return
        }
        showPrivacyPolicySafari = true
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
