import Foundation

extension Clipboard {
    struct Token: Hashable, Sendable {
        let id: String
        
        init(id: String) {
            self.id = id
        }
    }
    
    struct MatchResult: Sendable {
        let maskedString: String
        let secrets: [Token: String]
        
        init(maskedString: String, secrets: [Token: String]) {
            self.maskedString = maskedString
            self.secrets = secrets
        }
    }
}
