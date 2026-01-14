//
//  FontCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 14/01/2026.
//

import Foundation

struct FontCollector {
    
    static func getFontInfo() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileManager = FileManager.default
        
        // Font locations to scan
        let fontPaths = [
            (path: "/Library/Fonts", type: "System-Wide", dev: "Admin Installed"),
            (path: fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts").path, type: "User Font", dev: "User Installed"),
            (path: "/Network/Library/Fonts", type: "Network Font", dev: "Network Server")
            // Note: We deliberately skip /System/Library/Fonts as those are immutable macOS files
            // that exist on every Mac and don't need migration auditing.
        ]
        
        for (folderPath, _, devName) in fontPaths {
            guard fileManager.fileExists(atPath: folderPath) else { continue }
            
            guard let fontFiles = try? fileManager.contentsOfDirectory(atPath: folderPath) else { continue }
            
            let validExtensions = ["ttf", "otf", "ttc", "dfont"]
            
            for file in fontFiles {
                let ext = (file as NSString).pathExtension.lowercased()
                
                if validExtensions.contains(ext) {
                    // Create the full path
                    let fullPath = (folderPath as NSString).appendingPathComponent(file)
                    
                    // Get clean name (remove extension)
                    let name = (file as NSString).deletingPathExtension
                    
                    // Create an individual item for this font
                    items.append(AuditItem(
                        type: .font,
                        name: name,
                        details: fullPath, // Passing the path here allows the PDF to find the icon
                        developer: devName,
                        path: fullPath
                    ))
                }
            }
        }
        
        // If absolutely no custom fonts found, we can add a placeholder,
        // but usually it's cleaner to just show nothing if the lists are empty.
        if items.isEmpty {
            items.append(AuditItem(
                type: .font,
                name: "No Custom Fonts Found",
                details: "Using standard macOS fonts only",
                developer: "Apple",
                path: nil
            ))
        }
        
        return items
    }
}
