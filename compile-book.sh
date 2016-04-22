#!/bin/sh

# Extract and format chapter number and title
extract_chapter_title()
{
	chapter_filename=$(basename "$1")
	echo "#${chapter_filename%.*}"
}

output_file=output/output.html

# Iterate through all files to compile them into a single file
for file in chapters/*; do
	extract_chapter_title "$file"
	printf "\n\n"
	cat "$file"
	printf "\n\n"
done | python -m markdown > "$output_file"

echo "Markdown conversion complete. Output located in $output_file"
