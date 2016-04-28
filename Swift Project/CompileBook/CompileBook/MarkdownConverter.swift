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
    class func createHTMLPageFromMarkdownContent(content: String) -> String?
    {
        let tempFile = "temp.txt"
        
        let data = content.dataUsingEncoding(NSUTF8StringEncoding)
        guard NSFileManager.defaultManager().createFileAtPath(tempFile, contents: data, attributes: nil) else {
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
}