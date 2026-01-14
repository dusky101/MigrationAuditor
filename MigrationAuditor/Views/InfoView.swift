//
//  InfoView.swift
//  MigrationAuditor
//
//  Created by Marc on 02/01/2026.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- Header ---
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("About This Audit Tool")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // --- Scrollable Content ---
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Intro
                    Group {
                        Text("Purpose")
                            .font(.headline)
                        Text("This application assists IT in preparing your new Mac environment. By capturing your current setup, we ensure you have the correct hardware specs, software, and drivers ready on your new machine.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // What is scanned
                    Group {
                        Text("What is Scanned?")
                            .font(.headline)
                        
                        // Hardware
                        InfoRow(icon: "cpu", title: "System Specifications", desc: "Captures RAM, Chip type, Storage capacity, and Serial Number.")
                        InfoRow(icon: "server.rack", title: "Network Drives", desc: "Lists connected network shares and NAS volumes.")
                        InfoRow(icon: "cable.connector", title: "Peripherals", desc: "Identifies webcams, drawing tablets, and specialised USB devices.")
                        
                        // Software
                        InfoRow(icon: "app.badge.checkmark", title: "Applications", desc: "Lists installed software so we can redeploy essential apps.")
                        InfoRow(icon: "safari", title: "Web Browsers", desc: "Detects installed web browsers (Chrome, Firefox, etc.).")
                        InfoRow(icon: "terminal", title: "Homebrew", desc: "Lists developer packages installed via Homebrew.")
                        
                        // Configuration
                        InfoRow(icon: "textformat", title: "Fonts", desc: "Identifies user-installed fonts and optionally captures the font files for migration.")
                        InfoRow(icon: "printer.fill", title: "Printer Drivers", desc: "Copies driver files for your connected printers.")
                        InfoRow(icon: "cloud", title: "Cloud & Email", desc: "Lists configured email accounts and detected cloud storage providers.")
                    }
                    
                    Divider()
                    
                    // What is NOT scanned
                    Group {
                        Text("What is NOT Scanned?")
                            .font(.headline)
                        
                        InfoRow(icon: "lock.shield", title: "Private Data", desc: "No documents, passwords, or browsing history are accessed.")
                        InfoRow(icon: "network.slash", title: "Network Traffic", desc: "No internet monitoring or traffic analysis is performed.")
                    }
                    
                    Divider()
                    
                    // Instructions
                    Group {
                        Text("Instructions")
                            .font(.headline)
                        
                        HStack(alignment: .top) {
                            Text("1.")
                            Text("Plug in all devices you use (Printers, Scanners, Webcams).")
                        }
                        HStack(alignment: .top) {
                            Text("2.")
                            Text("Select 'Include Font Files' if you require your custom typography library moved.")
                        }
                        HStack(alignment: .top) {
                            Text("3.")
                            Text("Click 'Start Analysis' and wait for the scan to finish.")
                        }
                        HStack(alignment: .top) {
                            Text("4.")
                            Text("Review the data, then share/email the generated ZIP file to your administrator.")
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
    }
}

// Helper view for the list rows
struct InfoRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
