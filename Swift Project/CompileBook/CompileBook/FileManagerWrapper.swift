//
//  FileManagerWrapper.swift
//  CompileBook
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import Foundation

class FileManagerWrapper
{
    class func discoverContentsInDirectoryWithURL(url: NSURL) -> [NSURL]
    {
        let fileManager = NSFileManager.defaultManager()
        do {
            return try fileManager.contentsOfDirectoryAtURL(url,
                                                            includingPropertiesForKeys: [NSURLNameKey],
                                                            options: .SkipsHiddenFiles)
        }
        catch let error as NSError
        {
            fatalError(error.localizedDescription)
        }
    }
    
    class func addFileTitleToContents(contents: String, fileName: String) -> String
    {
        let titleWithMarkdown = "#" + fileName.stringByReplacingOccurrencesOfString(".txt", withString: "")
        return titleWithMarkdown.stringByAppendingString("\n" + contents + "\n")
    }
    
    class func concatenateContentsOfFilesWithURLs(fileURLs: [NSURL]) -> String
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
                contentsWithTitle = addFileTitleToContents(contents, fileName: fileURL.lastPathComponent!)
            }
            catch let error as NSError
            {
                print("Error loading file. \(error.localizedDescription)")
            }
            
            return allContent + contentsWithTitle
        }
    }

}