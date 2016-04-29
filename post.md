# Scripting in Swift

## Introduction

There has been a lot of talk about how Swift could be used to develop in many areas outside of iOS app development. Indeed there is (very early!) development to add Android support and IBM are looking to move a lot of their server development to using Swift. Another area where Swift could potentially be of use is as a Scripting language.

Its concise nature makes it feel a little like Python and Ruby, yet its powerful type system means we can potentially write less error-prone scripts.

To test out Swift's scripting ability, we'll write a program that reads a number of separate markdown files, concatenates them into a single file, and then converts the concatenated file into markdown.

A shellscript is perhaps the most common scripting language that is often turned to when a quick script is required. To test the viability of scripting in Swift, we'll write our markdown converter first as a shellscript and then compose a Swift version. We'll then do a quick comparison of the pros and cons of each script.

## The Shellscript

```sh
#!/bin/sh

# Extract and format chapter number and title
extract_chapter_title()
{
    chapter_filename=$(basename "$1")
    echo "# ${chapter_filename%.*}"
}

output_file=output/shellscript.html

# Iterate through all files to compile them into a single file
for file in chapters/*; do
    extract_chapter_title "$file"
    printf "\n\n"
    cat "$file"
    printf "\n\n"
done | python -m markdown > "$output_file"

echo "Markdown conversion complete. Output located in $output_file"
```

A brief overview of the script:

- We go through all files within the *chapters* folder
-- Extract the file name, appending a '#' to add a title to the file contents
-- Add various newlines to pad out the content
-- Output the contents of the file
- Pipe the contents of the concatenated files into a python markdown library. Install this using `pip install markdown`
- Print a message to the console

## The Swift Script