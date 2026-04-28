import SwiftUI
import UserNotifications

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { _, _ in }
    }

    // Show banners even when the app is in the foreground (no duplicate sound — NSSound handles audio)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }
}

// MARK: - App

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pomodoro = PomodoroTimer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pomodoro)
                .frame(
                    minWidth: 380, idealWidth: 380, maxWidth: 380,
                    minHeight: 480, idealHeight: 480, maxHeight: 480
                )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 380, height: 480)

        Settings {
            SettingsView()
                .environmentObject(pomodoro)
        }
    }
}
