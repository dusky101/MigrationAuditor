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
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "laptopcomputer.and.arrow.down")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Ready to Scan")
                .font(.title3)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Enter your Name:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                TextField("e.g. John Smith", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 250)
            }
            .padding(.vertical, 5)
            
            Text("Please ensure all your usual devices, drives, and printers are connected.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .font(.callout)
            
            Spacer()
            
            Button(action: startAction) {
                Text("Start Capture")
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding(5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}