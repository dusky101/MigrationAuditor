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
                            Text("The buttons at the top allow you to filter the list:")
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text("Click a category chip to toggle it on or off.")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "command")
                                Text("Hold **Command (⌘)** and click a chip to 'solo' it (hide everything else).")
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                Text("Use the search bar to find specific apps or files by name.")
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
                        }
                        .padding(.top, 5)
                    }
                    
                    Divider()
                    
                    // 4. Data Categories
                    Text("Data Categories Explained")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        DataCategoryRow(icon: "desktopcomputer", color: .purple, title: "System Specs", desc: "Hardware details & Serial Number.")
                        DataCategoryRow(icon: "app.badge", color: .indigo, title: "Applications", desc: "User-installed software.")
                        DataCategoryRow(icon: "folder.fill", color: .blue, title: "Apps Folder", desc: "Items found in /Applications.")
                        DataCategoryRow(icon: "textformat", color: .pink, title: "Fonts", desc: "User-installed typefaces.")
                        DataCategoryRow(icon: "server.rack", color: .green, title: "Network", desc: "Connected shares & NAS drives.")
                        DataCategoryRow(icon: "printer.fill", color: .orange, title: "Printers", desc: "Queues and driver files.")
                        DataCategoryRow(icon: "terminal.fill", color: .brown, title: "Homebrew", desc: "Developer packages & tools.")
                        DataCategoryRow(icon: "cloud.fill", color: .blue, title: "Cloud", desc: "Cloud storage providers.")
                    }
                }
                .padding(25)
            }
        }
        .frame(width: 600, height: 700)
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
