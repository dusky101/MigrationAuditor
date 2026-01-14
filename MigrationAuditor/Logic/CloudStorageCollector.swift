//
//  CloudStorageCollector.swift
//  MigrationAuditor
//
//  Created by Marc Oliff on 14/01/2026.
//


import Foundation

struct CloudStorageCollector {
    
    static func getCloudStorageInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        // --- Dropbox ---
        let dropboxPaths = [
            homeDir.appendingPathComponent("Dropbox"),
            homeDir.appendingPathComponent("Library/CloudStorage/Dropbox")
        ]
        for path in dropboxPaths {
            if fileManager.fileExists(atPath: path.path) {
                var details = "Active"
                // Try to get folder size info
                if let size = getFolderSize(path: path.path) {
                    details = "Active - \(formatBytes(size))"
                }
                items.append(AuditItem(
                    type: .cloudStorage,
                    name: "Dropbox",
                    details: details,
                    developer: "Dropbox Inc",
                    path: path.path
                ))
                break
            }
        }
        
        // --- Google Drive ---
        let googleDrivePaths = [
            homeDir.appendingPathComponent("Google Drive"),
            homeDir.appendingPathComponent("Library/CloudStorage/GoogleDrive")
        ]
        for path in googleDrivePaths {
            if fileManager.fileExists(atPath: path.path) {
                var details = "Active"
                if let size = getFolderSize(path: path.path) {
                    details = "Active - \(formatBytes(size))"
                }
                items.append(AuditItem(
                    type: .cloudStorage,
                    name: "Google Drive",
                    details: details,
                    developer: "Google",
                    path: path.path
                ))
                break
            }
        }
        
        // --- OneDrive ---
        let oneDrivePaths = [
            homeDir.appendingPathComponent("OneDrive"),
            homeDir.appendingPathComponent("Library/CloudStorage/OneDrive-Personal"),
            homeDir.appendingPathComponent("Library/CloudStorage/OneDrive-Business")
        ]
        var oneDriveFound = false
        for path in oneDrivePaths {
            if fileManager.fileExists(atPath: path.path) && !oneDriveFound {
                var details = "Active"
                let pathString = path.path
                if pathString.contains("Business") {
                    details = "Business Account"
                } else if pathString.contains("Personal") {
                    details = "Personal Account"
                }
                if let size = getFolderSize(path: path.path) {
                    details += " - \(formatBytes(size))"
                }
                items.append(AuditItem(
                    type: .cloudStorage,
                    name: "OneDrive",
                    details: details,
                    developer: "Microsoft",
                    path: path.path
                ))
                oneDriveFound = true
            }
        }
        
        // --- Box ---
        let boxPath = homeDir.appendingPathComponent("Box")
        if fileManager.fileExists(atPath: boxPath.path) {
            var details = "Active"
            if let size = getFolderSize(path: boxPath.path) {
                details = "Active - \(formatBytes(size))"
            }
            items.append(AuditItem(
                type: .cloudStorage,
                name: "Box",
                details: details,
                developer: "Box Inc",
                path: boxPath.path
            ))
        }
        
        // --- pCloud ---
        let pCloudPath = homeDir.appendingPathComponent("pCloud Drive")
        if fileManager.fileExists(atPath: pCloudPath.path) {
            items.append(AuditItem(
                type: .cloudStorage,
                name: "pCloud",
                details: "Active",
                developer: "pCloud",
                path: pCloudPath.path
            ))
        }
        
        // --- Sync.com ---
        let syncPath = homeDir.appendingPathComponent("Sync")
        if fileManager.fileExists(atPath: syncPath.path) {
            items.append(AuditItem(
                type: .cloudStorage,
                name: "Sync.com",
                details: "Active",
                developer: "Sync.com",
                path: syncPath.path
            ))
        }
        
        // --- Mega ---
        let megaPath = homeDir.appendingPathComponent("Mega")
        if fileManager.fileExists(atPath: megaPath.path) {
            items.append(AuditItem(
                type: .cloudStorage,
                name: "MEGA",
                details: "Active",
                developer: "Mega Limited",
                path: megaPath.path
            ))
        }
        
        // --- Resilio Sync (formerly BitTorrent Sync) ---
        let resilioPath = homeDir.appendingPathComponent("Library/Application Support/Resilio Sync")
        if fileManager.fileExists(atPath: resilioPath.path) {
            items.append(AuditItem(
                type: .cloudStorage,
                name: "Resilio Sync",
                details: "Active",
                developer: "Resilio",
                path: resilioPath.path
            ))
        }
        
        // If no cloud storage found
        if items.isEmpty {
            items.append(AuditItem(
                type: .cloudStorage,
                name: "No Cloud Storage",
                details: "No third-party cloud storage detected",
                developer: "N/A",
                path: nil
            ))
        }
        
        return items
    }
    
    // Helper: Get folder size (quick estimate, not recursive to avoid hanging)
    private static func getFolderSize(path: String) -> Int64? {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return nil }
        var totalSize: Int64 = 0
        var fileCount = 0
        
        // Limit to prevent hanging on huge folders
        let maxFiles = 1000
        
        while let file = enumerator.nextObject() as? String {
            fileCount += 1
            if fileCount > maxFiles { break }
            
            let filePath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
               let fileSize = attrs[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize > 0 ? totalSize : nil
    }
    
    // Helper: Format bytes to human readable
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
