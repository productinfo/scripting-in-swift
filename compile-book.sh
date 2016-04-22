#!/bin/sh

text=""

for file in chapters/*; do
file_contents=$(cat "$file")
chapter_title=$(basename "$file")
text="$text$chapter_title\n\n$file_contents\n\n"
done

output_file=output/output.html

echo "$text" | python -m markdown > "$output_file"

echo "\nMarkdown conversion complete. Output located in $output_file"
