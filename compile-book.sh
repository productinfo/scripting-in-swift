#!/bin/sh

text=$(cat "./chapters/0 - Introduction.txt" "./chapters/1 - The Beginning.txt")

echo "Text file contents:\n $text"

output_file=output/output.html

echo "$text" | python -m markdown > "$output_file"

echo "\nMarkdown conversion complete. Output located in $output_file"
