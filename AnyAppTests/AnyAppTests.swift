//
//  AnyAppTests.swift
//  AnyAppTests
//
//  Created by tdolenko on 06.07.22.
//

import XCTest
@testable import AnyApp

class AnyAppTests: XCTestCase {
    
    func testExample() throws {
        XCTAssertEqual(2*2, 4)
    }
    
    func testFailed() throws {
        XCTAssertEqual(2*2, 5)
    }
}
