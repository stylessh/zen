import Foundation

struct ModelSpec: Identifiable {
    enum Purpose: String {
        case speechToText = "speech-to-text"
        case intentUnderstanding = "intent-understanding"
    }

    let id: String
    let purpose: Purpose
    let fileName: String
    let remoteURL: URL
    let expectedBytes: Int64
}

enum ModelCatalog {
    static let defaults: [ModelSpec] = [
        ModelSpec(
            id: "whisper-base-en",
            purpose: .speechToText,
            fileName: "ggml-base.en.bin",
            remoteURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin")!,
            expectedBytes: 147_964_211
        ),
        ModelSpec(
            id: "qwen2.5-0.5b-instruct-q4",
            purpose: .intentUnderstanding,
            fileName: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            remoteURL: URL(string: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf")!,
            expectedBytes: 491_400_032
        )
    ]
}
