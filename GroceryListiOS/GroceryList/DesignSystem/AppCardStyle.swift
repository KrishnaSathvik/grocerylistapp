import SwiftUI
import SwiftData

struct AppCardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 4)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(AppCardStyle(padding: padding))
    }
}

// MARK: - Shared screen chrome

struct AppScreenBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            AppColors.backgroundGrouped

            LinearGradient(
                colors: [
                    AppColors.heroGradientTop,
                    AppColors.heroGradientTop.opacity(0.45),
                    AppColors.backgroundGrouped.opacity(0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }
}

/// Standard shell for My Lists, Store, Categories, and More.
struct TopLevelTabScreen<Content: View>: View {
    let title: String
    let subtitle: String
    var layout: AdaptiveContentLayout = .standard
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 0) {
                TopLevelHeader(title: title, metadata: subtitle)

                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .adaptiveContentWidth(layout: layout, alignment: .top)
        }
        .background(AppScreenBackground())
        .tabBarSafePadding()
    }
}

// MARK: - Adaptive layout (iPhone + iPad)

enum AdaptiveContentLayout {
    case standard
    case settings
}

enum AdaptiveLayout {
    static let phoneMaxContentWidth: CGFloat = 640
    /// Primary content column on iPad — wide enough to feel native, not phone-sized.
    static let tabletMaxContentWidth: CGFloat = 860
    /// Narrower column for settings-style pages on iPad.
    static let tabletSettingsMaxContentWidth: CGFloat = 720
    static let tabletHorizontalPadding: CGFloat = 24

    static func maxContentWidth(
        for horizontalSizeClass: UserInterfaceSizeClass?,
        layout: AdaptiveContentLayout = .standard
    ) -> CGFloat {
        guard horizontalSizeClass == .regular else { return phoneMaxContentWidth }
        switch layout {
        case .standard:
            return tabletMaxContentWidth
        case .settings:
            return tabletSettingsMaxContentWidth
        }
    }

    static func screenHorizontal(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? tabletHorizontalPadding : AppSpacing.screenHorizontal
    }
}

private struct AdaptiveContentWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var maxWidth: CGFloat?
    var layout: AdaptiveContentLayout
    var alignment: Alignment

    func body(content: Content) -> some View {
        let resolvedWidth = maxWidth ?? AdaptiveLayout.maxContentWidth(for: horizontalSizeClass, layout: layout)
        content
            .frame(maxWidth: resolvedWidth)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

private struct AdaptiveScreenContentModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var layout: AdaptiveContentLayout
    var alignment: Alignment

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AdaptiveLayout.screenHorizontal(for: horizontalSizeClass))
            .frame(maxWidth: AdaptiveLayout.maxContentWidth(for: horizontalSizeClass, layout: layout))
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

private struct AdaptiveHorizontalPaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var edges: Edge.Set

    func body(content: Content) -> some View {
        content.padding(edges, AdaptiveLayout.screenHorizontal(for: horizontalSizeClass))
    }
}

extension View {
    /// Centers content in a readable column; wider on iPad, capped on iPhone.
    func adaptiveContentWidth(
        maxWidth: CGFloat? = nil,
        layout: AdaptiveContentLayout = .standard,
        alignment: Alignment = .center
    ) -> some View {
        modifier(AdaptiveContentWidthModifier(maxWidth: maxWidth, layout: layout, alignment: alignment))
    }

    /// Applies adaptive horizontal padding and max content width for full screens.
    func adaptiveScreenContent(
        layout: AdaptiveContentLayout = .standard,
        alignment: Alignment = .top
    ) -> some View {
        modifier(AdaptiveScreenContentModifier(layout: layout, alignment: alignment))
    }

    func adaptiveHorizontalPadding(_ edges: Edge.Set = .horizontal) -> some View {
        modifier(AdaptiveHorizontalPaddingModifier(edges: edges))
    }

    /// Presents a full-screen cover on iPad and a page-sized sheet on iPhone.
    func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AdaptiveSheetHost(isPresented: isPresented, onDismiss: onDismiss, sheetContent: content))
    }

    func adaptiveSheetPresentation(_ style: AdaptiveSheetPresentation = .page) -> some View {
        modifier(AdaptiveSheetPresentationModifier(style: style))
    }
}

// MARK: - Adaptive sheet presentation

enum AdaptiveSheetPresentation {
    case form
    case page
}

