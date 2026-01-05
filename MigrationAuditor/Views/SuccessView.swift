//
//  SuccessView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//


import SwiftUI
import AppKit

struct SuccessView: View {
    let path: String
    let userName: String
    @ObservedObject var auditor: AuditLogic
    @State private var showingDetailsSheet = false
    
    func openShareSheet() {
        let fileURL = URL(fileURLWithPath: path)
        let picker = NSSharingServicePicker(items: [fileURL])
        
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let contentView = window.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
    }
    
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
                Button(action: openShareSheet) {
                    Label("Share File", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
            
            Button("Review Captured Data") { showingDetailsSheet = true }
                .buttonStyle(.link)
                .padding(.top, 5)
        }
        .sheet(isPresented: $showingDetailsSheet) {
            DataReviewView(items: auditor.scannedItems)
                .frame(width: 700, height: 600)
        }
    }
}