import Foundation
import AppKit
import UserNotifications

enum CycleType: String {
    case work       = "TRABAJO"
    case shortBreak = "DESCANSO CORTO"
    case longBreak  = "DESCANSO LARGO"
}

@MainActor
final class PomodoroTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval
    @Published var currentCycle: CycleType = .work
    @Published var isRunning = false
    @Published var completedSessions = 0
    @Published var progress: Double = 1.0

    @Published var workDuration: TimeInterval {
        didSet { UserDefaults.standard.set(workDuration, forKey: "workDuration") }
    }
    @Published var shortBreakDuration: TimeInterval {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: "shortBreakDuration") }
    }
    @Published var longBreakDuration: TimeInterval {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: "longBreakDuration") }
    }
    @Published var sessionsUntilLongBreak: Int {
        didSet { UserDefaults.standard.set(sessionsUntilLongBreak, forKey: "sessionsUntilLongBreak") }
    }
    @Published var autoStart: Bool {
        didSet { UserDefaults.standard.set(autoStart, forKey: "autoStart") }
    }

    private var timerSource: Timer?
    private var startDate: Date?
    private var timeRemainingOnStart: TimeInterval = 0
    private var totalDuration: TimeInterval

    init() {
        let d = UserDefaults.standard
        let work     = d.object(forKey: "workDuration") as? TimeInterval ?? 25 * 60
        let short    = d.object(forKey: "shortBreakDuration") as? TimeInterval ?? 5 * 60
        let long     = d.object(forKey: "longBreakDuration") as? TimeInterval ?? 15 * 60
        let sessions = d.object(forKey: "sessionsUntilLongBreak") as? Int ?? 4
        let auto     = d.object(forKey: "autoStart") as? Bool ?? false

        self.workDuration            = work
        self.shortBreakDuration      = short
        self.longBreakDuration       = long
        self.sessionsUntilLongBreak  = sessions
        self.autoStart               = auto
        self.timeRemaining           = work
        self.totalDuration           = work
    }

    var currentCycleDuration: TimeInterval {
        switch currentCycle {
        case .work:       return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak:  return longBreakDuration
        }
    }

    var formattedTime: String {
        let total = Int(ceil(timeRemaining))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    func togglePlayPause() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        timeRemainingOnStart = timeRemaining
        startDate = Date()
        isRunning = true
        timerSource = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(timerSource!, forMode: .common)
    }

    func pause() {
        isRunning = false
        startDate = nil
        timerSource?.invalidate()
        timerSource = nil
    }

    func reset() {
        pause()
        timeRemaining = currentCycleDuration
        totalDuration = currentCycleDuration
        progress = 1.0
    }

    func skip() {
        pause()
        advance(countSession: false)
    }

    func applySettings() {
        if !isRunning {
            totalDuration = currentCycleDuration
            timeRemaining = currentCycleDuration
            progress = 1.0
        }
    }

    // MARK: - Private

    private func tick() {
        guard let start = startDate else { return }
        let elapsed   = Date().timeIntervalSince(start)
        let remaining = max(0, timeRemainingOnStart - elapsed)
        timeRemaining = remaining
        progress      = totalDuration > 0 ? remaining / totalDuration : 0
        if remaining <= 0 { completeCycle() }
    }

    private func completeCycle() {
        pause()
        playAlarm()
        advance(countSession: currentCycle == .work)
        scheduleNotification(for: currentCycle) // currentCycle is already the next one after advance()
        if autoStart { start() }
    }

    private func advance(countSession: Bool) {
        switch currentCycle {
        case .work:
            if countSession { completedSessions += 1 }
            let goLong = completedSessions > 0 && completedSessions % sessionsUntilLongBreak == 0
            currentCycle = goLong ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            currentCycle = .work
        }
        totalDuration = currentCycleDuration
        timeRemaining = currentCycleDuration
        progress      = 1.0
    }

    private func playAlarm() {
        (NSSound(named: NSSound.Name("Glass")) ?? NSSound(named: NSSound.Name("Ping")))?.play()
    }

    private func scheduleNotification(for next: CycleType) {
        let content      = UNMutableNotificationContent()
        content.title    = next == .work ? "¡A trabajar!" : "¡Tiempo!"
        content.body     = next.rawValue
        content.sound    = nil // NSSound ya maneja el audio

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
