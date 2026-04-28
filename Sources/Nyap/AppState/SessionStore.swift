import Foundation
import Observation

@Observable
@MainActor
final class SessionStore {
    struct CatOption: Identifiable {
        let id: String
        let titleKey: String
        let assetName: String
    }

    enum Phase: String {
        case idle
        case work
        case breakTime
    }

    enum OverlayMode {
        case none
        case breakTime
        case preview
    }

    static let breakOverlayWindowID = "break-overlay"
    static let randomCatID = "random"
    static let catOptions: [CatOption] = [
        .init(id: randomCatID, titleKey: "cat.option.random", assetName: "CatSleep"),
        .init(id: "sleep", titleKey: "cat.option.sleep", assetName: "CatSleep"),
        .init(id: "stretch", titleKey: "cat.option.stretch", assetName: "CatStretch"),
        .init(id: "nap", titleKey: "cat.option.nap", assetName: "CatNap"),
    ]

    private(set) var phase: Phase = .idle
    private(set) var remainingSeconds: Int = 0
    private(set) var completedWorkSessions: Int = 0
    private(set) var skippedBreakCount: Int = 0
    private(set) var totalBreakSecondsToday: Int = 0
    private(set) var overlayMode: OverlayMode = .none
    private(set) var overlayRandomCatID: String?

    private(set) var workMinutes: Int
    private(set) var breakMinutes: Int

    var autoStartOnLaunch: Bool {
        didSet {
            defaults.set(autoStartOnLaunch, forKey: Keys.autoStartOnLaunch)
        }
    }

    private(set) var selectedCatID: String

    var isBreakOverlayPresented: Bool {
        overlayMode != .none
    }

    var isBreakOverlayPreviewMode: Bool {
        overlayMode == .preview
    }

    var selectedCatAssetName: String {
        if selectedCatID == Self.randomCatID {
            if let overlayRandomCatID {
                return Self.catOptions.first(where: { $0.id == overlayRandomCatID })?.assetName ?? "CatSleep"
            }
            return "CatSleep"
        }
        return Self.catOptions.first(where: { $0.id == selectedCatID })?.assetName ?? "CatSleep"
    }

    var phaseTitle: String {
        switch phase {
        case .idle:
            return L10n.tr("phase.idle")
        case .work:
            return L10n.tr("phase.work")
        case .breakTime:
            return L10n.tr("phase.break")
        }
    }

    var remainingTimeText: String {
        format(seconds: remainingSeconds)
    }

    var menuBarTitle: String {
        switch phase {
        case .idle:
            return L10n.tr("menubar.idle")
        case .work:
            return L10n.tr("menubar.work", remainingTimeText)
        case .breakTime:
            return L10n.tr("menubar.break", remainingTimeText)
        }
    }

    private let defaults: UserDefaults
    private let timerEngine = TimerEngine()
    private let notificationService = NotificationService()
    private var breakElapsedSeconds = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedWork = defaults.integer(forKey: Keys.workMinutes)
        let savedBreak = defaults.integer(forKey: Keys.breakMinutes)
        workMinutes = savedWork > 0 ? savedWork : 30
        breakMinutes = savedBreak > 0 ? savedBreak : 5
        autoStartOnLaunch = defaults.object(forKey: Keys.autoStartOnLaunch) as? Bool ?? false
        selectedCatID = defaults.string(forKey: Keys.selectedCatID) ?? "sleep"
        if !Self.catOptions.contains(where: { $0.id == selectedCatID }) {
            selectedCatID = "sleep"
        }

        completedWorkSessions = defaults.integer(forKey: Keys.completedWorkSessions)
        skippedBreakCount = defaults.integer(forKey: Keys.skippedBreakCount)
        totalBreakSecondsToday = defaults.integer(forKey: Keys.totalBreakSecondsToday)

        resetStatsIfNeeded()
        remainingSeconds = workMinutes * 60

