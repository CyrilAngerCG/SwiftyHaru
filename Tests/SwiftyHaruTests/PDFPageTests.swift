//
//  PDFPageTests.swift
//  SwiftyHaru
//
//  Created by Sergej Jaskiewicz on 02.10.16.
//
//

import XCTest
import SwiftyHaru

class PDFPageTests: XCTestCase {
    
    static var allTests : [(String, (PDFPageTests) -> () throws -> Void)] {
        return [
            ("testGetSetWidth", testGetSetWidth),
            ("testGetSetHeight", testGetSetHeight),
            ("testRotatePage", testRotatePage),
            ("testPathLineWidth", testPathLineWidth),
            ("testPathMoveDrawingPoint", testPathMoveDrawingPoint),
            ("testStrokeColorRGB", testStrokeColorRGB),
            ("testStrokeColorCMYK", testStrokeColorCMYK),
            ("testStrokeColorGray", testStrokeColorGray),
            ("testFillColorRGB", testFillColorRGB),
            ("testFillColorCMYK", testFillColorCMYK),
            ("testFillColorGray", testFillColorGray),
        ]
    }
    
    var recordMode = false
    
    var sut: PDFPage!
    
    var document: PDFDocument!
    
    override func setUp() {
        super.setUp()
        
        recordMode = false
        
        document = PDFDocument()
        sut = document.addPage()
    }
    
    override func tearDown() {
        
        if recordMode {
            saveReferenceFile(document.getData(), ofType: "pdf")
        }
        
        document = nil
        
        super.tearDown()
    }
    
    func testGetSetWidth() {
        
//        recordMode = true
        
        // Given
        let expectedDocumentData = getTestingResource(fromFile: currentTestName, ofType: "pdf")
        let expectedWidth: Float = 1000
        
        // When
        sut.width = 1000
        let returnedWidth = sut.width
        
        // Then
        XCTAssertEqual(expectedWidth, returnedWidth)
        
        // When
        sut.width = 2
        let returnedWidthTooSmall = sut.width
        
        // Then
        XCTAssertEqual(expectedWidth, returnedWidthTooSmall,
                       "Setting too small width should make no change")
        
        // When
        sut.width = 14401
        let returnedWidthTooBig = sut.width
        
        // Then
        XCTAssertEqual(expectedWidth, returnedWidthTooBig,
                       "Setting too big width should make no change")
        
        // When
        let returnedDocumentData = document.getData()
        
        // Then
        XCTAssertEqual(expectedDocumentData, returnedDocumentData)
    }
    
    func testGetSetHeight() {
        
//        recordMode = true
        
        // Given
        let expectedDocumentData = getTestingResource(fromFile: currentTestName, ofType: "pdf")
        let expectedHeight: Float = 2000
        
        // When
        sut.height = 2000
        let returnedHeight = sut.height
        
        // Then
        XCTAssertEqual(expectedHeight, returnedHeight)
        
        // When
        sut.height = 2
        let returnedHeightTooSmall = sut.height
        
        // Then
        XCTAssertEqual(expectedHeight, returnedHeightTooSmall,
                       "Setting too small width should make no change")
        
        // When
        sut.height = 14401
        let returnedHeightTooBig = sut.height
        
        // Then
        XCTAssertEqual(expectedHeight, returnedHeightTooBig,
                       "Setting too big width should make no change")
        
        // When
        let returnedDocumentData = document.getData()
        
        // Then
        XCTAssertEqual(expectedDocumentData, returnedDocumentData)
    }
    
    func testRotatePage() {
        
//        recordMode = true
        
        // Given
        let expectedDocumentData = getTestingResource(fromFile: currentTestName, ofType: "pdf")
        let page0 = sut!
        let page1 = document.addPage()
        let page2 = document.addPage()
        let page3 = document.addPage()
        
        // When
        try! page0.rotate(byAngle: 90)
        try! page1.rotate(byAngle: 810)
        try! page2.rotate(byAngle: -270)
        let returnedDocumentData = document.getData()
        
        // Then
        XCTAssertEqual(expectedDocumentData, returnedDocumentData)
        
        XCTAssertThrowsError(try page3.rotate(byAngle: 45))
    }
    
