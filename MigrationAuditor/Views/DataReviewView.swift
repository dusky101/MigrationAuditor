//
//  DataReviewView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//


import SwiftUI

struct DataReviewView: View {
    let items: [AuditItem]
    @Environment(\.presentationMode) var presentationMode
    @State private var showHelp = false // New State for Help Sheet
    
    // Sort Helper
    func sorted(_ list: [AuditItem]) -> [AuditItem] {
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var groupedRealApps: [(key: String, value: [AuditItem])] {
        let apps = items.filter { $0.type == .installedApp }
        let grouped = Dictionary(grouping: apps) { $0.developer }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var systemComponents: [AuditItem] {
        return items.filter { $0.type == .systemComponent }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER ---
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.blue)
                Text("Captured Inventory").font(.title2).fontWeight(.bold)
                
                // NEW: Help Button
                Button(action: { showHelp = true }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Understanding this data")
                
                Spacer()
                
                Button("Close") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            Divider()
            
            // --- SCROLL CONTENT ---
            ScrollView {
                VStack(spacing: 20) {
                    CategoryView(title: "System Specifications", icon: "desktopcomputer", color: .purple, items: items.filter { $0.type == .systemSpec })
                    CategoryView(title: "Applications Folder (Top Level)", icon: "folder.fill", color: .blue, items: sorted(items.filter { $0.type == .mainApp }))
                    
                    ForEach(groupedRealApps, id: \.key) { group in
                        CategoryView(title: "\(group.key) Applications", icon: "app.badge", color: .indigo, items: sorted(group.value))
                    }
                    
                    CategoryView(title: "Network & Storage", icon: "server.rack", color: .green, items: sorted(items.filter { $0.type == .networkDrive }))
                    CategoryView(title: "Printers & Drivers", icon: "printer.fill", color: .orange, items: sorted(items.filter { $0.type == .printer }))
                    CategoryView(title: "External Devices", icon: "cable.connector", color: .yellow, items: sorted(items.filter { $0.type == .device }))
                    
                    let fluff = sorted(items.filter { $0.type == .systemComponent })
                    if !fluff.isEmpty {
                        CategoryView(title: "System Internals & Helpers", icon: "gearshape.2", color: .gray, items: fluff)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        // NEW: Help Sheet
        .sheet(isPresented: $showHelp) {
            DataReviewHelpView()
        }
    }
}

// --- NEW HELP VIEW ---
struct DataReviewHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Understanding Your Data").font(.headline)
                Spacer()
                Button("Done") { presentationMode.wrappedValue.dismiss() }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    HelpRow(icon: "app.badge", title: "Applications", desc: "These are the standard apps you use daily (Word, Chrome, etc). We group them by developer to make them easy to read.")
                    HelpRow(icon: "gearshape.2", title: "System Internals", desc: "These are background tools, updaters, and helper files that keep your apps running. We capture them for completeness, but you can usually ignore them.")
                    HelpRow(icon: "printer.fill", title: "Printers", desc: "We capture the names of your printer drivers to ensure you can print on your new Mac.")
                    HelpRow(icon: "server.rack", title: "Network", desc: "Any shared drives or servers you are connected to will appear here.")
                }
                .padding()
            }
        }
        .frame(width: 400, height: 400)
    }
}

struct HelpRow: View {
    let icon: String, title: String, desc: String
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 30)
            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(desc).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