private struct AdaptiveSheetPresentationModifier: ViewModifier {
    let style: AdaptiveSheetPresentation

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            switch style {
            case .form:
                content.presentationSizing(.form)
            case .page:
                content.presentationSizing(.page)
            }
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct AdaptiveSheetHost<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var onDismiss: (() -> Void)?
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss, content: sheetContent)
        } else {
            content
                .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                    sheetContent()
                        .adaptiveSheetPresentation(.page)
                }
        }
    }
}

/// Full-screen shell with centered readable content and optional bottom overlay.
struct AdaptiveScreenShell<Content: View, BottomOverlay: View>: View {
    @ViewBuilder var content: () -> Content
    @ViewBuilder var bottomOverlay: () -> BottomOverlay

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder bottomOverlay: @escaping () -> BottomOverlay
    ) {
        self.content = content
        self.bottomOverlay = bottomOverlay
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppScreenBackground()

            content()
                .adaptiveContentWidth(alignment: .top)
                .frame(maxHeight: .infinity, alignment: .top)

            bottomOverlay()
                .adaptiveContentWidth(alignment: .center)
        }
    }
}

extension AdaptiveScreenShell where BottomOverlay == EmptyView {
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.bottomOverlay = { EmptyView() }
    }
}

/// Scrollable settings-style page with adaptive width.
struct AdaptiveScrollScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            content()
                .adaptiveScreenContent(alignment: .top)
                .padding(.vertical, 16)
                .padding(.bottom, 8)
        }
        .background(AppColors.backgroundGrouped)
    }
}

typealias TopLevelHeader = TabScreenHeader
typealias PrimaryActionRow = TabPrimaryActionBar

struct GroupedBrowseToolbar: View {
    let title: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .appSectionLabel()

            Spacer(minLength: 8)

            Button(action: action) {
                Label(actionTitle, systemImage: "plus")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.ink)
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.backgroundPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel(actionTitle)
        }
    }
}

struct GroupedItemsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.35), radius: 8, y: 3)
    }
}

// MARK: - Grouped browse sections (Store / Categories tabs)

enum GroupedSectionKind {
    case store(storeId: String?, label: String)
    case category(categoryId: String, label: String)

    var metadataMode: GroupedItemMetadataMode {
        switch self {
        case .store: return .category
        case .category: return .store
        }
    }
}

/// Unified read-only group card for Store and Categories tabs.
struct GroupedSummaryCard: View {
    let kind: GroupedSectionKind
    let itemCount: Int
    let items: [GroceryItem]

    private let horizontalPadding: CGFloat = 14
    private let iconSize: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 12)

            if !items.isEmpty {
                Divider()
                    .overlay(AppColors.cardBorder)
                    .padding(.leading, horizontalPadding)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        GroupedItemRow(
                            item: item,
                            metadataMode: kind.metadataMode,
                            style: .nested
                        )

                        if index < items.count - 1 {
                            Divider()
                                .overlay(AppColors.cardBorder)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 6)
            }
        }
        .background(AppColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.groupedSectionCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.groupedSectionCornerRadius, style: .continuous)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow.opacity(0.28), radius: 8, y: 3)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var groupHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            groupIcon

            VStack(alignment: .leading, spacing: 6) {
                Text(groupTitle)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.ink)
                    .lineLimit(1)

                Text(statusLabel)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.inkSecondary)
                    .lineLimit(1)

                if itemCount > 0 {
                    ProgressView(value: shoppingProgress)
                        .tint(AppColors.accentSuccess)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: AppIcons.chevron)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.inkSecondary)
        }
    }

    @ViewBuilder
    private var groupIcon: some View {
        switch kind {
        case .store(let storeId, let label):
            StoreLogoView(
                storeId: storeId,
                displayLabel: label,
                size: iconSize,
                cornerRadius: 12
            )
        case .category(let categoryId, _):
            CategoryIconView(
                categoryId: categoryId,
                containerSize: iconSize,
                cornerRadius: 12
            )
        }
    }

    private var groupTitle: String {
        switch kind {
        case .store(_, let label): return label
        case .category(_, let label): return label
        }
    }

    private var countLabel: String {
        "\(itemCount) item\(itemCount == 1 ? "" : "s")"
    }

    private var activeCount: Int {
        items.filter { !$0.isCompleted }.count
    }

    private var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    private var shoppingProgress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedCount) / Double(items.count)
    }

    private var statusLabel: String {
        guard itemCount > 0 else { return "No items yet" }
        if completedCount > 0 {
            return "\(activeCount) to buy · \(completedCount) picked up"
        }
        return countLabel
    }
}

typealias GroupedSectionCard = GroupedSummaryCard