    // MARK: - Path painting tests
    
    func testPathLineWidth() {
        
        // Given
        let expectedInitialLineWidth: Float = 1
        let expectedLineWidth: Float = 10
        let expectedFinalLineWidth = expectedInitialLineWidth
        
        // When
        var returnedInitialLineWidth: Float = -1
        sut.drawPath { context in
            returnedInitialLineWidth = context.lineWidth
        }
        
        // Then
        XCTAssertEqual(expectedInitialLineWidth, returnedInitialLineWidth)
        
        // When
        var returnedLineWidth: Float = -1
        sut.drawPath { context in
            context.lineWidth = 10
            returnedLineWidth = context.lineWidth
        }
        
        // Then
        XCTAssertEqual(expectedLineWidth, returnedLineWidth)
        
        // When
        var returnedFinalLineWidth: Float = -1
        sut.drawPath { context in
            returnedFinalLineWidth = context.lineWidth
        }
        
        // Then
        XCTAssertEqual(expectedFinalLineWidth, returnedFinalLineWidth)
    }
    
    func testPathMoveDrawingPoint() {
        
        // Given
        let expectedInitialPoint = Point(x: 0, y: 0)
        let expectedPoint = Point(x: 10, y: 20)
        let expectedFinalPoint = expectedInitialPoint
        
        // When
        var returnedInitialPoint = Point(x: -1000, y: -1000)
        sut.drawPath { context in
            returnedInitialPoint = context.currentPosition
        }
        
        // Then
        XCTAssertEqual(expectedInitialPoint, returnedInitialPoint)
        
        // When
        var returnedPoint = Point(x: -1000, y: -1000)
        sut.drawPath { context in
            context.move(to: Point(x: 10, y: 20))
            returnedPoint = context.currentPosition
        }
        
        // Then
        XCTAssertEqual(expectedPoint, returnedPoint)
        
        // When
        var returnedFinalPoint = Point(x: -1000, y: -1000)
        sut.drawPath { context in
            returnedFinalPoint = context.currentPosition
        }
        
        // Then
        XCTAssertEqual(expectedFinalPoint, returnedFinalPoint)
    }
    
    func testStrokeColorRGB() {
        
        // Given
        let expectedStrokeColor = Color(red: 0.1, green: 0.3, blue: 0.5)!
        let expectedColorSpace = PDFColorSpace.deviceRGB
        
        // When
        var returnedStrokeColor = Color(red: 0, green: 0, blue: 0)!
        var returnedColorSpace = PDFColorSpace.undefined
        sut.drawPath { context in
            context.strokeColor = expectedStrokeColor
            returnedStrokeColor = context.strokeColor
            returnedColorSpace = context.strokingColorSpace
        }
        
        // Then
        XCTAssertEqual(expectedStrokeColor, returnedStrokeColor)
        XCTAssertEqual(expectedColorSpace, returnedColorSpace)
    }
    
    func testStrokeColorCMYK() {
        
        // Given
        let expectedStrokeColor = Color(cyan: 0.1, magenta: 0.3, yellow: 0.5, black: 0.7)!
        let expectedColorSpace = PDFColorSpace.deviceCMYK
        
        // When
        var returnedStrokeColor = Color(cyan: 0, magenta: 0, yellow: 0, black: 0)!
        var returnedColorSpace = PDFColorSpace.undefined
        sut.drawPath { context in
            context.strokeColor = expectedStrokeColor
            returnedStrokeColor = context.strokeColor
            returnedColorSpace = context.strokingColorSpace
        }
        
        // Then
        XCTAssertEqual(expectedStrokeColor, returnedStrokeColor)
        XCTAssertEqual(expectedColorSpace, returnedColorSpace)
    }
    
