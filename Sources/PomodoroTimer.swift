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

    // MARK: - Published state

    @Published var timeRemaining: TimeInterval
    @Published var currentCycle: CycleType = .work
    @Published var isRunning = false
    @Published var completedSessions = 0
    @Published var progress: Double = 1.0
    @Published var isOvertime = false
    @Published var overtimeSeconds: TimeInterval = 0

    // MARK: - Settings (auto-persisted via didSet)

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

    // MARK: - Overtime stats (auto-persisted via didSet)

    @Published var totalWorkOvertime: TimeInterval {
        didSet { UserDefaults.standard.set(totalWorkOvertime, forKey: "totalWorkOvertime") }
    }
    @Published var totalBreakOvertime: TimeInterval {
        didSet { UserDefaults.standard.set(totalBreakOvertime, forKey: "totalBreakOvertime") }
    }

    // MARK: - Private

    private var timerSource: Timer?
    private var cycleEndDate: Date?   // absolute moment the cycle should end
    private var pauseDate: Date?      // moment we paused (nil when running)
    private var totalDuration: TimeInterval

    // MARK: - Init

    init() {
        let d = UserDefaults.standard
        let work     = d.object(forKey: "workDuration")           as? TimeInterval ?? 25 * 60
        let short    = d.object(forKey: "shortBreakDuration")     as? TimeInterval ?? 5 * 60
        let long     = d.object(forKey: "longBreakDuration")      as? TimeInterval ?? 15 * 60
        let sessions = d.object(forKey: "sessionsUntilLongBreak") as? Int          ?? 4
        let auto     = d.object(forKey: "autoStart")              as? Bool         ?? false
        let wOT      = d.object(forKey: "totalWorkOvertime")      as? TimeInterval ?? 0
        let bOT      = d.object(forKey: "totalBreakOvertime")     as? TimeInterval ?? 0

        self.workDuration           = work
        self.shortBreakDuration     = short
        self.longBreakDuration      = long
        self.sessionsUntilLongBreak = sessions
        self.autoStart              = auto
        self.totalWorkOvertime      = wOT
        self.totalBreakOvertime     = bOT
        self.timeRemaining          = work
        self.totalDuration          = work
    }

    // MARK: - Computed

    var currentCycleDuration: TimeInterval {
        switch currentCycle {
        case .work:       return workDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak:  return longBreakDuration
        }
    }

    var formattedTime: String {
        if isOvertime {
            let secs = Int(overtimeSeconds)
            return String(format: "+%02d:%02d", secs / 60, secs % 60)
        }
        let total = Int(ceil(timeRemaining))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // Preview the next cycle without mutating state (used for notification on overtime entry)
    private var peekNextCycle: CycleType {
        switch currentCycle {
        case .work:
            let next = completedSessions + 1
            guard sessionsUntilLongBreak > 0 else { return .shortBreak }
            return (next % sessionsUntilLongBreak == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    // MARK: - Public controls

    func togglePlayPause() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }

        if let pd = pauseDate, let endDate = cycleEndDate {
            // Resume: shift the end date forward by the time we were paused
            // This works correctly both in normal mode and in overtime mode.
            let pausedFor = Date().timeIntervalSince(pd)
            cycleEndDate = endDate.addingTimeInterval(pausedFor)
            pauseDate = nil
        } else {
            // Fresh start
            pauseDate = nil
            cycleEndDate = Date().addingTimeInterval(timeRemaining)
        }

        isRunning = true
        timerSource = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(timerSource!, forMode: .common)
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        pauseDate = Date()
        timerSource?.invalidate()
        timerSource = nil
    }

    func reset() {
        isRunning = false
        timerSource?.invalidate()
        timerSource = nil
        cycleEndDate = nil
        pauseDate = nil
        isOvertime = false
        overtimeSeconds = 0
        timeRemaining = currentCycleDuration
        totalDuration = currentCycleDuration
        progress = 1.0
    }

    func skip() {
        // Count session only if the timer reached 0 naturally (overtime was active)
        let shouldCount = isOvertime && currentCycle == .work
        accumulateOvertime()

        isRunning = false
        timerSource?.invalidate()
        timerSource = nil
        cycleEndDate = nil
        pauseDate = nil
        isOvertime = false
        overtimeSeconds = 0

        advance(countSession: shouldCount)
        if autoStart { start() }
    }

    func applySettings() {
        if !isRunning {
            cycleEndDate = nil
            pauseDate = nil
            isOvertime = false
            overtimeSeconds = 0
            totalDuration = currentCycleDuration
            timeRemaining = currentCycleDuration
            progress = 1.0
        }
    }

    // MARK: - Private

    private func tick() {
        guard let endDate = cycleEndDate else { return }

        // diff > 0: time still remaining. diff < 0: we're in overtime.
        let diff = endDate.timeIntervalSinceNow

        if diff > 0 {
            timeRemaining = diff
            progress = totalDuration > 0 ? diff / totalDuration : 0
        } else {
            timeRemaining = 0
            progress = 0

            if !isOvertime {
                // First tick past 0 — enter overtime
                isOvertime = true
                playAlarm()
                scheduleNotification(for: peekNextCycle)
            }
            overtimeSeconds = -diff   // diff is negative, so -diff is positive
        }
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
        progress = 1.0
    }

    // Add current overtime to the running total before clearing it.
    private func accumulateOvertime() {
        guard isOvertime && overtimeSeconds > 0 else { return }
        if currentCycle == .work {
            totalWorkOvertime += overtimeSeconds
        } else {
            totalBreakOvertime += overtimeSeconds
        }
    }

    private func playAlarm() {
        (NSSound(named: NSSound.Name("Glass")) ?? NSSound(named: NSSound.Name("Ping")))?.play()
    }

    private func scheduleNotification(for next: CycleType) {
        let content   = UNMutableNotificationContent()
        content.title = next == .work ? "¡A trabajar!" : "¡Es hora de descansar!"
        content.body  = next.rawValue
        content.sound = nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
