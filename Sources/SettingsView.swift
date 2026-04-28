import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var pomodoro: PomodoroTimer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.greige.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 20)

                Divider()
                    .overlay(Color.wineDark.opacity(0.2))
                    .padding(.bottom, 24)

                DurationRow(label: "TRABAJO", value: $pomodoro.workDuration, range: 1...90)
                    .padding(.bottom, 20)

                DurationRow(label: "DESCANSO CORTO", value: $pomodoro.shortBreakDuration, range: 1...30)
                    .padding(.bottom, 20)

                DurationRow(label: "DESCANSO LARGO", value: $pomodoro.longBreakDuration, range: 1...60)
                    .padding(.bottom, 20)

                sessionRow
                    .padding(.bottom, 20)

                autoStartRow
                    .padding(.bottom, 32)

                applyButton
            }
            .padding(32)
        }
        .frame(width: 340, height: 440)
    }

    private var header: some View {
        HStack {
            Text("CONFIGURACIÓN")
                .font(.system(size: 10, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.wineDark)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.wineDark.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    private var sessionRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESIONES ANTES DE DESCANSO LARGO")
                .font(.system(size: 8, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.wineDark.opacity(0.6))

            HStack(spacing: 16) {
                Slider(
                    value: Binding(
                        get: { Double(pomodoro.sessionsUntilLongBreak) },
                        set: { pomodoro.sessionsUntilLongBreak = Int($0) }
                    ),
                    in: 2...8,
                    step: 1
                )
                .tint(.wineDark)

                Text("\(pomodoro.sessionsUntilLongBreak)")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.wineDark)
                    .frame(width: 24, alignment: .trailing)
            }
        }
    }

    private var autoStartRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("AUTO-INICIO")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Color.wineDark.opacity(0.6))

                Text("Iniciar el siguiente ciclo automáticamente")
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color.wineDark.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $pomodoro.autoStart)
                .toggleStyle(.switch)
                .tint(.wineDark)
                .labelsHidden()
        }
    }

    private var applyButton: some View {
        Button {
            pomodoro.applySettings()
            dismiss()
        } label: {
            Text("APLICAR")
                .font(.system(size: 10, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.greige)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.wineDark)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Row

struct DurationRow: View {
    let label: String
    @Binding var value: TimeInterval
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.wineDark.opacity(0.6))

            HStack(spacing: 16) {
                Slider(
                    value: Binding(
                        get: { value / 60 },
                        set: { value = $0 * 60 }
                    ),
                    in: range,
                    step: 1
                )
                .tint(.wineDark)

                Text("\(Int(value / 60)) min")
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .foregroundStyle(Color.wineDark)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
}
