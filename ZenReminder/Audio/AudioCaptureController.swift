import AVFoundation
import CoreGraphics
import Foundation

final class AudioCaptureController {
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private let queue = DispatchQueue(label: "audio.capture.queue")

    var isRecording: Bool {
        engine.isRunning
    }

    func start(onLevels: @escaping ([CGFloat]) -> Void) throws {
        stopDiscarding()

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("zen-reminder-\(UUID().uuidString)")
            .appendingPathExtension("wav")

        outputURL = url
        audioFile = try AVAudioFile(forWriting: url, settings: format.settings)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }

            self.queue.async {
                try? self.audioFile?.write(from: buffer)
            }

            onLevels(AudioCaptureController.levels(from: buffer))
        }

        engine.prepare()
        try engine.start()
    }

    func stop(completion: @escaping (Result<URL, Error>) -> Void) {
        guard isRecording, let outputURL else {
            completion(.failure(AudioCaptureError.notRecording))
            return
        }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        queue.async { [weak self] in
            self?.audioFile = nil
            DispatchQueue.main.async {
                completion(.success(outputURL))
            }
        }
    }

    func stopDiscarding() {
        if isRecording {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }

        if let outputURL {
            try? FileManager.default.removeItem(at: outputURL)
        }

        audioFile = nil
        outputURL = nil
    }

    private static func levels(from buffer: AVAudioPCMBuffer) -> [CGFloat] {
        guard let channel = buffer.floatChannelData?[0] else {
            return Array(repeating: 0.08, count: 18)
        }

        let frameCount = Int(buffer.frameLength)
        let bucketCount = 18
        let framesPerBucket = max(frameCount / bucketCount, 1)

        return (0..<bucketCount).map { bucket in
            let start = bucket * framesPerBucket
            let end = min(start + framesPerBucket, frameCount)
            guard start < end else { return 0.08 }

            var sum: Float = 0
            for frame in start..<end {
                sum += abs(channel[frame])
            }

            let average = CGFloat(sum / Float(end - start))
            return min(max(average * 9, 0.08), 1)
        }
    }
}

enum AudioCaptureError: Error {
    case notRecording
}
