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
    echo -e "${CYAN}Usage: $0 [--dry-run] [--compare] <source_directory> <destination_directory>${RESET}"
    exit 1
}

# Check if the correct number of arguments are provided
if [ "$#" -lt 2 ]; then
    usage
fi

# Parse options
DRY_RUN=false
COMPARE=false
while [[ "$1" == --* ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --compare)
            COMPARE=true
            ;;
        *)
            usage
            ;;
    esac
    shift
done

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

# Function to compare directories by file names and folder structure
compare_directories() {
    echo -e "${CYAN}Comparing directories...${RESET}"

    # Find files in SRC_DIR and check against DEST_DIR
    while IFS= read -r -d '' file; do
        rel_path="${file#$SRC_DIR/}"
        if [ ! -e "$DEST_DIR/$rel_path" ]; then
            echo -e "${RED}Missing in $DEST_DIR: -$rel_path${RESET}"
        fi
    done < <(find "$SRC_DIR" -type f -print0)

    # Find files in DEST_DIR that are not in SRC_DIR
    while IFS= read -r -d '' file; do
        rel_path="${file#$DEST_DIR/}"
        if [ ! -e "$SRC_DIR/$rel_path" ]; then
            echo -e "${YELLOW}Extra in $DEST_DIR: +$rel_path${RESET}"
        fi
    done < <(find "$DEST_DIR" -type f -print0)

    echo -e "${GREEN}Directory comparison completed.${RESET}"
}

# Function to compare directories by file names and folder structure
sync_directories() {
    # Temp file to capture rsync output
    RSYNC_LOG=$(mktemp)

    # Use rsync with options to preserve metadata, exclude .DS_Store files, show progress for each file and detailed change information
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}Performing dry run...${RESET}"
        rsync -aHv --ignore-existing --exclude='.DS_Store' --progress --itemize-changes --dry-run "$SRC_DIR/" "$DEST_DIR/" | tee "$RSYNC_LOG"
    else
        echo -e "${CYAN}Copying files...${RESET}"
        rsync -aHv --partial --ignore-existing --exclude='.DS_Store' --progress --itemize-changes "$SRC_DIR/" "$DEST_DIR/" | tee "$RSYNC_LOG"
    fi

    # Count the number of files that would be copied or were copied
    TOTAL_FILES_COPIED=$(grep '^>f' "$RSYNC_LOG" | wc -l)

    # Clean up temporary file
    rm "$RSYNC_LOG"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}Dry run completed. No files were actually copied.${RESET}"
    elif [ "$TOTAL_FILES_COPIED" -eq 0 ]; then
        echo -e "${YELLOW}No files were copied.${RESET}"
    else
        echo -e "${GREEN}Total files copied: $TOTAL_FILES_COPIED${RESET}"
        echo -e "${GREEN}Copy completed successfully.${RESET}"
    fi
}

# Run directory comparison if --compare is passed
if [ "$COMPARE" = true ]; then
    compare_directories
else 
    sync_directories
fi