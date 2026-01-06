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
            
            // --- MAIN LOGIC ---
            if auditor.isScanning {
                ScanningView(message: auditor.progressMessage, progress: auditor.scanProgress)
            } else {
                if let path = reportPath {
                    SuccessView(path: path, userName: userName, auditor: auditor)
                } else {
                    IntroView(userName: $userName, startAction: {
                        auditor.performAudit(userName: userName) { path in
                            self.reportPath = path
                        }
                    })
                }
            }
        }
        .padding()
        // --- CHANGED SIZE HERE ---
        .frame(width: 550, height: 650)
        .sheet(isPresented: $showInfo) { InfoView() }
    }
}
