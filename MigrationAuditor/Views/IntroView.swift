//
//  IntroView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//

import SwiftUI

struct IntroView: View {
    @Binding var userName: String
    @Binding var includeFonts: Bool // New binding for the toggle
    var startAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- HERO SECTION ---
            VStack(spacing: 15) {
                Image(systemName: "macwindow.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.bottom, 10)
                
                Text("Welcome to Migration Auditor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Capture your complete Mac setup, apps, and settings for a seamless migration or replacement Mac.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 40)
            
            // --- INPUT CARD ---
            VStack(alignment: .leading, spacing: 20) {
                
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your Name", systemImage: "person.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("e.g. Jane Doe", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .onSubmit {
                            // Allows user to press Return to start
                            if !userName.trimmingCharacters(in: .whitespaces).isEmpty {
                                startAction()
                            }
                        }
                }
                
                Divider()
                
                // Font Toggle
                Toggle(isOn: $includeFonts) {
                    VStack(alignment: .leading) {
                        Text("Include Font Files in Zip")
                            .font(.headline)
                        Text("Warning: This may significantly increase file size.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.large)
                
            }
            .padding(30)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 60)
            .frame(maxWidth: 500)
            Spacer()
            
            // --- ACTION BUTTON ---
            Button(action: startAction) {
                HStack {
                    Text("Start Analysis")
                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: 300)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .keyboardShortcut(.defaultAction) // Allows simple Enter key usage if focus isn't in text field
            
            Text("Please ensure all peripheral devices are connected before starting.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 15)
            
            Spacer()
        }
        .padding()
    }
}
