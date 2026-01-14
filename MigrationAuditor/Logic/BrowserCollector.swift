//
//  BrowserCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 14/01/2026.
//

import Foundation

struct BrowserCollector {
    
    static func getBrowserInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        // --- Safari ---
        let safariBookmarks = homeDir.appendingPathComponent("Library/Safari/Bookmarks.plist")
        if fileManager.fileExists(atPath: safariBookmarks.path) {
            items.append(AuditItem(
                type: .browser,
                name: "Safari",
                details: "Bookmarks detected",
                developer: "Apple",
                path: safariBookmarks.path
            ))
        }
        
        // --- Google Chrome ---
        let chromeUserData = homeDir.appendingPathComponent("Library/Application Support/Google/Chrome")
        // Also check if the actual Chrome app exists to avoid false positives
        let chromeAppPath = "/Applications/Google Chrome.app"
        if fileManager.fileExists(atPath: chromeUserData.path) && fileManager.fileExists(atPath: chromeAppPath) {
            var profileCount = 0
            if let profiles = try? fileManager.contentsOfDirectory(atPath: chromeUserData.path) {
                for profile in profiles {
                    if profile.hasPrefix("Profile") || profile == "Default" {
                        profileCount += 1
                    }
                }
            }
            let detail = profileCount > 0 ? "\(profileCount) profile(s) detected" : "Installed"
            items.append(AuditItem(
                type: .browser,
                name: "Google Chrome",
                details: detail,
                developer: "Google",
                path: chromeUserData.path
            ))
        }
        
        // --- Microsoft Edge ---
        let edgeUserData = homeDir.appendingPathComponent("Library/Application Support/Microsoft Edge")
        let edgeAppPath = "/Applications/Microsoft Edge.app"
        if fileManager.fileExists(atPath: edgeUserData.path) && fileManager.fileExists(atPath: edgeAppPath) {
            var profileCount = 0
            if let profiles = try? fileManager.contentsOfDirectory(atPath: edgeUserData.path) {
                for profile in profiles {
                    if profile.hasPrefix("Profile") || profile == "Default" {
                        profileCount += 1
                    }
                }
            }
            let detail = profileCount > 0 ? "\(profileCount) profile(s) detected" : "Installed"
            items.append(AuditItem(
                type: .browser,
                name: "Microsoft Edge",
                details: detail,
                developer: "Microsoft",
                path: edgeUserData.path
            ))
        }
        
        // --- Firefox ---
        let firefoxProfiles = homeDir.appendingPathComponent("Library/Application Support/Firefox/Profiles")
        if fileManager.fileExists(atPath: firefoxProfiles.path) {
            var profileCount = 0
            if let profiles = try? fileManager.contentsOfDirectory(atPath: firefoxProfiles.path) {
                profileCount = profiles.filter { $0.contains(".") }.count
            }
            let detail = profileCount > 0 ? "\(profileCount) profile(s) detected" : "Installed"
            items.append(AuditItem(
                type: .browser,
                name: "Firefox",
                details: detail,
                developer: "Mozilla",
                path: firefoxProfiles.path
            ))
        }
        
        // --- Brave ---
        let braveUserData = homeDir.appendingPathComponent("Library/Application Support/BraveSoftware/Brave-Browser")
        if fileManager.fileExists(atPath: braveUserData.path) {
            var profileCount = 0
            if let profiles = try? fileManager.contentsOfDirectory(atPath: braveUserData.path) {
                for profile in profiles {
                    if profile.hasPrefix("Profile") || profile == "Default" {
                        profileCount += 1
                    }
                }
            }
            let detail = profileCount > 0 ? "\(profileCount) profile(s) detected" : "Installed"
            items.append(AuditItem(
                type: .browser,
                name: "Brave",
                details: detail,
                developer: "Brave Software",
                path: braveUserData.path
            ))
        }
        
        // --- Arc ---
        let arcUserData = homeDir.appendingPathComponent("Library/Application Support/Arc")
        if fileManager.fileExists(atPath: arcUserData.path) {
            items.append(AuditItem(
                type: .browser,
                name: "Arc",
                details: "User data detected",
                developer: "The Browser Company",
                path: arcUserData.path
            ))
        }
        
        return items
    }
}
