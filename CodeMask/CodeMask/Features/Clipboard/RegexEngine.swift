import Foundation
import OSLog

extension Clipboard {
    struct RuleUpdateReport: Sendable {
        let validCount: Int
        let invalidCount: Int
        let invalidRules: [Rule.ID]
    }

    actor RegexEngine {
        private var cachedRegexes: [Rule.ID: Regex<AnyRegexOutput>] = [:]
        private var combinedRegex: Regex<AnyRegexOutput>?
        private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "RegexEngine")
        
        func updateRules(_ rules: [Rule]) -> RuleUpdateReport {
            var newCache: [Rule.ID: Regex<AnyRegexOutput>] = [:]
            var invalidIDs: [Rule.ID] = []
            var validRulesForCombination: [String] = []
            
            for rule in rules where rule.isEnabled {
                do {
                    let regex = try Regex(rule.pattern)
                    newCache[rule.id] = regex
                    validRulesForCombination.append(rule.pattern)
                } catch {
                    logger.error("Error compiling regex for rule \(rule.id): \(error.localizedDescription)")
                    invalidIDs.append(rule.id)
                }
            }
            self.cachedRegexes = newCache
            
            // Optimization: Combine all rules into a single Regex for one-pass scanning.
            // Sort by length descending to ensure "Longest Match First" in alternation.
            let sortedPatterns = validRulesForCombination.sorted { $0.count > $1.count }
            
            if !sortedPatterns.isEmpty {
                // Wrap each pattern in non-capturing group (?:...) to isolate alternations
                let combinedPattern = sortedPatterns
                    .map { "(?:\($0))" }
                    .joined(separator: "|")
                
                do {
                    self.combinedRegex = try Regex(combinedPattern)
                } catch {
                    logger.error("Failed to compile combined regex: \(error.localizedDescription)")
                    self.combinedRegex = nil
                }
            } else {
                self.combinedRegex = nil
            }
            
            return RuleUpdateReport(
                validCount: newCache.count,
                invalidCount: invalidIDs.count,
                invalidRules: invalidIDs
            )
        }
        
        func mask(_ content: String) async -> MatchResult {
            guard let regex = combinedRegex else {
                return MatchResult(maskedString: content, secrets: [:])
            }
            
            let matches = content.matches(of: regex)
            
            var resultString = ""
            var secrets: [Token: String] = [:]
            var currentIndex = content.startIndex
            
            // Regex matches are non-overlapping and left-most first by definition.
            // Alternation order (Longest First) handles the priority.
            
            for match in matches {
                // Append text before match
                if currentIndex < match.range.lowerBound {
                    resultString.append(contentsOf: content[currentIndex..<match.range.lowerBound])
                }
                
                // Create Token
                let matchText = String(content[match.range])
                let uuid = UUID().uuidString
                let shortID = String(uuid.prefix(8))
                let tokenString = "{{CM_T:\(shortID)}}"
                let token = Token(id: shortID)
                
                resultString.append(tokenString)
                secrets[token] = matchText
                
                currentIndex = match.range.upperBound
            }
            
            // Append remaining text
            if currentIndex < content.endIndex {
                resultString.append(contentsOf: content[currentIndex..<content.endIndex])
            }
            
            return MatchResult(maskedString: resultString, secrets: secrets)
        }
    }
}
