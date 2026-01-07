//
//  Strings.swift
//  CodeMask
//
//  Localization strings for CodeMask UI and error messages
//  Created by Edison on 2026/1/7.
//

import Foundation

/// Localized strings for CodeMask application
enum Strings {
    // MARK: - Permission-Related Strings
    
    static let permissionAlertTitle = "需要權限"
    
    static let permissionAlertMessage = "CodeMask 需要輔助功能和輸入監控權限才能正常運作。請在系統設定中授予權限。"
    
    static let openSettingsButton = "打開設定"
    
    static let quitButton = "結束"
    
    // MARK: - Menu Bar Strings
    
    static let menuItemSafe = "安全"
    
    static let menuItemSetupRequired = "需要設定"
    
    static let menuItemCodeMaskPrefix = "CodeMask："
    
    static let menuItemOpenSystemPreferences = "打開系統設定"
    
    static let menuItemQuit = "結束"
    
    // MARK: - Status Strings
    
    static let statusSafe = "安全"
    
    static let statusUnsafe = "需要設定"
    
    // MARK: - Accessibility Descriptions
    
    static let accessibilityPermissionDescription = "CodeMask 需要輔助功能權限以貼上來自快捷指令的文字"
    
    static let inputMonitoringPermissionDescription = "CodeMask 需要輸入監控權限以偵測系統快捷鍵"
    
    static let safeStatusIconDescription = "CodeMask 安全"
    
    static let lockShieldIconDescription = "lock.shield"
    
    // MARK: - Restart Notification Strings
    
    static let restartAlertTitle = "權限已改變"
    
    static let restartAlertMessage = "輸入監控權限已改變。為了確保 CodeMask 正常運作，請重啟應用。"
    
    static let restartButton = "立即重啟"
    
    static let remindLaterButton = "稍後提醒"
}