    func testStrokeColorGray() {
        
        // Given
        let expectedStrokeColor = Color(gray: 0.7)!
        let expectedColorSpace = PDFColorSpace.deviceGray
        
        // When
        var returnedStrokeColor = Color(gray: 0)!
        var returnedColorSpace = PDFColorSpace.undefined
        sut.drawPath { context in
            context.strokeColor = expectedStrokeColor
            returnedStrokeColor = context.strokeColor
            returnedColorSpace = context.strokingColorSpace
        }
        
        // Then
        XCTAssertEqual(expectedStrokeColor, returnedStrokeColor)
        XCTAssertEqual(expectedColorSpace, returnedColorSpace)
    }
    
    func testFillColorRGB() {
        
        // Given
        let expectedFillColor = Color(red: 0.1, green: 0.3, blue: 0.5)!
        let expectedColorSpace = PDFColorSpace.deviceRGB
        
        // When
        var returnedFillColor = Color(red: 0, green: 0, blue: 0)!
        var returnedColorSpace = PDFColorSpace.undefined
        sut.drawPath { context in
            context.fillColor = expectedFillColor
            returnedFillColor = context.fillColor
            returnedColorSpace = context.fillingColorSpace
        }
        
        // Then
        XCTAssertEqual(expectedFillColor, returnedFillColor)
        XCTAssertEqual(expectedColorSpace, returnedColorSpace)
    }
    
    func testFillColorCMYK() {
        
        // Given
        let expectedFillColor = Color(cyan: 0.1, magenta: 0.3, yellow: 0.5, black: 0.7)!
        let expectedColorSpace = PDFColorSpace.deviceCMYK
        
        // When
        var returnedFillColor = Color(cyan: 0, magenta: 0, yellow: 0, black: 0)!
        var returnedColorSpace = PDFColorSpace.undefined
        sut.drawPath { context in
            context.fillColor = expectedFillColor
            returnedFillColor = context.fillColor
            returnedColorSpace = context.fillingColorSpace
        }
        
        // Then
        XCTAssertEqual(expectedFillColor, returnedFillColor)
        XCTAssertEqual(expectedColorSpace, returnedColorSpace)
    }
    
    func testFillColorGray() {
        
        // Given
        let expectedFillColor = Color(gray: 0.7)!
        let expectedColorSpace = PDFColorSpace.deviceGray
        
        // When
        var returnedFillColor = Color(gray: 0)!
        var returnedColorSpace = PDFColorSpace.undefined
        sut.drawPath { context in
            context.fillColor = expectedFillColor
            returnedFillColor = context.fillColor
            returnedColorSpace = context.fillingColorSpace
        }
        
        // Then
        XCTAssertEqual(expectedFillColor, returnedFillColor)
        XCTAssertEqual(expectedColorSpace, returnedColorSpace)
    }
    
    func testDrawPathWithoutPainting() {
        
//        recordMode = true
        
        // Given
        let expectedDocumentData = getTestingResource(fromFile: currentTestName, ofType: "pdf")
        let expectedPositionAfterAddingLine1 = Point(x: 10, y: 10)
        let expectedPositionAfterEndingPath = Point(x: 10, y: 20)
        
        // When
        var returnedPositionAfterAddingLine1 = Point.zero
        var returnedPositionAfterEndingPath = Point.zero
        sut.drawPath { context in
            context.move(to: .zero)
            context.line(to: Point(x: 10, y: 10))
            returnedPositionAfterAddingLine1 = context.currentPosition
            context.line(to: Point(x: 10, y: 20))
            context.endPath()
            returnedPositionAfterEndingPath = context.currentPosition
        }
        let returnedDocumentData = document.getData()
        
        // Then
        XCTAssertEqual(expectedPositionAfterAddingLine1, returnedPositionAfterAddingLine1)
        XCTAssertEqual(expectedPositionAfterEndingPath, returnedPositionAfterEndingPath)
        XCTAssertEqual(expectedDocumentData, returnedDocumentData)
    }
}
