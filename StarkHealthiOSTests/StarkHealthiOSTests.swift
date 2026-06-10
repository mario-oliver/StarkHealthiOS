//
//  StarkHealthiOSTests.swift
//  StarkHealthiOSTests
//
//  Created by Mario Oliver on 6/6/26.
//

import XCTest
@testable import StarkHealthiOS

final class StarkHealthiOSTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHarnessSmoke_runnerExecutesAssertions() {
        XCTAssertEqual(1 + 1, 2)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
