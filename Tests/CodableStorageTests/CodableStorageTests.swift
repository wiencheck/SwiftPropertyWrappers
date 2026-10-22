//
//  CodableStorageTests.swift
//  SwiftPropertyWrappers
//
//  Created by Adam Wienconek on 22/10/2026.
//

import Testing
@testable import SwiftPropertyWrappers

@Test
func test_codable_storage() {
    
    class TestClass {
        @CodableStorage(
            "testing_content",
            defaultValue: nil,
            directory: .applicationSupport(folder: "testing")
        )
        var file: MyFile?
    }
    
    let t1 = TestClass()
    t1.file = MyFile(title: "Title_1")
    
    let t2 = TestClass()
    #expect(
        t2.file?.title == "Title_1"
    )
    
    t2.file?.value = 90
    #expect(
        t1.file?.value == 90
    )
}

@Test
func test_read_nonexisting_file() {
    class TestClass {
//        @CodableStorage(
//            "nonexisting_file",
//            defaultValue: <#T##Decodable & Encodable#>,
//            directory: <#T##FileHelper.Directory#>
//        )
    }
}
