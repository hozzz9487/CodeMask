# Security Policy

[繁體中文](SECURITY.md) | **English**

## Project Goals
CodeMask is a security-first utility designed to demonstrate low-level memory management and secure development workflows on macOS. While this is a solo-maintained project, I am committed to maintaining high security standards.

## Supported Versions
Security updates are currently provided only for the latest code on the `prod` branch.

| Version | Status |
| :--- | :--- |
| Latest (prod) | ✅ Supported |
| Others | ❌ Not Supported |

## Reporting a Vulnerability
If you discover a security vulnerability, please **do not** open a public GitHub Issue.

Instead, please use the GitHub **[Private Vulnerability Reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)** feature:
1. Navigate to the **Security** tab of this repository.
2. Click on **Advisories** -> **Report a vulnerability**.

As a solo developer, I will do my best to provide an initial evaluation and response within one week of receiving a report.

## Security Best Practices in CodeMask
To protect user privacy, CodeMask implements several core security mechanisms:
- **`mlock` Memory Locking**: Prevents sensitive raw data from being written to swap space or disk.
- **Zero External Communication**: The application has no network access permissions, ensuring data never leaves the local machine.
- **Swift 6 Strict Concurrency**: Utilizes the latest concurrency safety models to eliminate memory leaks or accidental data exposure caused by race conditions.

---
*Thank you for your help in keeping the developer community secure.*
