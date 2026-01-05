//
//  CategoryView.swift
//  MigrationAuditor
//
//  Created by Marc on 05/01/2026.
//


import SwiftUI

struct CategoryView: View {
    let title: String
    let icon: String
    let color: Color
    let items: [AuditItem]
    @State private var isExpanded: Bool = true
    
    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: isExpanded ? "minus.circle.fill" : "plus.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                        .padding(.trailing, 5)
                    
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(color)
                        .cornerRadius(6)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(items.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }
                
                // List Items
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            VStack(spacing: 0) {
                                ResultRow(item: item, icon: "doc")
                                if index < items.count - 1 {
                                    Divider().padding(.leading, 34)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .cornerRadius(10)
                    .padding(.top, 5)
                }
            }
        }
    }
}

struct ResultRow: View {
    let item: AuditItem
    let icon: String
    
    var body: some View {
        HStack {
            if let path = item.path {
                Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                    .resizable().aspectRatio(contentMode: .fit).frame(width: 24, height: 24)
            } else {
                Image(systemName: icon)
                    .foregroundColor(.secondary).frame(width: 24)
            }
            VStack(alignment: .leading) {
                Text(item.name).fontWeight(.medium)
                Text(item.details).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}