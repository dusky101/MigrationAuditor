//
//  iCloudCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 13/01/2026.
//

import Foundation

struct iCloudCollector {
    
    /// Detects iCloud account status and type (personal vs managed)
    static func getiCloudAccountInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        
        // Method 1: Check iCloud account via defaults
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "MobileMeAccounts", "Accounts"]
        task.standardOutput = pipe
        task.standardError = Pipe() // Suppress errors
        
        var accountEmail: String?
        var accountType: String = "Not Detected"
        var isManaged = false
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                // Parse the output for email addresses
                // Look for patterns like "AccountID" or email addresses
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    // Look for AccountID or similar keys
                    if line.contains("AccountID") || line.contains("@") {
                        // Extract email using regex
                        if let emailMatch = extractEmail(from: line) {
                            accountEmail = emailMatch
                            break
                        }
                    }
                }
            }
        } catch {
            // Silently fail - no iCloud account detected
        }
        
        // Method 2: Check for iCloud account via system_profiler (more reliable)
        if accountEmail == nil {
            accountEmail = checkiCloudViaProfiler()
        }
        
        // Method 3: Check NSUbiquitousKeyValueStore availability
        let hasUbiquitousStore = FileManager.default.ubiquityIdentityToken != nil
        
        // Determine account status
        if let email = accountEmail {
            accountType = "Personal Account"
            
            // Check if it's a managed account
            // Managed accounts typically have MDM profiles or specific domain patterns
            if isManagedAccount(email: email) {
                accountType = "Managed Business Account"
                isManaged = true
            }
            
            let details = "Logged in: \(email)"
            let developer = isManaged ? "Business/MDM" : "Personal"
            
            items.append(AuditItem(
                type: .systemSpec,
                name: "iCloud Account",
                details: details,
                developer: developer,
                path: nil
            ))
        } else if hasUbiquitousStore {
            // iCloud is available but we couldn't get the email
            items.append(AuditItem(
                type: .systemSpec,
                name: "iCloud Account",
                details: "Signed in (email not detected)",
                developer: "iCloud",
                path: nil
            ))
        } else {
            // No iCloud account
            items.append(AuditItem(
                type: .systemSpec,
                name: "iCloud Account",
                details: "Not signed in",
                developer: "N/A",
                path: nil
            ))
        }
        
        return items
    }
    
    // MARK: - Helper Methods
    
    /// Extract email address from a string using regex
    private static func extractEmail(from text: String) -> String? {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first {
            return nsString.substring(with: match.range)
        }
        return nil
    }
    
    /// Check iCloud account via system_profiler
    private static func checkiCloudViaProfiler() -> String? {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPConfigurationProfileDataType", "-json"]
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for iCloud email in the output
                if let email = extractEmail(from: output) {
                    return email
                }
            }
        } catch {
            // Silently fail
        }
        
        return nil
    }
    
    /// Determine if an iCloud account is managed (business/MDM)
    private static func isManagedAccount(email: String) -> Bool {
        // Check for MDM profiles
        let hasMDMProfile = checkForMDMProfile()
        
        // Check for business domains (common patterns)
        let businessDomains = ["icloud.com", "me.com", "mac.com"]
        let isPersonalDomain = businessDomains.contains { email.lowercased().hasSuffix($0) }
        
        // If it's NOT a personal domain, it's likely managed
        if !isPersonalDomain {
            return true
        }
        
        // If MDM profile exists, it's managed
        if hasMDMProfile {
            return true
        }
        
        return false
    }
    
    /// Check for the presence of MDM (Mobile Device Management) profiles
    private static func checkForMDMProfile() -> Bool {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/bin/profiles"
        task.arguments = ["list"]
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for MDM-related keywords
                let mdmKeywords = ["MDM", "Device Management", "Configuration Profile", "com.apple.mdm"]
                for keyword in mdmKeywords {
                    if output.contains(keyword) {
                        return true
                    }
                }
            }
        } catch {
            // Silently fail
        }
        
        return false
    }
}
