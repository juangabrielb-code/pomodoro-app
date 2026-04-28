import SwiftUI

// MARK: - Theme

extension Color {
    static let greige   = Color(red: 0.769, green: 0.725, blue: 0.659) // #C4B9A8
    static let wineDark = Color(red: 0.447, green: 0.184, blue: 0.216) // #722F37
    static let wineMid  = Color(red: 0.580, green: 0.360, blue: 0.380)
}

// MARK: - Main View

struct ContentView: View {
    @EnvironmentObject var pomodoro: PomodoroTimer
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.greige.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 24)

                cycleLabel
                    .padding(.bottom, 28)

                TimerRingView()
                    .padding(.bottom, 28)

                SessionDotsView()
                    .padding(.bottom, 36)

                ControlsView()

                Spacer()
            }
            .padding(.horizontal, 36)
            .padding(.top, 32)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(pomodoro)
        }
    }

    private var topBar: some View {
        HStack {
            Text("pomodoro")
                .font(.system(size: 12, weight: .light, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.wineMid)

            Spacer()

            Button { showSettings.toggle() } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.wineDark)
            }
            .buttonStyle(.plain)
        }
    }

    private var cycleLabel: some View {
        Text(pomodoro.currentCycle.rawValue)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(4)
            .foregroundStyle(Color.wineDark)
            .animation(.easeInOut(duration: 0.3), value: pomodoro.currentCycle.rawValue)
    }
}

// MARK: - Timer Ring

struct TimerRingView: View {
    @EnvironmentObject var pomodoro: PomodoroTimer

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.wineDark.opacity(0.12), lineWidth: 5)

            Circle()
                .trim(from: 0, to: pomodoro.progress)
                .stroke(Color.wineDark, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: pomodoro.progress)

            Text(pomodoro.formattedTime)
                .font(.system(size: 50, weight: .thin, design: .monospaced))
                .foregroundStyle(Color.wineDark)
                .contentTransition(.numericText())
        }
        .frame(width: 188, height: 188)
    }
}

// MARK: - Session Dots

struct SessionDotsView: View {
    @EnvironmentObject var pomodoro: PomodoroTimer

    private var filled: Int {
        guard pomodoro.sessionsUntilLongBreak > 0 else { return 0 }
        return pomodoro.completedSessions % pomodoro.sessionsUntilLongBreak
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pomodoro.sessionsUntilLongBreak, id: \.self) { i in
                Circle()
                    .fill(i < filled ? Color.wineDark : Color.wineDark.opacity(0.18))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: filled)
            }
        }
    }
}

// MARK: - Controls

struct ControlsView: View {
    @EnvironmentObject var pomodoro: PomodoroTimer

    var body: some View {
        HStack(spacing: 44) {
            Button(action: pomodoro.reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.wineDark.opacity(0.65))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            Button(action: pomodoro.togglePlayPause) {
                Image(systemName: pomodoro.isRunning ? "pause" : "play.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.wineDark)
                    .frame(width: 60, height: 60)
                    .background(Color.wineDark.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])
            .animation(.easeInOut(duration: 0.15), value: pomodoro.isRunning)

            Button(action: pomodoro.skip) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.wineDark.opacity(0.65))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }
    }
}
