#!/bin/bash

# YouTube to MP3 Converter
# Description: Downloads YouTube videos and converts to high-quality MP3 using yt-dlp and ffmpeg
# Dependencies: yt-dlp, ffmpeg (install via: brew install yt-dlp ffmpeg)

set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_QUALITY=192

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Get current timestamp functions
get_timestamp_type1() {
    date +'%a-%Y-%b-%eth-at-%H-%M-%Shrs'
}

get_timestamp_type2() {
    date +'%Y-%-m-%-d-T%H-%M-%S'
}

get_timestamp_log() {
    date +'%H:%M:%S'
}

# Initialize log file
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME%.*}_$(get_timestamp_type2).log"
create_log_file() {
    touch "$LOG_FILE"
    echo "🎵 YouTube Downloader Log - Started at $(date)" >> "$LOG_FILE"
    echo "📁 Script: $SCRIPT_NAME" >> "$LOG_FILE"
    echo "📂 Log file: $LOG_FILE" >> "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
}

# Enhanced logging functions with timestamps and newlines
log_to_file() {
    local timestamp=$(get_timestamp_log)
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

log_info() { 
    local timestamp=$(get_timestamp_log)
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} [$timestamp] $message"
    log_to_file "INFO: $message"
}

log_success() { 
    local timestamp=$(get_timestamp_log)
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} [$timestamp] ✅ $message"
    log_to_file "SUCCESS: $message"
}

log_warning() { 
    local timestamp=$(get_timestamp_log)
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} [$timestamp] ⚠️  $message"
    log_to_file "WARNING: $message"
}

log_error() { 
    local timestamp=$(get_timestamp_log)
    local message="$1"
    echo -e "${RED}[ERROR]${NC} [$timestamp] ❌ $message" >&2
    log_to_file "ERROR: $message"
}

# Display usage information
show_usage() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] YOUTUBE_URL

Download a YouTube video and convert it to MP3 format using yt-dlp.

OPTIONS:
    -o, --output DIR      Output directory (default: current directory)
    -q, --quality NUM     Audio quality in kbps (default: ${DEFAULT_QUALITY})
    -f, --format FORMAT   Audio format: mp3, m4a, flac, wav (default: mp3)
    --no-metadata         Skip embedding metadata
    --keep-video          Keep the original video file in the output folder
    --compress            Compress the output folder to a zip file
    -h, --help           Show this help message

EXAMPLES:
    ${SCRIPT_NAME} https://www.youtube.com/watch?v=VIDEO_ID
    ${SCRIPT_NAME} -o ~/Music -q 320 -f flac https://youtu.be/VIDEO_ID
    ${SCRIPT_NAME} --no-metadata -q 256 --keep-video --compress https://www.youtube.com/watch?v=VIDEO_ID

QUALITY NOTES:
    128kbps - Good quality, small file size
    192kbps - Great quality (recommended)
    320kbps - Excellent quality, larger files
EOF
}

# Validate YouTube URL
validate_youtube_url() {
    local url="$1"
    
    # Comprehensive YouTube URL patterns
    local patterns=(
        "https://www.youtube.com/watch?v="
        "https://youtube.com/watch?v="
        "https://youtu.be/"
        "https://www.youtube.com/embed/"
        "https://music.youtube.com/watch?v="
        "https://www.youtube.com/playlist?list="
    )
    
    for pattern in "${patterns[@]}"; do
        if [[ "$url" == *"$pattern"* ]]; then
            return 0
        fi
    done
    
    return 1
}

# Check dependencies with version information
check_dependencies() {
    local missing_tools=()
    
    for tool in yt-dlp ffmpeg; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        else
            local version_info=""
            if [[ "$tool" == "yt-dlp" ]]; then
                version_info=$("$tool" --version 2>/dev/null | head -n1)
            elif [[ "$tool" == "ffmpeg" ]]; then
                version_info=$("$tool" -version 2>/dev/null | head -n1 | cut -d' ' -f1-3)
            fi
            log_info "🔧 $tool version: $version_info"
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install using: brew install ${missing_tools[*]}"
        exit 1
    fi
}

