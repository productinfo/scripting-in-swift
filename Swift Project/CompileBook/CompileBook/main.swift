//
//  main.swift
//  CompileBook
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import Foundation

func createHTMLContentFromMarkdownFiles() -> String
{
    let markdownFilesDirectory = "./chapters"
    
    let url = NSURL(fileURLWithPath: markdownFilesDirectory, isDirectory: true)
    
    let markdownFileURLs = FileManagerWrapper.discoverContentsInDirectoryWithURL(url)
    let markdownContent = FileManagerWrapper.concatenateContentsOfFilesWithURLs(markdownFileURLs)
    {
        fileURL, contents in
        let path = fileURL.lastPathComponent!

        let titleWithMarkdown = "#" + path.stringByReplacingOccurrencesOfString(".txt", withString: "")
        return titleWithMarkdown + "\n" + contents + "\n"
    }
    
    return markdownContent
}

let markdownContent = createHTMLContentFromMarkdownFiles()
guard let htmlContent = MarkdownConverter.createHTMLStringFromMarkdownContent_python(markdownContent) else
{
    print("Error generating html string from markdown content")
    exit(1)
}
FileManagerWrapper.createFileAtPath("./output", withFileName: "swift.html", contents: htmlContent)