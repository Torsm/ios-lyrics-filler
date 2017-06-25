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
    
    override func setUp() {
        super.setUp()
        genius = Genius(accessToken: "uQJZhbPCYbzn4GxIK9A7iQ9frDQj5NQ1lGtP-drisYoYiWQ07zHtRgekUM4IC4A6")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSearch() {
        let responseExpectation = expectation(description: "response expectation")
        
        self.genius.search(query: "99 Luftballons") { songs, error in
            XCTAssertNil(error)
            XCTAssertFalse(songs!.isEmpty)
            
            self.genius.getLyrics(song: songs!.first!) { lyrics, error in
                XCTAssertNil(error)
                
                print("\n\(lyrics!)\n")
                
                responseExpectation.fulfill()
            }
        }
        
        wait(for: [responseExpectation], timeout: 10)
    }
}
