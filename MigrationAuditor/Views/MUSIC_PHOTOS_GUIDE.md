# Music & Photos Library Feature - Quick Reference

## What Gets Scanned

### 🎵 Music Library
**Locations Checked:**
- `~/Music/Music/Music` (Apple Music)
- `~/Music/iTunes/iTunes Music` (Legacy iTunes)
- `~/Library/Application Support/Spotify/Users` (Spotify Cache)

**Information Captured:**
- Total number of music tracks
- Total storage size
- File types: mp3, m4a, aac, flac, wav, aiff, alac, ogg

**Example Output:**
```
Apple Music Library
2,847 tracks - 18.6 GB
```

### 📸 Photos Library
**Locations Checked:**
- `~/Pictures/Photos Library.photoslibrary`
- `~/Pictures/Photos.photoslibrary`

**Information Captured:**
- Total number of photos
- Total number of videos  
- Total library size (including all thumbnails, edits, metadata)

**Example Output:**
```
Apple Photos Library
4,523 photos, 312 videos - 127.3 GB
```

## Where It Appears

### 1. During Scan
```
Progress Bar: 33.5%
Message: "Scanning Music Library..."

Progress Bar: 33.7%
Message: "Analyzing Photos Library..."
```

### 2. In DataReviewView (App Interface)
- **Location**: Quick Info Grid (2-column layout)
- **Music Library**: Mint-colored chip with 🎵 icon
- **Photos Library**: Teal-colored chip with 📸 icon
- **Expandable**: Click to see details
- **Filterable**: Command+Click to solo, normal click to toggle

### 3. In CSV Export
```csv
TYPE,DEVELOPER,NAME,DETAILS
Music Library,Apple,Apple Music Library,"2,847 tracks - 18.6 GB"
Music Library,Spotify,Spotify Cache,"Local data - 2.3 GB"
Photos Library,Apple,Apple Photos Library,"4,523 photos, 312 videos - 127.3 GB"
```

### 4. In HTML Dashboard
- **Music Card**: 🎵 Music Library section
  - Shows all music libraries found
  - Click filter chip to show/hide
- **Photos Card**: 📸 Photos Library section
  - Shows all photo libraries found
  - Click filter chip to show/hide

### 5. In PDF Report
- **Section Header**: "Music Library (X items)"
  - Mint-colored music note icon
  - Individual library details listed
- **Section Header**: "Photos Library (X items)"
  - Teal-colored photo icon
  - Individual library details listed

## Icon Colors

| Category | Color | Icon | SF Symbol |
|----------|-------|------|-----------|
| Music Library | Mint | 🎵 | music.note.list |
| Photos Library | Teal | 📸 | photo.on.rectangle |

## Performance Notes

### Safe Limits Built-In
- **Music**: Scans up to 5,000 files then estimates
- **Photos**: Scans up to 10,000 items then estimates
- **Non-blocking**: Runs on background thread
- **Fast**: Typically 1-5 seconds per library

### Large Library Handling
If you have massive libraries (50,000+ photos):
- Count may be estimated (up to 10,000 items scanned)
- Size is still accurate (counts all bytes)
- Won't freeze or hang the app

## Migration Planning Use Cases

### Scenario 1: Small Libraries
```
Music: 500 tracks - 3 GB
Photos: 1,200 photos - 15 GB
→ Easy to migrate via Migration Assistant or manual copy
```

### Scenario 2: Medium Libraries
```
Music: 5,000 tracks - 35 GB
Photos: 8,000 photos - 85 GB
→ Consider iCloud Music Library / iCloud Photos
→ Or migrate via external drive for speed
```

### Scenario 3: Large Libraries
```
Music: 15,000 tracks - 120 GB
Photos: 25,000 photos - 350 GB
→ Definitely use external drive for migration
→ Consider cloud storage to save space on new Mac
→ Budget 2-3 hours for transfer time
```

## Common Questions

### Q: What if I don't have a Music library?
**A:** The report will show "No Music Library - No local music collection detected"

### Q: What if I use iCloud Photos?
**A:** The scan still counts your local library, which may be optimized (smaller)

### Q: Does it scan Apple Music streaming songs?
**A:** No, only downloaded/purchased music files stored locally

### Q: What about video files outside Photos?
**A:** Not included (would need separate video library collector)

### Q: Does it show individual song/photo names?
**A:** No, just totals and sizes. Individual files would make reports too large.

## File Extensions Counted

### Music
- mp3, m4a, aac (Most common)
- flac, wav, aiff, alac (High quality)
- ogg (Less common)

### Photos
- jpg, jpeg, png, heic, heif (Photos)
- gif, tiff, raw, cr2, nef, dng (Professional)

### Videos (in Photos Library)
- mov, mp4, m4v (Common)
- avi, mkv (Less common)

## Troubleshooting

### Music Library Shows 0 Tracks
- Check if Music app uses a custom library location
- Verify files are actually in ~/Music folder
- Ensure Music app has indexed your library

### Photos Library Shows Wrong Size
- Photos.photoslibrary is a bundle containing:
  - Original photos/videos
  - Edited versions
  - Thumbnails and previews
  - Face recognition data
  - All this is included in the reported size

### Spotify Cache Not Detected
- Spotify stores cache in Library folder only if app is installed
- Not all Spotify users have local files enabled
