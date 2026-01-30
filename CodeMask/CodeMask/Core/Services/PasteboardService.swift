
import AppKit

/// Protocol defining pasteboard operations.
/// Must be safe to call from any actor, but implementation will enforce main thread safety where needed.
protocol PasteboardServiceProtocol: Sendable {
    /// Reads the current string from the pasteboard.
    /// Non-blocking, MainActor-safe.
    func string() async -> String?
    
    /// Writes a string to the pasteboard.
    /// MainActor-safe.
    func setString(_ content: String) async
}

/// Live implementation wrapping NSPasteboard.
final class LivePasteboardService: PasteboardServiceProtocol {
    
    // We use MainActor to interact with NSPasteboard safely
    @MainActor
    private func readFromPasteboard() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
    
    @MainActor
    private func writeToPasteboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
    func string() async -> String? {
        return await readFromPasteboard()
    }
    
    func setString(_ content: String) async {
        await writeToPasteboard(content)
    }
}
