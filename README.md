# Mac Migration Auditor 🚀

A native macOS utility built with **SwiftUI** designed to assist IT teams during hardware refreshes and migrations.

It scans a user's current Mac to generate a "Hardware & Software Baseline," ensuring that their new machine is set up with the correct specs, applications, and drivers.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)
![Licence](https://img.shields.io/badge/License-MIT-blue.svg)

## 🎯 Purpose

When migrating users to new machines, IT often asks: *"What apps do you actually use?"* or *"Do you need 32GB of RAM?"*
Users often don't know the answer.

This tool runs a safe, local-only audit to capture:
* **System Specs:** Serial Number, Chip Type (M1/M2/Intel), RAM, and Drive Capacity.
* **Applications:** Lists user-installed apps (filtering out system "fluff" and frameworks).
* **Peripherals:** Identifies connected webcams, drawing tablets, and specialised USB devices.
* **Printers:** Captures installed printer drivers.
* **Network:** Maps connected NAS and Server drives.

## 🔒 Privacy First

* **No Personal Data:** Does not scan Documents, Photos, Emails, or Browsing History.
* **Local Only:** No data is uploaded to the cloud. The app generates a ZIP file on the Desktop for the user to email manually.
* **Transparency:** Users can review every single data point captured inside the app before sharing it.

## 🛠 Tech Stack

* **Language:** Swift 5
* **UI Framework:** SwiftUI
* **Logic:** Native `system_profiler` calls and `FileManager` APIs.
* **Output:** Generates structured CSV (for data ingestion) and HTML (for human review) reports.

## 🚀 How to Run

1. Clone the repo.
2. Open `MigrationAuditor.xcodeproj` in Xcode.
3. Set the Signing Team to your Apple Developer Account (required for Hardened Runtime).
4. Build and Run (`Cmd + R`).

## 📦 Distribution

To distribute this tool to users without Xcode:
1. Archive the project (`Product -> Archive`).
2. **Notarise** the app using your Apple Developer ID (this prevents Gatekeeper warnings).
3. Export the Notarised app.
4. Zip and share via email or MDM.

## 📄 Licence

This project is open-source and available under the MIT License.
