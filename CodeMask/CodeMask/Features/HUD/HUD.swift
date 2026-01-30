
import Foundation
import SwiftUI

enum HUD {
    struct State: Equatable {
        var isVisible: Bool = false
        var message: String = ""
        var type: FeedbackType = .neutral
        
        enum FeedbackType {
            case neutral
            case success
            case error
        }
    }
    
    enum Action {
        case show(message: String, type: State.FeedbackType)
        case hide
    }
}
