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
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            
            // --- HEADER ---
            ZStack {
                // Background layer with logo and info button
                HStack(alignment: .center, spacing: 0) {
                    // Logo (left side)
                    Image(colorScheme == .dark ? "zellisdark" : "zellislight")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                    
                    Spacer()
                    
                    // Info Button (right side)
                    Button(action: { showInfo = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("What does this app do?")
                }
                .padding(.horizontal, 40)
                
                // Title Section (centered overlay)
                VStack(spacing: 4) {
                    Text("Mac Migration Assistant")
                        .font(.system(size: 28, weight: .semibold))
                    Text("Capture your setup for easy migration")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 20)
//            .background(Color(nsColor: .windowBackgroundColor))
            
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
