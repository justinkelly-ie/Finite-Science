#!/bin/bash
for dir in 0*/; do
    folder_name=$(echo "$dir" | sed 's/\///')
    master_md="${dir}${folder_name}_Full_Notes.md"
    
    echo "Creating: $master_md"
    
    # Force a clean file
    cat /dev/null > "$master_md"

    # Get the files, sort them naturally, and process
    find "$dir" -maxdepth 1 -name "*.vtt" | sort -V | while read -r f; do
        title=$(basename "${f%.vtt}")
        echo "   -> Adding: $title"
        
        {
            echo "# $title"
            echo ""
            sed -E 's/[0-9:.]+ --> [0-9:.]+//g; s/&nbsp;//g; /^WEBVTT/d; /^[[:space:]]*$/d' "$f" | \
            tr '\n' ' ' | sed 's/  */ /g'
            echo -e "\n\n---\n"
        } >> "$master_md"
    done
done
