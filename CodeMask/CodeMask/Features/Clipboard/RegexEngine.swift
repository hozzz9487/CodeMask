import Foundation

extension Clipboard {
    actor RegexEngine {
        private var cachedRegexes: [Rule.ID: Regex<AnyRegexOutput>] = [:]
        
        func updateRules(_ rules: [Rule]) {
            var newCache: [Rule.ID: Regex<AnyRegexOutput>] = [:]
            for rule in rules where rule.isEnabled {
                do {
                    let regex = try Regex(rule.pattern)
                    newCache[rule.id] = regex
                } catch {
                    print("Error compiling regex for rule \(rule.id): \(error)")
                }
            }
            self.cachedRegexes = newCache
        }
        
        func mask(_ content: String) async -> MatchResult {
            struct CandidateMatch {
                let range: Range<String.Index>
                let ruleID: Rule.ID
                let text: Substring
            }
            
            var allMatches: [CandidateMatch] = []
            
            for (id, regex) in cachedRegexes {
                let matches = content.matches(of: regex)
                for match in matches {
                    allMatches.append(CandidateMatch(range: match.range, ruleID: id, text: content[match.range]))
                }
            }
            
            // Sort: Primary Length (Descending), Secondary Position (Ascending)
            allMatches.sort {
                if $0.text.count != $1.text.count {
                    return $0.text.count > $1.text.count
                }
                return $0.range.lowerBound < $1.range.lowerBound
            }
            
            var acceptedMatches: [CandidateMatch] = []
            
            for match in allMatches {
                let overlaps = acceptedMatches.contains { accepted in
                    match.range.overlaps(accepted.range)
                }
                
                if !overlaps {
                    acceptedMatches.append(match)
                }
            }
            
            // Re-sort by position for replacement
            acceptedMatches.sort { $0.range.lowerBound < $1.range.lowerBound }
            
            var resultString = ""
            var secrets: [Token: String] = [:]
            var currentIndex = content.startIndex
            
            for match in acceptedMatches {
                if currentIndex < match.range.lowerBound {
                    resultString.append(contentsOf: content[currentIndex..<match.range.lowerBound])
                }
                
                let uuid = UUID().uuidString
                let shortID = String(uuid.prefix(8))
                let tokenString = "{{CM_T:\(shortID)}}"
                let token = Token(id: shortID)
                
                resultString.append(tokenString)
                secrets[token] = String(match.text)
                
                currentIndex = match.range.upperBound
            }
            
            if currentIndex < content.endIndex {
                resultString.append(contentsOf: content[currentIndex..<content.endIndex])
            }
            
            return MatchResult(maskedString: resultString, secrets: secrets)
        }
    }
}
