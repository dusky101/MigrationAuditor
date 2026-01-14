//
//  ContentView.swift
//  MigrationAuditor
//
//  Created by Marc on 02/01/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var auditor = AuditLogic()
    @State private var reportPath: String? = nil
    @State private var showInfo = false
    @State private var userName = ""
    
    // Toggle for including font files
    @State private var includeFonts = false
    
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
            .padding(.horizontal, 30) // Added extra padding here to pull it in from the edges
            .padding(.bottom, 10)
            
            Divider()
            
            // --- MAIN LOGIC ---
            if auditor.isScanning {
                ScanningView(message: auditor.progressMessage, progress: auditor.scanProgress)
            } else {
                if let path = reportPath {
                    SuccessView(
                        path: path,
                        userName: userName,
                        auditor: auditor,
                        onReset: {
                            // RESET LOGIC
                            self.reportPath = nil
                            self.userName = ""
                            self.includeFonts = false
                            self.auditor.scannedItems = []
                        }
                    )
                } else {
                    IntroView(
                        userName: $userName,
                        includeFonts: $includeFonts,
                        startAction: {
                            auditor.performAudit(userName: userName, includeFonts: includeFonts) { path in
                                self.reportPath = path
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .frame(width: 1320, height: 800) // Updated to your new landscape size
        .sheet(isPresented: $showInfo) { InfoView() }
    }
}
