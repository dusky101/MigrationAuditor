//
//  HomebrewCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 14/01/2026.
//

import Foundation

struct HomebrewCollector {
    
    static func getHomebrewPackages() -> [AuditItem] {
        var items: [AuditItem] = []
        
        // Check if Homebrew is installed
        let brewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"       // Intel
        ]
        
        var brewPath: String?
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                brewPath = path
                break
            }
        }
        
        guard let validBrewPath = brewPath else {
            items.append(AuditItem(
                type: .homebrew,
                name: "Homebrew Not Installed",
                details: "No Homebrew package manager detected",
                developer: "N/A",
                path: nil
            ))
            return items
        }
        
        // Homebrew is installed - note the location
        let brewLocation = validBrewPath.contains("/opt/homebrew") ? "Apple Silicon" : "Intel"
        items.append(AuditItem(
            type: .homebrew,
            name: "Homebrew Installed",
            details: "Location: \(brewLocation)",
            developer: "Homebrew",
            path: validBrewPath
        ))
        
        // Get list of installed formulae
        let formulae = runBrewCommand(brewPath: validBrewPath, args: ["list", "--formula", "-1"])
        if !formulae.isEmpty {
            let formulaeList = formulae.components(separatedBy: "\n").filter { !$0.isEmpty }
            items.append(AuditItem(
                type: .homebrew,
                name: "Brew Packages",
                details: "\(formulaeList.count) formulae installed",
                developer: "Homebrew",
                path: nil
            ))
            
            // Add top 10 packages as individual items (or all if less than 10)
            let topPackages = Array(formulaeList.prefix(20))
            for package in topPackages {
                items.append(AuditItem(
                    type: .homebrew,
                    name: package,
                    details: "Homebrew Formula",
                    developer: "Community",
                    path: nil
                ))
            }
            
            if formulaeList.count > 20 {
                items.append(AuditItem(
                    type: .homebrew,
                    name: "...and \(formulaeList.count - 20) more",
                    details: "Run 'brew list' to see all",
                    developer: "Homebrew",
                    path: nil
                ))
            }
        }
        
        // Get list of installed casks (GUI apps)
        let casks = runBrewCommand(brewPath: validBrewPath, args: ["list", "--cask", "-1"])
        if !casks.isEmpty {
            let caskList = casks.components(separatedBy: "\n").filter { !$0.isEmpty }
            items.append(AuditItem(
                type: .homebrew,
                name: "Brew Casks",
                details: "\(caskList.count) GUI apps installed",
                developer: "Homebrew",
                path: nil
            ))
            
            // Add casks as individual items
            for cask in caskList {
                items.append(AuditItem(
                    type: .homebrew,
                    name: cask,
                    details: "Homebrew Cask",
                    developer: "Community",
                    path: nil
                ))
            }
        }
        
        // Get list of taps
        let taps = runBrewCommand(brewPath: validBrewPath, args: ["tap"])
        if !taps.isEmpty {
            let tapList = taps.components(separatedBy: "\n").filter { !$0.isEmpty }
            if tapList.count > 3 { // More than default taps
                items.append(AuditItem(
                    type: .homebrew,
                    name: "Brew Taps",
                    details: "\(tapList.count) repositories",
                    developer: "Homebrew",
                    path: nil
                ))
            }
        }
        
        // If Homebrew is installed but no packages found, note it
        if items.count == 1 { // Only the "Homebrew Installed" item exists
            items.append(AuditItem(
                type: .homebrew,
                name: "No Packages Installed",
                details: "Homebrew is installed but no packages detected",
                developer: "Homebrew",
                path: nil
            ))
        }
        
        return items
    }
    
    // Helper: Run brew command and return output with timeout
    private static func runBrewCommand(brewPath: String, args: [String]) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: brewPath)
        task.arguments = args
        task.standardOutput = pipe
        task.standardError = Pipe() // Suppress errors
        
        // Set environment to avoid any interactive prompts
        var environment = ProcessInfo.processInfo.environment
        environment["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        environment["HOMEBREW_NO_INSTALL_CLEANUP"] = "1"
        task.environment = environment
        
        do {
            try task.run()
            
            // Add timeout of 10 seconds
            let timeoutSeconds = 10.0
            let startTime = Date()
            
            while task.isRunning {
                if Date().timeIntervalSince(startTime) > timeoutSeconds {
                    task.terminate()
                    return ""
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }
}
