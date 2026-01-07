//
//  HardwareCollector.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//

import Foundation

class HardwareCollector {
    
    // 1. Storage Only
    static func getStorageSpecs() -> [AuditItem] {
        var items: [AuditItem] = []
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let capacity = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity {
                let totalStr = ByteCountFormatter.string(fromByteCount: Int64(capacity), countStyle: .file)
                let freeStr = ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file)
                
                items.append(AuditItem(type: .systemSpec, name: "Hard Drive Capacity", details: totalStr, developer: "Apple", path: nil))
                items.append(AuditItem(type: .systemSpec, name: "Available Space", details: freeStr, developer: "Apple", path: nil))
            }
        } catch {
            print("Error retrieving storage info: \(error)")
        }
        return items
    }
    
    // 2. RAM & Chip Only
    static func getMemoryAndChipSpecs() -> [AuditItem] {
        var items: [AuditItem] = []
        let hardwareInfo = getHardwareInfo()
        
        // Check for "Memory" (Standard) first, then "Physical Memory" (Legacy)
        if let ram = hardwareInfo["Memory"] ?? hardwareInfo["Physical Memory"] {
            items.append(AuditItem(type: .systemSpec, name: "Memory (RAM)", details: ram, developer: "Apple", path: nil))
        }
        
        if let chip = hardwareInfo["Chip"] ?? hardwareInfo["Processor Name"] {
            items.append(AuditItem(type: .systemSpec, name: "Processor / Chip", details: chip, developer: "Apple", path: nil))
        }
        return items
    }
    
    // 3. Serial, Model & Compliance
    static func getIdentitySpecs() -> [AuditItem] {
        var items: [AuditItem] = []
        let hardwareInfo = getHardwareInfo()
        
        if let serial = hardwareInfo["Serial Number (system)"] {
            items.append(AuditItem(type: .systemSpec, name: "Serial Number", details: serial, developer: "Apple", path: nil))
        }
        
        var modelID = ""
        if let model = hardwareInfo["Model Identifier"] {
            modelID = model
            items.append(AuditItem(type: .systemSpec, name: "Model Identifier", details: model, developer: "Apple", path: nil))
        }
        
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        items.append(AuditItem(type: .systemSpec, name: "macOS Version", details: os, developer: "Apple", path: nil))
        
        // --- TAHOE COMPLIANCE CHECK ---
        let chipName = hardwareInfo["Chip"] ?? hardwareInfo["Processor Name"] ?? ""
        let status = calculateTahoeStatus(modelID: modelID, chipName: chipName)
        
        items.append(AuditItem(type: .systemSpec, name: "Tahoe Support", details: status, developer: "Apple", path: nil))
        
        return items
    }
    
    // --- Helper: The Compliance Logic (Modernized Scanner) ---
    private static func calculateTahoeStatus(modelID: String, chipName: String) -> String {
        // 1. Apple Silicon is always Fully Supported (AI + OS)
        if chipName.contains("Apple M") || chipName.contains("Apple") {
            return "✅ Full Support (AI Ready)"
        }
        
        // 2. Intel Logic (OS Support requires 2019+ hardware)
        let scanner = Scanner(string: modelID)
        
        // Modern Scanner API (macOS 10.15+) - No pointers needed!
        // Scans "MacBookPro" from "MacBookPro15,1"
        let type = scanner.scanUpToCharacters(from: .decimalDigits) ?? ""
        
        // Scans "15"
        let major = scanner.scanInt() ?? 0
        
        // Scans "," (we discard the result with `_ =`)
        _ = scanner.scanString(",")
        
        // Scans "1"
        let minor = scanner.scanInt() ?? 0
        
        // Rules for Intel Macs (2019+ cutoff)
        var supported = false
        
        if type.contains("MacBookPro") {
            // 2019 starts at 15,3 (15,1 & 15,2 are 2018)
            if major > 15 { supported = true }
            else if major == 15 && minor >= 3 { supported = true }
        }
        else if type.contains("MacBookAir") {
            // 2019 is 8,2 (2018 is 8,1)
            if major > 8 { supported = true }
            else if major == 8 && minor >= 2 { supported = true }
        }
        else if type.contains("iMac") {
            // 2019 is 19,1
            if major >= 19 { supported = true }
        }
        else if type.contains("Macmini") {
            // 2018 is 8,1 (Technically sold until 2020, but strict cutoff is usually 2019 release)
            if major > 8 { supported = true }
        }
        else if type.contains("MacPro") {
            // 2019 is 7,1
            if major >= 7 { supported = true }
        }
        
        if supported {
            return "⚠️ OS Only (No AI)"
        } else {
            return "❌ Unsupported"
        }
    }
    
    // --- Internal Helper (Runs system_profiler once) ---
    private static func getHardwareInfo() -> [String: String] {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/sbin/system_profiler"
        task.arguments = ["SPHardwareDataType"]
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                var dict: [String: String] = [:]
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        dict[parts[0]] = parts[1]
                    }
                }
                return dict
            }
        } catch {
            return [:]
        }
        return [:]
    }
}