# Get detailed video information
get_detailed_video_info() {
    local url="$1"
    
    log_to_file "📡 Fetching detailed video information for $url"
    
    # Get basic info
    local title
    title=$(yt-dlp --get-title --no-warnings --no-playlist "$url" 2>&1 | grep -v "WARNING" | head -n1)

    # Fallback if title fetch fails
    if [ -z "$title" ] || [[ "$title" == *"ERROR"* ]] || [[ "$title" == *"http"* ]]; then
        log_warning "Failed to fetch title directly, trying alternative method..."
        title=$(yt-dlp --get-filename -o "%(title)s" --no-warnings --no-playlist "$url" 2>&1 | grep -v "WARNING" | head -n1)
    fi
    
    local duration
    duration=$(yt-dlp --get-duration --no-warnings "$url" 2>/dev/null)
    
    local uploader
    uploader=$(yt-dlp --get-filename -o "%(uploader)s" --no-warnings "$url" 2>/dev/null)
    
    local view_count
    view_count=$(yt-dlp --get-filename -o "%(view_count)s" --no-warnings "$url" 2>/dev/null)
    
    local upload_date
    upload_date=$(yt-dlp --get-filename -o "%(upload_date)s" --no-warnings "$url" 2>/dev/null)
    
    local description
    description=$(yt-dlp --get-description --no-warnings "$url" 2>/dev/null | head -5)
    
    if [ -z "$title" ] || [[ "$title" == *"http"* ]]; then
        log_error "Failed to fetch video information. Using fallback filename..."
        title="youtube_video_$(date +%s)"
    fi

    # Clean up title from potential URL remnants
    title=$(echo "$title" | sed 's/https*:\/\///g' | sed 's/www\.//g' | sed 's/youtube\.com//g' | sed 's/watch?v=//g' | sed 's/&.*//g')
    
    # Display video metadata to user
    echo "" >&2
    log_info "🎬 VIDEO METADATA:" >&2
    echo "┌──────────────────────────────────────────────" >&2
    echo "│ 📝 Title: $title" >&2
    echo "│ ⏱️  Duration: ${duration:-Unknown}" >&2
    echo "│ 👤 Uploader: ${uploader:-Unknown}" >&2
    echo "│ 👀 Views: ${view_count:-Unknown}" >&2
    echo "│ 📅 Upload Date: ${upload_date:-Unknown}" >&2
    if [ -n "$description" ]; then
        echo "│ 📋 Description (first 5 lines):" >&2
        while IFS= read -r line; do
            echo "│   $line" >&2
        done <<< "$description"
    fi
    echo "└──────────────────────────────────────────────" >&2
    echo "" >&2
    
    # Log video metadata separately
    log_to_file "VIDEO METADATA - Title: $title"
    log_to_file "VIDEO METADATA - Duration: ${duration:-Unknown}"
    log_to_file "VIDEO METADATA - Uploader: ${uploader:-Unknown}"
    log_to_file "VIDEO METADATA - Views: ${view_count:-Unknown}"
    log_to_file "VIDEO METADATA - Upload Date: ${upload_date:-Unknown}"
    
    echo "$title|$duration|$uploader|$view_count|$upload_date"
}

str_clean() {
    local str="$1"
    local cleaned=$(echo "$str" | sed -e 's/[\\/:*?"<>|]/_/g' \
        -e 's/[[:space:]]/_/g' \
        -e 's/__*/_/g' \
        -e 's/^[[:space:]_]*//' \
        -e 's/[[:space:]_]*$//' \
        -e 's/^-*//' \
        | tr '[:upper:]' '[:lower:]')
    
    log_to_file "STR_CLEAN: cleaned: $cleaned, original: $str"

    echo "$cleaned"
}

# Sanitize filename with timestamp option
sanitize_filename() {
    local filename="$1"
    local add_timestamp="${2:-false}"
    
    # Remove or replace problematic characters
    filename=$(str_clean "$filename")
    
    if [ "$add_timestamp" = "true" ]; then
        local timestamp
        timestamp=$(get_timestamp_type1)
        filename="${filename}_${timestamp}"
        filename=$(str_clean "$filename")
    fi
    
    echo "$filename"
}

