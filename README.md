# KIB YouTube Downloader & Converter

A robust Bash script for downloading YouTube videos and converting them to high-quality audio formats (MP3, FLAC, M4A, WAV, OPUS) with automatic metadata embedding and thumbnail extraction.

## Features

- 🎵 Download YouTube videos as audio files
- 🎚️ Customizable audio quality (128-512 kbps)
- 📋 Automatic metadata embedding (title, artist, album art)
- 🖼️ Thumbnail extraction and embedding
- 🎥 Optional video file preservation
- 📝 Detailed metadata markdown files
- 🗜️ Optional ZIP compression of output
- 📊 Comprehensive logging with timestamps
- ✨ Clean, organized output folders

## Prerequisites

- macOS or Linux
- Bash 4.0+
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [ffmpeg](https://ffmpeg.org/)

## Installation

### 1. Install Dependencies

**macOS (Homebrew):**
```bash
brew install yt-dlp ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install yt-dlp ffmpeg
```

**Linux (Fedora):**
```bash
sudo dnf install yt-dlp ffmpeg
```

### 2. Clone Repository

```bash
git clone https://github.com/yourusername/kib_yt_dl_converter.git
cd kib_yt_dl_converter
```

### 3. Make Script Executable

```bash
chmod +x yt_down.sh
```

## Usage

### Basic Usage

```bash
./yt_down.sh https://www.youtube.com/watch?v=VIDEO_ID
```

### Advanced Options

```bash
./yt_down.sh [OPTIONS] YOUTUBE_URL
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-o, --output DIR` | Output directory | Current directory |
| `-q, --quality NUM` | Audio quality in kbps (1-512) | 192 |
| `-f, --format FORMAT` | Audio format: mp3, m4a, flac, wav, opus | mp3 |
| `--no-metadata` | Skip embedding metadata | Enabled |
| `--keep-video` | Keep original video file | Disabled |
| `--compress` | Compress output to ZIP | Disabled |
| `-h, --help` | Show help message | - |

### Examples

**Download with default settings (192kbps MP3):**
```bash
./yt_down.sh https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

**High-quality FLAC to custom directory:**
```bash
./yt_down.sh -o ~/Music -q 320 -f flac https://youtu.be/dQw4w9WgXcQ
```

**Keep video file and compress output:**
```bash
./yt_down.sh --keep-video --compress https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

**256kbps MP3 without metadata:**
```bash
./yt_down.sh -q 256 --no-metadata https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

## Output Structure

Each download creates a structured folder:

```
audio__video_title_timestamp/
├── video_title_timestamp.mp3       # Audio file
├── video_title_thumbnail.png       # Thumbnail image
├── metadata.md                     # Detailed metadata
├── video_title_timestamp.mp4       # Video (if --keep-video used)
└── yt_down_timestamp.log           # Processing log
```

### Metadata File Contents

The `metadata.md` includes:
- Video title, duration, uploader
- View count and upload date
- Audio quality and format settings
- File sizes and processing information
- Complete file listing

## Quality Guidelines

| Quality | Use Case | File Size |
|---------|----------|-----------|
| 128kbps | Good quality, small files | ~1MB/min |
| 192kbps | Great quality (recommended) | ~1.5MB/min |
| 256kbps | Very high quality | ~2MB/min |
| 320kbps | Maximum quality | ~2.5MB/min |

## Supported URLs

- Standard: `https://www.youtube.com/watch?v=VIDEO_ID`
- Short: `https://youtu.be/VIDEO_ID`
- Embedded: `https://www.youtube.com/embed/VIDEO_ID`
- Music: `https://music.youtube.com/watch?v=VIDEO_ID`
- Playlists: `https://www.youtube.com/playlist?list=PLAYLIST_ID`

## Logging

Logs are automatically generated with timestamps in the script directory:
```
yt_down_2025-10-4-T14-30-45.log
```

Each log contains:
- Download progress and status
- Metadata extraction details
- File operations and errors
- Completion statistics

## Troubleshooting

**"Missing required tools" error:**
```bash
brew install yt-dlp ffmpeg
```

**Permission denied:**
```bash
chmod +x yt_down.sh
```

**Output directory not writable:**
```bash
mkdir -p ~/Downloads && ./yt_down.sh -o ~/Downloads URL
```

**yt-dlp outdated:**
```bash
brew upgrade yt-dlp
# or
pip install -U yt-dlp
```

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is open source and available under the MIT License.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - YouTube download engine
- [ffmpeg](https://ffmpeg.org/) - Audio/video processing

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Note:** This tool is for personal use only. Respect copyright laws and YouTube's Terms of Service.
