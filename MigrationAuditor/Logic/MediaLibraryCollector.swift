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
        
        // --- Apple Music / iTunes Library ---
        let musicLibraryPaths = [
            homeDir.appendingPathComponent("Music/Music/Media.localized/Music"),
            homeDir.appendingPathComponent("Music/iTunes/iTunes Music"),
            homeDir.appendingPathComponent("Music/Music/Music"),
            homeDir.appendingPathComponent("Music")
        ]
        
        var foundMusicLibrary = false
        
        for musicPath in musicLibraryPaths {
            if fileManager.fileExists(atPath: musicPath.path) {
                let (trackCount, totalSize) = analyzeMusicFolder(path: musicPath.path)
                
                if trackCount > 0 {
                    let sizeFormatted = formatBytes(totalSize)
                    let details = "\(trackCount) tracks - \(sizeFormatted)"
                    
                    items.append(AuditItem(
                        type: .musicLibrary,
                        name: "Apple Music Library",
                        details: details,
                        developer: "Apple",
                        path: musicPath.path
                    ))
                    foundMusicLibrary = true
                    break
                }
            }
        }
        
        // --- Spotify Local Files ---
        let spotifyLocalPath = homeDir.appendingPathComponent("Library/Application Support/Spotify/Users")
        if fileManager.fileExists(atPath: spotifyLocalPath.path) {
            if let size = getFolderSize(path: spotifyLocalPath.path) {
                let sizeFormatted = formatBytes(size)
                items.append(AuditItem(
                    type: .musicLibrary,
                    name: "Spotify Cache",
                    details: "Local data - \(sizeFormatted)",
                    developer: "Spotify",
                    path: spotifyLocalPath.path
                ))
            }
        }
        
        // If no music library found
        if !foundMusicLibrary {
            items.append(AuditItem(
                type: .musicLibrary,
                name: "No Music Library",
                details: "No local music collection detected",
                developer: "N/A",
                path: nil
            ))
        }
        
        return items
    }
    
    // MARK: - Photos Library
    
    static func getPhotosLibraryInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        // --- Apple Photos Library ---
        let photosLibraryPaths = [
            homeDir.appendingPathComponent("Pictures/Photos Library.photoslibrary"),
            homeDir.appendingPathComponent("Pictures/Photos.photoslibrary")
        ]
        
        var foundPhotosLibrary = false
        
        for photosPath in photosLibraryPaths {
            if fileManager.fileExists(atPath: photosPath.path) {
                // Get the bundle size
                if let size = getPhotosLibrarySize(path: photosPath.path) {
                    let sizeFormatted = formatBytes(size)
                    
                    // Try to count photos and videos
                    let (photoCount, videoCount) = countPhotosAndVideos(libraryPath: photosPath.path)
                    
                    var details = sizeFormatted
                    if photoCount > 0 || videoCount > 0 {
                        details = "\(photoCount) photos, \(videoCount) videos - \(sizeFormatted)"
                    }
                    
                    items.append(AuditItem(
                        type: .photosLibrary,
                        name: "Apple Photos Library",
                        details: details,
                        developer: "Apple",
                        path: photosPath.path
                    ))
                    foundPhotosLibrary = true
                    break
                }
            }
        }
        
        // --- iCloud Photos Status ---
        let iCloudPhotosPath = homeDir.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        if fileManager.fileExists(atPath: iCloudPhotosPath.path) {
            // This indicates iCloud Drive is active, but Photos might be using iCloud Photos
            // We can detect this by checking if the Photos library is relatively small (cloud-optimized)
        }
        
        // If no photos library found
        if !foundPhotosLibrary {
            items.append(AuditItem(
                type: .photosLibrary,
                name: "No Photos Library",
                details: "No Apple Photos library detected",
                developer: "N/A",
                path: nil
            ))
        }
        
        return items
    }
    
    // MARK: - Helper Functions
    
    /// Analyzes a music folder and returns (track count, total size)
    private static func analyzeMusicFolder(path: String) -> (Int, Int64) {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return (0, 0) }
        
        var trackCount = 0
        var totalSize: Int64 = 0
        let musicExtensions = ["mp3", "m4a", "aac", "flac", "wav", "aiff", "alac", "ogg"]
        
        // Limit iteration to avoid hanging
        let maxFiles = 5000
        var fileCount = 0
        
        while let file = enumerator.nextObject() as? String {
            fileCount += 1
            if fileCount > maxFiles { break }
            
            let filePath = (path as NSString).appendingPathComponent(file)
            let fileExtension = (file as NSString).pathExtension.lowercased()
            
            if musicExtensions.contains(fileExtension) {
                trackCount += 1
                
                if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
                   let fileSize = attrs[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        }
        
        return (trackCount, totalSize)
    }
    
    /// Gets the total size of a Photos library bundle
    private static func getPhotosLibrarySize(path: String) -> Int64? {
        let fileManager = FileManager.default
        
        // For Photos libraries, we want to get the whole bundle size
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        var totalSize: Int64 = 0
        var fileCount = 0
        let maxFiles = 10000 // Photos libraries can be large, but limit for safety
        
        for case let fileURL as URL in enumerator {
            fileCount += 1
            if fileCount > maxFiles { break }
            
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            if let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize > 0 ? totalSize : nil
    }
    
    /// Counts photos and videos in the Photos library
    private static func countPhotosAndVideos(libraryPath: String) -> (photos: Int, videos: Int) {
        let originalsPath = (libraryPath as NSString).appendingPathComponent("originals")
        
        guard let enumerator = FileManager.default.enumerator(atPath: originalsPath) else {
            return (0, 0)
        }
        
        var photoCount = 0
        var videoCount = 0
        
        let photoExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "tiff", "raw", "cr2", "nef", "dng"]
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv"]
        
        let maxFiles = 5000
        var fileCount = 0
        
        while let file = enumerator.nextObject() as? String {
            fileCount += 1
            if fileCount > maxFiles { break }
            
            let fileExtension = (file as NSString).pathExtension.lowercased()
            
            if photoExtensions.contains(fileExtension) {
                photoCount += 1
            } else if videoExtensions.contains(fileExtension) {
                videoCount += 1
            }
        }
        
        return (photoCount, videoCount)
    }
    
    /// Gets folder size with file limit for safety
    private static func getFolderSize(path: String) -> Int64? {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return nil }
        var totalSize: Int64 = 0
        var fileCount = 0
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
    
    /// Format bytes to human-readable string
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
