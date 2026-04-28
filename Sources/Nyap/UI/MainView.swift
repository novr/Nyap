import SwiftUI

struct MainView: View {
    @Bindable var store: SessionStore

    private let pageBackground = Color("PageBackground", bundle: .module)
    private let cardBackground = Color("CardBackground", bundle: .module)
    private let panelBackground = Color("PanelBackground", bundle: .module)
    private let brandBlue = Color("BrandBlue", bundle: .module)
    private let brandRed = Color("BrandRed", bundle: .module)

    private var workMinutesBinding: Binding<Int> {
        Binding(
            get: { store.workMinutes },
            set: { store.setWorkMinutes($0) }
        )
    }

    private var breakMinutesBinding: Binding<Int> {
        Binding(
            get: { store.breakMinutes },
            set: { store.setBreakMinutes($0) }
        )
    }

    private var selectedCatBinding: Binding<String> {
        Binding(
            get: { store.selectedCatID },
            set: { store.setSelectedCat($0) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                topBar
                heroCard
                settingsGrid
                achievementCard
            }
            .padding(20)
        }
        .background(pageBackground.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Label(L10n.tr("app.name"), systemImage: "pawprint.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            Divider()
                .frame(height: 18)

            Text(L10n.tr("main.header.title"))
                .font(.subheadline.weight(.semibold))

            Text(L10n.tr("main.header.live"))
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(brandBlue.opacity(0.18))
                .clipShape(Capsule())

            Spacer()

            Image(systemName: "bell")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var heroCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(L10n.tr("main.currentPhase"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(store.phaseTitle)
                    .font(.system(size: 34, weight: .bold))
            }

            Text(store.remainingTimeText)
                .font(.system(size: 62, weight: .black, design: .rounded))
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 10) {
                Button {
                    store.startWorkSession()
                } label: {
                    Label(L10n.tr("main.startWork"), systemImage: "play.circle")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(store.phase == .work)

                Button(L10n.tr("main.stop")) {
                    store.stopSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(store.phase == .idle)

                Button(L10n.tr("main.skipBreak")) {
                    store.skipBreak()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(store.phase != .breakTime)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var settingsGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle(L10n.tr("main.section.sessionSettings"))
                Stepper(value: workMinutesBinding, in: 1...180) {
                    settingRow(label: L10n.tr("main.workTime"), value: "\(store.workMinutes)")
                }
                Stepper(value: breakMinutesBinding, in: 1...60) {
                    settingRow(label: L10n.tr("main.breakTime"), value: "\(store.breakMinutes)")
                }
                Toggle(L10n.tr("main.autoStart"), isOn: $store.autoStartOnLaunch)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                sectionTitle(L10n.tr("main.section.companionDisplay"))
                HStack {
                    Text(L10n.tr("main.catDisplay"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("猫表示スタイル", selection: $store.catDisplayStyle) {
                        Text(L10n.tr("main.catDisplay.still")).tag("static")
                        Text(L10n.tr("main.catDisplay.animated")).tag("animated")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }

                HStack {
                    Text(L10n.tr("main.pose"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("猫のポーズ", selection: selectedCatBinding) {
                        ForEach(SessionStore.catOptions) { option in
                            Text(L10n.tr(option.titleKey)).tag(option.id)
                        }
                    }
                    .frame(width: 170)
                }

                HStack {
                    Spacer()
                    Button(L10n.tr("main.previewCat")) {
                        store.previewBreakOverlay()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isBreakOverlayPresented)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var achievementCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L10n.tr("main.achievements"), systemImage: "rosette")
                    .font(.title2.weight(.bold))
                Spacer()
                Text(L10n.tr("main.viewHistory"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(brandBlue)
            }

            HStack(spacing: 12) {
                metricCard(
                    title: L10n.tr("main.metric.completed"),
                    value: "\(store.completedWorkSessions)",
                    suffix: L10n.tr("main.metric.sessions"),
                    progress: Double(store.completedWorkSessions) / 16.0,
                    color: brandBlue
                )
                metricCard(
                    title: L10n.tr("main.metric.skipped"),
                    value: "\(store.skippedBreakCount)",
                    suffix: L10n.tr("main.metric.breaks"),
                    progress: Double(store.skippedBreakCount) / 8.0,
                    color: brandRed
                )
                metricCard(
                    title: L10n.tr("main.metric.totalBreakTime"),
                    value: "\(totalBreakMinutes)",
                    suffix: L10n.tr("main.metric.minutes"),
                    progress: Double(totalBreakMinutes) / 90.0,
                    color: brandBlue
                )
            }
        }
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func settingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func metricCard(title: String, value: String, suffix: String, progress: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text(suffix)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(1, progress))
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var totalBreakMinutes: Int {
        store.totalBreakSecondsToday / 60
    }
}
