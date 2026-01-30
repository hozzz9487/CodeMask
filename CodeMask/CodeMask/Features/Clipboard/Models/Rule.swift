import Foundation

extension Clipboard {
    struct Rule: Identifiable, Sendable {
        let id: UUID
        let pattern: String
        let isEnabled: Bool
        
        init(id: UUID = UUID(), pattern: String, isEnabled: Bool = true) {
            self.id = id
            self.pattern = pattern
            self.isEnabled = isEnabled
        }
    }
}

extension Clipboard.Rule {
    static var defaults: [Clipboard.Rule] {
        [
            Clipboard.Rule(
                id: UUID(),
                pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
                isEnabled: true
            ), // Email
            Clipboard.Rule(
                id: UUID(),
                pattern: "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)",
                isEnabled: true
            ), // URL
            Clipboard.Rule(
                id: UUID(),
                pattern: "\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b",
                isEnabled: true
            ), // IPv4
            Clipboard.Rule(
                id: UUID(),
                pattern: "(?i)(api[_-]?key[\\s:=]{1,10})([A-Za-z0-9_\\-]{16,})|(?i)(secret[\\s:=]{1,10})([A-Za-z0-9_\\-]{16,})",
                isEnabled: true
            ) // Generic Key (Detects label + value)
        ]
    }
}
