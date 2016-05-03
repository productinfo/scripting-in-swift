# Scripting in Swift

## Introduction

There has been a lot of talk about how Swift could be used to develop in many areas outside of iOS app development. Indeed there is (very early!) development to add Android support and IBM are looking to move a lot of their server development to using Swift. Another area where Swift could potentially be of use is as a Scripting language.

Its concise nature makes it feel a little like Python and Ruby, yet its powerful type system means we can potentially write less error-prone scripts.

To test out Swift's scripting ability, we'll write a program that reads a number of separate markdown files, concatenates them into a single file, and then converts the concatenated file into HTML.

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
	- Extract the file name, appending a '#' to add a title to the file contents
	- Add various newlines to pad out the content
	- Output the contents of the file
- Pipe the contents of the concatenated files into a python markdown library (install this using `pip install markdown`).
- Print a message to the console

## The Swift Script

### Setting up

I used Xcode's OSX's 'Command Line Tool' template to set up the project. Doing it this way, meant I could use syntax highlighting and auto-complete.

### FileManagerWrapper.swift

This acts as a simple wrapper around Foundation classes that interact with the file system. There's not too much of interest here: the class simply handles any errors returned by NSFileManager and NSFileHandle, prints relevant messages to the console. We make use of Swift's optionals so we can protect against the case where a file cannot be read, a file cannot be found e.t.c.

It's pretty impossible to argue that the above class is much of an improvement over the shellscript; interacting with files is where shellscripting really shines, for example, the equivalent of `cat file1.txt` is a lot less concise in Swift.

However, using Swift does enable us to gain access to a couple of nifty features, such as collection's `reduce`.  We can also make use of an optional closure to give the caller a way of adjusting the contents of a file before concatenating the contents with those of the previous files.

```swift
class func concatenateContentsOfFilesWithURLs(
    fileURLs: [NSURL],
    adjustFileContentsBeforeConcatenating: ((fileURL: NSURL, content: String) -> String)? = nil
    ) -> String
{
    return fileURLs.reduce("")
    {
        (allContent: String, fileURL) in
        guard let rawFileContent = readContentFromFileWithURL(fileURL) else
        {
            return allContent
        }
        
        let contentsOfFile = adjustFileContentsBeforeConcatenating?(fileURL: fileURL, content: rawFileContent) ?? rawFileContent
        
        return allContent + contentsOfFile
    }
}
```

### MarkdownConverter.swift

Fortunately, there are number of Markdown to HTML converting libraries written for iOS which are at our disposal. However, I was interested in seeing how we would call out to the Python library used in the Shellscript.

```swift
class func createHTMLStringFromMarkdownContent_python(content: String) -> String?
{
    let tempFile = "temp.txt"
    
    let data = content.dataUsingEncoding(NSUTF8StringEncoding)
    guard NSFileManager.defaultManager().createFileAtPath(tempFile, contents: data, attributes: nil) else
    {
        print("Error creating temporary file")
        return nil
    }
    
    let outputPipe = NSPipe()
    
    let task = NSTask()
    task.launchPath = "/usr/local/bin/python"
    task.arguments = ["-m", "markdown", tempFile]
    task.standardOutput = outputPipe
    
    task.launch()
    task.waitUntilExit()
    
    try! NSFileManager.defaultManager().removeItemAtPath(tempFile)
    
    let convertedMarkdownData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    
    return NSString(data: convertedMarkdownData, encoding: NSUTF8StringEncoding) as? String
}
```

Urgh. Well... what were we expecting? 

This method creates a temporary file to store the contents of our concatenated Markdown string which is then passed to the Python library. To capture the HTML string we use an NSPipe that we can read from later.

Right, enough of that nonsense, let's use a native Swift library! I chose [Markingbird](https://github.com/kristopherjohnson/Markingbird), mostly for its simplicity - simply drag `Markdown.swift` into the project and you're good to go.

