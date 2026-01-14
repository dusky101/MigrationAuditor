//
//  PDFExporter.swift
//  MigrationAuditor
//
//  Created by Marc on 14/01/2026.
//

import Foundation
import AppKit
import PDFKit

struct PDFExporter {
    
    static func exportToPDF(items: [AuditItem], userName: String) -> URL? {
        guard let pdfData = generatePDF(items: items, userName: userName) else { return nil }
        
        let fileManager = FileManager.default
        guard let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let safeName = userName.components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
        let filename = "Migration_Report_\(safeName)_\(timestamp).pdf"
        let fileURL = desktopURL.appendingPathComponent(filename)
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    private static func generatePDF(items: [AuditItem], userName: String) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfMetaData = [
            kCGPDFContextTitle: "Migration Audit Report - \(userName)",
            kCGPDFContextAuthor: "Mac Migration Assistant"
        ]
        
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, pdfMetaData as CFDictionary) else { return nil }
        
        let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = graphicsContext
        
        let groupedItems = Dictionary(grouping: items) { $0.type }
        let sortedTypes = AuditItem.ItemType.allCases.filter { type in
            guard let items = groupedItems[type] else { return false }
            if type == .internalDevice && items.isEmpty { return false }
            return !items.isEmpty
        }
        
        var yPosition: CGFloat = pageHeight - margin
        var currentPage = 1
        
        pdfContext.beginPage(mediaBox: &mediaBox)
        
        // Header
        yPosition = drawHeader(yPosition: yPosition, pageWidth: pageWidth, margin: margin, userName: userName)
        
        // Summary
        yPosition -= 20
        yPosition = drawSectionTitle(title: "Summary", iconName: "list.bullet.clipboard", itemType: nil, yPosition: yPosition, margin: margin, contentWidth: contentWidth)
        yPosition -= 10
        
        for itemType in sortedTypes {
            let count = groupedItems[itemType]?.count ?? 0
            yPosition = drawSummaryRow(title: itemType.rawValue, count: count, yPosition: yPosition, margin: margin)
            if yPosition < margin + 50 {
                startNewPage(context: pdfContext, mediaBox: &mediaBox, pageNumber: &currentPage, yPosition: &yPosition, pageHeight: pageHeight, pageWidth: pageWidth, margin: margin)
            }
        }
        
        yPosition -= 20
        
        // Details
        for itemType in sortedTypes {
            guard let categoryItems = groupedItems[itemType] else { continue }
            let sortedItems = categoryItems.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            if yPosition < margin + 80 {
                startNewPage(context: pdfContext, mediaBox: &mediaBox, pageNumber: &currentPage, yPosition: &yPosition, pageHeight: pageHeight, pageWidth: pageWidth, margin: margin)
            }
            
            yPosition = drawSectionTitle(title: "\(itemType.rawValue) (\(sortedItems.count))", iconName: itemType.icon, itemType: itemType, yPosition: yPosition, margin: margin, contentWidth: contentWidth)
            yPosition -= 10
            
            for item in sortedItems {
                let itemHeight = calculateItemHeight(item: item, width: contentWidth - 40)
                if yPosition < margin + itemHeight + 10 {
                    startNewPage(context: pdfContext, mediaBox: &mediaBox, pageNumber: &currentPage, yPosition: &yPosition, pageHeight: pageHeight, pageWidth: pageWidth, margin: margin)
                }
                yPosition = drawItem(item: item, yPosition: yPosition, margin: margin, contentWidth: contentWidth)
            }
            yPosition -= 20
        }
        
        drawFooter(pageWidth: pageWidth, margin: margin)
        pdfContext.endPage()
        pdfContext.closePDF()
        
