//
//  ScanningView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//


import SwiftUI

struct ScanningView: View {
    var message: String
    var progress: Double
    
    @State private var pulseAnimation = false
    
    var currentIcon: String {
        if message.contains("Hard Drive") { return "internaldrive" }
        if message.contains("Memory") { return "memorychip" }
        if message.contains("Serial") { return "barcode.viewfinder" }
        if message.contains("iCloud") { return "icloud.fill" }
        if message.contains("Applications") { return "app.badge.checkmark" }
        if message.contains("Network") { return "server.rack" }
        if message.contains("Deep System") { return "cpu.fill" }
        if message.contains("USB") { return "cable.connector" }
        if message.contains("Printer") { return "printer.fill" }
        if message.contains("Zip") || message.contains("Finalising") { return "doc.zipper" }
        return "magnifyingglass"
    }
    
    // Show helpful context during the long deep scan
    var isDeepScan: Bool {
        message.contains("Deep System") && progress >= 0.5 && progress <= 0.75
    }
    
    var deepScanContext: String {
        if progress < 0.55 {
            return "Indexing installed applications..."
        } else if progress < 0.60 {
            return "Scanning system frameworks..."
        } else if progress < 0.65 {
            return "Checking background processes..."
        } else if progress < 0.70 {
            return "Analyzing helper applications..."
        } else {
            return "Completing deep system analysis..."
        }
    }
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            ZStack {
                // Pulsing background ring for deep scan
                if isDeepScan {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
                
                Image(systemName: currentIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .symbolEffect(.bounce, value: message)
                    .symbolEffect(.pulse, isActive: isDeepScan)
            }
            
            VStack(spacing: 12) {
                Text(message)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .id(message)
                    .transition(.opacity.animation(.easeInOut))
                
                // Show context message during deep scan
                if isDeepScan {
                    Text(deepScanContext)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.animation(.easeInOut))
                        .id(deepScanContext)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.caption2)
                            .symbolEffect(.pulse)
                        Text("This may take 1-3 minutes")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 300)
                    .animation(.easeOut(duration: 0.3), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(isDeepScan ? .semibold : .regular)
            }
            Spacer()
        }
        .onChange(of: isDeepScan) { _, newValue in
            // Start/stop pulse when deep scan toggles; schedule to next run loop to avoid multiple updates per frame
            DispatchQueue.main.async {
                pulseAnimation = newValue
            }
        }
        .onAppear {
            // Initialize pulse state based on current deep scan flag
            pulseAnimation = isDeepScan
        }
    }
}
