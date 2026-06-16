import AppKit
import Foundation
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let modelBootstrapper = ModelBootstrapper()
    private let permissionController = PermissionController()
    private let hotKeyController = HotKeyController()
    private let overlayController = ListeningOverlayController()
    private let audioCapture = AudioCaptureController()
    private let transcriber: SpeechTranscriber = NativeSpeechTranscriber()
    private let parser = ReminderIntentParser()
    private let store = ReminderStore()
    private let scheduler = ReminderScheduler()

    private lazy var statusMenuController = StatusMenuController(
        onToggleListening: { [weak self] in self?.toggleListening() },
        onOpenModelsFolder: { [weak self] in self?.openModelsFolder() },
        onQuit: { NSApplication.shared.terminate(nil) }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenuController.install()
        wireEvents()

        permissionController.requestNotificationAuthorization()
        permissionController.requestSpeechAuthorization()
        permissionController.requestMicrophoneAuthorization()

        Task { [modelBootstrapper] in
            await modelBootstrapper.bootstrapIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController.unregister()
        audioCapture.stopDiscarding()
    }

    private func wireEvents() {
        modelBootstrapper.onStatusChange = { [weak self] status in
            DispatchQueue.main.async {
                self?.statusMenuController.updateModelStatus(status.menuTitle)
            }
        }

        hotKeyController.onPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleListening()
            }
        }

        do {
            try hotKeyController.registerDefaultShortcut()
            statusMenuController.updateShortcut("control option space")
        } catch {
            statusMenuController.updateShortcut("shortcut unavailable")
        }
    }

    private func toggleListening() {
        if audioCapture.isRecording {
            finishListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        overlayController.show()
        statusMenuController.updateCaptureState(isRecording: true)

        do {
            try audioCapture.start { [weak self] levels in
                DispatchQueue.main.async {
                    self?.overlayController.updateAudioLevels(levels)
                }
            }
        } catch {
            overlayController.showMessage("microphone unavailable")
            statusMenuController.updateCaptureState(isRecording: false)
        }
    }

    private func finishListening() {
        statusMenuController.updateCaptureState(isRecording: false)
        overlayController.showMessage("understanding")

        audioCapture.stop { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let audioURL):
                Task { @MainActor in
                    await self.handleCapturedAudio(audioURL)
                }
            case .failure:
                DispatchQueue.main.async {
                    self.overlayController.showMessage("could not save audio")
                    self.overlayController.hide(after: 1.2)
                }
            }
        }
    }

    @MainActor
    private func handleCapturedAudio(_ audioURL: URL) async {
        do {
            let transcript = try await transcriber.transcribeAudio(at: audioURL)
            overlayController.showMessage("saving reminder")

            let intent = try parser.parse(transcript)
            try store.save(intent.reminder)
            try await scheduler.schedule(intent.reminder)

            overlayController.showMessage("reminder saved")
            overlayController.hide(after: 1.1)
            statusMenuController.updateLastReminder(intent.reminder)
        } catch {
            overlayController.showMessage("try again")
            overlayController.hide(after: 1.3)
        }

        try? FileManager.default.removeItem(at: audioURL)
    }

    private func openModelsFolder() {
        NSWorkspace.shared.open(modelBootstrapper.modelsDirectory)
    }
}
