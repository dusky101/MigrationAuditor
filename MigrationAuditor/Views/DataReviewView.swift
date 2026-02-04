//
//  DataReviewView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//

import SwiftUI
import AppKit // Required for NSEvent modifier flags

struct DataReviewView: View {
    let items: [AuditItem]
    let userName: String
    @Environment(\.presentationMode) var presentationMode
    @State private var showHelp = false
    @State private var searchText = ""
    @State private var selectedFilters: Set<AuditItem.ItemType> = Set(AuditItem.ItemType.allCases)
    @State private var isExporting = false
    @State private var showExportSuccess = false
    @State private var exportedFileURL: URL?
    
    // Sort Helper
    func sorted(_ list: [AuditItem]) -> [AuditItem] {
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // Filter items based on search and selected categories
    var filteredItems: [AuditItem] {
        items.filter { item in
            let matchesFilter = selectedFilters.contains(item.type)
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.details.localizedCaseInsensitiveContains(searchText) ||
                item.developer.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }
    
    var groupedRealApps: [(key: String, value: [AuditItem])] {
        let apps = filteredItems.filter { $0.type == .installedApp }
        let grouped = Dictionary(grouping: apps) { $0.developer }
        return grouped.sorted { $0.key < $1.key }
    }
    
    // Export to PDF function
    func exportToPDF() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let itemsToExport = self.filteredItems
            if let fileURL = PDFExporter.exportToPDF(items: itemsToExport, userName: self.userName) {
                DispatchQueue.main.async {
                    self.exportedFileURL = fileURL
                    self.showExportSuccess = true
                    self.isExporting = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isExporting = false
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER ---
            HeaderView(
                title: "Captured Inventory",
                icon: "list.bullet.clipboard.fill",
                isExporting: isExporting,
                onHelp: { showHelp = true },
                onExport: exportToPDF,
                onClose: { presentationMode.wrappedValue.dismiss() }
            )
            
            // --- CONTROLS SECTION ---
            VStack(spacing: 12) {
                // Search
                SearchBar(text: $searchText)
                
                // Filter Chips (Using Center-Aligned Flow Layout)
                FilterGrid(items: items, selectedFilters: $selectedFilters)
                
                // Stats Row with Centered "Glassy" Buttons
                HStack(spacing: 12) {
                    
                    Spacer()
                    
                    // --- SELECT ALL (Green Glass) ---
                    Button(action: { selectedFilters = Set(AuditItem.ItemType.allCases) }) {
                        Text("Select All")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // --- DESELECT ALL (Red Glass) ---
                    Button(action: { selectedFilters.removeAll() }) {
                        Text("Deselect All")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Item count stays on the far right
                    Text("\(filteredItems.count) of \(items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // --- SCROLL CONTENT ---
            ScrollView {
                LazyVStack(spacing: 20) {
                    // System Specs
                    if !filteredItems.filter({ $0.type == .systemSpec }).isEmpty {
                        CompactCategoryView(
                            title: "System Specifications",
                            icon: "desktopcomputer",
                            color: .purple,
                            itemType: .systemSpec,
                            items: filteredItems.filter { $0.type == .systemSpec }
                        )
                    }
                    
                    // Quick Info Grid
                    let quickInfoTypes: [AuditItem.ItemType] = [.browser, .emailAccount, .cloudStorage, .musicLibrary, .photosLibrary, .font, .homebrew, .networkDrive, .printer, .device, .internalDevice]
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(quickInfoTypes, id: \.self) { type in
                            let items = filteredItems.filter { $0.type == type }
                            if !items.isEmpty {
                                CompactCategoryView(
                                    title: type.rawValue,
                                    icon: type.icon,
                                    color: type.color,
                                    itemType: type,
                                    items: sorted(items)
                                )
                            }
                        }
                    }
                    
                    // Applications Folder
                    if !filteredItems.filter({ $0.type == .mainApp }).isEmpty {
                        CompactCategoryView(
                            title: "Applications Folder (Top Level)",
                            icon: "folder.fill",
                            color: .blue,
                            itemType: .mainApp,
                            items: sorted(filteredItems.filter { $0.type == .mainApp })
                        )
                    }
                    
                    // Detected Apps Groups
                    ForEach(groupedRealApps, id: \.key) { group in
                        CompactCategoryView(
                            title: "\(group.key) Applications",
                            icon: "app.badge",
                            color: .indigo,
                            itemType: .installedApp,
                            items: sorted(group.value)
                        )
                    }
                    
                    // System Internals
                    let fluff = sorted(filteredItems.filter { $0.type == .systemComponent })
                    if !fluff.isEmpty {
                        CompactCategoryView(
                            title: "System Internals & Helpers",
                            icon: "gearshape.2",
                            color: .gray,
                            itemType: .systemComponent,
                            items: fluff
                        )
                    }
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 1200, minHeight: 800)
        .sheet(isPresented: $showHelp) { DataReviewHelpView() }
        .alert("PDF Exported Successfully", isPresented: $showExportSuccess) {
            Button("Show in Finder") {
                if let url = exportedFileURL {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            if let url = exportedFileURL {
                Text("Report saved to:\n\(url.lastPathComponent)")
            } else {
                Text("Report has been saved to your Desktop")
            }
        }
    }
}

// --- SUBVIEWS ---

struct HeaderView: View {
    let title: String
    let icon: String
    let isExporting: Bool
    let onHelp: () -> Void
    let onExport: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(title).font(.title2).fontWeight(.bold)
            Spacer()
            Button(action: onHelp) {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.bordered)
            
            Button(action: onExport) {
                HStack(spacing: 4) {
                    if isExporting {
                        ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                    }
                    Text(isExporting ? "Exporting..." : "Export PDF")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isExporting)
            
            Button("Close", action: onClose)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search everything...", text: $text).textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

// --- UPDATED FILTER GRID ---
struct FilterGrid: View {
    let items: [AuditItem]
    @Binding var selectedFilters: Set<AuditItem.ItemType>
    
    var body: some View {
        // Using FlowLayout to center the items naturally
        FlowLayout(spacing: 10) {
            ForEach(AuditItem.ItemType.allCases, id: \.self) { itemType in
                let itemCount = items.filter { $0.type == itemType }.count
                if !(itemType == .internalDevice && itemCount == 0) {
                    FilterChip(
                        title: itemType.rawValue,
                        icon: itemType.icon,
                        color: itemType.color,
                        isSelected: selectedFilters.contains(itemType),
                        count: itemCount
                    ) {
                        // --- COMMAND CLICK LOGIC ---
                        if NSEvent.modifierFlags.contains(.command) {
                            // "Solo" this filter
                            selectedFilters = [itemType]
                        } else {
                            // Standard Toggle
                            if selectedFilters.contains(itemType) {
                                selectedFilters.remove(itemType)
                            } else {
                                selectedFilters.insert(itemType)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CompactCategoryView: View {
    let title: String
    let icon: String
    let color: Color
    let itemType: AuditItem.ItemType
    let items: [AuditItem]
    @State private var isExpanded = true
    @State private var showAllItems = false
    private let limit = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    if itemType == .homebrew {
                        Image("homebrew")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 18))
                            .frame(width: 24)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        Text("\(items.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 8) {
                    let displayItems = showAllItems ? items : Array(items.prefix(limit))
                    ForEach(displayItems) { item in
                        CompactItemRow(item: item)
                    }
                    if items.count > limit {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAllItems.toggle()
                            }
                        }) {
                            HStack {
                                Text(showAllItems ? "Show Less" : "...and \(items.count - limit) more")
                                    .fontWeight(.medium)
                                Image(systemName: showAllItems ? "chevron.up" : "chevron.down")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 4)
                .transition(.opacity)
            }
        }
        .padding(6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CompactItemRow: View {
    let item: AuditItem
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            IconHelper.icon(for: item)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if !item.details.isEmpty && item.details != item.name {
                    Text(item.details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct IconHelper {
    static func icon(for item: AuditItem) -> Image {
        if item.type == .homebrew { return Image("homebrew") }
        if item.type == .systemSpec {
            let name = item.name.lowercased()
            if name.contains("drive") || name.contains("storage") { return Image(systemName: "internaldrive") }
            if name.contains("available") { return Image(systemName: "internaldrive.fill") }
            if name.contains("memory") || name.contains("ram") { return Image(systemName: "memorychip") }
            if name.contains("processor") || name.contains("chip") { return Image(systemName: "cpu") }
            if name.contains("serial") { return Image(systemName: "barcode") }
            if name.contains("model") { return Image(systemName: "laptopcomputer") }
            if name.contains("version") { return Image(systemName: "macwindow") }
            if name.contains("tahoe") || name.contains("support") { return Image(systemName: "sparkles") }
            if name.contains("icloud") { return Image(systemName: "icloud") }
        }
        // Music Library Icons
        if item.type == .musicLibrary {
            let name = item.name.lowercased()
            if name.contains("spotify") { return Image(systemName: "music.note") }
            return Image(systemName: "music.note.list")
        }
        // Photos Library Icons
        if item.type == .photosLibrary {
            return Image(systemName: "photo.on.rectangle")
        }
        if item.details.hasPrefix("/") {
            let nsImage = NSWorkspace.shared.icon(forFile: item.details)
            return Image(nsImage: nsImage)
        }
        return Image(systemName: item.type.icon)
    }
}

// --- UPDATED LIQUID GLASS FILTER CHIP ---
struct FilterChip: View {
    let title: String, icon: String, color: Color, isSelected: Bool, count: Int, action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if title == "Homebrew Packages" {
                     Image("homebrew")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: icon).font(.caption)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1) // PRIORITIZE NAME SHRINKING
                
                // --- FIXED SIZE COUNT BADGE ---
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? color : Color.gray.opacity(0.5))
                    .cornerRadius(8)
                    .fixedSize() // <--- PREVENTS "1..." TRUNCATION
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.15) : Color(NSColor.controlBackgroundColor).opacity(0.5))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }.buttonStyle(.plain)
    }
}

// --- FLOW LAYOUT FOR CENTERING ---
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flow(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flow(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        for (index, row) in result.rows.enumerated() {
            let rowWidth = row.map { $0.size.width }.reduce(0, +) + CGFloat(row.count - 1) * spacing
            let xOffset = (bounds.width - rowWidth) / 2
            var currentX = bounds.minX + xOffset
            let y = bounds.minY + result.rowYs[index]
            for item in row {
                subviews[item.index].place(at: CGPoint(x: currentX, y: y), proposal: ProposedViewSize(item.size))
                currentX += item.size.width + spacing
            }
        }
    }
    
    private struct LayoutResult {
        var rows: [[(index: Int, size: CGSize)]] = []
        var rowYs: [CGFloat] = []
        var size: CGSize = .zero
    }
    
    private func flow(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) -> LayoutResult {
        var result = LayoutResult()
        var currentRow: [(index: Int, size: CGSize)] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && !currentRow.isEmpty {
                result.rows.append(currentRow)
                result.rowYs.append(currentY)
                currentY += currentRowHeight + spacing
                currentRow = []
                currentX = 0
                currentRowHeight = 0
            }
            currentRow.append((index, size))
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        if !currentRow.isEmpty {
            result.rows.append(currentRow)
            result.rowYs.append(currentY)
            currentY += currentRowHeight
        }
        result.size = CGSize(width: maxWidth, height: currentY)
        return result
    }
}
