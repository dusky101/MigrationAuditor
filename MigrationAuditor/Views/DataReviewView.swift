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
    
    // Helper: Sort items A-Z
    func sorted(_ list: [AuditItem]) -> [AuditItem] {
        return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // Group "Real" Apps by Developer
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
            // Header
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.blue)
                Text("Captured Inventory").font(.title2).fontWeight(.bold)
                Spacer()
                Button("Close") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            Divider()
            
            // Scrollable Content
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
                    
                    // Fluff
                    let fluff = sorted(items.filter { $0.type == .systemComponent })
                    if !fluff.isEmpty {
                        CategoryView(title: "System Internals & Helpers", icon: "gearshape.2", color: .gray, items: fluff)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}