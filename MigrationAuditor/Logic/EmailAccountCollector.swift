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
                            let emailAddresses = account["EmailAddresses"] as? [String] ?? []
                            let primaryEmail = account["EmailAddress"] as? String
                            
                            var details: String
                            if !emailAddresses.isEmpty {
                                details = emailAddresses.joined(separator: ", ")
                            } else if let primaryEmail = primaryEmail, !primaryEmail.isEmpty {
                                details = primaryEmail
                            } else {
                                details = "Type: \(type)"
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
                for profile in profiles where profile != "." && profile != ".." {
                    let profileURL = outlookProfilePath.appendingPathComponent(profile)
                    var foundEmails: [String] = []
                    
                    // Common Outlook for Mac account storage locations
                    let candidateFiles = [
                        "Data/Outlook.sqlite", // older DB-based storage
                        "Data/Accounts.plist", // hypothetical plist
                        "Data/Account Settings.plist",
                        "Accounts.plist"
                    ]
                    
                    for rel in candidateFiles {
                        let url = profileURL.appendingPathComponent(rel)
                        if fileManager.fileExists(atPath: url.path) {
                            if let data = try? Data(contentsOf: url) {
                                // Try property list first
                                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                                    // Look for common keys
                                    if let accountsArray = plist["Accounts"] as? [[String: Any]] {
                                        for acc in accountsArray {
                                            if let email = acc["EmailAddress"] as? String, !email.isEmpty {
                                                foundEmails.append(email)
                                            } else if let smtp = acc["SMTPAddress"] as? String, !smtp.isEmpty {
                                                foundEmails.append(smtp)
                                            }
                                        }
                                    } else {
                                        // Flat plist: scan for any string values that look like emails
                                        foundEmails.append(contentsOf: extractEmails(fromPlist: plist))
                                    }
                                } else if let text = String(data: data, encoding: .utf8) {
                                    // Fallback: scan text content for email-like strings
                                    foundEmails.append(contentsOf: extractEmails(fromText: text))
                                } else {
                                    // Last resort: scan binary content for ASCII email patterns (e.g., within SQLite)
                                    foundEmails.append(contentsOf: extractEmails(fromBinary: data))
                                }
                            }
                        }
                    }
                    
                    let details: String
                    if !foundEmails.isEmpty {
                        // Deduplicate while preserving order
                        var seen = Set<String>()
                        let unique = foundEmails.filter { seen.insert($0.lowercased()).inserted }
                        details = unique.joined(separator: ", ")
                    } else {
                        details = profile
                    }
                    
                    items.append(AuditItem(
                        type: .emailAccount,
                        name: "Outlook Profile",
                        details: details,
                        developer: "Microsoft",
                        path: profileURL.path
                    ))
                }
            }
        }
        
        // Alternative Outlook path (newer versions)
        let outlookDataPath = homeDir.appendingPathComponent("Library/Containers/com.microsoft.Outlook")
        if fileManager.fileExists(atPath: outlookDataPath.path) {
            var details = "Account data detected"
            // Try the shared group container where Outlook often stores account info
            let groupContainer = homeDir.appendingPathComponent("Library/Group Containers/UBF8T346G9.Office/Outlook/Outlook 15 Profiles")
            if fileManager.fileExists(atPath: groupContainer.path) {
                // Attempt to reuse the above logic by listing profiles and extracting emails
                if let profiles = try? fileManager.contentsOfDirectory(atPath: groupContainer.path) {
                    var emails: [String] = []
                    for profile in profiles where profile != "." && profile != ".." {
                        let profileURL = groupContainer.appendingPathComponent(profile)
                        let rels = [
                            "Accounts.plist",
                            "Data/Accounts.plist",
                            "Data/Account Settings.plist",
                            "Data/Outlook.sqlite"
                        ]
                        for rel in rels {
                            let candidate = profileURL.appendingPathComponent(rel)
                            if fileManager.fileExists(atPath: candidate.path),
                               let data = try? Data(contentsOf: candidate) {
                                if candidate.pathExtension.lowercased() == "plist",
                                   let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                                    emails.append(contentsOf: extractEmails(fromPlist: plist))
                                } else if let text = String(data: data, encoding: .utf8) {
                                    emails.append(contentsOf: extractEmails(fromText: text))
                                } else {
                                    emails.append(contentsOf: extractEmails(fromBinary: data))
                                }
                            }
                        }
                    }
                    if !emails.isEmpty {
                        var seen = Set<String>()
                        let unique = emails.filter { seen.insert($0.lowercased()).inserted }
                        details = unique.joined(separator: ", ")
                    }
                }
            }
            // Also scan common Outlook preference plists for email addresses
            let prefCandidates = [
                homeDir.appendingPathComponent("Library/Group Containers/UBF8T346G9.Office/Library/Preferences/com.microsoft.Outlook.plist"),
                homeDir.appendingPathComponent("Library/Containers/com.microsoft.Outlook/Data/Library/Preferences/com.microsoft.Outlook.plist"),
                homeDir.appendingPathComponent("Library/Group Containers/UBF8T346G9.Office/Library/Preferences/com.microsoft.officeprefs.plist")
            ]
            for pref in prefCandidates where fileManager.fileExists(atPath: pref.path) {
                if let data = try? Data(contentsOf: pref),
                   let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                    let found = extractEmails(fromPlist: plist)
                    if !found.isEmpty {
                        var seen = Set<String>()
                        let unique = found.filter { seen.insert($0.lowercased()).inserted }
                        if details == "Account data detected" {
                            details = unique.joined(separator: ", ")
                        } else {
                            let current = details.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                            var seen2 = Set(current.map { $0.lowercased() })
                            let merged = current + unique.filter { seen2.insert($0.lowercased()).inserted }
                            details = merged.joined(separator: ", ")
                        }
                    }
                }
            }
            items.append(AuditItem(
                type: .emailAccount,
                name: "Outlook",
                details: details,
                developer: "Microsoft",
                path: outlookDataPath.path
            ))
        }
        
        // --- Thunderbird ---
        let thunderbirdProfilesPath = homeDir.appendingPathComponent("Library/Thunderbird/Profiles")
        if fileManager.fileExists(atPath: thunderbirdProfilesPath.path) {
            var totalEmails: [String] = []
            if let profiles = try? fileManager.contentsOfDirectory(atPath: thunderbirdProfilesPath.path) {
                for profile in profiles where profile.contains(".") {
                    let profileURL = URL(fileURLWithPath: thunderbirdProfilesPath.path).appendingPathComponent(profile)
                    // prefs.js often contains lines like: user_pref("mail.identity.id1.useremail", "name@example.com");
                    let prefsURL = profileURL.appendingPathComponent("prefs.js")
                    if fileManager.fileExists(atPath: prefsURL.path),
                       let text = try? String(contentsOf: prefsURL, encoding: .utf8) {
                        totalEmails.append(contentsOf: extractEmails(fromText: text))
                    }
                    // Newer Thunderbird may have JSON configs
                    let accountsJSON = profileURL.appendingPathComponent("accounts.json")
                    if fileManager.fileExists(atPath: accountsJSON.path),
                       let data = try? Data(contentsOf: accountsJSON) {
                        let json = try? JSONSerialization.jsonObject(with: data)
                        if let json {
                            totalEmails.append(contentsOf: extractEmails(fromAnyJSON: json))
                        }
                    }
                }
            }
            let details: String
            if !totalEmails.isEmpty {
                var seen = Set<String>()
                let unique = totalEmails.filter { seen.insert($0.lowercased()).inserted }
                details = unique.joined(separator: ", ")
            } else {
                let profileCount = (try? fileManager.contentsOfDirectory(atPath: thunderbirdProfilesPath.path).filter { $0.contains(".") }.count) ?? 0
                details = profileCount > 0 ? "\(profileCount) profile(s)" : "Installed"
            }
            items.append(AuditItem(
                type: .emailAccount,
                name: "Thunderbird",
                details: details,
                developer: "Mozilla",
                path: thunderbirdProfilesPath.path
            ))
        }
        
        // --- Spark ---
        let sparkPath = homeDir.appendingPathComponent("Library/Application Support/Spark")
        if fileManager.fileExists(atPath: sparkPath.path) {
            var details = "Account data detected"
            // Spark 2 stores accounts in JSON under Accounts.json or similar
            let candidates = [
                sparkPath.appendingPathComponent("Accounts.json"),
                sparkPath.appendingPathComponent("accounts.json"),
                sparkPath.appendingPathComponent("Preferences.plist")
            ]
            var emails: [String] = []
            for url in candidates where fileManager.fileExists(atPath: url.path) {
                if let data = try? Data(contentsOf: url) {
                    if url.pathExtension.lowercased() == "plist",
                       let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                        emails.append(contentsOf: extractEmails(fromPlist: plist))
                    } else if let text = String(data: data, encoding: .utf8) {
                        emails.append(contentsOf: extractEmails(fromText: text))
                    } else if let json = try? JSONSerialization.jsonObject(with: data) {
                        emails.append(contentsOf: extractEmails(fromAnyJSON: json))
                    }
                }
            }
            if !emails.isEmpty {
                var seen = Set<String>()
                let unique = emails.filter { seen.insert($0.lowercased()).inserted }
                details = unique.joined(separator: ", ")
            }
            items.append(AuditItem(
                type: .emailAccount,
                name: "Spark",
                details: details,
                developer: "Readdle",
                path: sparkPath.path
            ))
        }
        
        // --- Airmail ---
        let airmailPath = homeDir.appendingPathComponent("Library/Containers/it.bloop.airmail2")
        if fileManager.fileExists(atPath: airmailPath.path) {
            var details = "Account data detected"
            var emails: [String] = []
            let prefsDir = airmailPath.appendingPathComponent("Data/Library/Preferences")
            if fileManager.fileExists(atPath: prefsDir.path),
               let files = try? fileManager.contentsOfDirectory(atPath: prefsDir.path) {
                for file in files where file.hasSuffix(".plist") {
                    let url = prefsDir.appendingPathComponent(file)
                    if let data = try? Data(contentsOf: url),
                       let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                        emails.append(contentsOf: extractEmails(fromPlist: plist))
                    }
                }
            }
            if !emails.isEmpty {
                var seen = Set<String>()
                let unique = emails.filter { seen.insert($0.lowercased()).inserted }
                details = unique.joined(separator: ", ")
            }
            items.append(AuditItem(
                type: .emailAccount,
                name: "Airmail",
                details: details,
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
    
    // MARK: - Helpers
    private static func extractEmails(fromText text: String) -> [String] {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length)).map { ns.substring(with: $0.range) }
    }
    
    private static func extractEmails(fromPlist plist: [String: Any]) -> [String] {
        var results: [String] = []
        func walk(_ value: Any) {
            if let str = value as? String {
                results.append(contentsOf: extractEmails(fromText: str))
            } else if let dict = value as? [String: Any] {
                for (_, v) in dict { walk(v) }
            } else if let arr = value as? [Any] {
                for v in arr { walk(v) }
            }
        }
        walk(plist)
        return results
    }
    
    private static func extractEmails(fromAnyJSON json: Any) -> [String] {
        var results: [String] = []
        func walk(_ value: Any) {
            if let str = value as? String {
                results.append(contentsOf: extractEmails(fromText: str))
            } else if let dict = value as? [String: Any] {
                for (_, v) in dict { walk(v) }
            } else if let arr = value as? [Any] {
                for v in arr { walk(v) }
            }
        }
        walk(json)
        return results
    }
    
    private static func extractEmails(fromBinary data: Data) -> [String] {
        // Decode binary as UTF-8 (lossy) and run regex search for email patterns
        let text = String(decoding: data, as: UTF8.self)
        return extractEmails(fromText: text)
    }
}