# Create output folder structure
create_output_folder() {
    local video_title="$1"
    local output_dir="$2"
    
    local folder_name=$(str_clean "audio__${video_title}")
    local full_path="${output_dir}/${folder_name}"
    
    mkdir -p "$full_path" || {
        log_error "Cannot create output folder: $full_path"
        exit 1
    }
    
    echo "$full_path"
}

# Download thumbnail
download_thumbnail() {
    local url="$1"
    local output_folder="$2"
    local video_title="$3"
    
    log_info "🖼️  Downloading thumbnail..."
    
    local thumbnail_cmd=(
        yt-dlp
        --write-thumbnail
        --skip-download
        --convert-thumbnails png
        --output "${output_folder}/thumbnail"
        --no-overwrites
    )
    
    if "${thumbnail_cmd[@]}" "$url" 2>/dev/null; then
        # Find the actual thumbnail file
        local thumbnail_file=$(find "$output_folder" -name "thumbnail*" -type f | head -1)
        if [ -n "$thumbnail_file" ]; then
            local final_name="${output_folder}/$(str_clean "${video_title}_thumbnail").png"
            mv "$thumbnail_file" "$final_name" 2>/dev/null || true
            if [ -f "$final_name" ]; then
                log_success "Thumbnail downloaded: $(basename "$final_name")"
                return 0
            fi
        fi
    fi
    
    log_warning "Thumbnail not available or download failed"
    return 1
}

# Download video file if requested
download_video_file() {
    local url="$1"
    local output_folder="$2"
    local video_title="$3"
    
    log_info "🎥 Downloading video file..."
    
    local safe_title=$(sanitize_filename "$video_title" "true")
    local video_cmd=(
        yt-dlp
        --format "best[height<=1080]"
        --output "${output_folder}/${safe_title}.%(ext)s"
        --no-overwrites
        --no-playlist
    )
    
    if "${video_cmd[@]}" "$url"; then
        local video_file=$(find "$output_folder" -name "*${safe_title}*" -type f ! -name "*.${audio_format}" ! -name "*.png" ! -name "*.md" | head -1)
        if [ -n "$video_file" ]; then
            local file_size=$(du -h "$video_file" | cut -f1)
            log_success "Video downloaded: $(basename "$video_file") (Size: $file_size)"
            return 0
        fi
    fi
    
    log_warning "Video download failed"
    return 1
}

# Format duration from HH:MM:SS or MM:SS to human readable
format_duration() {
    local duration="$1"
    if [ -z "$duration" ] || [ "$duration" = "Unknown" ]; then
        echo "Unknown"
        return
    fi
    
    # Check if duration contains hours
    if [[ "$duration" =~ ^[0-9]+:[0-9]{2}:[0-9]{2}$ ]]; then
        # HH:MM:SS format
        local hours=$(echo "$duration" | cut -d: -f1)
        local minutes=$(echo "$duration" | cut -d: -f2)
        local seconds=$(echo "$duration" | cut -d: -f3)
        echo "${hours}h ${minutes}m ${seconds}s"
    elif [[ "$duration" =~ ^[0-9]+:[0-9]{2}$ ]]; then
        # MM:SS format
        local minutes=$(echo "$duration" | cut -d: -f1)
        local seconds=$(echo "$duration" | cut -d: -f2)
        echo "${minutes}m ${seconds}s"
    else
        echo "$duration"
    fi
}

# Format number with thousands separators
format_number() {
    local number="$1"
    if [ -z "$number" ] || [ "$number" = "Unknown" ] || ! [[ "$number" =~ ^[0-9]+$ ]]; then
        echo "Unknown"
        return
    fi
    printf "%'d" "$number"
}

