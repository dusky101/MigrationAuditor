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
        
        // NEW CATEGORIES
        let browsers = items.filter { $0.type == .browser }
        let emails = items.filter { $0.type == .emailAccount }
        let cloudStorage = items.filter { $0.type == .cloudStorage }
        let fonts = items.filter { $0.type == .font }
        let homebrew = items.filter { $0.type == .homebrew }
        
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
                :root {
                    --primary: #007AFF;
                    --bg: #F5F5F7;
                    --card: #FFFFFF;
                    --text: #1D1D1F;
                    --secondary: #86868B;
                    --border: #E5E5EA;
                    --hover: #F2F2F7;
                }
                
                * { margin: 0; padding: 0; box-sizing: border-box; }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: var(--text);
                    padding: 20px;
                    min-height: 100vh;
                }
                
                .container {
                    max-width: 1400px;
                    margin: 0 auto;
                    background: var(--bg);
                    border-radius: 20px;
                    padding: 40px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                }
                
                .header-container {
                    text-align: center;
                    margin-bottom: 40px;
                    padding-bottom: 30px;
                    border-bottom: 2px solid var(--border);
                }
                
                h1 {
                    font-weight: 700;
                    font-size: 2.5rem;
                    margin-bottom: 8px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    background-clip: text;
                }
                
                .subtitle {
                    color: var(--secondary);
                    font-size: 1.1rem;
                    margin-bottom: 15px;
                }
                
                .user-badge {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 8px 20px;
                    border-radius: 25px;
                    font-weight: 600;
                    font-size: 0.9rem;
                    display: inline-block;
                    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
                }
                
                /* Filter Controls */
                .filter-section {
                    background: var(--card);
                    border-radius: 15px;
                    padding: 25px;
                    margin-bottom: 30px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.05);
                }
                
                .search-box {
                    width: 100%;
                    padding: 15px 20px;
                    border: 2px solid var(--border);
                    border-radius: 12px;
                    font-size: 16px;
                    margin-bottom: 20px;
                    transition: all 0.3s ease;
                }
                
                .search-box:focus {
                    outline: none;
                    border-color: var(--primary);
                    box-shadow: 0 0 0 4px rgba(0, 122, 255, 0.1);
                }
                
                .filter-chips {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 10px;
                    margin-bottom: 15px;
                }
                
                .filter-chip {
                    padding: 8px 16px;
                    border-radius: 20px;
                    border: 2px solid var(--border);
                    background: var(--card);
                    cursor: pointer;
                    transition: all 0.2s ease;
                    font-size: 14px;
                    font-weight: 500;
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                }
                
                .filter-chip:hover {
                    border-color: var(--primary);
                    transform: translateY(-2px);
                    box-shadow: 0 4px 12px rgba(0, 122, 255, 0.2);
                }
                
                .filter-chip.active {
                    background: var(--primary);
                    color: white;
                    border-color: var(--primary);
                }
                
                .filter-chip .count {
                    background: rgba(0,0,0,0.1);
                    padding: 2px 8px;
                    border-radius: 10px;
                    font-size: 12px;
                    font-weight: 600;
                }
                
                .filter-chip.active .count {
                    background: rgba(255,255,255,0.3);
                }
                
                .filter-actions {
                    display: flex;
                    gap: 10px;
                    align-items: center;
                }
                
                .filter-actions button {
                    padding: 6px 14px;
                    border: 1px solid var(--border);
                    background: var(--hover);
                    border-radius: 8px;
                    cursor: pointer;
                    font-size: 13px;
                    transition: all 0.2s ease;
                }
                
                .filter-actions button:hover {
                    background: var(--primary);
                    color: white;
                    border-color: var(--primary);
                }
                
                .item-count {
                    margin-left: auto;
                    color: var(--secondary);
                    font-size: 14px;
                }
                
                /* Cards */
                .card {
                    background: var(--card);
                    border-radius: 15px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.05);
                    padding: 25px;
                    margin-bottom: 25px;
                    transition: all 0.3s ease;
                }
                
                .card:hover {
                    box-shadow: 0 8px 20px rgba(0,0,0,0.1);
                    transform: translateY(-2px);
                }
                
                .card-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 2px solid var(--border);
                    padding-bottom: 15px;
                    margin-bottom: 20px;
                }
                
                .card-title {
                    font-size: 1.3rem;
                    font-weight: 600;
                    color: var(--primary);
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }
                
                .badge {
                    display: inline-block;
                    padding: 6px 12px;
                    border-radius: 20px;
                    font-size: 13px;
                    font-weight: 600;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }
                
                /* Spec Grid */
                .spec-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
                    gap: 20px;
                }
                
                .spec-item {
                    background: linear-gradient(135deg, #667eea15 0%, #764ba215 100%);
                    padding: 20px;
                    border-radius: 12px;
                    border: 1px solid var(--border);
                    transition: all 0.2s ease;
                }
                
                .spec-item:hover {
                    transform: translateY(-4px);
                    box-shadow: 0 6px 20px rgba(102, 126, 234, 0.2);
                }
                
                .spec-label {
                    font-size: 12px;
                    color: var(--secondary);
                    text-transform: uppercase;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                    margin-bottom: 8px;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                
                .spec-value {
                    font-size: 18px;
                    font-weight: 600;
                    color: var(--text);
                }
                
                /* Tables */
                table {
                    width: 100%;
                    border-collapse: separate;
                    border-spacing: 0;
                    font-size: 14px;
                }
                
                th {
                    text-align: left;
                    padding: 12px 15px;
                    background: var(--hover);
                    color: var(--secondary);
                    font-weight: 600;
                    text-transform: uppercase;
                    font-size: 12px;
                    letter-spacing: 0.5px;
                }
                
                th:first-child {
                    border-radius: 8px 0 0 0;
                }
                
                th:last-child {
                    border-radius: 0 8px 0 0;
                }
                
                td {
                    padding: 14px 15px;
                    border-bottom: 1px solid var(--border);
                }
                
                tr:last-child td {
                    border-bottom: none;
                }
                
                tr:hover {
                    background: var(--hover);
                }
                
                /* Two Column Grid */
                .grid-2col {
                    display: grid;
                    grid-template-columns: repeat(2, 1fr);
                    gap: 25px;
                }
                
                @media (max-width: 1024px) {
                    .grid-2col {
                        grid-template-columns: 1fr;
                    }
                    
                    .spec-grid {
                        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                    }
                }
                
                .footer {
                    text-align: center;
                    color: var(--secondary);
                    font-size: 13px;
                    margin-top: 40px;
                    padding-top: 20px;
                    border-top: 1px solid var(--border);
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header-container">
                    <h1>📊 Migration Audit Report</h1>
                    <div class="subtitle">Generated on \(dateString)</div>
                    <div class="user-badge">👤 \(userName)</div>
                </div>
                
                <div class="filter-section">
                    <input type="text" id="searchInput" class="search-box" placeholder="🔍 Search everything..." onkeyup="filterContent()">
                    
                    <div class="filter-chips" id="filterChips"></div>
                    
                    <div class="filter-actions">
                        <button onclick="selectAllFilters()">Select All</button>
                        <button onclick="deselectAllFilters()">Deselect All</button>
                        <span class="item-count" id="itemCount"></span>
                    </div>
                </div>
                
                <div id="content">
                    <div class="card" data-category="specs">
                        <div class="card-header">
                            <span class="card-title">🖥 System Specifications</span>
                        </div>
                        <div class="spec-grid">
        """
        
        html += Self.generateSpecGrid(items: specs)
        
        html += """
                        </div>
                    </div>
                    
                    <div class="grid-2col">
                        <div class="card" data-category="browsers">
                            <div class="card-header">
                                <span class="card-title">🌐 Browsers</span>
                                <span class="badge">\(browsers.count)</span>
                            </div>
                            <table><thead><tr><th>Browser</th><th>Details</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: browsers)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="email">
                            <div class="card-header">
                                <span class="card-title">📧 Email</span>
                                <span class="badge">\(emails.count)</span>
                            </div>
                            <table><thead><tr><th>Client</th><th>Details</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: emails)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="cloud">
                            <div class="card-header">
                                <span class="card-title">☁️ Cloud Storage</span>
                                <span class="badge">\(cloudStorage.count)</span>
                            </div>
                            <table><thead><tr><th>Service</th><th>Status</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: cloudStorage)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="fonts">
                            <div class="card-header">
                                <span class="card-title">🔤 Fonts</span>
                                <span class="badge">\(fonts.count)</span>
                            </div>
                            <table><thead><tr><th>Collection</th><th>Details</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: fonts)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="network">
                            <div class="card-header">
                                <span class="card-title">🌐 Network</span>
                                <span class="badge">\(network.count)</span>
                            </div>
                            <table><thead><tr><th>Drive</th><th>Type</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: network)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="printers">
                            <div class="card-header">
                                <span class="card-title">🖨 Printers</span>
                                <span class="badge">\(printers.count)</span>
                            </div>
                            <table><thead><tr><th>Name</th><th>Status</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: printers)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="devices">
                            <div class="card-header">
                                <span class="card-title">🔌 Devices</span>
                                <span class="badge">\(external.count)</span>
                            </div>
                            <table><thead><tr><th>Name</th><th>Type</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: external)
        
        html += """
                            </tbody></table>
                        </div>
                        
                        <div class="card" data-category="homebrew">
                            <div class="card-header">
                                <span class="card-title">🍺 Homebrew</span>
                                <span class="badge">\(homebrew.count)</span>
                            </div>
                            <table><thead><tr><th>Package</th><th>Type</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: homebrew)
        
        html += """
                            </tbody></table>
                        </div>
                    </div>
                    
                    <div class="card" data-category="apps">
                        <div class="card-header">
                            <span class="card-title">📂 Applications Folder</span>
                            <span class="badge">\(mainApps.count)</span>
                        </div>
                        <table><thead><tr><th>App Name</th><th>Path</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: mainApps)
        
        html += """
                        </tbody></table>
                    </div>
        """
        
        for key in sortedKeys {
            if let groupItems = groupedApps[key] {
                html += """
                    <div class="card" data-category="apps">
                        <div class="card-header">
                            <span class="card-title">📱 \(key) Applications</span>
                            <span class="badge">\(groupItems.count)</span>
                        </div>
                        <table><thead><tr><th>Name</th><th>Version</th></tr></thead><tbody>
                """
                
                html += Self.generateRows(items: groupItems)
                
                html += """
                        </tbody></table>
                    </div>
                """
            }
        }
        
        html += """
                    <div class="card" data-category="internals">
                        <div class="card-header">
                            <span class="card-title">⚙️ System Internals</span>
                            <span class="badge">\(internals.count)</span>
                        </div>
                        <table><thead><tr><th>Component</th><th>Details</th></tr></thead><tbody>
        """
        
        html += Self.generateRows(items: internals)
        
        html += """
                        </tbody></table>
                    </div>
                </div>
                
                <div class="footer">
                    Generated by Migration Auditor • \(dateString)
                </div>
            </div>
        """
        
        html += """
            
            <script>
                const categories = [
                    { id: 'specs', name: 'System Specs', icon: '🖥', count: 1 },
                    { id: 'browsers', name: 'Browsers', icon: '🌐', count: \(browsers.count) },
                    { id: 'email', name: 'Email', icon: '📧', count: \(emails.count) },
                    { id: 'cloud', name: 'Cloud Storage', icon: '☁️', count: \(cloudStorage.count) },
                    { id: 'fonts', name: 'Fonts', icon: '🔤', count: \(fonts.count) },
                    { id: 'homebrew', name: 'Homebrew', icon: '🍺', count: \(homebrew.count) },
                    { id: 'apps', name: 'Applications', icon: '📱', count: \(mainApps.count + realApps.count) },
                    { id: 'network', name: 'Network', icon: '🌐', count: \(network.count) },
                    { id: 'printers', name: 'Printers', icon: '🖨', count: \(printers.count) },
                    { id: 'devices', name: 'Devices', icon: '🔌', count: \(external.count) },
                    { id: 'internals', name: 'Internals', icon: '⚙️', count: \(internals.count) }
                ];
                
                let activeFilters = new Set(categories.map(c => c.id));
                
                function initFilters() {
                    const container = document.getElementById('filterChips');
                    categories.forEach(cat => {
                        const chip = document.createElement('div');
                        chip.className = 'filter-chip active';
                        chip.dataset.category = cat.id;
                        chip.innerHTML = '<span>' + cat.icon + ' ' + cat.name + '</span><span class="count">' + cat.count + '</span>';
                        chip.onclick = () => toggleFilter(cat.id);
                        container.appendChild(chip);
                    });
                    updateItemCount();
                }
                
                function toggleFilter(category) {
                    const chip = document.querySelector('[data-category="' + category + '"]');
                    if (activeFilters.has(category)) {
                        activeFilters.delete(category);
                        chip.classList.remove('active');
                    } else {
                        activeFilters.add(category);
                        chip.classList.add('active');
                    }
                    filterContent();
                }
                
                function selectAllFilters() {
                    activeFilters = new Set(categories.map(c => c.id));
                    document.querySelectorAll('.filter-chip').forEach(chip => chip.classList.add('active'));
                    filterContent();
                }
                
                function deselectAllFilters() {
                    activeFilters.clear();
                    document.querySelectorAll('.filter-chip').forEach(chip => chip.classList.remove('active'));
                    filterContent();
                }
                
                function filterContent() {
                    const searchTerm = document.getElementById('searchInput').value.toUpperCase();
                    let visibleCount = 0;
                    
                    document.querySelectorAll('.card[data-category]').forEach(card => {
                        const category = card.dataset.category;
                        const categoryMatch = activeFilters.has(category);
                        
                        let textMatch = true;
                        if (searchTerm) {
                            const text = card.textContent.toUpperCase();
                            textMatch = text.includes(searchTerm);
                        }
                        
                        if (categoryMatch && textMatch) {
                            card.style.display = '';
                            visibleCount++;
                        } else {
                            card.style.display = 'none';
                        }
                    });
                    
                    updateItemCount(visibleCount);
                }
                
                function updateItemCount(visible = null) {
                    const total = categories.reduce((sum, cat) => sum + cat.count, 0);
                    const shown = visible !== null ? visible : document.querySelectorAll('.card[data-category]').length;
                    document.getElementById('itemCount').textContent = 'Showing ' + shown + ' of ' + shown + ' sections';
                }
                
                initFilters();
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
            let name = item.name.lowercased()
            var icon = "🖥"
            
            if name.contains("drive") || name.contains("storage") { icon = "💾" }
            else if name.contains("memory") || name.contains("ram") { icon = "🧠" }
            else if name.contains("processor") || name.contains("chip") { icon = "⚡️" }
            else if name.contains("serial") { icon = "🏷" }
            else if name.contains("model") { icon = "💻" }
            else if name.contains("version") { icon = "🍎" }
            else if name.contains("tahoe") { icon = "✨" }
            else if name.contains("icloud") { icon = "☁️" }
            
            html += """
            <div class="spec-item">
                <div class="spec-label"><span>\(icon)</span> \(item.name)</div>
                <div class="spec-value">\(item.details)</div>
            </div>
            """
        }
        return html
    }
}
