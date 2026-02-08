//
//  MediaLibraryCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 04/02/2026.
//

import Foundation

struct MediaLibraryCollector {
    
    // MARK: - Music Library
    
    static func getMusicLibraryInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let musicFolder = homeDir.appendingPathComponent("Music")
        
        // Check if Music folder exists and try to access it (will trigger permission prompt if needed)
        guard fileManager.fileExists(atPath: musicFolder.path) else {
            items.append(AuditItem(
                type: .musicLibrary,
                name: "No Music Folder",
                details: "Music folder not found",
                developer: "N/A",
                path: nil
            ))
            return items
        }
        
        // Get all subfolders in ~/Music
        do {
            let contents = try fileManager.contentsOfDirectory(at: musicFolder, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            
            for item in contents {
                // Check if it's a directory
                if let resourceValues = try? item.resourceValues(forKeys: [.isDirectoryKey]),
                   let isDirectory = resourceValues.isDirectory,
                   isDirectory {
                    
                    // Get folder size (will trigger permission prompt on first access)
                    if let size = getFolderSize(path: item.path) {
                        let sizeFormatted = formatBytes(size)
                        let folderName = item.lastPathComponent
                        
                        items.append(AuditItem(
                            type: .musicLibrary,
                            name: folderName,
                            details: sizeFormatted,
                            developer: "Music",
                            path: item.path
                        ))
                    }
                }
            }
            
        } catch {
            print("Error reading Music folder: \(error)")
        }
        
        // If no subfolders found, report that
        if items.isEmpty {
            items.append(AuditItem(
                type: .musicLibrary,
                name: "Empty Music Folder",
                details: "No music libraries found",
                developer: "N/A",
                path: musicFolder.path
            ))
        }
        
        return items
    }
    
    // MARK: - Photos Library
    
    static func getPhotosLibraryInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let picturesFolder = homeDir.appendingPathComponent("Pictures")
        
        // Check if Pictures folder exists
        guard fileManager.fileExists(atPath: picturesFolder.path) else {
            items.append(AuditItem(
                type: .photosLibrary,
                name: "No Pictures Folder",
                details: "Pictures folder not found",
                developer: "N/A",
                path: nil
            ))
            return items
        }
        
        // Look for Photos Library bundles (common names)
        let photosLibraryNames = [
            "Photos Library.photoslibrary",
            "Photos.photoslibrary",
            "Photo Library.photoslibrary"
        ]
        
        var foundPhotosLibrary = false
        
        for libraryName in photosLibraryNames {
            let libraryPath = picturesFolder.appendingPathComponent(libraryName)
            
            if fileManager.fileExists(atPath: libraryPath.path) {
                foundPhotosLibrary = true
                
                // Get the size of the Photos Library bundle
                if let size = getFolderSize(path: libraryPath.path) {
                    let sizeFormatted = formatBytes(size)
                    
                    items.append(AuditItem(
                        type: .photosLibrary,
                        name: libraryName,
                        details: sizeFormatted,
                        developer: "Apple",
                        path: libraryPath.path
                    ))
                } else {
                    items.append(AuditItem(
                        type: .photosLibrary,
                        name: libraryName,
                        details: "Unable to calculate size",
                        developer: "Apple",
                        path: libraryPath.path
                    ))
                }
            }
        }
        
        // If no Photos Library found, just report the Pictures folder
        if !foundPhotosLibrary {
            if let size = getFolderSize(path: picturesFolder.path) {
                let sizeFormatted = formatBytes(size)
                
                items.append(AuditItem(
                    type: .photosLibrary,
                    name: "Pictures Folder",
                    details: sizeFormatted,
                    developer: "Pictures",
                    path: picturesFolder.path
                ))
            } else {
                items.append(AuditItem(
                    type: .photosLibrary,
                    name: "No Photos Library",
                    details: "No Photos Library detected",
                    developer: "N/A",
                    path: nil
                ))
            }
        }
        
        return items
    }
    
    // MARK: - Helper Functions
    
    /// Gets folder size (matching CloudStorageCollector pattern - will trigger permission prompt)
    /// Gets folder size - uses URL-based enumerator for better bundle support
    private static func getFolderSize(path: String) -> Int64? {
        let fileManager = FileManager.default
        let folderURL = URL(fileURLWithPath: path)
        
        // First: try a fast shell summary via 'du'
        if let shellSize = getFolderSizeViaShell(path: path) {
            return shellSize
        }
        
        // Fallback: enumerate files and sum allocated sizes (silent)
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey],
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return nil
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]),
               let size = resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize > 0 ? totalSize : nil
    }
    
    /// Fallback: Use shell command to get folder size (bypasses some permission issues)
    private static func getFolderSizeViaShell(path: String) -> Int64? {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/bin/du"
        task.arguments = ["-sk", path] // -s = summary, -k = kilobytes
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                // Output format: "123456\t/path/to/folder"
                let components = output.components(separatedBy: "\t")
                if let sizeString = components.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let sizeInKB = Int64(sizeString) {
                    return sizeInKB * 1024
                }
            }
        } catch {
            // Silent fail
        }
        return nil
    }
    
    /// Format bytes to human-readable string
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

