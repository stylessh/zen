import AVFoundation
import Speech
import UserNotifications

final class PermissionController {
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    func requestMicrophoneAuthorization() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }
}
