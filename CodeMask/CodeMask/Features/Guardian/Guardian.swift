//
//  Guardian.swift
//  CodeMask
//
//  Created by Edison on 2026/2/12.
//

import Foundation

enum Guardian {
    struct State: Equatable {
        var isBrowserFocused: Bool = false
        var activeBrowserBundleID: String? = nil
    }
    
    enum Action: Equatable {
        case didActivateBrowserApp(bundleID: String)
        case didDeactivateBrowserApp
    }
}
