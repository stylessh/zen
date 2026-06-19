import AppKit

final class ListeningOverlayController {
    private let panel: NSPanel
    private let pillView = AuroraPillView()

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 72),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.ignoresMouseEvents = true
        panel.contentView = pillView
    }

    func show() {
        positionPanel()
        pillView.showListening()
        panel.orderFrontRegardless()
    }

    func showMessage(_ message: String) {
        positionPanel()
        pillView.showMessage(message)
        panel.orderFrontRegardless()
    }

    func updateAudioLevels(_ levels: [CGFloat]) {
        pillView.updateAudioLevels(levels)
    }

    func hide(after delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.panel.orderOut(nil)
        }
    }

    private func positionPanel() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }

        let size = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.minY + 34
        )
        panel.setFrameOrigin(origin)
    }
}
