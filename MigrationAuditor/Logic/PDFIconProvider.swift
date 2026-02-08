//
//  PDFIconProvider.swift
//  MigrationAuditor
//
//  Created by Assistant on 07/02/2026.
//

import Foundation
import AppKit

struct PDFIconProvider {
    static func image(for item: AuditItem, iconSize: CGFloat) -> NSImage? {
        // 1) Use a real file icon when we have a path
        if let path = item.path, FileManager.default.fileExists(atPath: path) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        // 2) Or if details looks like a path
        let details = item.details.trimmingCharacters(in: .whitespacesAndNewlines)
        if details.hasPrefix("/"), FileManager.default.fileExists(atPath: details) {
            return NSWorkspace.shared.icon(forFile: details)
        }
        
        // 3) Type-specific handling
        switch item.type {
        case .systemSpec:
            let symbolName = symbolForSystemSpec(name: item.name)
            return symbolImage(named: symbolName, pointSize: iconSize, color: .darkGray)
        case .browser:
            if let appIcon = browserAppIcon(for: item.name) { return appIcon }
            return symbolImage(named: "safari", pointSize: iconSize, color: .systemBlue)
        case .emailAccount:
            return symbolImage(named: "envelope.fill", pointSize: iconSize, color: .systemRed)
        case .cloudStorage:
            return symbolImage(named: "cloud.fill", pointSize: iconSize, color: .systemBlue)
        case .printer:
            return symbolImage(named: "printer.fill", pointSize: iconSize, color: .systemGray)
        case .device:
            return symbolImage(named: "cable.connector", pointSize: iconSize, color: .systemYellow)
        case .internalDevice:
            return symbolImage(named: "internaldrive", pointSize: iconSize, color: .systemOrange)
        case .networkDrive:
            return symbolImage(named: "server.rack", pointSize: iconSize, color: .systemGreen)
        case .font:
            return symbolImage(named: "textformat", pointSize: iconSize, color: .systemPink)
        case .homebrew:
            if let img = NSImage(named: "homebrew") { return img }
            return symbolImage(named: "terminal.fill", pointSize: iconSize, color: .brown)
        case .musicLibrary:
            return symbolImage(named: "music.note.list", pointSize: iconSize, color: .systemMint)
        case .photosLibrary:
            return symbolImage(named: "photo.on.rectangle", pointSize: iconSize, color: .systemTeal)
        case .mainApp, .installedApp, .systemComponent:
            // Fallback symbol for non-path apps/components
            return symbolImage(named: item.type.icon, pointSize: iconSize, color: .darkGray)
        }
    }
    
    private static func symbolForSystemSpec(name: String) -> String {
        let n = name.lowercased()
        if n.contains("drive") || n.contains("storage") { return "internaldrive" }
        if n.contains("available") { return "internaldrive.fill" }
        if n.contains("memory") || n.contains("ram") { return "memorychip" }
        if n.contains("processor") || n.contains("chip") { return "cpu" }
        if n.contains("serial") { return "barcode" }
        if n.contains("model") { return "laptopcomputer" }
        if n.contains("version") { return "macwindow" }
        if n.contains("tahoe") || n.contains("support") { return "sparkles" }
        if n.contains("icloud") { return "icloud" }
        if n.contains("battery") { return "battery.100percent.bolt" }
        return "desktopcomputer"
    }
    
    private static func symbolImage(named: String, pointSize: CGFloat, color: NSColor) -> NSImage? {
        guard let base = NSImage(systemSymbolName: named, accessibilityDescription: nil) else { return nil }
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        let configured = base.withSymbolConfiguration(config)
        
        // Rasterize into a new image to ensure proper rendering in PDF contexts
        let size = NSSize(width: pointSize, height: pointSize)
        let out = NSImage(size: size)
        out.lockFocus()
        color.set()
        configured?.isTemplate = true
        configured?.draw(in: NSRect(origin: .zero, size: size))
        out.unlockFocus()
        return out
    }
    
    private static func browserAppIcon(for name: String) -> NSImage? {
        let bundleIDs: [String: String] = [
            "safari": "com.apple.Safari",
            "google chrome": "com.google.Chrome",
            "chrome": "com.google.Chrome",
            "microsoft edge": "com.microsoft.edgemac",
            "edge": "com.microsoft.edgemac",
            "firefox": "org.mozilla.firefox",
            "brave": "com.brave.Browser",
            "opera": "com.operasoftware.Opera",
            "arc": "company.thebrowser.Browser"
        ]
        let key = name.lowercased()
        if let id = bundleIDs.first(where: { key.contains($0.key) })?.value,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
}
