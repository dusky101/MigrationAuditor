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

struct AuditItem: Identifiable {
    let id = UUID()
    let type: ItemType
    let name: String
    let details: String
    let developer: String
    let path: String?
    
    enum ItemType: String {
        case systemSpec = "System Specifications"
        case mainApp = "Applications Folder"      // Manual Scan of /Applications
        case installedApp = "Detected Applications" // Profiler Scan (Real User Apps)
        case systemComponent = "System Internals"   // Profiler Scan (Background/Helper/Fluff)
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
    @Published var scanProgress: Double = 0.0
    @Published var scannedItems: [AuditItem] = []
    
    // Developer Detective
    func detectDeveloper(from info: String?, name: String, path: String?) -> String {
        let infoString = (info ?? "").lowercased()
        let nameString = name.lowercased()
        let pathString = (path ?? "").lowercased()
        
        // Priority Checks
        if infoString.contains("microsoft") || nameString.contains("microsoft") { return "Microsoft" }
        if infoString.contains("adobe") || nameString.contains("adobe") { return "Adobe" }
        if infoString.contains("google") || nameString.contains("google") { return "Google" }
        if infoString.contains("zoom") { return "Zoom" }
        if infoString.contains("cisco") || nameString.contains("webex") { return "Cisco" }
        
        // Apple Checks
        if pathString.hasPrefix("/system/") || pathString.contains("/core services/") { return "Apple" }
        if ["safari", "numbers", "pages", "keynote", "xcode", "imovie", "garageband", "photos", "podcasts", "music", "tv", "mail", "finder", "preview", "textedit"].contains(nameString) { return "Apple" }
        if infoString.contains("apple") || infoString.contains("mac app store") { return "Apple" }
        
        return "Other Developers"
    }
    
    // The "Fluff Filter"
    func isUserFacingApp(path: String?) -> Bool {
        guard let p = path else { return false }
        
        // 1. Must be in a valid Application folder
        let inAppFolder = p.hasPrefix("/Applications") ||
                          p.hasPrefix("/System/Applications") ||
                          p.hasPrefix("/Users/") && p.contains("/Applications/")
        
        // 2. Must NOT be nested inside another app (e.g. Word.app/Contents/Updater.app)
        let isNested = p.components(separatedBy: ".app/").count > 2
        
        // 3. Must NOT be in System Library fluff (CoreServices, Frameworks, etc)
        let isSystemLib = p.hasPrefix("/System/Library") || p.hasPrefix("/Library")
        
        return inAppFolder && !isNested && !isSystemLib
    }
    
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
    
    func performAudit(userName: String, completion: @escaping (String?) -> Void) {
        isScanning = true
        progressMessage = "Initialising scan..." // BRITISH SPELLING
        scanProgress = 0.0
        
        DispatchQueue.main.async { self.scannedItems = [] }
        let safeName = userName.components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
        
        DispatchQueue.global(qos: .userInitiated).async {
            var tempItems: [AuditItem] = []
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent("Migration_Audit_\(UUID().uuidString)")
            let driversDir = tempDir.appendingPathComponent("Printer_Drivers")
            try? fileManager.createDirectory(at: driversDir, withIntermediateDirectories: true, attributes: nil)
            
            // --- STEP 1: Specs ---
            DispatchQueue.main.async { self.progressMessage = "Analysing Storage & RAM..."; self.scanProgress = 0.1 } // BRITISH SPELLING
            Thread.sleep(forTimeInterval: 1.0)
            tempItems.append(contentsOf: HardwareCollector.getStorageSpecs())
            
            DispatchQueue.main.async { self.scanProgress = 0.2 }
            tempItems.append(contentsOf: HardwareCollector.getMemoryAndChipSpecs())
            
            DispatchQueue.main.async { self.scanProgress = 0.3 }
            tempItems.append(contentsOf: HardwareCollector.getIdentitySpecs())

            // --- STEP 2: Apps Folder ---
            DispatchQueue.main.async { self.progressMessage = "Scanning Applications..."; self.scanProgress = 0.4 }
            let appFolderURL = URL(fileURLWithPath: "/Applications")
            if let urls = try? fileManager.contentsOfDirectory(at: appFolderURL, includingPropertiesForKeys: nil) {
                for url in urls {
                    if url.pathExtension == "app" {
                        let name = url.deletingPathExtension().lastPathComponent
                        tempItems.append(AuditItem(type: .mainApp, name: name, details: url.path, developer: "Installed App", path: url.path))
                    }
                }
            }
            
            // --- STEP 3: Network ---
            DispatchQueue.main.async { self.progressMessage = "Checking Network Drives..."; self.scanProgress = 0.45 }
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
            
            // --- STEP 4: DEEP SYSTEM SCAN ---
            DispatchQueue.main.async { self.progressMessage = "Deep System Analysis..." }
            
            let deepScanFinished = AtomicBool()
            let step4Start = 0.5
            let step4Target = 0.75
            
            DispatchQueue.global().async {
                var current = step4Start
                while !deepScanFinished.value && current < step4Target {
                    Thread.sleep(forTimeInterval: 0.1)
                    current += 0.002
                    let updateVal = current
                    DispatchQueue.main.async { self.scanProgress = updateVal }
                }
            }
            
            let apps = self.runSystemProfiler(dataType: "SPApplicationsDataType")
            deepScanFinished.value = true
            
            for app in apps {
                let name = (app._name ?? "Unknown").replacingOccurrences(of: ",", with: " ")
                let version = app.version ?? "N/A"
                let devName = self.detectDeveloper(from: app.info, name: name, path: app.path)
                
                // FLUFF FILTER
                let type: AuditItem.ItemType = self.isUserFacingApp(path: app.path) ? .installedApp : .systemComponent
                
                tempItems.append(AuditItem(type: type, name: name, details: version, developer: devName, path: app.path))
            }
            
            // --- STEP 5: Peripherals ---
            DispatchQueue.main.async { self.progressMessage = "Scanning USB Devices..."; self.scanProgress = 0.8 }
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
            
            // --- STEP 6: Printers ---
            DispatchQueue.main.async { self.progressMessage = "Capturing Printer Drivers..."; self.scanProgress = 0.9 }
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
            
            // --- STEP 7: Finalize ---
            DispatchQueue.main.async { self.progressMessage = "Saving Report..."; self.scanProgress = 1.0 }
            
            // CLEAN CSV (Removed User/Date header)
            var csvContent = "TYPE, DEVELOPER, NAME, VERSION/PATH\n"
            for item in tempItems {
                csvContent += "\(item.type.rawValue), \(item.developer), \(item.name), \(item.details)\n"
            }
            
            let csvFilename = "Audit_Report_\(safeName).csv"
            try? csvContent.write(to: tempDir.appendingPathComponent(csvFilename), atomically: true, encoding: .utf8)
            
            let htmlContent = HTMLBuilder.generateHTML(items: tempItems, userName: userName)
            let htmlFilename = "Dashboard_\(safeName).html"
            try? htmlContent.write(to: tempDir.appendingPathComponent(htmlFilename), atomically: true, encoding: .utf8)
            
            // ZIP
            DispatchQueue.main.async { self.progressMessage = "Finalising package..." } // BRITISH SPELLING
            
            let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
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

class AtomicBool: @unchecked Sendable {
    private var val: Bool = false
    private let lock = NSLock()
    var value: Bool {
        get { lock.lock(); defer { lock.unlock() }; return val }
        set { lock.lock(); defer { lock.unlock() }; val = newValue }
    }
}
