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
        do
        {
            return try fileManager.contentsOfDirectoryAtURL(url,
                                                            includingPropertiesForKeys: [NSURLNameKey],
                                                            options: .SkipsHiddenFiles)
        }
        catch let error as NSError
        {
            fatalError(error.localizedDescription)
        }
    }
    
    class func readContentFromFileWithURL(fileURL: NSURL) -> String?
    {
        do
        {
            let fileHandle = try NSFileHandle(forReadingFromURL: fileURL)
            let data = fileHandle.readDataToEndOfFile()
            
            return NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        }
        catch let error as NSError
        {
            print("Error reading from file. \(error.localizedDescription)")
            return nil
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
            
            guard let rawFileContent = readContentFromFileWithURL(fileURL) else
            {
                return allContent
            }
            
            let contentsOfFile = adjustFileContentsBeforeConcatenating?(fileURL: fileURL, content: rawFileContent) ?? rawFileContent
            
            return allContent + contentsOfFile
        }
    }

    class func createFileAtPath(path: String, withFileName fileName: String, contents: String)
    {
        let outputPath = path + "/" + fileName
        NSFileManager.defaultManager().createFileAtPath(outputPath,
                                                        contents: contents.dataUsingEncoding(NSUTF8StringEncoding),
                                                        attributes: nil)
    }
}