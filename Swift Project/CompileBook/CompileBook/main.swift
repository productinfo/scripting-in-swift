//
//  main.swift
//  CompileBook
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import Foundation

func createHTMLPageFromMarkdownFiles()
{
    let markdownFilesDirectoryName = "chapters"
    
    let currentDirectory = NSFileManager.defaultManager().currentDirectoryPath
    let url = NSURL(fileURLWithPath: "\(currentDirectory)/\(markdownFilesDirectoryName)", isDirectory: true)
    
    let markdownFileURLs = FileManagerWrapper.discoverContentsInDirectoryWithURL(url)
    let markdownContent = FileManagerWrapper.concatenateContentsOfFilesWithURLs(markdownFileURLs)
    
    MarkdownConverter.createHTMLPageFromMarkdownContent(markdownContent)
}

createHTMLPageFromMarkdownFiles()