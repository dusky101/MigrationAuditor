//
//  AuditLogic.swift
//  MigrationAuditor
//
//  Created by Marc on 02/01/2026.
//

import Foundation
import Combine

// --- 1. Data Models ---

struct SystemProfileItem: Codable {
    let _name: String?
    let version: String?
    let path: String?
    let info: String?
    let _items: [SystemProfileItem]?
}

struct SystemProfileRoot: Codable {
    let _items: [SystemProfileItem]
    let _dataType: String?
}

// What we show in the UI
struct AuditItem: Identifiable {
    let id = UUID()
    let type: ItemType
    let name: String
    let details: String
    let developer: String
    let path: String?
    
    enum ItemType: String {
        case mainApp = "Applications Folder"
        case app = "All System Software"
        case device = "External Peripherals"
        case networkDrive = "Network & Storage"
        case internalDevice = "Built-in / System"
        case printer = "Printers"
    }
}

// --- 2. The Logic Class ---

class AuditLogic: ObservableObject {
    @Published var isScanning = false
    @Published var progressMessage = "Ready"
    @Published var scannedItems: [AuditItem] = []
    
    // Developer Detective
    func detectDeveloper(from info: String?, name: String, path: String?) -> String {
        let infoString = (info ?? "").lowercased()
        let nameString = name.lowercased()
        let pathString = (path ?? "").lowercased()
        
        if pathString.hasPrefix("/system/") { return "Apple" }
        if ["safari", "numbers", "pages", "keynote", "xcode", "imovie", "garageband", "photos", "podcasts", "music", "tv", "mail", "finder"].contains(nameString) { return "Apple" }
        if infoString.contains("apple") || infoString.contains("mac app store") { return "Apple" }
        if infoString.contains("microsoft") || nameString.contains("microsoft") { return "Microsoft" }
        if infoString.contains("adobe") { return "Adobe" }
        if infoString.contains("google") || nameString.contains("google") { return "Google" }
        if infoString.contains("jamf") { return "Jamf" }
        if infoString.contains("zoom") { return "Zoom" }
        if infoString.contains("cisco") || nameString.contains("webex") { return "Cisco" }
        
        return "Other Developers"
    }
    
