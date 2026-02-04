import Foundation
import OSLog

extension Clipboard {
    struct RuleUpdateReport: Sendable {
        let validCount: Int
        let invalidCount: Int
        let invalidRules: [Rule.ID]
    }

    protocol RegexEngineProtocol: Actor {
        func updateRules(_ rules: [Rule]) -> RuleUpdateReport
        func mask(_ content: String) async -> MatchResult
        func replace(content: String, mapping: [String: String?]) async -> String
        func scanForTokenIDs(_ content: String) async -> [String]
    }

    actor RegexEngine: RegexEngineProtocol {
        private var cachedRegexes: [Rule.ID: Regex<AnyRegexOutput>] = [:]
        private var combinedRegex: Regex<AnyRegexOutput>?
        private let tokenRegex: Regex<AnyRegexOutput>?
        private let logger = Logger(subsystem: "com.edsncfw.CodeMask", category: "RegexEngine")
        
        init() {
            // Pre-compile the token regex
            let pattern = "\\{\\{CM_T:([a-f0-9]{12})\\}\\}"
            do {
                self.tokenRegex = try Regex(pattern)
            } catch {
                print("Critical: Failed to compile token regex: \(error)")
                self.tokenRegex = nil
            }
        }
        
        func updateRules(_ rules: [Rule]) -> RuleUpdateReport {
            var newCache: [Rule.ID: Regex<AnyRegexOutput>] = [:]
            var invalidIDs: [Rule.ID] = []
            var patterns: [String] = []
            
            for rule in rules where rule.isEnabled {
                do {
                    let regex = try Regex(rule.pattern)
                    newCache[rule.id] = regex
                    patterns.append(rule.pattern)
                } catch {
                    logger.error("Error compiling regex for rule \(rule.id): \(error.localizedDescription)")
                    invalidIDs.append(rule.id)
                }
            }
            self.cachedRegexes = newCache
            
            // Optimization: Combined all rules into a single Regex for one-pass scanning.
            // Sorting by pattern string length descending helps the regex engine prioritize
            // longer matches in alternations (A|B).
            let sortedPatterns = patterns.sorted { $0.count > $1.count }
            
            if !sortedPatterns.isEmpty {
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
        
        func scanForTokenIDs(_ content: String) async -> [String] {
            guard let regex = tokenRegex else { return [] }
            
            let matches = content.matches(of: regex)
            let ids = matches.compactMap { match -> String? in
                // Group 1 is the ID
                if match.output.count > 1 {
                    let substring = match.output[1].substring
                    return String(substring ?? "")
                }
                return nil
            }
            // Return unique IDs
            return Array(Set(ids))
        }
        
        func replace(content: String, mapping: [String: String?]) async -> String {
            guard let regex = tokenRegex else {
                logger.error("Token regex not available")
                return content
            }
            
            var result = ""
            var currentIndex = content.startIndex
            
            let matches = content.matches(of: regex)
            
            for match in matches {
                // Append text before match
                if match.range.lowerBound > currentIndex {
                    result.append(contentsOf: content[currentIndex..<match.range.lowerBound])
                }
                
                let fullToken = content[match.range]
                // Extract ID: {{CM_T: (7 chars) ... }} (2 chars)
                // Length is 7 + 12 + 2 = 21
                let idStartIndex = fullToken.index(fullToken.startIndex, offsetBy: 7)
                let idEndIndex = fullToken.index(idStartIndex, offsetBy: 12)
                let id = String(fullToken[idStartIndex..<idEndIndex])
                
                if let secretOpt = mapping[id], let secret = secretOpt {
                    result.append(secret)
                } else {
                    // Mapping missing or value is nil
                    result.append(">>MISSING_SECRET<<")
                }
                
                currentIndex = match.range.upperBound
            }
            
            // Append remaining
            if currentIndex < content.endIndex {
                result.append(contentsOf: content[currentIndex..<content.endIndex])
            }
            
            return result
        }
        
        func mask(_ content: String) async -> MatchResult {
            guard let regex = combinedRegex else {
                return MatchResult(maskedString: content, secrets: [:])
            }
            
            let matches = content.matches(of: regex)
            
            var resultString = ""
            var secrets: [Token: String] = [:]
            var currentIndex = content.startIndex
            
            resultString.reserveCapacity(content.count)
            
            for match in matches {
                let fullRange = match.range
                var maskRange = fullRange
                
                // Robust Label Preservation:
                // Find all valid capture group ranges within this match.
                // We pick the range that starts LATEST (furthest to the right)
                // as the value to mask, assuming everything before it is the label.
                var latestCaptureRange: Range<String.Index>? = nil
                
                // index 0 is full match, so we check 1 onwards
                for i in 1..<match.output.count {
                    if let captureRange = match[i].range {
                        if latestCaptureRange == nil || captureRange.lowerBound > latestCaptureRange!.lowerBound {
                            latestCaptureRange = captureRange
                        }
                    }
                }
                
                if let target = latestCaptureRange {
                    maskRange = target
                }
                
                // Append text before maskRange (this includes any labels or surrounding text)
                if currentIndex < maskRange.lowerBound {
                    resultString.append(contentsOf: content[currentIndex..<maskRange.lowerBound])
                }
                
                // Create Token
                let matchText = String(content[maskRange])
                let fullUUID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                let shortID = String(fullUUID.prefix(12)).lowercased()
                let tokenString = "{{CM_T:\(shortID)}}"
                let token = Token(id: shortID)
                
                resultString.append(tokenString)
                secrets[token] = matchText
                
                currentIndex = maskRange.upperBound
            }
            
            // Append remaining text
            if currentIndex < content.endIndex {
                resultString.append(contentsOf: content[currentIndex..<content.endIndex])
            }
            
            return MatchResult(maskedString: resultString, secrets: secrets)
        }
    }
}