        NSGraphicsContext.current = previousContext
        return pdfData as Data
    }
    
    private static func startNewPage(context: CGContext, mediaBox: inout CGRect, pageNumber: inout Int, yPosition: inout CGFloat, pageHeight: CGFloat, pageWidth: CGFloat, margin: CGFloat) {
        drawFooter(pageWidth: pageWidth, margin: margin)
        context.endPage()
        context.beginPage(mediaBox: &mediaBox)
        pageNumber += 1
        yPosition = pageHeight - margin
        drawPageNumber(pageNumber: pageNumber, pageWidth: pageWidth, yPosition: pageHeight - margin + 20, margin: margin)
    }
    
    // --- DRAWING HELPERS ---
    
    private static func drawHeader(yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat, userName: String) -> CGFloat {
        var y = yPosition
        let titleFont = NSFont.boldSystemFont(ofSize: 24)
        let title = "Mac Migration Inventory"
        let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: NSColor.black]
        let titleSize = title.size(withAttributes: titleAttr)
        title.draw(at: CGPoint(x: margin, y: y - titleSize.height), withAttributes: titleAttr)
        y -= (titleSize.height + 8)
        
        let subFont = NSFont.systemFont(ofSize: 12)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let subtitle = "Generated for: \(userName)  |  Date: \(dateFormatter.string(from: Date()))"
        let subAttr: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: NSColor.darkGray]
        let subSize = subtitle.size(withAttributes: subAttr)
        subtitle.draw(at: CGPoint(x: margin, y: y - subSize.height), withAttributes: subAttr)
        y -= (subSize.height + 15)
        
        let linePath = NSBezierPath()
        linePath.move(to: CGPoint(x: margin, y: y))
        linePath.line(to: CGPoint(x: pageWidth - margin, y: y))
        linePath.lineWidth = 1
        NSColor.lightGray.setStroke()
        linePath.stroke()
        return y - 10
    }
    
    private static func drawSectionTitle(title: String, iconName: String, itemType: AuditItem.ItemType?, yPosition: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let barHeight: CGFloat = 28
        let rect = CGRect(x: margin, y: yPosition - barHeight, width: contentWidth, height: barHeight)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor(white: 0.95, alpha: 1.0).setFill()
        path.fill()
        
        let iconSize: CGFloat = 14
        let iconRect = CGRect(x: margin + 8, y: yPosition - barHeight + (barHeight - iconSize)/2, width: iconSize, height: iconSize)
        
        var iconDrawn = false
        if let type = itemType, type == .homebrew, let image = NSImage(named: "homebrew") {
             image.draw(in: iconRect)
             iconDrawn = true
        }
        
        if !iconDrawn, let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            image.isTemplate = true
            NSColor.darkGray.set()
            image.draw(in: iconRect)
        }
        
        let font = NSFont.boldSystemFont(ofSize: 12)
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let titleSize = title.size(withAttributes: attr)
        let textY = yPosition - barHeight + (barHeight - titleSize.height)/2
        title.draw(at: CGPoint(x: margin + 30, y: textY), withAttributes: attr)
        
        return yPosition - barHeight - 5
    }
    
    private static func drawSummaryRow(title: String, count: Int, yPosition: CGFloat, margin: CGFloat) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 11)
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let text = "• \(title): \(count) items"
        let size = text.size(withAttributes: attr)
        text.draw(at: CGPoint(x: margin + 10, y: yPosition - size.height), withAttributes: attr)
        return yPosition - size.height - 4
    }
    
    private static func drawItem(item: AuditItem, yPosition: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let iconSize: CGFloat = 24
        let iconPadding: CGFloat = 10
        let textX = margin + iconSize + iconPadding
        let textWidth = contentWidth - iconSize - iconPadding
        var currentY = yPosition
        
        let iconRect = CGRect(x: margin, y: currentY - iconSize, width: iconSize, height: iconSize)
        var iconDrawn = false
        
        // 1. Homebrew Check
        if item.type == .homebrew, let hbImage = NSImage(named: "homebrew") {
            hbImage.draw(in: iconRect)
            iconDrawn = true
        }
        
        // 2. System Specs Logic
        if !iconDrawn && item.type == .systemSpec {
            let name = item.name.lowercased()
            var sysIconName = "desktopcomputer" // fallback
            
            if name.contains("drive") || name.contains("storage") { sysIconName = "internaldrive" }
            else if name.contains("available") { sysIconName = "internaldrive.fill" }
            else if name.contains("memory") || name.contains("ram") { sysIconName = "memorychip" }
            else if name.contains("processor") || name.contains("chip") { sysIconName = "cpu" }
            else if name.contains("serial") { sysIconName = "barcode" }
            else if name.contains("model") { sysIconName = "laptopcomputer" }
            else if name.contains("version") { sysIconName = "macwindow" }
            else if name.contains("tahoe") || name.contains("support") { sysIconName = "sparkles" }
            else if name.contains("icloud") { sysIconName = "icloud" }
            
            if let img = NSImage(systemSymbolName: sysIconName, accessibilityDescription: nil) {
                img.isTemplate = true
                NSColor.darkGray.set()
                img.draw(in: iconRect)
                iconDrawn = true
            }
        }
        
        // 3. File Path Check
        if !iconDrawn {
            let details = item.details.trimmingCharacters(in: .whitespacesAndNewlines)
            if details.hasPrefix("/") {
                let fileIcon = NSWorkspace.shared.icon(forFile: details)
                fileIcon.draw(in: iconRect)
                iconDrawn = true
            }
        }
        
        // 4. Fallback
        if !iconDrawn {
            let symbolImage = NSImage(systemSymbolName: item.type.icon, accessibilityDescription: nil) ?? NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
            symbolImage?.isTemplate = true
            NSColor.lightGray.set()
            symbolImage?.draw(in: iconRect)
        }
        
        let nameFont = NSFont.boldSystemFont(ofSize: 10)
        let nameAttr: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: NSColor.black]
        let nameHeight = item.name.boundingRect(with: CGSize(width: textWidth, height: .infinity), options: .usesLineFragmentOrigin, attributes: nameAttr).height
        item.name.draw(in: CGRect(x: textX, y: currentY - nameHeight, width: textWidth, height: nameHeight), withAttributes: nameAttr)
        currentY -= (nameHeight + 2)
        
        if !item.details.isEmpty && item.details != item.name {
            let detailFont = NSFont.systemFont(ofSize: 9)
            let detailAttr: [NSAttributedString.Key: Any] = [.font: detailFont, .foregroundColor: NSColor.gray]
            let detailRect = item.details.boundingRect(with: CGSize(width: textWidth, height: .infinity), options: .usesLineFragmentOrigin, attributes: detailAttr)
            item.details.draw(in: CGRect(x: textX, y: currentY - detailRect.height, width: textWidth, height: detailRect.height), withAttributes: detailAttr)
            currentY -= detailRect.height
        }
        
        if !item.developer.isEmpty {
            let devFont = NSFont.systemFont(ofSize: 8)
            let devAttr: [NSAttributedString.Key: Any] = [.font: devFont, .foregroundColor: NSColor(white: 0.6, alpha: 1.0)]
            let devString = "Developer: \(item.developer)"
            let devHeight = devString.size(withAttributes: devAttr).height
            devString.draw(at: CGPoint(x: textX, y: currentY - devHeight), withAttributes: devAttr)
            currentY -= devHeight
        }
        
        let totalHeightUsed = yPosition - currentY
        return yPosition - max(totalHeightUsed, iconSize) - 8
    }
    
    private static func calculateItemHeight(item: AuditItem, width: CGFloat) -> CGFloat {
        let nameFont = NSFont.boldSystemFont(ofSize: 10)
        let detailFont = NSFont.systemFont(ofSize: 9)
        let devFont = NSFont.systemFont(ofSize: 8)
        var height: CGFloat = 0
        let nameRect = item.name.boundingRect(with: CGSize(width: width, height: 1000), options: .usesLineFragmentOrigin, attributes: [.font: nameFont])
        height += nameRect.height + 2
        if !item.details.isEmpty && item.details != item.name {
            let detailRect = item.details.boundingRect(with: CGSize(width: width, height: 1000), options: .usesLineFragmentOrigin, attributes: [.font: detailFont])
            height += detailRect.height
        }
        if !item.developer.isEmpty {
            height += devFont.pointSize + 2
        }
        return max(height, 24) + 8
    }
    
    private static func drawPageNumber(pageNumber: Int, pageWidth: CGFloat, yPosition: CGFloat, margin: CGFloat) {
        let font = NSFont.systemFont(ofSize: 9)
        let text = "Page \(pageNumber)"
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.gray]
        let size = text.size(withAttributes: attr)
        text.draw(at: CGPoint(x: pageWidth - margin - size.width, y: yPosition), withAttributes: attr)
    }
    
    private static func drawFooter(pageWidth: CGFloat, margin: CGFloat) {
        let font = NSFont.systemFont(ofSize: 9)
        let text = "Generated by Mac Migration Auditor"
        let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(white: 0.8, alpha: 1.0)]
        text.draw(at: CGPoint(x: margin, y: 30), withAttributes: attr)
    }
}
