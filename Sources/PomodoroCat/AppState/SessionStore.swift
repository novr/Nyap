import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    enum Phase: String {
        case idle
        case work
        case breakTime
    }

    static let breakOverlayWindowID = "break-overlay"

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var completedWorkSessions: Int = 0
    @Published private(set) var skippedBreakCount: Int = 0
    @Published private(set) var totalBreakSecondsToday: Int = 0
    @Published var isBreakOverlayPresented: Bool = false

    @Published private(set) var workMinutes: Int
    @Published private(set) var breakMinutes: Int

    @Published var autoStartOnLaunch: Bool {
        didSet {
            defaults.set(autoStartOnLaunch, forKey: Keys.autoStartOnLaunch)
        }
    }

    @Published var catDisplayStyle: String {
        didSet {
            defaults.set(catDisplayStyle, forKey: Keys.catDisplayStyle)
        }
    }

    var phaseTitle: String {
        switch phase {
        case .idle:
            return "待機中"
        case .work:
            return "作業中"
        case .breakTime:
            return "休憩中"
        }
    }

    var remainingTimeText: String {
        format(seconds: remainingSeconds)
    }

    var menuBarTitle: String {
        switch phase {
        case .idle:
            return "🐱 待機"
        case .work:
            return "💼 \(remainingTimeText)"
        case .breakTime:
            return "😺 休憩 \(remainingTimeText)"
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
        catDisplayStyle = defaults.string(forKey: Keys.catDisplayStyle) ?? "static"

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

    func startWorkSession() {
        resetStatsIfNeeded()
        phase = .work
        isBreakOverlayPresented = false
        remainingSeconds = workMinutes * 60
        breakElapsedSeconds = 0
        notificationService.send(title: "作業スタート", body: "集中タイムを開始しました。")
        startTicking()
    }

    func startBreakSession() {
        phase = .breakTime
        remainingSeconds = breakMinutes * 60
        breakElapsedSeconds = 0
        isBreakOverlayPresented = true
        notificationService.send(title: "休憩スタート", body: "猫と一緒にひと休みしましょう。")
        startTicking()
    }

    func skipBreak() {
        guard phase == .breakTime else { return }
        skippedBreakCount += 1
        persistStats()
        isBreakOverlayPresented = false
        startWorkSession()
    }

    func stopSession() {
        timerEngine.stop()
        phase = .idle
        isBreakOverlayPresented = false
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
        isBreakOverlayPresented = false
        notificationService.send(title: "休憩終了", body: "作業に戻りましょう。")
        startWorkSession()
    }

    private func format(seconds: Int) -> String {
        let safeValue = max(0, seconds)
        let minutes = safeValue / 60
        let secs = safeValue % 60
        return String(format: "%02d:%02d", minutes, secs)
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
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private enum Keys {
    static let workMinutes = "workMinutes"
    static let breakMinutes = "breakMinutes"
    static let autoStartOnLaunch = "autoStartOnLaunch"
    static let catDisplayStyle = "catDisplayStyle"

    static let completedWorkSessions = "completedWorkSessions"
    static let skippedBreakCount = "skippedBreakCount"
    static let totalBreakSecondsToday = "totalBreakSecondsToday"
    static let lastStatsDay = "lastStatsDay"
}
