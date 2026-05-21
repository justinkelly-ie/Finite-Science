for f in *.vtt; do
    # Extract filename without extension for the Header
    title="${f%.en-en.vtt}"
    
    # Clean text: remove timestamps, headers, &nbsp;, and join into one paragraph
    echo "# $title" > "${f%.vtt}.md"
    echo "" >> "${f%.vtt}.md"
    sed -E 's/[0-9:.]+ --> [0-9:.]+//g; s/&nbsp;//g; /^WEBVTT/d' "$f" | tr '\n' ' ' | sed 's/  */ /g' >> "${f%.vtt}.md"
    echo -e "\n" >> "${f%.vtt}.md"
done