# Format date from YYYYMMDD to human readable with day (Linux/macOS compatible)
format_date() {
    local date_str="$1"
    if [ -z "$date_str" ] || [ "$date_str" = "Unknown" ] || ! [[ "$date_str" =~ ^[0-9]{8}$ ]]; then
        echo "Unknown"
        return
    fi
    
    # Extract components
    local year=${date_str:0:4}
    local month=${date_str:4:2}
    local day=${date_str:6:2}
    
    # Remove leading zeros
    month=$((10#$month))
    day=$((10#$day))
    
    # Try different date formatting approaches
    local formatted_date=""
    
    # macOS approach
    if formatted_date=$(date -j -f "%Y%m%d" "$date_str" "+%a, %d %b %Y" 2>/dev/null); then
        # Add ordinal suffix (macOS)
        case "$day" in
            1|21|31) suffix="st" ;;
            2|22) suffix="nd" ;;
            3|23) suffix="rd" ;;
            *) suffix="th" ;;
        esac
        # Replace the day number with ordinal version
        formatted_date=$(echo "$formatted_date" | sed "s/ $day / ${day}${suffix} /")
    # Linux approach
    elif formatted_date=$(date -d "$year-$month-$day" "+%a, %d %b %Y" 2>/dev/null); then
        # Add ordinal suffix (Linux)
        case "$day" in
            1|21|31) suffix="st" ;;
            2|22) suffix="nd" ;;
            3|23) suffix="rd" ;;
            *) suffix="th" ;;
        esac
        formatted_date=$(echo "$formatted_date" | sed "s/ $day / ${day}${suffix} /")
    else
        # Fallback
        local month_names=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
        local month_name=${month_names[$((month-1))]}
        case "$day" in
            1|21|31) suffix="st" ;;
            2|22) suffix="nd" ;;
            3|23) suffix="rd" ;;
            *) suffix="th" ;;
        esac
        formatted_date="${day}${suffix} ${month_name} ${year}"
    fi
    
    echo "$formatted_date"
}

# Create metadata markdown file
create_metadata_file() {
    local output_folder="$1"
    local video_title="$2"
    local duration="$3"
    local uploader="$4"
    local view_count="$5"
    local upload_date="$6"
    local youtube_url="$7"
    local audio_quality="$8"
    local audio_format="$9"
    local no_metadata="${10}"
    local audio_file="${11}"
    local video_file="${12}"
    
    local metadata_file="${output_folder}/metadata.md"
    local timestamp=$(date -Iseconds)
    
    # Format values for human readability
    local formatted_duration=$(format_duration "$duration")
    local formatted_views=$(format_number "$view_count")
    local formatted_date=$(format_date "$upload_date")

    # Get file sizes
    local audio_file_size="N/A"
    local video_file_size="N/A"
    
    if [ -n "$audio_file" ] && [ -f "$audio_file" ]; then
        audio_file_size=$(du -h "$audio_file" | cut -f1)
    fi
    
    if [ -n "$video_file" ] && [ -f "$video_file" ]; then
        video_file_size=$(du -h "$video_file" | cut -f1)
    fi
    
        cat > "$metadata_file" << EOF
# YouTube Audio Download Metadata

## Video Information
- **Title**: ${video_title}
- **Duration**: ${formatted_duration}
- **Uploader**: ${uploader:-Unknown}
- **Views**: ${formatted_views}
- **Upload Date**: ${formatted_date}
- **URL**: ${youtube_url}

## Audio Settings
- **Format**: ${audio_format}
- **Quality**: ${audio_quality}kbps
- **Metadata Embedded**: $([ "$no_metadata" = "false" ] && echo "Yes" || echo "No")
- **File Size**: ${audio_file_size}

## Video Information
$([ "$video_file_size" != "N/A" ] && echo "- **File Size**: ${video_file_size}" || echo "- **Status**: Not downloaded")

## Processing Information
- **Download Date**: ${timestamp}
- **Processing Script**: ${SCRIPT_NAME}

## Files in this folder
$(find "$output_folder" -maxdepth 1 -type f -exec basename {} \; | while read file; do echo "- \`$file\`"; done)
EOF

    log_success "Metadata file created: $(basename "$metadata_file")"
}

