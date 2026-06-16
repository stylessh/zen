import AppKit

final class AudioWaveView: NSView {
    private var levels: [CGFloat] = Array(repeating: 0.12, count: 18)

    func update(_ levels: [CGFloat]) {
        self.levels = levels
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)

        let gap: CGFloat = 4
        let barWidth = max((bounds.width - CGFloat(levels.count - 1) * gap) / CGFloat(levels.count), 2)
        let midY = bounds.midY

        for (index, level) in levels.enumerated() {
            let height = max(bounds.height * level, 4)
            let x = CGFloat(index) * (barWidth + gap)
            let rect = CGRect(x: x, y: midY - height / 2, width: barWidth, height: height)
            let path = CGPath(roundedRect: rect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
            context.addPath(path)
            context.fillPath()
        }
    }
}