```swift
class func createHTMLStringFromMarkdownContent_swift(content: String) -> String
{
    var markdown = Markdown()
    return markdown.transform(content)
}
```

### main.swift

This is the entry point to the script. This will call out to the other classes.

```swift
func createHTMLContentFromMarkdownFiles() -> String
{
    let markdownFilesDirectory = "./chapters"
    let url = NSURL(fileURLWithPath: markdownFilesDirectory, isDirectory: true)
    
    guard let markdownFileURLs = FileManagerWrapper.discoverContentsInDirectoryWithURL(url) else
    {
        exit(1)
    }
    
    let markdownContent = FileManagerWrapper.concatenateContentsOfFilesWithURLs(markdownFileURLs)
    {
        fileURL, contents in
        guard let path = fileURL.lastPathComponent else
        {
            return contents
        }

        let titleWithMarkdown = "# " + path.stringByReplacingOccurrencesOfString(".md", withString: "")
        return titleWithMarkdown + "\n" + contents + "\n"
    }
    
    return markdownContent
}
```

The above method simply asks the `FileManagerWrapper` for the contents of the "chapters" directory. If successful, we concatenate each file's contents into a single string, prepending the filename, minus the file extensions.

To tie it all together, we pass the Markdown string to our converter and then write the converted HTML string to our output file.

```swift
let markdownContent = createHTMLContentFromMarkdownFiles()
let htmlContent = MarkdownConverter.createHTMLStringFromMarkdownContent_swift(markdownContent)

FileManagerWrapper.createFileAtPath("./output", withFileName: "swift.html", contents: htmlContent)

print("Markdown conversion complete. Output located at output/swift.html")
```

### Building

If we build and run the script in Xcode, we can copy the .exe from the Derived Data directory into the same directory as our chapters folder resides. We need to do this as, for simplicity, our path to the chapters directory is currently hardcoded within the script itself. Alternatively, we can add a stage to our executable target's *Build Phases* that copies the executable into the location we desire.

```shell
cp "${CONFIGURATION_BUILD_DIR}/${PRODUCT_NAME}" "${SRCROOT}/../.."
```
However, did you spot the size of the executable? It's coming out at a whopping 5MB! This seems a little extraordinary, especially when we compare to the tiny 467 bytes that our Shell Script requires.

We can simply compile the files ourselves:

```shell
# From the directory containing our 'chapters', compile all swift files 
swiftc $(echo "Swift-Project"/CompileBook/CompileBook/*.swift) -o CompileBook
```

The executable generated using the above command is now a much more reasonable 400KB.

To run the Swift script, all we have to do now is `./CompileBook`. We can now examine the output located within `output/swift.html`.

## Thoughts

So, what can we learn from the above experiment?

- The Swift script took longer to write, but is arguably easier to understand, due to better separation into separate classes, methods e.t.c
- Aside from wrapping NSFileManager (which is over 50% of the script - ignoring the 3rd party Markdown parsing) there isn't much to the script.
- We can use the familiar environment of Xcode with its excellent code-completion and syntax-highlighting.
- We can write unit tests using XCTest. It's trivial to add a testing target and can use XCTest as you would in any iOS/Mac project..
- We can make use of powerful Swift features: Standard Library, Error Handling, Closures

For basic scripts that simply shift files around, a quick Shell Script is almost certainly the way to go. However if you are planning on writing a more complicated command line application, Swift may be the way to go.

## Further Investigation

A collection of links to videos, blog posts and libraries should you wish to investigate a little more:

- [Swift for CLI](https://realm.io/news/swift-for-CLI/)
- [Swift Scripting By Example: Generating Acknowledgements For CocoaPods & Carthage Dependencies](http://swift.ayaka.me/posts/2015/11/5/swift-scripting-generating-acknowledgements-for-cocoapods-and-carthage-dependencies)
- [Scripting in Swift](http://krakendev.io/blog/scripting-in-swift)

