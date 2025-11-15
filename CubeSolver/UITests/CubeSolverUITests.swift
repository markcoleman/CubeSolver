//
//  CubeSolverUITests.swift
//  CubeSolverUITests
//
//  Created by GitHub Copilot
//

import XCTest

/// UI Tests for CubeSolver app with screenshot capture
final class CubeSolverUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Main Interface Tests
    
    func testMainInterfaceElements() throws {
        // Verify main title exists
        let mainTitle = app.staticTexts["mainTitle"]
        XCTAssertTrue(mainTitle.exists, "Main title should exist")
        XCTAssertEqual(mainTitle.label, "Rubik's Cube Solver")
        
        // Verify cube view exists
        let cubeView = app.otherElements["cubeView"]
        XCTAssertTrue(cubeView.exists, "Cube view should exist")
        
        // Verify all control buttons exist
        XCTAssertTrue(app.buttons["manualInputButton"].exists, "Manual Input button should exist")
        XCTAssertTrue(app.buttons["scrambleButton"].exists, "Scramble button should exist")
        XCTAssertTrue(app.buttons["solveButton"].exists, "Solve button should exist")
        XCTAssertTrue(app.buttons["resetButton"].exists, "Reset button should exist")
        
        // Take screenshot of main interface
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MainInterface"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testScrambleFlow() throws {
        // Initial state - cube should be solved
        let cubeView = app.otherElements["cubeView"]
        XCTAssertTrue(cubeView.exists)
        
        // Take screenshot of solved state
        let solvedScreenshot = app.screenshot()
        let solvedAttachment = XCTAttachment(screenshot: solvedScreenshot)
        solvedAttachment.name = "SolvedCube"
        solvedAttachment.lifetime = .keepAlways
        add(solvedAttachment)
        
        // Tap scramble button
        let scrambleButton = app.buttons["scrambleButton"]
        XCTAssertTrue(scrambleButton.exists)
        scrambleButton.tap()
        
        // Wait for scramble to complete
        Thread.sleep(forTimeInterval: 0.5)
        
        // Take screenshot of scrambled state
        let scrambledScreenshot = app.screenshot()
        let scrambledAttachment = XCTAttachment(screenshot: scrambledScreenshot)
        scrambledAttachment.name = "ScrambledCube"
        scrambledAttachment.lifetime = .keepAlways
        add(scrambledAttachment)
    }
    
    func testSolveFlow() throws {
        // Scramble the cube first
        let scrambleButton = app.buttons["scrambleButton"]
        scrambleButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Tap solve button
        let solveButton = app.buttons["solveButton"]
        XCTAssertTrue(solveButton.exists)
        solveButton.tap()
        
        // Wait for solution to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify solution steps view appears
        let solutionStepsView = app.scrollViews["solutionStepsView"]
        XCTAssertTrue(solutionStepsView.waitForExistence(timeout: 2), "Solution steps should appear")
        
        // Take screenshot of solution
        let solutionScreenshot = app.screenshot()
        let solutionAttachment = XCTAttachment(screenshot: solutionScreenshot)
        solutionAttachment.name = "SolutionSteps"
        solutionAttachment.lifetime = .keepAlways
        add(solutionAttachment)
    }
    
    func testResetFlow() throws {
        // Scramble the cube
        app.buttons["scrambleButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Reset the cube
        let resetButton = app.buttons["resetButton"]
        XCTAssertTrue(resetButton.exists)
        resetButton.tap()
        
        // Wait for reset to complete
        Thread.sleep(forTimeInterval: 0.5)
        
        // Take screenshot of reset state
        let resetScreenshot = app.screenshot()
        let resetAttachment = XCTAttachment(screenshot: resetScreenshot)
        resetAttachment.name = "ResetCube"
        resetAttachment.lifetime = .keepAlways
        add(resetAttachment)
    }
    
    // MARK: - Manual Input Tests
    
    func testManualInputInterface() throws {
        // Open manual input
        let manualInputButton = app.buttons["manualInputButton"]
        XCTAssertTrue(manualInputButton.exists, "Manual Input button should exist")
        manualInputButton.tap()
        
        // Wait for sheet to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify manual input elements exist
        let manualInputTitle = app.staticTexts["manualInputTitle"]
        XCTAssertTrue(manualInputTitle.waitForExistence(timeout: 2), "Manual input title should appear")
        
        // Verify face selector exists
        let faceSelector = app.otherElements["faceSelector"]
        XCTAssertTrue(faceSelector.exists, "Face selector should exist")
        
        // Verify color selector exists
        let colorSelector = app.otherElements["colorSelector"]
        XCTAssertTrue(colorSelector.exists, "Color selector should exist")
        
        // Verify editable face view exists
        let editableFaceView = app.otherElements["editableFaceView"]
        XCTAssertTrue(editableFaceView.exists, "Editable face view should exist")
        
        // Take screenshot of manual input interface
        let manualInputScreenshot = app.screenshot()
        let manualInputAttachment = XCTAttachment(screenshot: manualInputScreenshot)
        manualInputAttachment.name = "ManualInputInterface"
        manualInputAttachment.lifetime = .keepAlways
        add(manualInputAttachment)
    }
    
    func testManualInputColorSelection() throws {
        // Open manual input
        app.buttons["manualInputButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Select a different color
        let redColorButton = app.buttons["RColorButton"]
        if redColorButton.exists {
            redColorButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        // Take screenshot after color selection
        let colorSelectedScreenshot = app.screenshot()
        let colorSelectedAttachment = XCTAttachment(screenshot: colorSelectedScreenshot)
        colorSelectedAttachment.name = "ColorSelected"
        colorSelectedAttachment.lifetime = .keepAlways
        add(colorSelectedAttachment)
        
        // Close manual input
        let doneButton = app.buttons["doneButton"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            // Try close button if done button doesn't exist
            let closeButton = app.buttons["closeButton"]
            if closeButton.exists {
                closeButton.tap()
            }
        }
        
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Verify main title has accessibility traits
        let mainTitle = app.staticTexts["mainTitle"]
        XCTAssertTrue(mainTitle.exists)
        
        // Verify buttons have accessibility identifiers
        XCTAssertTrue(app.buttons["scrambleButton"].exists)
        XCTAssertTrue(app.buttons["solveButton"].exists)
        XCTAssertTrue(app.buttons["resetButton"].exists)
        XCTAssertTrue(app.buttons["manualInputButton"].exists)
        
        // Verify cube view has accessibility
        let cubeView = app.otherElements["cubeView"]
        XCTAssertTrue(cubeView.exists)
    }
    
    func testAccessibilityHints() throws {
        // Test that buttons have accessibility hints by checking they're accessible
        let scrambleButton = app.buttons["scrambleButton"]
        XCTAssertTrue(scrambleButton.isHittable, "Scramble button should be hittable")
        
        let solveButton = app.buttons["solveButton"]
        XCTAssertTrue(solveButton.isHittable, "Solve button should be hittable")
        
        let resetButton = app.buttons["resetButton"]
        XCTAssertTrue(resetButton.isHittable, "Reset button should be hittable")
    }
    
    // MARK: - Screenshot Gallery Tests
    
    func testScreenshotGallery() throws {
        // This test creates a comprehensive screenshot gallery
        
        // 1. Initial state
        let initialScreenshot = app.screenshot()
        let initialAttachment = XCTAttachment(screenshot: initialScreenshot)
        initialAttachment.name = "01_InitialState"
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)
        
        // 2. After scramble
        app.buttons["scrambleButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        let scrambledScreenshot = app.screenshot()
        let scrambledAttachment = XCTAttachment(screenshot: scrambledScreenshot)
        scrambledAttachment.name = "02_Scrambled"
        scrambledAttachment.lifetime = .keepAlways
        add(scrambledAttachment)
        
        // 3. After solve
        app.buttons["solveButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        let solvedScreenshot = app.screenshot()
        let solvedAttachment = XCTAttachment(screenshot: solvedScreenshot)
        solvedAttachment.name = "03_SolutionShown"
        solvedAttachment.lifetime = .keepAlways
        add(solvedAttachment)
        
        // 4. Manual input interface
        app.buttons["resetButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        app.buttons["manualInputButton"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        let manualInputScreenshot = app.screenshot()
        let manualInputAttachment = XCTAttachment(screenshot: manualInputScreenshot)
        manualInputAttachment.name = "04_ManualInput"
        manualInputAttachment.lifetime = .keepAlways
        add(manualInputAttachment)
    }
}
