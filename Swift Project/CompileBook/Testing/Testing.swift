//
//  Testing.swift
//  Testing
//
//  Created by Samuel Burnstone on 28/04/2016.
//  Copyright © 2016 ShinobiControls. All rights reserved.
//

import XCTest

class Testing: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    /** Simple tests to ensure we're calling through to markdown-parsing libraries successfully */
    func test_markdown_is_converted_into_html_using_python_library()
    {
        let markdown = "# This is a title"
        
        let expectedHTML = "<h1>This is a title</h1>"
        
        let convertedHTML = MarkdownConverter.createHTMLStringFromMarkdownContent_python(markdown)
        
        XCTAssertEqual(expectedHTML, convertedHTML)
    }
    
    func test_markdown_is_converted_into_html_using_swift_library()
    {
        let markdown = "# This is a title"
        
        let expectedHTML = "<h1>This is a title</h1>\n"
        
        let convertedHTML = MarkdownConverter.createHTMLStringFromMarkdownContent_swift(markdown)
        
        XCTAssertEqual(expectedHTML, convertedHTML)
    }
}
