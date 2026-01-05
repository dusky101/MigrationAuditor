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
    
    var currentIcon: String {
        if message.contains("Hard Drive") { return "internaldrive" }
        if message.contains("Memory") { return "memorychip" }
        if message.contains("Serial") { return "barcode.viewfinder" }
        if message.contains("Applications") { return "app.badge.checkmark" }
        if message.contains("Network") { return "server.rack" }
        if message.contains("USB") { return "cable.connector" }
        if message.contains("Printer") { return "printer.fill" }
        if message.contains("Zip") { return "doc.zipper" }
        return "magnifyingglass"
    }
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: currentIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .symbolEffect(.bounce, value: message)
            
            VStack(spacing: 12) {
                Text(message)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .id(message)
                    .transition(.opacity.animation(.easeInOut))
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 300)
                    .animation(.easeOut(duration: 0.3), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}