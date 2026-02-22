---
name: music-add
description: Organize music and add to Navidrome. Verifies ID3 tags against online sources, renames to convention, moves to NAS.
---

# Music Add Workflow

Invoke with: `/music-add <source>`

Source can be:
- An archive file (`.rar`, `.zip`, `.7z`, `.tar.gz`)
- A folder containing music files

---

## Step 1: Extract (if archive)

If source is an archive:
```bash
mkdir -p /tmp/music-organize
unrar x -p"<password>" <source> /tmp/music-organize/  # for .rar
unzip <source> -d /tmp/music-organize/                 # for .zip
7z x <source> -o/tmp/music-organize/                   # for .7z
tar -xzf <source> -C /tmp/music-organize/              # for .tar.gz
```

If source is a folder, use it directly.

Report what was found:
- Number of audio files
- Formats present (mp3, flac, etc.)
- Folder structure

---

## Step 2: Verify ID3 Tags

### 2a. Read existing tags
```bash
for f in <folder>/*.{mp3,flac}; do
  echo "=== $(basename "$f") ==="
  ffprobe -v quiet -show_format "$f" | grep -E "TAG:"
done
```

### 2b. Check required tags
Required: `artist`, `album`, `date`, `title`, `track`

Report any missing tags.

### 2c. Verify against online source
Search MusicBrainz or Wikipedia for the album:
```
https://musicbrainz.org/ws/2/release/?query=album:<album>%20AND%20artist:<artist>&fmt=json
```

Compare:
- Track titles (spelling, punctuation)
- Track order
- Year
- Genre

### 2d. Report discrepancies
Show user a comparison table. **Ask before making changes.**

### 2e. Check Audio Quality
Scan bitrate of all files to verify quality:
```bash
for f in <folder>/*.mp3; do
  BITRATE=$(ffprobe -v quiet -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$f")
  KBPS=$(awk "BEGIN {printf \"%.0f\", $BITRATE/1000}")
  echo "$(basename "$f"): ${KBPS} kbps"
done
```

**Quality levels:**
| Bitrate | Quality |
|---------|---------|
| 320 kbps | ✅ Highest MP3 (target) |
| 256 kbps | ⚠️ High |
| 192 kbps | ⚠️ Decent |
| <192 kbps | ❌ Low quality |

Report if any files are below 320 kbps.

### 2f. Remove comment tags
```bash
ffmpeg -i "$f" -map_metadata -1 -map 0:a -c:a copy \
  -metadata title="<title>" -metadata artist="<artist>" \
  -metadata album="<album>" -metadata track="<track>" \
  -metadata date="<date>" -metadata genre="<genre>" \
  "${f%.mp3}-clean.mp3" && mv "${f%.mp3}-clean.mp3" "$f"
```

---

## Step 2.5: Cover Art Check

### Check for existing cover
Look for common cover art filenames:
```bash
ls <folder>/*.{jpg,jpeg,png,bmp} 2>/dev/null | grep -iE "(cover|folder|front|album)"
```

Acceptable names: `cover.jpg`, `folder.jpg`, `front.jpg`, `albumart.jpg`

### If no cover found, download from Cover Art Archive

1. **Get MusicBrainz Release ID:**
```bash
curl -s "https://musicbrainz.org/ws/2/release/?query=album:<album>%20AND%20artist:<artist>&fmt=json" | jq -r '.releases[0].id'
```

2. **Download cover from Cover Art Archive:**
```bash
RELEASE_ID="<from-above>"
curl -L -o cover.jpg "https://coverartarchive.org/release/$RELEASE_ID/front-500.jpg"
```

3. **Fallback to Discogs if not found:**
Search Discogs API:
```bash
curl -s "https://api.discogs.com/database/search?release_title=<album>&artist=<artist>&token=<DISCOGS_TOKEN>" | jq -r '.results[0].cover_image'
curl -L -o cover.jpg "<cover_url>"
```

