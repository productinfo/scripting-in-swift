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
    
    class func concatenateContentsOfFilesWithURLs(
        fileURLs: [NSURL],
        adjustFileContentsBeforeConcatenating: ((fileURL: NSURL, content: String) -> String)? = nil
        ) -> String
    {
        return fileURLs.reduce("")
        {
            (allContent: String, fileURL) in
            var contentsOfFile = ""
            do
            {
                let fileHandle = try NSFileHandle(forReadingFromURL: fileURL)
                let data = fileHandle.readDataToEndOfFile()
                
                let rawFileContent = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
                
                contentsOfFile = adjustFileContentsBeforeConcatenating?(fileURL: fileURL, content: rawFileContent) ?? rawFileContent
            }
            catch let error as NSError
            {
                print("Error loading file. \(error.localizedDescription)")
            }
            
            return allContent + contentsOfFile
        }
    }

}