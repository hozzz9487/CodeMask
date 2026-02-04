import Foundation

extension Clipboard {
    struct PresetLoader {
        enum PresetError: Error {
            case fileNotFound(String)
            case decodingFailed(Error)
        }
        
        static func loadMobilePresets(bundle: Bundle = .main) throws -> [Clipboard.Rule] {
            guard let url = bundle.url(forResource: "MobilePack", withExtension: "json") else {
                // If checking default bundle, allow silent failure or throw?
                // Story implies: "Update RegexEngine ... to load these presets"
                // If file missing (e.g. testing), returning empty might be safer than crashing default flow, 
                // but explicit error is better for dev.
                throw PresetError.fileNotFound("MobilePack.json")
            }
            return try loadRules(at: url)
        }
        
        static func loadRules(at url: URL) throws -> [Clipboard.Rule] {
            do {
                let data = try Data(contentsOf: url)
                let rules = try JSONDecoder().decode([Clipboard.Rule].self, from: data)
                return rules
            } catch {
                throw PresetError.decodingFailed(error)
            }
        }
    }
}