# Compress output folder
compress_output_folder() {
    local output_folder="$1"
    
    if command -v zip &> /dev/null; then
        local zip_name="${output_folder}.zip"
        log_info "🗜️  Compressing output folder..."
        
        if cd "$(dirname "$output_folder")" && zip -r "$zip_name" "$(basename "$output_folder")" > /dev/null 2>&1; then
            local zip_size=$(du -h "$zip_name" | cut -f1)
            log_success "Folder compressed: $(basename "$zip_name") (Size: $zip_size)"
            return 0
        else
            log_warning "Compression failed"
            return 1
        fi
    else
        log_warning "zip command not available, skipping compression"
        return 1
    fi
}

# Main download and conversion function
download_and_convert() {
    local url="$1"
    local output_dir="$2"
    local quality="$3"
    local format="$4"
    local no_metadata="$5"
    local keep_video="$6"
    local compress_folder="$7"
    
    local video_info
    video_info=$(get_detailed_video_info "$url") || exit 1
    
    IFS='|' read -r title duration uploader view_count upload_date <<< "$video_info"
    
    # Create output folder
    local output_folder
    output_folder=$(create_output_folder "$title" "$output_dir")
    log_info "📁 Created output folder: $(basename "$output_folder")"
    
    local safe_title
    safe_title=$(sanitize_filename "$title" "true")
    
    log_info "💾 Output: ${output_folder}/${safe_title}.${format}"
    
    # Build yt-dlp command
    local yt_dlp_cmd=(
        yt-dlp
        --extract-audio
        --audio-format "$format"
        --audio-quality "$quality"
        --output "${output_folder}/${safe_title}.%(ext)s"
        --no-overwrites
        --no-playlist
        --concurrent-fragments 5
        --throttled-rate 100K
    )
    
    # Add metadata options unless disabled
    if [ "$no_metadata" = "false" ]; then
        yt_dlp_cmd+=(--embed-metadata --embed-thumbnail)
        log_info "📋 Audio metadata will be embedded (title, artist, album, etc.)"
    else
        yt_dlp_cmd+=(--no-embed-metadata --no-embed-thumbnail)
        log_info "🚫 Audio metadata embedding disabled"
    fi
    
    # Differentiate between video and audio metadata in logs
    log_to_file "METADATA DIFFERENTIATION: Video metadata includes title, duration, uploader, etc. Audio metadata includes ID3 tags, album art, etc."
    
    # Add progress indicators
    yt_dlp_cmd+=(--newline --progress)
    
    log_info "⬇️  Starting download and conversion..."
    log_to_file "DOWNLOAD_START: $url -> $output_folder/${safe_title}.$format"
    
    # Execute download
    if "${yt_dlp_cmd[@]}" "$url"; then
        local output_file="${output_folder}/${safe_title}.${format}"
        if [ -f "$output_file" ]; then
            local file_size
            file_size=$(du -h "$output_file" | cut -f1)
            log_success "Download completed: $output_file (Size: $file_size) 🎉"
            log_to_file "DOWNLOAD_COMPLETE: $output_file - Size: $file_size"
            
            # Download thumbnail
            download_thumbnail "$url" "$output_folder" "$title"

            # Find the actual audio file
            local actual_audio_file=$(find "$output_folder" -name "*${safe_title}*.${format}" -type f | head -1)
            local actual_video_file=""
            
            # Download video if requested
            if [ "$keep_video" = "true" ]; then
                download_video_file "$url" "$output_folder" "$title"
                actual_video_file=$(find "$output_folder" -name "*${safe_title}*" -type f ! -name "*.${audio_format}" ! -name "*.png" ! -name "*.md" | head -1)
            fi
            
            # Create metadata file
            create_metadata_file "$output_folder" "$title" "$duration" "$uploader" \
                "$view_count" "$upload_date" "$url" "$quality" "$format" "$no_metadata" \
                "$actual_audio_file" "$actual_video_file"
            
            # Compress folder if requested
            if [ "$compress_folder" = "true" ]; then
                compress_output_folder "$output_folder"
            fi
            
            # Log final audio file details
            log_info "🔊 AUDIO FILE CREATED:"
            echo "┌──────────────────────────────────────────────"
            echo "│ 📁 File: $(basename "$output_file")"
            echo "│ 📊 Size: $file_size"
            echo "│ 🎵 Format: $format"
            echo "│ 🔊 Quality: ${quality}kbps"
            echo "│ 📍 Location: $output_folder"
            echo "└──────────────────────────────────────────────"
            return 0
        else
            # yt-dlp might use slightly different filename sanitization
            local actual_file
            actual_file=$(find "$output_folder" -name "*${safe_title}*.${format}" -type f | head -1)
            if [ -n "$actual_file" ]; then
                local file_size
                file_size=$(du -h "$actual_file" | cut -f1)
                log_success "Download completed: $actual_file (Size: $file_size) 🎉"
                log_to_file "DOWNLOAD_COMPLETE: $actual_file - Size: $file_size"
                return 0
            fi
        fi
    fi
    
    log_error "Download failed ❗"
    log_to_file "DOWNLOAD_FAILED: $url"
    return 1
}