    // Helper to run command
    func runSystemProfiler(dataType: String) -> [SystemProfileItem] {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["-xml", dataType]
        task.standardOutput = pipe
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let decoder = PropertyListDecoder()
            let result = try decoder.decode([SystemProfileRoot].self, from: data)
            return result.first?._items ?? []
        } catch { return [] }
    }
    
    // --- UPDATED: Now accepts userName ---
    func performAudit(userName: String, completion: @escaping (String?) -> Void) {
        isScanning = true
        progressMessage = "Initialising scan..."
        DispatchQueue.main.async { self.scannedItems = [] }
        
        // Clean up user name for filename (remove spaces/special chars)
        let safeName = userName.components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
        
        DispatchQueue.global(qos: .userInitiated).async {
            var tempItems: [AuditItem] = []
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent("Migration_Audit_\(UUID().uuidString)")
            let driversDir = tempDir.appendingPathComponent("Printer_Drivers")
            try? fileManager.createDirectory(at: driversDir, withIntermediateDirectories: true, attributes: nil)
            
            // --- A. Scan /Applications Folder Manually ---
            DispatchQueue.main.async { self.progressMessage = "Checking Applications folder..." }
            let appFolderURL = URL(fileURLWithPath: "/Applications")
            if let urls = try? fileManager.contentsOfDirectory(at: appFolderURL, includingPropertiesForKeys: nil) {
                for url in urls {
                    if url.pathExtension == "app" {
                        let name = url.deletingPathExtension().lastPathComponent
                        tempItems.append(AuditItem(type: .mainApp, name: name, details: url.path, developer: "Installed App", path: url.path))
                    }
                }
            }
            
            // --- B. Scan Network & Storage Volumes ---
            DispatchQueue.main.async { self.progressMessage = "Scanning network drives..." }
            let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsLocalKey]
            if let mountedVolumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) {
                for volume in mountedVolumes {
                    if let values = try? volume.resourceValues(forKeys: Set(keys)) {
                        let name = values.volumeName ?? "Unknown Volume"
                        let isLocal = values.volumeIsLocal ?? true
                        let path = volume.path
                        if path == "/" { continue }
                        var typeDesc = "External Drive"
                        if !isLocal { typeDesc = "Network Share / NAS" }
                        tempItems.append(AuditItem(type: .networkDrive, name: name, details: typeDesc, developer: "Storage", path: path))
                    }
                }
            }
            
            // --- C. Scan System Profiler Apps ---
            DispatchQueue.main.async { self.progressMessage = "Analysing deep system info..." }
            let apps = self.runSystemProfiler(dataType: "SPApplicationsDataType")
            for app in apps {
                let name = (app._name ?? "Unknown").replacingOccurrences(of: ",", with: " ")
                let version = app.version ?? "N/A"
                let devName = self.detectDeveloper(from: app.info, name: name, path: app.path)
                tempItems.append(AuditItem(type: .app, name: name, details: version, developer: devName, path: app.path))
            }
            
            // --- D. Scan USB ---
            DispatchQueue.main.async { self.progressMessage = "Detecting peripherals..." }
            let usbDevices = self.runSystemProfiler(dataType: "SPUSBDataType")
            let internalKeywords = ["Bus", "Host Controller", "Root Hub", "Simulation", "Bridge", "Internal", "T2", "Ambient", "Touch Bar", "Backlight", "Sensor", "Headset", "Apple Internal", "Keyboard/Trackpad"]
            
            func parseUSBItems(_ items: [SystemProfileItem]) {
                for item in items {
                    let name = (item._name ?? "Unknown").replacingOccurrences(of: ",", with: " ")
                    var isInternal = false
                    for keyword in internalKeywords { if name.contains(keyword) { isInternal = true } }
                    let type: AuditItem.ItemType = isInternal ? .internalDevice : .device
                    let details = isInternal ? "System Hardware" : "Connected Device"
                    tempItems.append(AuditItem(type: type, name: name, details: details, developer: "Hardware", path: nil))
                    if let children = item._items { parseUSBItems(children) }
                }
            }
            parseUSBItems(usbDevices)
            
            // --- E. Printers ---
            DispatchQueue.main.async { self.progressMessage = "Capturing printer drivers..." }
            let printers = self.runSystemProfiler(dataType: "SPPrintersDataType")
            let ppdSourcePath = "/etc/cups/ppd/"
            if let ppdFiles = try? fileManager.contentsOfDirectory(atPath: ppdSourcePath) {
                for file in ppdFiles {
                    let sourceURL = URL(fileURLWithPath: ppdSourcePath).appendingPathComponent(file)
                    let destURL = driversDir.appendingPathComponent(file)
                    try? fileManager.copyItem(at: sourceURL, to: destURL)
                }
            }
            for printer in printers {
                let name = (printer._name ?? "Unknown").replacingOccurrences(of: ",", with: " ")
                tempItems.append(AuditItem(type: .printer, name: name, details: "Driver Captured", developer: "Printer", path: nil))
            }
            
            DispatchQueue.main.async { self.scannedItems = tempItems }
            
            // --- F. Generate Outputs ---
            
            // CSV - Add User Name Header
            var csvContent = "USER: \(userName)\nDATE: \(Date())\n\n"
            csvContent += "TYPE, DEVELOPER, NAME, VERSION/PATH\n"
            for item in tempItems {
                csvContent += "\(item.type.rawValue), \(item.developer), \(item.name), \(item.details)\n"
            }
            
            // Filename includes USERNAME now
            let csvFilename = "Audit_Report_\(safeName).csv"
            try? csvContent.write(to: tempDir.appendingPathComponent(csvFilename), atomically: true, encoding: .utf8)
            
            // HTML - Pass userName
            let htmlContent = HTMLBuilder.generateHTML(items: tempItems, userName: userName)
            let htmlFilename = "Dashboard_\(safeName).html"
            try? htmlContent.write(to: tempDir.appendingPathComponent(htmlFilename), atomically: true, encoding: .utf8)
            
            // --- G. Zip ---
            DispatchQueue.main.async { self.progressMessage = "Finalising package..." }
            let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
            
            // Zip Filename includes USERNAME
            let zipFilename = "Migration_Data_\(safeName)_\(ISO8601DateFormatter().string(from: Date()).prefix(10)).zip"
            let destinationZipURL = desktopURL.appendingPathComponent(zipFilename)
            
            let zipTask = Process()
            zipTask.launchPath = "/usr/bin/zip"
            zipTask.currentDirectoryURL = tempDir
            zipTask.arguments = ["-r", destinationZipURL.path, "."]
            
            zipTask.terminationHandler = { _ in
                try? fileManager.removeItem(at: tempDir)
                DispatchQueue.main.async {
                    self.isScanning = false
                    self.progressMessage = "Complete"
                    completion(destinationZipURL.path)
                }
            }
            try? zipTask.run()
        }
    }
}