### Report
- If cover found: "Cover art present: cover.jpg"
- If downloaded: "Cover art downloaded from Cover Art Archive"
- If not found: "No cover art found, please add manually"

---

## Step 3: Rename to Convention

### Target structure:
```
<Artist>/
└── <Year> - <Album>/
    ├── 01 - <Title>.ext
    ├── 02 - <Title>.ext
    └── cover.jpg
```

### Naming rules:
- **Artist folder:** Keep "The" prefix (The Beatles, not Beatles, The)
- **Album folder:** `<Year> - <Album Name>`
- **Track files:** `<##> - <Title>.<ext>` (zero-padded: 01, 02, ... 99)
- **Special characters:** Replace `/` with `-`, `:` with `_`
- **Edition info:** Append in brackets if present: `2005 - City of Evil [Remastered]`

### Rename commands:
```bash
WORKDIR="/tmp/music-organize"
ARTIST="<from-tag>"
YEAR="<from-tag>"
ALBUM="<from-tag>"

# Create target structure
mkdir -p "$WORKDIR/$ARTIST/$YEAR - $ALBUM"

# Rename and move tracks
for f in "$WORKDIR"/*/*.{mp3,flac}; do
  TRACK=$(ffprobe -v quiet -show_format "$f" | grep TAG:track= | cut -d= -f2)
  TITLE=$(ffprobe -v quiet -show_format "$f" | grep TAG:title= | cut -d= -f2)
  EXT="${f##*.}"
  mv "$f" "$WORKDIR/$ARTIST/$YEAR - $ALBUM/$(printf '%02d' $TRACK) - $TITLE.$EXT"
done

# Move cover art if present
mv "$WORKDIR"/*/cover.jpg "$WORKDIR/$ARTIST/$YEAR - $ALBUM/" 2>/dev/null
```

---

## Step 4: Move to NAS

### Destination:
`nas:/mnt/spinningpool/music/<Artist>/<Year> - <Album>/`

### Transfer:
```bash
rsync -av --dry-run "$WORKDIR/<Artist>/" nas:/mnt/spinningpool/music/<Artist>/
```

**Always dry-run first!** Show user what will be transferred.

After confirmation:
```bash
rsync -av "$WORKDIR/<Artist>/" nas:/mnt/spinningpool/music/<Artist>/
```

### Verify:
```bash
ssh nas "ls -la /mnt/spinningpool/music/<Artist>/<Year> - <Album>/"
```

### Fix Permissions:
Files copied via SSH will be owned by `admin:admin`. Fix to `lysergic:apps` (uid=3000, gid=568) for Navidrome:
```bash
ssh nas "midclt call filesystem.chown '{\"path\": \"/mnt/spinningpool/music/<Artist>\", \"uid\": 3000, \"gid\": 568, \"options\": {\"recursive\": true}}'"
```

### Cleanup:
Delete temp files after successful transfer:
```bash
rm -rf /tmp/music-organize /tmp/navidrome-check
```

---

## Step 5: Report

Summarize:
- Album added: `<Artist> - <Album> (<Year>)`
- Tracks: X files
- Location: `/mnt/spinningpool/music/<Artist>/<Year> - <Album>/`
- Any issues requiring manual follow-up

Optional: Trigger Navidrome scan via web UI or API.

---

## Example Usage

```
User: /music-add /home/lysergic/Downloads/AVESE-04-965987.rar

AI: I'll organize this album. The archive password is required.
User: www.discografiascompletas.net

AI: [Extracts] Found 11 MP3 files for "Avenged Sevenfold - City of Evil (2005)"
    [Verifies tags against MusicBrainz] Tags look correct!
    [Removes comment tags] Done.
    [Renames to convention] Done.
    [Shows dry-run rsync] Ready to move. Proceed?
User: yes

AI: [Transfers] Done! Album added to Navidrome library.
```
