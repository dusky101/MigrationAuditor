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
    
    // Animation States
    @State private var buttonsVisible = false
    @State private var shimmerOffset: CGFloat = -200
    
    func openShareSheet() {
        let fileURL = URL(fileURLWithPath: path)
        let picker = NSSharingServicePicker(items: [fileURL])
        
        // Fix: Anchor the menu to the button area (Bottom Center)
        // rather than the whole window.
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let contentView = window.contentView {
            
            // Define a rectangle near the bottom center of the window
            let buttonRect = NSRect(x: contentView.bounds.midX, y: 120, width: 0, height: 0)
            
            picker.show(relativeTo: buttonRect, of: contentView, preferredEdge: .minY)
        }
    }
    
    func revealFile() {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // --- SUCCESS ICON ---
            VStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("Capture Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("The report has been saved to your Desktop.")
                    .foregroundColor(.secondary)
            }
            .offset(y: buttonsVisible ? 0 : 20)
            .opacity(buttonsVisible ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.8), value: buttonsVisible)
            
            Spacer()
            
            // --- BUTTONS ---
            VStack(spacing: 15) {
                
                // 1. REVIEW BUTTON (Top - Primary Visibility)
                Button(action: { showingDetailsSheet = true }) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.title3)
                            .foregroundColor(.indigo)
                        VStack(alignment: .leading) {
                            Text("Review Captured Data")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Check what was found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                
                // 2. SHARE BUTTON (Middle - Blue with Glimmer)
                Button(action: openShareSheet) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title3)
                        VStack(alignment: .leading) {
                            Text("Share File")
                                .fontWeight(.bold)
                            Text("Send to IT Support")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "paperplane.fill")
                    }
                    .padding()
                    .foregroundColor(.white) // Force White Text
                    .background(Color.blue)
                    .cornerRadius(10)
                    .overlay(
                        // GLIMMER EFFECT
                        Rectangle()
                            .fill(
                                LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 100)
                            .offset(x: shimmerOffset)
                            .mask(Rectangle().cornerRadius(10))
                    )
                }
                .buttonStyle(.plain)
                .shadow(radius: 3)
                
                // 3. FINDER BUTTON (Bottom - Proper Button)
                Button(action: revealFile) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.gray)
                        Text("Show in Finder")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 320) // Consistent width for all buttons
            .opacity(buttonsVisible ? 1.0 : 0.0)
            .offset(y: buttonsVisible ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: buttonsVisible)
            
            Spacer()
        }
        .onAppear {
            buttonsVisible = true
            
            // Run Glimmer Animation loop
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 350
                }
            }
        }
        .sheet(isPresented: $showingDetailsSheet) {
            DataReviewView(items: auditor.scannedItems)
                .frame(width: 700, height: 600)
        }
    }
}
