import AppKit

final class AuroraPillView: NSVisualEffectView {
    private let gradientLayer = CAGradientLayer()
    private let waveView = AudioWaveView()
    private let label = NSTextField(labelWithString: "listening")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height / 2

        let inset: CGFloat = 12
        let waveWidth: CGFloat = 146
        waveView.frame = NSRect(
            x: inset,
            y: 16,
            width: waveWidth,
            height: bounds.height - 32
        )
        label.frame = NSRect(
            x: waveView.frame.maxX + 12,
            y: 0,
            width: bounds.width - waveView.frame.maxX - 24,
            height: bounds.height
        )
    }

    func showListening() {
        label.stringValue = "listening"
        waveView.isHidden = false
        animateGradient()
    }

    func showMessage(_ message: String) {
        label.stringValue = message
        waveView.isHidden = true
        animateGradient()
    }

    func updateAudioLevels(_ levels: [CGFloat]) {
        waveView.update(levels)
    }

    private func configure() {
        wantsLayer = true
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active

        layer?.cornerRadius = 36
        layer?.masksToBounds = true
        layer?.borderColor = NSColor.white.withAlphaComponent(0.26).cgColor
        layer?.borderWidth = 1

        gradientLayer.colors = [
            NSColor.systemTeal.withAlphaComponent(0.55).cgColor,
            NSColor.systemPink.withAlphaComponent(0.45).cgColor,
            NSColor.systemIndigo.withAlphaComponent(0.50).cgColor,
            NSColor.systemMint.withAlphaComponent(0.45).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.opacity = 0.9
        layer?.insertSublayer(gradientLayer, at: 0)

        waveView.wantsLayer = true
        addSubview(waveView)

        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.alignment = .left
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)
    }

    private func animateGradient() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-0.4, 0.0, 0.5, 1.0]
        animation.toValue = [0.0, 0.45, 0.8, 1.4]
        animation.duration = 2.8
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        gradientLayer.add(animation, forKey: "aurora-locations")
    }
}