# Main execution function
main() {
    local youtube_url=""
    local output_dir="."
    local audio_quality="$DEFAULT_QUALITY"
    local audio_format="mp3"
    local no_metadata="false"
    local keep_video="false"
    local compress_folder="false"
    
    # Create log file at the very beginning
    create_log_file
    
    log_info "🚀 Starting YouTube to MP3 Converter..."
    log_to_file "SCRIPT_START: Arguments: $*"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                output_dir="$2"
                log_info "📂 Output directory set to: $output_dir"
                log_to_file "ARGUMENT: output_dir=$output_dir"
                shift 2
                ;;
            -q|--quality)
                if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -le 512 ]; then
                    audio_quality="$2"
                    log_info "🎚️  Audio quality set to: ${audio_quality}kbps"
                    log_to_file "ARGUMENT: quality=${audio_quality}kbps"
                else
                    log_error "Invalid quality: $2. Must be a number <= 512"
                    exit 1
                fi
                shift 2
                ;;
            -f|--format)
                case "$2" in
                    mp3|m4a|flac|wav|opus) 
                        audio_format="$2"
                        log_info "📄 Audio format set to: $audio_format"
                        log_to_file "ARGUMENT: format=$audio_format"
                        ;;
                    *) 
                        log_error "Unsupported format: $2. Use: mp3, m4a, flac, wav, opus"
                        exit 1 
                        ;;
                esac
                shift 2
                ;;
            --no-metadata)
                no_metadata="true"
                log_info "🚫 Metadata embedding disabled"
                log_to_file "ARGUMENT: no_metadata=true"
                shift
                ;;
            --keep-video)
                keep_video="true"
                log_info "🎥 Video file will be kept in output folder"
                log_to_file "ARGUMENT: keep_video=true"
                shift
                ;;
            --compress)
                compress_folder="true"
                log_info "🗜️  Output folder will be compressed"
                log_to_file "ARGUMENT: compress_folder=true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                youtube_url="$1"
                log_info "🔗 YouTube URL: $youtube_url"
                log_to_file "ARGUMENT: youtube_url=$youtube_url"
                shift
                ;;
        esac
    done
    
    # Validate inputs
    if [ -z "$youtube_url" ]; then
        log_error "YouTube URL is required"
        show_usage
        exit 1
    fi
    
    if ! validate_youtube_url "$youtube_url"; then
        log_error "Invalid YouTube URL: $youtube_url"
        show_usage
        exit 1
    fi
    
    # Create output directory
    mkdir -p "$output_dir" || {
        log_error "Cannot create output directory: $output_dir"
        exit 1
    }
    
    # Check if output directory is writable
    if [ ! -w "$output_dir" ]; then
        log_error "Output directory is not writable: $output_dir"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Perform download and conversion
    download_and_convert "$youtube_url" "$output_dir" "$audio_quality" "$audio_format" \
        "$no_metadata" "$keep_video" "$compress_folder"
    
    log_success "Script execution completed successfully! 🎊"
    log_to_file "SCRIPT_COMPLETE: Success"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

