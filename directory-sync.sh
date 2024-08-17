#!/bin/bash

# Define color codes
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'

# Function to print usage
usage() {
    echo -e "${CYAN}Usage: $0 [--dry-run] <source_directory> <destination_directory>${RESET}"
    exit 1
}

# Check if the correct number of arguments are provided
if [ "$#" -lt 2 ]; then
    usage
fi

# Parse the --dry-run option
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    shift
fi

SRC_DIR=$1
DEST_DIR=$2

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}Source directory $SRC_DIR does not exist.${RESET}"
    exit 1
fi

# Check if destination directory exists, create it if it doesn't
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}Destination directory $DEST_DIR does not exist. Creating it...${RESET}"
    mkdir -p "$DEST_DIR"
fi

# Temp file to capture rsync output
RSYNC_LOG=$(mktemp)

# Use rsync with options to preserve metadata, exclude .DS_Store files, show progress for each file and detailed change information
if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}Performing dry run...${RESET}"
    rsync -aHv --ignore-existing --exclude='.DS_Store' --progress --itemize-changes --dry-run "$SRC_DIR/" "$DEST_DIR/" | tee "$RSYNC_LOG"
else
    rsync -aHv --partial --ignore-existing --exclude='.DS_Store' --progress --itemize-changes "$SRC_DIR/" "$DEST_DIR/" | tee "$RSYNC_LOG"
fi

# Count the number of files that would be copied or were copied
echo -e "${CYAN}Processing rsync output...${RESET}"
TOTAL_FILES_COPIED=$(grep '^>f' "$RSYNC_LOG" | wc -l)
echo -e "${GREEN}Total files copied: $TOTAL_FILES_COPIED${RESET}"

# Clean up temporary file
rm "$RSYNC_LOG"

if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}Dry run completed. No files were actually copied.${RESET}"
else
    echo -e "${GREEN}Copy completed successfully.${RESET}"
fi
