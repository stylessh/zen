import Foundation

final class ModelBootstrapper {
    var onStatusChange: ((ModelBootstrapStatus) -> Void)?

    let modelsDirectory: URL
    private let fileManager = FileManager.default
    private let modelSpecs: [ModelSpec]

    init(modelSpecs: [ModelSpec] = ModelCatalog.defaults) {
        self.modelSpecs = modelSpecs
        self.modelsDirectory = ModelBootstrapper.defaultModelsDirectory(fileManager: fileManager)
    }

    func bootstrapIfNeeded() async {
        do {
            try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)

            for spec in modelSpecs {
                try await ensureDownloaded(spec)
            }

            onStatusChange?(.ready)
        } catch {
            onStatusChange?(.failed)
        }
    }

    private func ensureDownloaded(_ spec: ModelSpec) async throws {
        let destination = modelsDirectory.appendingPathComponent(spec.fileName)

        if isUsableModel(at: destination, expectedBytes: spec.expectedBytes) {
            onStatusChange?(.available(spec))
            return
        }

        onStatusChange?(.downloading(spec))

        let temporaryDestination = destination.appendingPathExtension("download")
        try? fileManager.removeItem(at: temporaryDestination)

        let (downloadURL, response) = try await URLSession.shared.download(from: spec.remoteURL)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ModelBootstrapError.downloadFailed(http.statusCode)
        }

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: downloadURL, to: temporaryDestination)
        try fileManager.moveItem(at: temporaryDestination, to: destination)

        guard isUsableModel(at: destination, expectedBytes: spec.expectedBytes) else {
            throw ModelBootstrapError.invalidSize(spec.fileName)
        }

        onStatusChange?(.available(spec))
    }

    private func isUsableModel(at url: URL, expectedBytes: Int64) -> Bool {
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? NSNumber
        else {
            return false
        }

        return size.int64Value >= expectedBytes
    }

    private static func defaultModelsDirectory(fileManager: FileManager) -> URL {
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)

        return base
            .appendingPathComponent("ZenReminder", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }
}

enum ModelBootstrapStatus {
    case downloading(ModelSpec)
    case available(ModelSpec)
    case ready
    case failed

    var menuTitle: String {
        switch self {
        case .downloading(let spec):
            return "downloading \(spec.purpose.rawValue)"
        case .available(let spec):
            return "\(spec.purpose.rawValue) ready"
        case .ready:
            return "models ready"
        case .failed:
            return "model download failed"
        }
    }
}

enum ModelBootstrapError: Error {
    case downloadFailed(Int)
    case invalidSize(String)
}
