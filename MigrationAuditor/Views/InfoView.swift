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
                        InfoRow(icon: "cpu", title: "System Specifications", desc: "Captures RAM, Chip type, Storage capacity, Serial Number, and Tahoe (Apple Intelligence) compatibility.")
                        InfoRow(icon: "battery.100percent", title: "Battery Health", desc: "Records battery condition, maximum capacity, and cycle count (MacBooks only).")
                        InfoRow(icon: "server.rack", title: "Network & Storage", desc: "Lists connected network shares, NAS volumes, and external USB drives.")
                        InfoRow(icon: "cable.connector", title: "External Peripherals", desc: "Identifies webcams, drawing tablets, and specialised USB devices.")
                        
                        // Software
                        InfoRow(icon: "app.badge.checkmark", title: "Applications", desc: "Lists installed software so we can redeploy essential apps.")
                        InfoRow(icon: "safari", title: "Web Browsers", desc: "Detects installed web browsers and their profiles (Safari, Chrome, Edge, Firefox).")
                        InfoRow(icon: "terminal", title: "Homebrew Packages", desc: "Lists developer packages and CLI tools installed via Homebrew.")
                        
                        // Media Libraries
                        InfoRow(icon: "music.note.list", title: "Music Library", desc: "Scans your Music folder and reports the total size and number of music files.")
                        InfoRow(icon: "photo.on.rectangle", title: "Photos Library", desc: "Measures your Photos Library size to help plan storage for your new Mac.")
                        
                        // Configuration
                        InfoRow(icon: "textformat", title: "Fonts", desc: "Identifies user-installed and admin-installed fonts, optionally captures font files for migration.")
                        InfoRow(icon: "printer.fill", title: "Printer Drivers", desc: "Copies driver files for your connected printers.")
                        InfoRow(icon: "envelope.fill", title: "Email Accounts", desc: "Detects configured email accounts in Mail and Outlook.")
                        InfoRow(icon: "cloud", title: "Cloud Storage", desc: "Lists detected cloud storage providers (Dropbox, OneDrive, Google Drive, etc.).")
                    }
                    
                    Divider()
                    
                    // What is NOT scanned
                    Group {
                        Text("What is NOT Scanned?")
                            .font(.headline)
                        
                        InfoRow(icon: "lock.shield", title: "Private Data", desc: "No documents, passwords, or browsing history are accessed. Music and Photos are measured only for size, not content.")
                        InfoRow(icon: "network.slash", title: "Network Traffic", desc: "No internet monitoring or traffic analysis is performed.")
                        InfoRow(icon: "photo.slash", title: "Individual Files", desc: "We do not scan individual photos, music tracks, or personal files—only storage size totals.")
                    }
                    
                    Divider()
                    
                    // Instructions
                    Group {
                        Text("Instructions")
                            .font(.headline)
                        
                        HStack(alignment: .top) {
                            Text("1.")
                            Text("Plug in all devices you use regularly (Printers, Scanners, Webcams, External Drives).")
                        }
                        HStack(alignment: .top) {
                            Text("2.")
                            Text("Grant permissions if prompted (Photos Library access requires approval in System Settings).")
                        }
                        HStack(alignment: .top) {
                            Text("3.")
                            Text("Select 'Include Font Files' if you require your custom typography library moved to your new Mac.")
                        }
                        HStack(alignment: .top) {
                            Text("4.")
                            Text("Click 'Start Analysis' and wait for the scan to finish (typically 1-3 minutes).")
                        }
                        HStack(alignment: .top) {
                            Text("5.")
                            Text("Review the captured data, then share/email the generated ZIP file to your IT administrator.")
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
