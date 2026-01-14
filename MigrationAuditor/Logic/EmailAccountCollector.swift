//
//  EmailAccountCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 14/01/2026.
//

import Foundation

struct EmailAccountCollector {
    
    static func getEmailAccounts() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        // --- Apple Mail Accounts ---
        let mailAccountsPath = homeDir.appendingPathComponent("Library/Mail/V10/MailData/Accounts.plist")
        let mailAccountsPathV9 = homeDir.appendingPathComponent("Library/Mail/V9/MailData/Accounts.plist")
        let mailAccountsPathV8 = homeDir.appendingPathComponent("Library/Mail/V8/MailData/Accounts.plist")
        
        // Try different Mail versions
        for accountPath in [mailAccountsPath, mailAccountsPathV9, mailAccountsPathV8] {
            if fileManager.fileExists(atPath: accountPath.path) {
                if let accountData = try? Data(contentsOf: accountPath),
                   let plist = try? PropertyListSerialization.propertyList(from: accountData, format: nil) as? [String: Any],
                   let accounts = plist["Accounts"] as? [[String: Any]] {
                    
                    for account in accounts {
                        if let accountName = account["AccountName"] as? String ?? account["DisplayName"] as? String {
                            let type = account["AccountType"] as? String ?? "Unknown"
                            let emailAddress = account["EmailAddresses"] as? [String] ?? []
                            
                            var details = "Type: \(type)"
                            if let firstEmail = emailAddress.first {
                                details = firstEmail
                            }
                            
                            items.append(AuditItem(
                                type: .emailAccount,
                                name: "Mail: \(accountName)",
                                details: details,
                                developer: "Apple Mail",
                                path: accountPath.path
                            ))
                        }
                    }
                }
                break // Stop after finding one valid version
            }
        }
        
        // --- Microsoft Outlook ---
        let outlookProfilePath = homeDir.appendingPathComponent("Library/Group Containers/UBF8T346G9.Office/Outlook/Outlook 15 Profiles")
        if fileManager.fileExists(atPath: outlookProfilePath.path) {
            if let profiles = try? fileManager.contentsOfDirectory(atPath: outlookProfilePath.path) {
                for profile in profiles {
                    if profile != "." && profile != ".." {
                        items.append(AuditItem(
                            type: .emailAccount,
                            name: "Outlook Profile",
                            details: profile,
                            developer: "Microsoft",
                            path: outlookProfilePath.path
                        ))
                    }
                }
            }
        }
        
        // Alternative Outlook path (newer versions)
        let outlookDataPath = homeDir.appendingPathComponent("Library/Containers/com.microsoft.Outlook")
        if fileManager.fileExists(atPath: outlookDataPath.path) {
            items.append(AuditItem(
                type: .emailAccount,
                name: "Outlook",
                details: "Account data detected",
                developer: "Microsoft",
                path: outlookDataPath.path
            ))
        }
        
        // --- Thunderbird ---
        let thunderbirdProfilesPath = homeDir.appendingPathComponent("Library/Thunderbird/Profiles")
        if fileManager.fileExists(atPath: thunderbirdProfilesPath.path) {
            if let profiles = try? fileManager.contentsOfDirectory(atPath: thunderbirdProfilesPath.path) {
                let profileCount = profiles.filter { $0.contains(".") }.count
                let details = profileCount > 0 ? "\(profileCount) profile(s)" : "Installed"
                items.append(AuditItem(
                    type: .emailAccount,
                    name: "Thunderbird",
                    details: details,
                    developer: "Mozilla",
                    path: thunderbirdProfilesPath.path
                ))
            }
        }
        
        // --- Spark ---
        let sparkPath = homeDir.appendingPathComponent("Library/Application Support/Spark")
        if fileManager.fileExists(atPath: sparkPath.path) {
            items.append(AuditItem(
                type: .emailAccount,
                name: "Spark",
                details: "Account data detected",
                developer: "Readdle",
                path: sparkPath.path
            ))
        }
        
        // --- Airmail ---
        let airmailPath = homeDir.appendingPathComponent("Library/Containers/it.bloop.airmail2")
        if fileManager.fileExists(atPath: airmailPath.path) {
            items.append(AuditItem(
                type: .emailAccount,
                name: "Airmail",
                details: "Account data detected",
                developer: "Bloop",
                path: airmailPath.path
            ))
        }
        
        // If no email accounts found
        if items.isEmpty {
            items.append(AuditItem(
                type: .emailAccount,
                name: "No Email Accounts",
                details: "No configured email clients detected",
                developer: "N/A",
                path: nil
            ))
        }
        
        return items
    }
}
