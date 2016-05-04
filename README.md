## Introduction

There has been a lot of talk about how Swift could be used to develop in many areas outside of iOS app development. Indeed there is (very early!) progress being made to [add Android support](https://github.com/apple/swift/blob/master/docs/Android.md) and IBM are looking to use [Swift on the server](https://developer.ibm.com/swift/). Another area where Swift could potentially be of use is as a Scripting language. Its concise nature makes it feel a little like Python and Ruby, yet its powerful type system means we can potentially write less error-prone scripts.

To test out Swift's scripting ability, we'll write a program that reads a number of separate markdown files, concatenates them into a single file, and then converts the concatenated file into HTML.

A shell script is perhaps the most popular command-line scripting language, particularly in the mobile development world. To test the viability of scripting in Swift, we'll write our markdown converter first as a shell script and then compose a Swift version. We'll then do a quick comparison of the pros and cons of each script.

The code used in this blog post can be found on [GitHub](https://github.com/shinobicontrols/scripting-in-swift).

## The shell script

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

- We go through all files within the "chapters" directory
	- Extract the file name, appending a '#' to add a title to the file contents
	- Add various newlines to pad out the content
	- Output the contents of the file
- Pipe the contents of the concatenated files into a python markdown library (install this using `pip install markdown`).
- Print a message to the console

The script is run by simply typing `./compile-book.sh`. The outputted HTML can be inspected by opening `output/shellscript.html` in a browser.

## The Swift Script

### Setting up

I used Xcode's OSX 'Command Line Tool' template to set up the project. Doing it this way means we can make use of Xcode's syntax highlighting and auto-completion features.

### FileManagerWrapper.swift

This acts as a simple wrapper around Foundation classes that interact with the file system. There's not too much of interest here: the class simply handles any errors returned by `NSFileManager` and prints relevant messages to the console. We make use of Swift Optionals in the case where a file cannot be read or cannot be found.

This class, at first, doesn't seem to offer that many benefits over its more traditional counterpart, however the equivalent of `cat file1.txt` isn't that much more verbose in Swift (we need the URL which we then pass into the `String` intializer). In fact, you could argue the Swift variant is better, as it forces us to be aware of errors thrown in the case the file cannot be found at the given location, whereas the shell script does no such thing.

Additionally, using Swift enables us to gain access to a couple of nifty features, such as `SequenceType`'s `reduce` method.  We can also make use of an optional closure to give the caller a way of adjusting the contents of a file before concatenating the contents with those of the previous files.

```swift
class func concatenateContentsOfFilesWithURLs(
    fileURLs: [NSURL],
    adjustFileContentsBeforeConcatenating: ((fileURL: NSURL, content: String) -> String)? = nil
    ) -> String
{
    return fileURLs.reduce("")
    {
        (allContent: String, fileURL) in
        guard let rawFileContent = try? String(contentsOfURL: fileURL) else
        {
            return allContent
        }
        
        let contentsOfFile = adjustFileContentsBeforeConcatenating?(fileURL: fileURL, content: rawFileContent) ?? rawFileContent
        
        return allContent + contentsOfFile
    }
```

### MarkdownConverter.swift

I was interested in seeing how we would call out to the same Python library used in the shell script in the case a native library wasn't available for us to use.

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

Urgh. Well... what were we expecting, I suppose?! 

This method creates a temporary file to store the contents of our concatenated Markdown string which is then passed to the Python library. To capture the HTML string we use an NSPipe that we can read from later.

Right, enough of that nonsense, let's use a native Swift library! I chose [Markingbird](https://github.com/kristopherjohnson/Markingbird), mostly for its simplicity - just drag `Markdown.swift` into the project and you're good to go.

```swift
class func createHTMLStringFromMarkdownContent_swift(content: String) -> String
{
    var markdown = Markdown()
    return markdown.transform(content)
}
```

### main.swift

This is the entry point to the script and links the other classes together.

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

The above method simply asks the `FileManagerWrapper` for the contents of the "chapters" directory. If successful in finding the directory, we concatenate each file's contents into a single string and prepend the filename, minus the file extension.

To tie it all together, we pass the Markdown string to our converter and then write the converted HTML string to our output file.

```swift
let markdownContent = createHTMLContentFromMarkdownFiles()
let htmlContent = MarkdownConverter.createHTMLStringFromMarkdownContent_swift(markdownContent)

FileManagerWrapper.createFileAtPath("./output", withFileName: "swift.html", contents: htmlContent)

print("Markdown conversion complete. Output located at output/swift.html")
```

### Building

If we build and run the script in Xcode, we can copy the executable from the Derived Data directory into the same directory as our chapters folder. We need to do this as, for simplicity, our path to the chapters directory is currently hardcoded within the script itself. Alternatively, we can add a stage to our executable target's *Build Phases* that copies the executable into the location we desire whenever we hit the 'Run' button.

```shell
cp "${CONFIGURATION_BUILD_DIR}/${PRODUCT_NAME}" "${SRCROOT}/../.."
```

Now we can run the script by typing `./CompileBook` in Terminal and then inspect the contents located at `output/swift.html`. 

Great, that's working. However, did you spot the size of the executable? It's coming out at a whopping 5MB! This seems a little extraordinary, especially considering our shell script consumed a tiny 467 Bytes.

We can bypass Xcode's compilation and simply compile the files ourselves:

```shell
# From the directory containing our 'chapters', compile all swift files
swiftc $(echo Swift-Project/CompileBook/CompileBook/*.swift) -o CompileBook
```

The executable generated using the above command is now a much more reasonable 400KB. We can verify the output is the same by running `./CompileBook` again.

## Thoughts

So, what can we learn from the above experiment?

There are a lot of advantages to being able to use the same tools and languages across multiple disciplines (in this case, mobile development and scripting). I rarely write shell scripts, so whenever I do, a lot of time is spent trawling sites like Stack Overflow for answers to relatively basic questions. Swift, on the other hand, is a much more familiar language to me which I develop with regularly, so I can dive in and get started a lot more easily. As for the tooling, Xcode provides good support for unit testing (and is getting better with almost every release), so we can make use of XCTest to help automate the testing of our script.

The shell script is a lot more concise (15 lines, opposed to around 150), however it does this at the cost of readability - I personally feel it's much easier to understand what the Swift script is doing. Powerful Swift features such as its standard library, error handling model and closures help us to write readable scripts that are less error prone. This is because it forces us to take into account situations such as when a file is not found or the contents of the file cannot be read; edge cases I find myself often overlooking when writing shell scripts.

For basic scripts that simply shift files around, a shell script is almost certainly the way to go. However if you are planning on writing a more complicated command line application, Swift may be worth your consideration.

If you would like to find out a little bit more about scripting in Swift, the following resources may be of interest:

- [Swift for CLI](https://realm.io/news/swift-for-CLI/)
- [Swift Scripting By Example: Generating Acknowledgements For CocoaPods & Carthage Dependencies](http://swift.ayaka.me/posts/2015/11/5/swift-scripting-generating-acknowledgements-for-cocoapods-and-carthage-dependencies)
- [Scripting in Swift](http://krakendev.io/blog/scripting-in-swift)

