//
//  MarkdownConverter.swift
//  CompileBook
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import Foundation

class MarkdownConverter
{
    /**
      Launches an NSTask that calls out to the markdown python library to convert markdown into an HTML string.
     
     - parameter content: The content string formatted with markdown
     
     - returns: An HTML string
     */
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
    
    /**
     Uses a native Swift library to transform a markdown string into HTML.
     
     - parameter content: The content string formatter with markdown
     
     - returns: An HTML string
     */
    class func createHTMLStringFromMarkdownContent_swift(content: String) -> String
    {
        var markdown = Markdown()
        return markdown.transform(content)
    }
}