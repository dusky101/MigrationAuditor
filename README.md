# Mac Migration Auditor 🚀

A native macOS utility built with **SwiftUI** designed to assist IT teams during hardware refreshes and migrations.

It scans a user's current Mac to generate a "Hardware & Software Baseline," ensuring that their new machine is set up with the correct specs, applications, fonts, and drivers.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg)
![Licence](https://img.shields.io/badge/License-MIT-blue.svg)

## 📥 Download

**Don't want to build from source?**
You can download the latest **Apple Notarised** version of the app directly from our Releases page. This version is signed and ready to run on any Mac without Gatekeeper warnings.

[**👉 Download Latest Release**](https://github.com/dusky101/MigrationAuditor/releases)

---

## 🎯 Purpose

When migrating users to new machines, IT often asks: *"What apps do you actually use?"*, *"Do you need custom fonts moved?"*, or *"Do you need 32GB of RAM?"*
Users often don't know the answer.

This tool runs a safe, local-only audit to capture:

### 🖥️ Hardware & System
* **System Specs:** Serial Number, Chip Type (M-Series/Intel), RAM, and Drive Capacity.
* **Peripherals:** Identifies connected webcams, drawing tablets, and specialised USB devices.
* **Network:** Maps connected NAS and Server drives.

### 📦 Software & Assets
* **Applications:** Lists user-installed apps (intelligently filtering out system "fluff" and frameworks).
* **Developer Tools:** Automatically detects and lists installed **Homebrew** packages.
* **Typography:** Scans user-installed fonts (grouped by Font Family). Includes an optional toggle to **backup physical font files** into the export package.
* **Printers:** Captures installed printer drivers (`.ppd` files) for easy redeployment.
* **Configuration:** Identifies default Web Browsers, Email Accounts, and Cloud Storage providers.

## 📊 Comprehensive Reporting

The app generates a single **ZIP archive** on the Desktop containing:
1.  **PDF Report:** A professionally formatted, multi-page document with dynamic icons and category summaries.
2.  **Interactive HTML Dashboard:** A searchable, browser-based view of the system data.
3.  **CSV Export:** Raw data for spreadsheet analysis.
4.  **Asset Folders:** Collected Fonts (optional) and Printer Drivers.

## 🔒 Privacy First

* **No Personal Data:** Does not scan Documents, Photos, Emails, Passwords, or Browsing History.
* **Local Only:** No data is uploaded to the cloud. The app generates a ZIP file on the Desktop for the user to email manually.
* **Transparency:** Users can review every single data point captured inside the app via the "Review Data" screen before sharing it.

## 🛠 Tech Stack

* **Language:** Swift 5
* **UI Framework:** SwiftUI (featuring a modern "Liquid Glass" translucent interface).
* **Logic:** Native `system_profiler` calls, `CoreText` for font metadata, and `FileManager` APIs.
* **Design:** Custom Flow Layouts for filtering and responsive window sizing.

## 🚀 How to Run (For Developers)

1. Clone the repo.
2. Open `MigrationAuditor.xcodeproj` in Xcode.
3. Set the Signing Team to your Apple Developer Account (required for Hardened Runtime).
4. Build and Run (`Cmd + R`).

## 📄 Licence

This project is open-source and available under the MIT License.
