import SwiftUI

struct MainView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("PomodoroCat")
                .font(.largeTitle.weight(.bold))

            GroupBox("現在の状態") {
                VStack(alignment: .leading, spacing: 8) {
                    Label(store.phaseTitle, systemImage: phaseIcon)
                        .font(.headline)
                    Text(store.remainingTimeText)
                        .font(.system(size: 42, weight: .semibold, design: .monospaced))
                    if store.phase == .breakTime {
                        Text("休憩残り時間を表示中")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("操作") {
                HStack(spacing: 10) {
                    Button("作業を開始") {
                        store.startWorkSession()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(store.phase == .work)

                    Button("停止") {
                        store.stopSession()
                    }
                    .disabled(store.phase == .idle)

                    Button("今は休憩しない") {
                        store.skipBreak()
                    }
                    .disabled(store.phase != .breakTime)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("設定") {
                VStack(alignment: .leading, spacing: 10) {
                    Stepper(value: $store.workMinutes, in: 1...180) {
                        Text("作業時間: \(store.workMinutes) 分")
                    }

                    Stepper(value: $store.breakMinutes, in: 1...60) {
                        Text("休憩時間: \(store.breakMinutes) 分")
                    }

                    Picker("猫表示スタイル", selection: $store.catDisplayStyle) {
                        Text("静止画像").tag("static")
                        Text("簡易アニメ").tag("animated")
                    }
                    .pickerStyle(.segmented)

                    Toggle("起動時に自動で作業開始", isOn: $store.autoStartOnLaunch)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("今日の実績") {
                HStack(spacing: 18) {
                    statColumn(title: "完了回数", value: "\(store.completedWorkSessions)")
                    statColumn(title: "スキップ回数", value: "\(store.skippedBreakCount)")
                    statColumn(title: "総休憩時間", value: formatBreakTotal(store.totalBreakSecondsToday))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
    }

    private var phaseIcon: String {
        switch store.phase {
        case .idle:
            return "pause.circle"
        case .work:
            return "briefcase.fill"
        case .breakTime:
            return "moon.zzz.fill"
        }
    }

    private func statColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.semibold))
        }
    }

    private func formatBreakTotal(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        return "\(minutes) 分"
    }
}
