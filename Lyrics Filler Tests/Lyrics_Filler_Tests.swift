//
//  Lyrics_Filler_Tests.swift
//  Lyrics Filler Tests
//
//  Created by Torben Schmitz on 25.06.17.
//  Copyright © 2017 Torben Schmitz. All rights reserved.
//

import XCTest
@testable import Lyrics_Filler

class Lyrics_Filler_Tests: XCTestCase {
    var genius: Genius!
    var song: GeniusSong!
    var responseExpectation: XCTestExpectation!

    
    override func setUp() {
        super.setUp()
        genius = Genius(accessToken: "uQJZhbPCYbzn4GxIK9A7iQ9frDQj5NQ1lGtP-drisYoYiWQ07zHtRgekUM4IC4A6")
        responseExpectation = expectation(description: "api response expectation")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSearch() {
        genius.search(query: "99 luftballons") { songs, error in
            
            XCTAssert(error == nil)
            XCTAssert(!songs!.isEmpty)
            
            self.song = songs!.first!
            
            self.responseExpectation.fulfill()
        }
        
        wait(for: [responseExpectation], timeout: 10)
        self.responseExpectation = expectation(description: "html response expectation")
        
        genius.getLyrics(song: song) { lyrics, error in
            XCTAssert(error == nil)
            XCTAssert(lyrics != nil)
            
            print("\n----------\n\(lyrics!)\n-----------\n")
            
            self.responseExpectation.fulfill()
        }
        
        wait(for: [responseExpectation], timeout: 10)
    }
}
