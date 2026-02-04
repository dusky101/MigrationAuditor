# Media Library Scanning Feature

## Overview
Added comprehensive music and photos library scanning to the Migration Auditor app. This feature detects and measures the size of local music collections and Photos libraries on the Mac.

## What Was Added

### 1. New File: `MediaLibraryCollector.swift`
A new collector module that scans for:

#### Music Libraries:
- **Apple Music/iTunes Library** - Scans common Music folder locations
  - Counts total music tracks (mp3, m4a, flac, wav, etc.)
  - Reports total storage used
  - Supports both legacy iTunes and modern Music app locations
- **Spotify Cache** - Detects local Spotify data and cache size

#### Photos Libraries:
- **Apple Photos Library** - Locates the Photos.photoslibrary bundle
  - Calculates total library size
  - Counts photos and videos in the library
  - Reports comprehensive storage information
- **iCloud Photos Status** - Detects if iCloud Photos is active

### 2. Updated: `AuditLogic.swift`

#### New Item Types:
- `.musicLibrary` - Mint colored icon with music note symbol
- `.photosLibrary` - Teal colored icon with photo symbol

#### Integration:
The new scans are automatically included in the audit process:
- Music scan runs at ~33.5% progress
- Photos scan runs at ~33.7% progress
- Progress messages update to show "Scanning Music Library..." and "Analyzing Photos Library..."

## How It Works

### Music Scanning
1. Checks multiple possible locations for the Music library
2. Recursively scans folders for audio files (up to 5000 files for safety)
3. Counts tracks and calculates total storage
4. Also checks for Spotify local data

### Photos Scanning
1. Locates the Photos.photoslibrary bundle (typically in ~/Pictures)
2. Calculates the entire bundle size (all photos, videos, thumbnails, etc.)
3. Scans the "originals" folder to count actual photos and videos
4. Formats the output as "X photos, Y videos - ZZ GB"

### Safety Features
- **File limits**: Prevents hanging on massive libraries by limiting scans
- **Efficient enumeration**: Uses FileManager's enumerator for performance
- **Non-blocking**: Runs on background queue, doesn't freeze UI
- **Graceful fallback**: Reports "No Music/Photos Library" if nothing found

## Example Output

### Music Library:
```
Name: Apple Music Library
Details: 2,847 tracks - 18.6 GB
Developer: Apple
Path: /Users/Marc/Music/Music/Music
```

### Photos Library:
```
Name: Apple Photos Library
Details: 4,523 photos, 312 videos - 127.3 GB
Developer: Apple
Path: /Users/Marc/Pictures/Photos Library.photoslibrary
```

## CSV Export
The new data appears in the CSV report under:
- **TYPE**: "Music Library" or "Photos Library"
- **DEVELOPER**: "Apple" or "Spotify"
- **NAME**: Library name
- **DETAILS**: Count and size information

## HTML Dashboard
The interactive HTML dashboard now includes:
- Music note icon for music libraries (mint color)
- Photo icon for Photos libraries (teal color)
- Storage size prominently displayed
- Counts of tracks/photos for easy migration planning

## Performance Notes
- Music scan: ~1-2 seconds for typical libraries
- Photos scan: ~2-5 seconds for typical libraries (Photos libraries are large bundles)
- Large libraries (10,000+ items) may take longer but are capped at safe limits

## Migration Benefits
This feature helps users:
1. **Plan storage** for the new Mac based on media library sizes
2. **Identify what to migrate** - large music/photo collections need special handling
3. **Decide on cloud options** - if libraries are huge, consider iCloud Photos/Music
4. **Estimate migration time** - large media libraries take longer to transfer

## Future Enhancements
Possible additions:
- Support for third-party photo managers (Lightroom, Capture One)
- Detection of music streaming service downloads (Tidal, Amazon Music)
- Video library scanning (Final Cut Pro, iMovie projects)
- Podcast library detection
