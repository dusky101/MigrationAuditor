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
        let hardwareInfo = getHardwareInfo() // Uses helper below
        
        if let ram = hardwareInfo["Physical Memory"] {
            items.append(AuditItem(type: .systemSpec, name: "Memory (RAM)", details: ram, developer: "Apple", path: nil))
        }
        if let chip = hardwareInfo["Chip"] ?? hardwareInfo["Processor Name"] {
            items.append(AuditItem(type: .systemSpec, name: "Processor / Chip", details: chip, developer: "Apple", path: nil))
        }
        return items
    }
    
    // 3. Serial & Model Only
    static func getIdentitySpecs() -> [AuditItem] {
        var items: [AuditItem] = []
        let hardwareInfo = getHardwareInfo()
        
        if let serial = hardwareInfo["Serial Number (system)"] {
            items.append(AuditItem(type: .systemSpec, name: "Serial Number", details: serial, developer: "Apple", path: nil))
        }
        if let model = hardwareInfo["Model Identifier"] {
            items.append(AuditItem(type: .systemSpec, name: "Model Identifier", details: model, developer: "Apple", path: nil))
        }
        
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        items.append(AuditItem(type: .systemSpec, name: "macOS Version", details: os, developer: "Apple", path: nil))
        
        return items
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
