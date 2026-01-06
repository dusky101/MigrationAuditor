//
//  IntroView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//


import SwiftUI

struct IntroView: View {
    @Binding var userName: String
    var startAction: () -> Void
    
    var body: some View {
        VStack(spacing: 25) { // Increased spacing slightly for better separation
            Spacer()
            
            Image(systemName: "laptopcomputer.and.arrow.down")
                .font(.system(size: 70)) // Made slightly larger
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Ready to Scan")
                .font(.title2)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your Name:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
                
                TextField("e.g. John Smith", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 260)
            }
            .padding(.vertical, 10)
            
            Text("Please ensure all your usual devices, drives, and printers are connected.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40) // Added side padding for cleaner text wrapping
                .font(.callout)
            
            // Button is now immediately below the text, not pushed to bottom
            Button(action: startAction) {
                Text("Start Capture")
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding(5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.top, 10)
            
            Spacer()
            Spacer() // This "Double Spacer" lifts the whole content block higher up
        }
        .padding()
    }
}
