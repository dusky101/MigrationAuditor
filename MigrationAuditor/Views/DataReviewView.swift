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
    @Environment(\.colorScheme) var colorScheme
    @State private var showHelp = false
    @State private var searchText = ""
    @State private var selectedFilters: Set<AuditItem.ItemType> = Set(AuditItem.ItemType.allCases)
    @State private var isExporting = false
    @State private var showExportSuccess = false
    @State private var exportedFileURL: URL?
    @State private var scrollToSection: AuditItem.ItemType? = nil
    @State private var expandAllSections = true
    
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
                FilterGrid(
                    items: items,
                    selectedFilters: $selectedFilters,
                    scrollToSection: $scrollToSection,
                    colorScheme: colorScheme
                )
                
                // Stats Row with Buttons
                HStack(spacing: 12) {
                    
                    // --- COLLAPSE/EXPAND ALL TOGGLE (LEFT SIDE) ---
                    Button(action: { expandAllSections.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: expandAllSections ? "chevron.up.circle" : "chevron.down.circle")
                            Text(expandAllSections ? "Collapse All" : "Expand All")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // --- SELECT ALL (Green Glass) - CENTERED ---
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
                    
                    // --- DESELECT ALL (Red Glass) - CENTERED ---
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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // System Specs
                        if !filteredItems.filter({ $0.type == .systemSpec }).isEmpty {
                            CompactCategoryView(
                                title: "System Specifications",
                                icon: "desktopcomputer",
                                color: .purple,
                                itemType: .systemSpec,
                                items: filteredItems.filter { $0.type == .systemSpec },
                                globalExpanded: $expandAllSections
                            )
                            .id(AuditItem.ItemType.systemSpec)
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
                                        items: sorted(items),
                                        globalExpanded: $expandAllSections
                                    )
                                    .id(type)
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
                                items: sorted(filteredItems.filter { $0.type == .mainApp }),
                                globalExpanded: $expandAllSections
                            )
                            .id(AuditItem.ItemType.mainApp)
                        }
                        
                        // Detected Apps Groups
                        ForEach(groupedRealApps, id: \.key) { group in
                            CompactCategoryView(
                                title: "\(group.key) Applications",
                                icon: "app.badge",
                                color: .indigo,
                                itemType: .installedApp,
                                items: sorted(group.value),
                                globalExpanded: $expandAllSections
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
                                items: fluff,
                                globalExpanded: $expandAllSections
                            )
                            .id(AuditItem.ItemType.systemComponent)
                        }
                    }
                    .padding()
                }
                .background(Color(NSColor.windowBackgroundColor))
                .onChange(of: scrollToSection) { oldValue, newSection in
                    guard let section = newSection else { return }
                    
                    Task { @MainActor in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(section, anchor: .top)
                        }
                        
                        // Reset after scrolling (outside of onChange to avoid re-triggering)
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        scrollToSection = nil
                    }
                }
            }
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
    @Binding var scrollToSection: AuditItem.ItemType?
    let colorScheme: ColorScheme
    
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
                        count: itemCount,
                        colorScheme: colorScheme
                    ) {
                        let modifiers = NSEvent.modifierFlags
                        
                        // --- COMMAND (⌘) CLICK: SOLO MODE (with toggle) ---
                        if modifiers.contains(.command) {
                            if selectedFilters.count == 1 && selectedFilters.contains(itemType) {
                                // If already solo'd, revert to all
                                selectedFilters = Set(AuditItem.ItemType.allCases)
                            } else {
                                // Solo this filter - show only this category
                                selectedFilters = [itemType]
                            }
                        }
                        // --- OPTION (⌥) CLICK: SCROLL TO SECTION ---
                        else if modifiers.contains(.option) {
                            // Enable this filter if not already selected
                            if !selectedFilters.contains(itemType) {
                                selectedFilters.insert(itemType)
                            }
                            // Trigger scroll to this section
                            scrollToSection = itemType
                        }
                        // --- NORMAL CLICK: TOGGLE ---
                        else {
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
    @Binding var globalExpanded: Bool
    @State private var showAllItems = false
    private let limit = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { globalExpanded.toggle() } }) {
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
                        .rotationEffect(.degrees(globalExpanded ? 90 : 0))
                }
                .padding(14)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if globalExpanded {
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
            if name.contains("battery") { return Image(systemName: "battery.100percent") }
        }
        // Music Library Icons
        if item.type == .musicLibrary {
            let name = item.name.lowercased()
            if name.contains("spotify") { return Image(systemName: "music.note") }
            return Image(systemName: "music.note.list")
        }
        // Photos Library Icons - Use actual app icon if it's a .photoslibrary bundle
        if item.type == .photosLibrary {
            // If we have a path to the Photos Library bundle, get its icon
            if let path = item.path, path.contains(".photoslibrary") {
                let nsImage = NSWorkspace.shared.icon(forFile: path)
                return Image(nsImage: nsImage)
            }
            // Fallback to SF Symbol
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
    let title: String, icon: String, color: Color, isSelected: Bool, count: Int
    let colorScheme: ColorScheme
    let action: () -> Void
    
    // Helper to get better text color for readability
    private var textColor: Color {
        if isSelected {
            // White text for selected state (high contrast)
            return .white
        } else {
            // Dark mode: light gray, Light mode: darker gray
            return colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.4)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            // Darker, more saturated background for selected (especially in dark mode)
            if colorScheme == .dark {
                return color.opacity(0.6) // Darker in dark mode
            } else {
                return color.opacity(0.8) // Same as before in light mode
            }
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.5)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return color
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
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
                    .fontWeight(isSelected ? .bold : .medium)
                    .lineLimit(1)
                
                // --- FIXED SIZE COUNT BADGE ---
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.7))
                    .cornerRadius(8)
                    .fixedSize()
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .shadow(color: isSelected && colorScheme == .dark ? color.opacity(0.5) : .clear, radius: 8, x: 0, y: 0) // Glow effect in dark mode
        }
        .buttonStyle(.plain)
        .help("""
            Click: Toggle filter
            ⌘ Command+Click: Solo (show only this, click again to show all)
            ⌥ Option+Click: Scroll to section
            """)
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
