import AppKit

final class StatusMenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let modelStatusItem = NSMenuItem(title: "models pending", action: nil, keyEquivalent: "")
    private let shortcutItem = NSMenuItem(title: "shortcut pending", action: nil, keyEquivalent: "")
    private let captureItem = NSMenuItem(title: "start listening", action: #selector(toggleListening), keyEquivalent: "")
    private let lastReminderItem = NSMenuItem(title: "no reminders yet", action: nil, keyEquivalent: "")

    private let onToggleListening: () -> Void
    private let onOpenModelsFolder: () -> Void
    private let onQuit: () -> Void

    init(
        onToggleListening: @escaping () -> Void,
        onOpenModelsFolder: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onToggleListening = onToggleListening
        self.onOpenModelsFolder = onOpenModelsFolder
        self.onQuit = onQuit
        super.init()
    }

    func install() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell.badge.waveform", accessibilityDescription: "Zen Reminder")
            button.imagePosition = .imageOnly
        }

        captureItem.target = self

        let modelsFolderItem = NSMenuItem(title: "open models folder", action: #selector(openModelsFolder), keyEquivalent: "")
        modelsFolderItem.target = self

        let quitItem = NSMenuItem(title: "quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        menu.addItem(captureItem)
        menu.addItem(.separator())
        menu.addItem(shortcutItem)
        menu.addItem(modelStatusItem)
        menu.addItem(modelsFolderItem)
        menu.addItem(.separator())
        menu.addItem(lastReminderItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func updateModelStatus(_ title: String) {
        modelStatusItem.title = title
    }

    func updateShortcut(_ title: String) {
        shortcutItem.title = "shortcut: \(title)"
    }

    func updateCaptureState(isRecording: Bool) {
        captureItem.title = isRecording ? "stop listening" : "start listening"
    }

    func updateLastReminder(_ reminder: Reminder) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        lastReminderItem.title = "\(reminder.title) - \(formatter.string(from: reminder.dueDate))"
    }

    @objc private func toggleListening() {
        onToggleListening()
    }

    @objc private func openModelsFolder() {
        onOpenModelsFolder()
    }

    @objc private func quit() {
        onQuit()
    }
}
