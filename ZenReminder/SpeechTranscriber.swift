import Foundation
import Speech

protocol SpeechTranscriber {
    func transcribeAudio(at url: URL) async throws -> String
}

final class NativeSpeechTranscriber: SpeechTranscriber {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))

    func transcribeAudio(at url: URL) async throws -> String {
        guard let recognizer, recognizer.isAvailable else {
            throw SpeechTranscriberError.unavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        return try await withCheckedThrowingContinuation { continuation in
            var didResume = false

            recognizer.recognitionTask(with: request) { result, error in
                guard !didResume else { return }

                if let error {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }

                guard let result, result.isFinal else { return }
                let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)

                if transcript.isEmpty {
                    didResume = true
                    continuation.resume(throwing: SpeechTranscriberError.emptyTranscript)
                } else {
                    didResume = true
                    continuation.resume(returning: transcript)
                }
            }
        }
    }
}

enum SpeechTranscriberError: Error {
    case unavailable
    case emptyTranscript
}
