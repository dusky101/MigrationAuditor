//
//  ContentView.swift
//  MigrationAuditor
//
//  Created by Marc on 02/01/2026.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var auditor = AuditLogic()
    @State private var reportPath: String? = nil
    @State private var showInfo = false
    @State private var userName = "" // <--- NEW: Stores the user input
    
    var body: some View {
        VStack(spacing: 20) {
            
            // --- HEADER ---
            HStack {
                Image(systemName: "archivebox.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Mac Migration Assistant")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Capture your setup for IT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { showInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("What does this app do?")
            }
            .padding(.bottom, 10)
            
            Divider()
            
            // --- MAIN CONTENT ---
            if auditor.isScanning {
                ScanningView(message: auditor.progressMessage)
            } else {
                if let path = reportPath {
                    SuccessView(path: path, auditor: auditor)
                } else {
                    // Pass binding to userName
                    IntroView(userName: $userName, startAction: {
                        // Pass userName to Logic
                        auditor.performAudit(userName: userName) { path in
                            self.reportPath = path
                        }
                    })
                }
            }
        }
        .padding()
        .frame(width: 500, height: 500)
        .sheet(isPresented: $showInfo) { InfoView() }
    }
}

// --- SUB-VIEWS ---

struct IntroView: View {
    @Binding var userName: String // <--- NEW binding
    var startAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "laptopcomputer.and.arrow.down")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Ready to Scan")
                .font(.title3)
                .fontWeight(.medium)
            
            // --- NEW: Name Input Field ---
            VStack(alignment: .leading, spacing: 5) {
                Text("Enter your Name:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                TextField("e.g. John Smith", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)
            }
            .padding(.vertical, 5)
            
            Text("Please ensure all your usual devices, drives, and printers are connected.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .font(.callout)
            
            Spacer()
            
            Button(action: startAction) {
                Text("Start Capture")
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding(5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty) // <--- DISABLER
        }
    }
}

struct ScanningView: View {
    var message: String
    
    var currentIcon: String {
        if message.contains("Applications") || message.contains("software") { return "app.badge.checkmark" }
        if message.contains("network") || message.contains("drives") { return "server.rack" }
        if message.contains("peripherals") { return "cable.connector" }
        if message.contains("printer") { return "printer.fill" }
        if message.contains("package") || message.contains("Finalising") { return "doc.zipper" }
        return "magnifyingglass"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: currentIcon)
                .resizable().aspectRatio(contentMode: .fit).frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .symbolEffect(.bounce, value: message)
            
            VStack(spacing: 10) {
                ProgressView().controlSize(.large)
                Text(message).font(.title3).fontWeight(.medium).foregroundColor(.secondary)
                    .id(message).transition(.opacity.animation(.easeInOut))
            }
            Spacer()
        }
        .animation(.spring(), value: currentIcon)
    }
}

struct SuccessView: View {
    let path: String
    @ObservedObject var auditor: AuditLogic
    @State private var showingDetailsSheet = false
    
    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60)).foregroundColor(.green)
            Text("Capture Complete!").font(.title3).fontWeight(.bold)
            Text("Your data has been saved to the Desktop.").foregroundColor(.secondary)
            HStack {
                Image(systemName: "doc.zipper")
                Text(URL(fileURLWithPath: path).lastPathComponent).fontWeight(.medium)
            }
            .padding().background(Color.gray.opacity(0.1)).cornerRadius(8)
            Spacer()
            HStack(spacing: 15) {
                Button("Review Captured Data") { showingDetailsSheet = true }.buttonStyle(.bordered)
                Button("Reveal in Finder") { NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "") }.buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
        }
        .sheet(isPresented: $showingDetailsSheet) {
            DataReviewView(items: auditor.scannedItems)
                .frame(width: 700, height: 600)
        }
    }
}

struct DataReviewView: View {
    let items: [AuditItem]
    @Environment(\.presentationMode) var presentationMode
    
    var groupedApps: [(key: String, value: [AuditItem])] {
        let apps = items.filter { $0.type == .app }
        let grouped = Dictionary(grouping: apps) { $0.developer }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Captured Inventory").font(.title2).fontWeight(.bold)
                Spacer()
                Button("Close") { presentationMode.wrappedValue.dismiss() }
            }
            .padding().background(Color(NSColor.controlBackgroundColor))
            
            List {
                Section(header: Label("Applications Folder", systemImage: "folder.fill")) {
                    ForEach(items.filter { $0.type == .mainApp }) { item in
                        ResultRow(item: item, icon: "app")
                    }
                }
                
                Section(header: Label("Network & Storage", systemImage: "server.rack")) {
                    ForEach(items.filter { $0.type == .networkDrive }) { item in
                        ResultRow(item: item, icon: "internaldrive.fill")
                    }
                    if items.filter({ $0.type == .networkDrive }).isEmpty {
                        Text("No mounted drives found").font(.caption).foregroundColor(.secondary)
                    }
                }
                
                Section(header: Label("Printers & Drivers", systemImage: "printer.fill")) {
                    ForEach(items.filter { $0.type == .printer }) { item in
                        ResultRow(item: item, icon: "printer")
                    }
                }
                
                Section(header: Label("External Devices", systemImage: "cable.connector")) {
                    ForEach(items.filter { $0.type == .device }) { item in
                        ResultRow(item: item, icon: "externaldrive.fill")
                    }
                }
                
                ForEach(groupedApps, id: \.key) { group in
                    Section(header: Label("System Software: \(group.key)", systemImage: "gearshape.2")) {
                        ForEach(group.value) { item in
                            ResultRow(item: item, icon: "app")
                        }
                    }
                }
                
                Section(header: Label("Built-in System Hardware", systemImage: "cpu")) {
                    ForEach(items.filter { $0.type == .internalDevice }) { item in
                        ResultRow(item: item, icon: "memorychip")
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct ResultRow: View {
    let item: AuditItem
    let icon: String
    
    var body: some View {
        HStack {
            if let path = item.path {
                Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                    .resizable().aspectRatio(contentMode: .fit).frame(width: 24, height: 24)
            } else {
                Image(systemName: icon)
                    .foregroundColor(.blue).frame(width: 24)
            }
            VStack(alignment: .leading) {
                Text(item.name).fontWeight(.medium)
                Text(item.details).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
