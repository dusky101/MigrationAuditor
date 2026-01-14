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
    
    // NEW: Closure to handle the reset action
    var onReset: () -> Void
    
    @State private var showingDetailsSheet = false
    
    // Animation States
    @State private var buttonsVisible = false
    @State private var shimmerOffset: CGFloat = -500
    
    // Copy Feedback State
    @State private var hasCopied = false
    
    func copyFileToClipboard() {
        let fileURL = URL(fileURLWithPath: path)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileURL as NSPasteboardWriting])
        
        // Trigger "Copied!" animation
        withAnimation { hasCopied = true }
        
        // Reset back to normal after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { hasCopied = false }
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
                
                // 1. REVIEW BUTTON (Top)
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
                
                // 2. COPY BUTTON (Middle - Blue with Shine -> Turns Green on Click)
                Button(action: copyFileToClipboard) {
                    HStack {
                        // Icon changes checkmark when copied
                        Image(systemName: hasCopied ? "checkmark" : "doc.on.doc.fill")
                            .font(.title3)
                            .scaleEffect(hasCopied ? 1.2 : 1.0)
                        
                        VStack(alignment: .leading) {
                            // Text changes when copied
                            Text(hasCopied ? "Copied to Clipboard!" : "Copy Report File")
                                .fontWeight(.bold)
                            Text(hasCopied ? "Ready to Paste (Cmd+V)" : "Paste into Outlook / Email")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(.white)
                    // Background changes to Green when copied
                    .background(hasCopied ? Color.green : Color.blue)
                    .cornerRadius(10)
                    // THE SHINE EFFECT (Only shows when NOT copied)
                    .overlay(
                        Group {
                            if !hasCopied {
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    .clear,
                                                    .white.opacity(0.1),
                                                    .white.opacity(0.6),
                                                    .white.opacity(0.1),
                                                    .clear
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .rotationEffect(.degrees(45))
                                        .frame(width: geo.size.width * 2, height: geo.size.height * 2)
                                        .offset(x: shimmerOffset, y: -geo.size.height)
                                }
                                .mask(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .shadow(radius: 3)
                .animation(.spring(), value: hasCopied)
                
                // 3. FINDER BUTTON (Bottom)
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
                
                // 4. NEW: RESET BUTTON
                Button(action: onReset) {
                    Text("Start New Audit")
                        .foregroundColor(.secondary)
                        .font(.callout)
                        .underline(true, color: .clear) // Invisible underline to keep text size consistent on hover if we wanted
                }
                .buttonStyle(.link)
                .padding(.top, 10)
            }
            .frame(maxWidth: 320)
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
                    shimmerOffset = 500
                }
            }
        }
        .sheet(isPresented: $showingDetailsSheet) {
            DataReviewView(items: auditor.scannedItems, userName: userName)
        }
    }
}
