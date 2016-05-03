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
    /**
     Retrieves the files located within the directory at the given URL, skipping any hidden files.
     
     - parameter url: The URL of the directory.
     
     - returns: An array of NSURLs representing the contents of the directory.
     */
    class func discoverContentsInDirectoryWithURL(url: NSURL) -> [NSURL]?
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
            print("Error reading contents of directory. \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     Reads content from the file at the given URL.
     
     - parameter fileURL: The URL of the file to read from.
     
     - returns: The contents of the file.
     */
    class func readContentFromFileWithURL(fileURL: NSURL) -> String?
    {
        do
        {
            return try String(contentsOfURL: fileURL)
        }
        catch let error as NSError
        {
            print("Error reading from file. \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     Concatenates the content of all files at the given urls into a single string.
     
     - parameter fileURLs:                              The file urls to concatenate.
     - parameter adjustFileContentsBeforeConcatenating: Callback to adjust the text read from the file before being concatenated.
     
     - returns: The concatenated string.
     */
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
    
    /**
     Creates a file with the supplied attributes.
     
     - parameter path:     The path to where the file will be located.
     - parameter fileName: Name of the file.
     - parameter contents: The contents to insert into the file.
     */
    class func createFileAtPath(path: String, withFileName fileName: String, contents: String)
    {
        let outputPath = path + "/" + fileName
        NSFileManager.defaultManager().createFileAtPath(outputPath,
                                                        contents: contents.dataUsingEncoding(NSUTF8StringEncoding),
                                                        attributes: nil)
    }
}