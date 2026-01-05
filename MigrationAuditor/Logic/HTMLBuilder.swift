//
//  HTMLBuilder.swift
//  MigrationAuditor
//
//  Created by Marc on 02/01/2026.
//

import Foundation

class HTMLBuilder {
    
    static func generateHTML(items: [AuditItem], userName: String) -> String {
        
        let printers = items.filter { $0.type == .printer }
        let external = items.filter { $0.type == .device }
        let mainApps = items.filter { $0.type == .mainApp }
        let network = items.filter { $0.type == .networkDrive }
        let specs = items.filter { $0.type == .systemSpec }
        
        // Group Real Apps
        let realApps = items.filter { $0.type == .installedApp }
        let groupedApps = Dictionary(grouping: realApps) { $0.developer }
        let sortedKeys = groupedApps.keys.sorted()
        
        // The Fluff
        let internals = items.filter { $0.type == .systemComponent }
        
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Migration Report - \(userName)</title>
            <style>
                :root { --primary: #007AFF; --bg: #F5F5F7; --card: #FFFFFF; --text: #1D1D1F; }
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: var(--bg); color: var(--text); margin: 0; padding: 40px; }
                .container { max-width: 1000px; margin: 0 auto; }
                .header-container { text-align: center; margin-bottom: 40px; }
                h1 { font-weight: 700; margin-bottom: 5px; }
                .subtitle { color: #86868B; font-size: 1.1rem; }
                .user-badge { background: #E5F1FF; color: #007AFF; padding: 5px 12px; border-radius: 20px; font-weight: 600; font-size: 0.9rem; margin-top: 10px; display: inline-block; }
                
                .card { background: var(--card); border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); padding: 20px; margin-bottom: 30px; }
                .card-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #E5E5EA; padding-bottom: 15px; margin-bottom: 15px; }
                .card-title { font-size: 1.2rem; font-weight: 600; color: var(--primary); }
                
                .spec-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 15px; }
                .spec-item { background: #F2F2F7; padding: 15px; border-radius: 8px; }
                .spec-label { font-size: 12px; color: #86868B; text-transform: uppercase; font-weight: 600; }
                .spec-value { font-size: 16px; font-weight: 600; color: #1D1D1F; margin-top: 5px; }

                input[type="text"] { width: 100%; padding: 12px; border: 1px solid #D1D1D6; border-radius: 8px; font-size: 16px; margin-bottom: 20px; box-sizing: border-box; }
                table { width: 100%; border-collapse: collapse; font-size: 14px; }
                th { text-align: left; padding: 10px; border-bottom: 2px solid #E5E5EA; color: #86868B; font-weight: 600; }
                td { padding: 10px; border-bottom: 1px solid #E5E5EA; }
                tr:hover { background-color: #F2F2F7; }
                .badge { display: inline-block; padding: 4px 8px; border-radius: 6px; font-size: 12px; font-weight: 600; }
                .badge-blue { background: #E5F1FF; color: #007AFF; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header-container">
                    <h1>Migration Audit Report</h1>
                    <div class="subtitle">Generated on \(dateString)</div>
                    <div class="user-badge">User: \(userName)</div>
                </div>
                
                <div class="card">
                    <div class="card-header"><span class="card-title">🖥 System Specifications</span></div>
                    <div class="spec-grid">\(generateSpecGrid(items: specs))</div>
                </div>
                
                <div class="card">
                    <div class="card-header"><div class="card-title">🔍 Search & Filter</div></div>
                    <input type="text" id="searchInput" onkeyup="filterTable()" placeholder="Type to search...">
                </div>

                <div class="card">
                    <div class="card-header"><span class="card-title">📂 Applications Folder (Top Level)</span> <span class="badge badge-blue">\(mainApps.count)</span></div>
                    <table id="tableApps"><thead><tr><th>App Name</th><th>Path</th></tr></thead><tbody>\(generateRows(items: mainApps))</tbody></table>
                </div>
        """
        
        // Loop through Developers for Detected Apps
        for key in sortedKeys {
            if let groupItems = groupedApps[key] {
                html += """
                <div class="card">
                    <div class="card-header"><span class="card-title">📱 \(key) Applications</span> <span class="badge badge-blue">\(groupItems.count)</span></div>
                    <table><thead><tr><th>Name</th><th>Version / Details</th></tr></thead><tbody>\(generateRows(items: groupItems))</tbody></table>
                </div>
                """
            }
        }
        
        html += """
                <div class="card">
                    <div class="card-header"><span class="card-title">☁️ Network & Storage</span> <span class="badge badge-blue">\(network.count)</span></div>
                    <table><thead><tr><th>Drive Name</th><th>Type</th></tr></thead><tbody>\(generateRows(items: network))</tbody></table>
                </div>

                <div class="card">
                    <div class="card-header"><span class="card-title">🖨 Printers & Drivers</span> <span class="badge badge-blue">\(printers.count)</span></div>
                    <table><thead><tr><th>Name</th><th>Status</th></tr></thead><tbody>\(generateRows(items: printers))</tbody></table>
                </div>

                <div class="card">
                    <div class="card-header"><span class="card-title">🔌 Connected Devices</span> <span class="badge badge-blue">\(external.count)</span></div>
                    <table><thead><tr><th>Name</th><th>Type</th></tr></thead><tbody>\(generateRows(items: external))</tbody></table>
                </div>
        
                <div class="card">
                    <div class="card-header"><span class="card-title">⚙️ System Internals & Helpers</span> <span class="badge badge-blue">\(internals.count)</span></div>
                    <table><thead><tr><th>Component</th><th>Path</th></tr></thead><tbody>\(generateRows(items: internals))</tbody></table>
                </div>
                
                <p style="text-align:center; color:#86868B; font-size:12px;">Generated by Migration Assistant</p>
            </div>
            <script>
                function filterTable() {
                    var input = document.getElementById("searchInput");
                    var filter = input.value.toUpperCase();
                    var tables = document.querySelectorAll("table");
                    tables.forEach(table => {
                        var tr = table.getElementsByTagName("tr");
                        for (i = 1; i < tr.length; i++) {
                            var tdArray = tr[i].getElementsByTagName("td");
                            var found = false;
                            for (j = 0; j < tdArray.length; j++) {
                                if (tdArray[j]) {
                                    if (tdArray[j].innerHTML.toUpperCase().indexOf(filter) > -1) { found = true; }
                                }
                            }
                            tr[i].style.display = found ? "" : "none";
                        }
                    });
                }
            </script>
        </body>
        </html>
        """
        return html
    }
    
    private static func generateRows(items: [AuditItem]) -> String {
        var rows = ""
        for item in items {
            rows += "<tr><td><b>\(item.name)</b></td><td>\(item.details)</td></tr>"
        }
        return rows
    }
    
    private static func generateSpecGrid(items: [AuditItem]) -> String {
        var html = ""
        for item in items {
            html += """
            <div class="spec-item">
                <div class="spec-label">\(item.name)</div>
                <div class="spec-value">\(item.details)</div>
            </div>
            """
        }
        return html
    }
}
