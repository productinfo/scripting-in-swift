//
//  main.swift
//  CompileBook
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import Foundation

let markdownFilesDirectoryName = "chapters"

func discoverContentsInDirectoryWithURL(url: NSURL) -> [NSURL]
{
    let fileManager = NSFileManager.defaultManager()
    do {
        return try fileManager.contentsOfDirectoryAtURL(url,
                                                        includingPropertiesForKeys: [NSURLNameKey],
                                                        options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
    }
    catch let error as NSError
    {
        fatalError(error.localizedDescription)
    }
}

func addFileTitleToContents(contents: String, filePath: String) -> String
{
    let titleWithMarkdown = "#" + filePath.stringByReplacingOccurrencesOfString(".txt", withString: "")
    return titleWithMarkdown.stringByAppendingString("\n" + contents + "\n")
}

func concatenateContentsOfFilesWithURLs(fileURLs: [NSURL]) -> String
{
    return fileURLs.reduce("")
    {
    (allContent: String, fileURL) in
        var contentsWithTitle = ""
        do
        {
            let fileHandle = try NSFileHandle(forReadingFromURL: fileURL)
            let data = fileHandle.readDataToEndOfFile()
            
            let contents = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
            contentsWithTitle = addFileTitleToContents(contents, filePath: fileURL.lastPathComponent!)
        }
        catch let error as NSError
        {
            print("Error loading file. \(error.localizedDescription)")
        }
        
        return allContent + contentsWithTitle
    }
}

func generateMarkdownForContent(content: String)
{
    let tempFile = markdownFilesDirectoryName + "/concatenatedFile.txt"
    
    let data = content.dataUsingEncoding(NSUTF8StringEncoding)
    guard NSFileManager.defaultManager().createFileAtPath(tempFile, contents: data, attributes: nil) else {
        print("Error creating temporary file")
        return
    }
    
    let outputPipe = NSPipe()
    
    let task = NSTask()
    task.launchPath = "/usr/local/bin/python"
    task.arguments = ["-m", "markdown", tempFile]
    task.standardOutput = outputPipe
    
    task.launch()
    task.waitUntilExit()
    
    try! NSFileManager.defaultManager().removeItemAtPath(tempFile)
    
    let outputPath = "output/swift-output.html"
    NSFileManager.defaultManager().createFileAtPath(outputPath,
                                                    contents: outputPipe.fileHandleForReading.readDataToEndOfFile(),
                                                    attributes: nil)
    print("Finished markdown generation.")
}

let currentDirectory = NSFileManager.defaultManager().currentDirectoryPath
let url = NSURL(fileURLWithPath: "\(currentDirectory)/\(markdownFilesDirectoryName)", isDirectory: true)

let fileURLs = discoverContentsInDirectoryWithURL(url)
print(fileURLs)
let content = concatenateContentsOfFilesWithURLs(fileURLs)

generateMarkdownForContent(content)
