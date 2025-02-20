//
//  AnyAppTests.swift
//  AnyAppTests
//
//  Created by tdolenko on 06.07.22.
//

import XCTest
@testable import AnyApp

class AnyAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
       XCTAssertEqual(2*2, 4, "should be equal")
    }

     func testExample1() throws {
       XCTAssertEqual(25*100, 2500, "should be equal")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
