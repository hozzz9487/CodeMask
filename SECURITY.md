# 安全政策 (Security Policy)

**繁體中文** | [English](SECURITY_EN.md)

## 專案目標
CodeMask 是一個安全優先的工具，旨在展示 macOS 底層記憶體管理與安全開發流程。雖然這是一個個人維護的專案，但我仍致力於維持高品質的安全標準。

## 支援的版本
目前僅支援 `prod` 分支的最新代碼。

| 版本 | 狀態 |
| :--- | :--- |
| Latest (prod) | ✅ 安全修復 |
| Others | ❌ 不支援 |

## 如何回報漏洞
如果您發現安全性問題，請**不要**使用公開的 GitHub Issue。

請使用 GitHub 內建的 **[Private Vulnerability Reporting](https://docs.github.com/zh/code-security/how-tos/report-and-fix-vulnerabilities/report-a-vulnerability/privately-reporting-a-security-vulnerability)** 功能：
1. 導覽至此儲存庫的 **Security** 標籤頁。
2. 點擊 **Advisories** -> **Report a vulnerability**。

作為個人開發者，我會盡力在收到通知後一週內進行初步評估與回覆。

## 安全特性說明 (Best Practices)
為了保護用戶隱私，CodeMask 實作了以下核心安全機制：
- **`mlock` 記憶體鎖定**: 防止機密原始數據被寫入 Swap 空間或硬碟。
- **零外部通訊**: 應用程式完全不具備網路存取權限，確保數據不離開本地機器。
- **Swift 6 Strict Concurrency**: 採用嚴格的併發安全模型，消除因競態條件 (Race Conditions) 可能導致的記憶體洩漏或數據意外暴露。

---
*感謝您的協助，讓開發者的工作環境變得更安全。*
