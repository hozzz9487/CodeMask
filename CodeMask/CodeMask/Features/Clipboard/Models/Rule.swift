import Foundation

extension Clipboard {
    struct Rule: Identifiable, Sendable, Codable {
        let id: UUID
        let name: String
        let pattern: String
        let isEnabled: Bool
        
        init(id: UUID = UUID(), name: String, pattern: String, isEnabled: Bool = true) {
            self.id = id
            self.name = name
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
                name: "Email",
                pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
                isEnabled: true
            ),
            Clipboard.Rule(
                id: UUID(),
                name: "URL",
                pattern: "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)",
                isEnabled: true
            ),
            Clipboard.Rule(
                id: UUID(),
                name: "IPv4 Address",
                pattern: "\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b",
                isEnabled: true
            ),
            Clipboard.Rule(
                id: UUID(),
                name: "OpenAI API Key",
                pattern: "\\b(?:sk-[a-zA-Z0-9]{20,})\\b",
                isEnabled: true
            ),
            Clipboard.Rule(
                id: UUID(),
                name: "Generic API Key",
                pattern: "(?i)(api[_-]?key[\\s:=]{1,10})[\"']?([A-Za-z0-9_\\-]{16,})[\"']?|(?i)(secret[\\s:=]{1,10})[\"']?([A-Za-z0-9_\\-]{16,})[\"']?",
                isEnabled: true
            )
        ]
    }
}
