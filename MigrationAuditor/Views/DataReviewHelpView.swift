//
//  DataReviewHelpView.swift
//  MigrationAuditor
//
//  Created by Marc Oliff on 14/01/2026.
//


import SwiftUI

struct DataReviewHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- Header ---
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("How to Review Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // --- Content ---
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 1. Interface Overview
                    HelpSection(title: "Interface Overview", icon: "macwindow") {
                        Text("This screen displays every item captured during the audit. Items are grouped into categories like Applications, Fonts, and System Specs.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // 2. Filtering
                    HelpSection(title: "Using Filters", icon: "line.3.horizontal.decrease.circle") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("The category chips at the top allow you to filter the list:")
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text("**Click** a category chip to toggle it on or off.")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "option")
                                Text("Hold **Option (⌥)** and click a chip to 'solo' it (show only that category).")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "command")
                                Text("Hold **Command (⌘)** and click a chip to ensure it's visible and selected.")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text("Use the **search bar** to find specific apps or files by name.")
                            }
                        }
                        .font(.callout)
                    }
                    
                    // 3. Exporting
                    HelpSection(title: "Exporting to PDF", icon: "doc.text.fill") {
                        Text("The **Export PDF** button creates a report based on your current view.")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• If you have filters active, only the visible items will be included in the PDF.")
                                .font(.callout)
                            Text("• If you want a full report, ensure 'Select All' is clicked before exporting.")
                                .font(.callout)
                            Text("• The PDF includes proper icons for Music Library, Photos Library, and all other items.")
                                .font(.callout)
                        }
                        .padding(.top, 5)
                    }
                    
                    // Storage Planning
                    HelpSection(title: "Understanding Storage Data", icon: "internaldrive.fill") {
                        Text("The Music Library and Photos Library items help you plan storage for your new Mac:")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• **Music Library**: Total size of all music files in your Music folder (including Apple Music, iTunes, and Spotify cache).")
                                .font(.callout)
                            Text("• **Photos Library**: Complete size of your Photos Library bundle, including all originals, edits, thumbnails, and metadata.")
                                .font(.callout)
                            Text("• Use these numbers to determine if you need additional storage on your new Mac.")
                                .font(.callout)
                        }
                        .padding(.top, 5)
                    }
                    
                    // Battery Health
                    HelpSection(title: "Battery Health Information", icon: "battery.100percent") {
                        Text("For MacBook users, battery health metrics are captured:")
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• **Condition**: Normal, Fair, or Service Recommended")
                                .font(.callout)
                            Text("• **Maximum Capacity**: Current battery health as a percentage")
                                .font(.callout)
                            Text("• **Cycle Count**: Number of charge cycles completed")
                                .font(.callout)
                            Text("This helps IT assess whether a battery replacement is needed before migration.")
                                .font(.callout)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 5)
                    }
                    
                    Divider()
                    
                    // 4. Data Categories
                    Text("Data Categories Explained")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        Text("Your captured data is organised into the following categories:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            // Hardware & System
                            DataCategoryRow(icon: "desktopcomputer", color: .purple, title: "System Specs", desc: "Hardware details, Serial Number, and Tahoe support.")
                            DataCategoryRow(icon: "battery.100percent", color: .purple, title: "Battery Health", desc: "Condition, capacity, and cycle count (laptops only).")
                            
                            // Applications
                            DataCategoryRow(icon: "app.badge", color: .indigo, title: "Detected Apps", desc: "User-installed applications from system profile.")
                            DataCategoryRow(icon: "folder.fill", color: .blue, title: "Applications Folder", desc: "Apps found in /Applications directory.")
                            DataCategoryRow(icon: "gearshape.2", color: .gray, title: "System Internals", desc: "Background helpers and system components.")
                            
                            // Media Libraries
                            DataCategoryRow(icon: "music.note.list", color: .mint, title: "Music Library", desc: "Size and location of music collections.")
                            DataCategoryRow(icon: "photo.on.rectangle", color: .teal, title: "Photos Library", desc: "Photos app library size for storage planning.")
                            
                            // Configuration & Tools
                            DataCategoryRow(icon: "textformat", color: .pink, title: "Fonts", desc: "User-installed and admin-installed typefaces.")
                            DataCategoryRow(icon: "terminal.fill", color: .brown, title: "Homebrew", desc: "Developer packages and CLI tools.")
                            
                            // Internet & Cloud
                            DataCategoryRow(icon: "safari", color: .cyan, title: "Browsers", desc: "Installed web browsers and profiles.")
                            DataCategoryRow(icon: "envelope.fill", color: .red, title: "Email Accounts", desc: "Configured email in Mail and Outlook.")
                            DataCategoryRow(icon: "cloud.fill", color: .blue, title: "Cloud Storage", desc: "Detected cloud storage providers.")
                            
                            // Hardware & Peripherals
                            DataCategoryRow(icon: "server.rack", color: .green, title: "Network & Storage", desc: "Network shares, NAS drives, and USB storage.")
                            DataCategoryRow(icon: "cable.connector", color: .yellow, title: "External Devices", desc: "Connected peripherals like webcams.")
                            DataCategoryRow(icon: "printer.fill", color: .orange, title: "Printers", desc: "Printer queues and driver files.")
                        }
                    }
                }
                .padding(25)
            }
        }
        .frame(width: 650, height: 800)
    }
}

// --- Helper Views for Help Screen ---

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                content
            }
        }
    }
}

struct DataCategoryRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold).font(.subheadline)
                Text(desc).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
