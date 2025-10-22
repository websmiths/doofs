#!/bin/bash

# Image Conversion Script for Web Viewing using ImageMagick
# Converts images to JPG with max 800px longest dimension and 250KB file size

# Default values
INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-web-optimized}"
MAX_SIZE="250KB"
MAX_DIMENSION="800"
QUALITY="85"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed${NC}"
    echo "Install it with: brew install imagemagick"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "Converting images from: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Max dimension: ${MAX_DIMENSION}px"
echo "Max file size: $MAX_SIZE"
echo "-----------------------------------"

# Counter for statistics
total=0
converted=0
skipped=0
failed=0

# Create associative array to track counts per directory
declare -A dir_counts

# Process images recursively
find "$INPUT_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.heic" -o -iname "*.webp" \) | while read -r file; do
    total=$((total + 1))
    
    # Get the parent directory name
    parent_dir=$(basename "$(dirname "$file")")
    
    # Initialize counter for this directory if not exists
    if [ -z "${dir_counts[$parent_dir]}" ]; then
        dir_counts[$parent_dir]=1
    else
        dir_counts[$parent_dir]=$((dir_counts[$parent_dir] + 1))
    fi
    
    # Create output filename: directoryname_index.jpg
    index="${dir_counts[$parent_dir]}"
    output_filename="${parent_dir}_${index}.jpg"
    output_file="$OUTPUT_DIR/${output_filename}"
    
    # Get original filename for display
    filename=$(basename "$file")
    
    # Skip if output already exists
    if [ -f "$output_file" ]; then
        echo -e "${YELLOW}Skipping (exists): $filename -> $output_filename${NC}"
        skipped=$((skipped + 1))
        continue
    fi
    
    echo -n "Converting: $filename -> $output_filename ... "
    
    # Convert image with ImageMagick
    # -resize: resize to fit within max dimension while maintaining aspect ratio
    # -quality: JPEG quality (we'll adjust if needed)
    # -define jpeg:extent: limit file size to approximately MAX_SIZE
    # -strip: remove EXIF data to reduce size
    
    if convert "$file" \
        -resize "${MAX_DIMENSION}x${MAX_DIMENSION}>" \
        -quality "$QUALITY" \
        -define jpeg:extent="$MAX_SIZE" \
        -strip \
        "$output_file" 2>/dev/null; then
        
        # Get the file size
        file_size=$(ls -lh "$output_file" | awk '{print $5}')
        echo -e "${GREEN}✓ ($file_size)${NC}"
        converted=$((converted + 1))
    else
        echo -e "${RED}✗ Failed${NC}"
        failed=$((failed + 1))
    fi
done

echo "-----------------------------------"
echo "Conversion complete!"
echo "Converted: $converted files"
echo "Skipped: $skipped files"
echo "Failed: $failed files"
echo "Output directory: $OUTPUT_DIR"
