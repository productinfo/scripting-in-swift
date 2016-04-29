//
//  main.swift
//  CompileBook
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import Foundation

/**
 Searches through the markdown files located within the 'chapters' folder and converts them into a single HTML file.
 
 - returns: An HTML representation of the markdown files, concatenated into a single HTML file.
 */
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
        let path = fileURL.lastPathComponent!

        let titleWithMarkdown = "# " + path.stringByReplacingOccurrencesOfString(".md", withString: "")
        return titleWithMarkdown + "\n" + contents + "\n"
    }
    
    return markdownContent
}

let markdownContent = createHTMLContentFromMarkdownFiles()
let htmlContent = MarkdownConverter.createHTMLStringFromMarkdownContent_swift(markdownContent)

FileManagerWrapper.createFileAtPath("./output", withFileName: "swift.html", contents: htmlContent)

print("Markdown conversion complete. Output located at output/swift.html")