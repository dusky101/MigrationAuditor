//
//  iCloudCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 13/01/2026.
//

import Foundation

struct iCloudCollector {
    
    /// Account management types
    enum AccountManagementType {
        case appleBusinessManager  // Managed via Apple Business Manager
        case mdmManaged           // Has MDM but not ABM
        case personal             // Standard personal iCloud
    }
    
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
            // Check the management type
            let managementType = checkManagedAccountType(email: email)
            
            var accountSymbol: String
            var accountTypeDesc: String
            var developer: String
            
            switch managementType {
            case .appleBusinessManager:
                accountSymbol = "🏢"
                accountTypeDesc = "Apple Business Manager"
                developer = "Business/MDM"
            case .mdmManaged:
                accountSymbol = "🔐"
                accountTypeDesc = "MDM Managed"
                developer = "Business/MDM"
            case .personal:
                accountSymbol = "👤"
                accountTypeDesc = "Personal iCloud"
                developer = "Personal"
            }
            
            let details = "\(accountSymbol) \(accountTypeDesc) - \(email)"
            
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
                details: "❓ Signed in (email not detected)",
                developer: "iCloud",
                path: nil
            ))
        } else {
            // No iCloud account
            items.append(AuditItem(
                type: .systemSpec,
                name: "iCloud Account",
                details: "❌ Not signed in",
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
    
    /// Determine the management type of an iCloud account
    private static func checkManagedAccountType(email: String) -> AccountManagementType {
        // Check for Apple Business Manager indicators
        let isABM = checkForAppleBusinessManager()
        
        // Check for MDM profiles
        let hasMDM = checkForMDMProfile()
        
        let emailLower = email.lowercased()
        
        // Apple ID domains (can be used with ABM)
        let appleIDDomains = ["icloud.com", "me.com", "mac.com"]
        let isAppleID = appleIDDomains.contains { emailLower.hasSuffix($0) }
        
        // Common personal email providers (NEVER used with ABM)
        let personalEmailProviders = [
            "gmail.com", "googlemail.com",
            "hotmail.com", "outlook.com", "live.com", "msn.com",
            "yahoo.com", "ymail.com",
            "aol.com",
            "protonmail.com", "proton.me",
            "icloud.com", "me.com", "mac.com"
        ]
        let isPersonalEmailProvider = personalEmailProviders.contains { emailLower.hasSuffix($0) }
        
        // RULE 1: If it's a personal email provider (Gmail, Hotmail, etc.), it's ALWAYS personal
        // Even if MDM is present (could be leftover from previous enrollment)
        if isPersonalEmailProvider {
            return .personal
        }
        
        // RULE 2: If Apple Business Manager is explicitly detected AND it's an Apple ID, it's ABM
        if isABM && isAppleID {
            return .appleBusinessManager
        }
        
        // RULE 3: If there's active MDM and it's a custom corporate domain, it's MDM managed
        if hasMDM && !isAppleID {
            return .mdmManaged
        }
        
        // RULE 4: Custom domain without MDM = likely corporate but unmanaged
        if !isAppleID && !isPersonalEmailProvider {
            return .mdmManaged
        }
        
        // RULE 5: Default to personal
        return .personal
    }
    
    /// Check for Apple Business Manager enrollment
    private static func checkForAppleBusinessManager() -> Bool {
        // Method 1: Check for DEP/ABM enrollment via profiles
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/bin/profiles"
        task.arguments = ["status", "-type", "enrollment"]
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for ABM/DEP enrollment indicators
                let abmKeywords = ["Enrolled via DEP", "Device Enrollment", "User Approved", "enrollment"]
                for keyword in abmKeywords {
                    if output.contains(keyword) {
                        return true
                    }
                }
            }
        } catch {
            // Silently fail
        }
        
        // Method 2: Check for the presence of ABM-related files
        let abmIndicatorPaths = [
            "/Library/Application Support/com.apple.TCC/MDMOverrides.plist",
            "/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord",
            "/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
        ]
        
        for path in abmIndicatorPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
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
                // Only consider it MDM if there are ACTIVE profiles
                // Check for actual profile identifiers, not just the word "Configuration"
                let lines = output.components(separatedBy: .newlines)
                
                var hasActiveProfiles = false
                for line in lines {
                    // Look for actual MDM profile indicators
                    if line.contains("com.apple.mdm") || 
                       line.contains("devicemanagement") ||
                       (line.contains("Attribute: profileIdentifier:") && line.contains("mdm")) {
                        hasActiveProfiles = true
                        break
                    }
                }
                
                // Also check if there are ANY configuration profiles installed
                // If output contains profile UUIDs or identifiers, MDM might be active
                if !hasActiveProfiles && output.contains("profileIdentifier") {
                    // There are some profiles, check if they're MDM-related
                    if output.lowercased().contains("jamf") ||
                       output.lowercased().contains("intune") ||
                       output.lowercased().contains("workspace") ||
                       output.lowercased().contains("kandji") ||
                       output.lowercased().contains("mosyle") {
                        hasActiveProfiles = true
                    }
                }
                
                return hasActiveProfiles
            }
        } catch {
            // Silently fail
        }
        
        return false
    }
}
