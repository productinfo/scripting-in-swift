#!/bin/sh

# Extract and format chapter number and title
extract_chapter_title()
{
	chapter_filename=$(basename "$1")
	echo "#${chapter_filename%.*}"
}

text=""

# Iterate through all files to compile them into a single file
for file in chapters/*; do
	file_contents=$(cat "$file")
	chapter_title=$(extract_chapter_title "$file")
	all_chapter_content="$chapter_title\n\n$file_contents\n\n"
	text="$text$all_chapter_content"
done

output_file=output/output.html

# Pass concatenated chapters to markdown parser
echo "$text" | python -m markdown > "$output_file"

echo "Markdown conversion complete. Output located in $output_file"