        if autoStartOnLaunch {
            startWorkSession()
        }
    }

    func bindNotificationPermission() {
        notificationService.requestAuthorization()
    }

    func setWorkMinutes(_ minutes: Int) {
        let clamped = max(1, minutes)
        guard workMinutes != clamped else { return }
        workMinutes = clamped
        defaults.set(clamped, forKey: Keys.workMinutes)
        if phase == .idle {
            remainingSeconds = clamped * 60
        }
    }

    func setBreakMinutes(_ minutes: Int) {
        let clamped = max(1, minutes)
        guard breakMinutes != clamped else { return }
        breakMinutes = clamped
        defaults.set(clamped, forKey: Keys.breakMinutes)
        if phase == .breakTime {
            remainingSeconds = min(remainingSeconds, clamped * 60)
        }
    }

    func setSelectedCat(_ catID: String) {
        guard Self.catOptions.contains(where: { $0.id == catID }) else { return }
        guard selectedCatID != catID else { return }
        selectedCatID = catID
        defaults.set(catID, forKey: Keys.selectedCatID)
        if selectedCatID != Self.randomCatID {
            overlayRandomCatID = nil
        } else if overlayMode != .none {
            overlayRandomCatID = resolveOverlayRandomCatID()
        }
    }

    func startWorkSession() {
        resetStatsIfNeeded()
        phase = .work
        closeOverlay()
        remainingSeconds = workMinutes * 60
        breakElapsedSeconds = 0
        notificationService.send(
            title: L10n.tr("notification.workStart.title"),
            body: L10n.tr("notification.workStart.body")
        )
        startTicking()
    }

    func startBreakSession() {
        phase = .breakTime
        openOverlay(mode: .breakTime)
        remainingSeconds = breakMinutes * 60
        breakElapsedSeconds = 0
        notificationService.send(
            title: L10n.tr("notification.breakStart.title"),
            body: L10n.tr("notification.breakStart.body")
        )
        startTicking()
    }

    func markBreakOverlayClosed() {
        closeOverlay()
    }

    func previewBreakOverlay() {
        guard overlayMode == .none else { return }
        openOverlay(mode: .preview)
    }

    func skipBreak() {
        guard phase == .breakTime else { return }
        skippedBreakCount += 1
        persistStats()
        startWorkSession()
    }

    func stopSession() {
        timerEngine.stop()
        phase = .idle
        closeOverlay()
        remainingSeconds = workMinutes * 60
    }

    private func startTicking() {
        timerEngine.start { [weak self] in
            self?.handleTick()
        }
    }

    private func handleTick() {
        guard phase != .idle else {
            timerEngine.stop()
            return
        }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
            if phase == .breakTime {
                breakElapsedSeconds += 1
            }
        }

        guard remainingSeconds == 0 else { return }

        switch phase {
        case .work:
            completedWorkSessions += 1
            persistStats()
            startBreakSession()
        case .breakTime:
            finishBreak()
        case .idle:
            break
        }
    }

    private func finishBreak() {
        totalBreakSecondsToday += breakElapsedSeconds
        persistStats()
        closeOverlay()
        notificationService.send(
            title: L10n.tr("notification.breakEnd.title"),
            body: L10n.tr("notification.breakEnd.body")
        )
        startWorkSession()
    }

    private func format(seconds: Int) -> String {
        let safeValue = max(0, seconds)
        let minutes = safeValue / 60
        let secs = safeValue % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func openOverlay(mode: OverlayMode) {
        overlayMode = mode
        if selectedCatID == Self.randomCatID {
            overlayRandomCatID = resolveOverlayRandomCatID()
        } else {
            overlayRandomCatID = nil
        }
    }

    private func closeOverlay() {
        overlayMode = .none
    }

    private func resolveOverlayRandomCatID() -> String {
        let candidates = Self.catOptions.filter { $0.id != Self.randomCatID }
        return candidates.randomElement()?.id ?? "sleep"
    }

    private func resetStatsIfNeeded() {
        let todayKey = Self.dayKey(for: Date())
        let lastDay = defaults.string(forKey: Keys.lastStatsDay)
        guard lastDay != todayKey else { return }

        completedWorkSessions = 0
        skippedBreakCount = 0
        totalBreakSecondsToday = 0
        defaults.set(todayKey, forKey: Keys.lastStatsDay)
        persistStats()
    }

    private func persistStats() {
        defaults.set(completedWorkSessions, forKey: Keys.completedWorkSessions)
        defaults.set(skippedBreakCount, forKey: Keys.skippedBreakCount)
        defaults.set(totalBreakSecondsToday, forKey: Keys.totalBreakSecondsToday)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private enum Keys {
    static let workMinutes = "workMinutes"
    static let breakMinutes = "breakMinutes"
    static let autoStartOnLaunch = "autoStartOnLaunch"
    static let selectedCatID = "selectedCatID"

    static let completedWorkSessions = "completedWorkSessions"
    static let skippedBreakCount = "skippedBreakCount"
    static let totalBreakSecondsToday = "totalBreakSecondsToday"
    static let lastStatsDay = "lastStatsDay"
}
