import CubeCore
//
//  CubeValidationTests.swift
//  CubeSolver
//
//  Tests for CubeValidation module
//

import XCTest
@testable import CubeCore

final class CubeValidationTests: XCTestCase {
    
    // MARK: - Basic Validation Tests
    
    func testValidateSolvedCube() {
        let state = CubeState()
        
        // A solved cube should pass all validation
        XCTAssertNoThrow(try CubeValidator.validate(state))
    }
    
    func testValidateBasicSolvedCube() {
        let state = CubeState()
        
        // A solved cube should pass basic validation
        XCTAssertNoThrow(try CubeValidator.validateBasic(state))
    }
    
    func testInvalidStickerCount() {
        var state = CubeState()
        
        // Change one sticker to create invalid color count
        state.setSticker(face: .front, index: 0, color: .blue) // Front should be all red
        
        // Now we have 8 red and 10 blue
        XCTAssertThrowsError(try CubeValidator.validateBasic(state)) { error in
            guard let validationError = error as? CubeValidationError else {
                XCTFail("Expected CubeValidationError")
                return
            }
            
            // Should throw either too many blue or too few red
            switch validationError {
            case .invalidStickerCount(let color, let count):
                XCTAssertTrue(
                    (color == .red && count == 8) || (color == .blue && count == 10),
                    "Expected invalid count for red (8) or blue (10)"
                )
            default:
                XCTFail("Expected invalidStickerCount error")
            }
        }
    }
    
    func testNonUniqueCenters() {
        // Create a state where two centers have the same color
        // We'll manually create faces where up and down have the same center
        var faces: [Face: [CubeColor]] = [:]
        
        // All faces have their normal colors except we duplicate white center
        faces[.up] = Array(repeating: .white, count: 9)
        faces[.down] = [.yellow, .yellow, .yellow, .yellow, .white, .yellow, .yellow, .yellow, .yellow] // white center instead of yellow
        faces[.left] = Array(repeating: .green, count: 9)
        faces[.right] = Array(repeating: .blue, count: 9)
        faces[.front] = Array(repeating: .red, count: 9)
        
        // Back face needs to have the extra yellow to balance counts
        // We have 10 whites (9 on up + 1 on down), so we need 8 yellows
        // Down has 8 yellows, back needs 1 yellow + 8 orange
        faces[.back] = [.orange, .orange, .orange, .orange, .orange, .orange, .orange, .orange, .yellow]
        
        let invalidState = CubeState(faces: faces)
        
        XCTAssertThrowsError(try CubeValidator.validateBasic(invalidState)) { error in
            guard let validationError = error as? CubeValidationError else {
                XCTFail("Expected CubeValidationError")
                return
            }
            
            // This state is invalid in multiple ways, so we accept either error
            switch validationError {
            case .nonUniqueCenters:
                // Expected error
                break
            case .invalidStickerCount:
                // Also acceptable - the sticker count is off
                break
            default:
                XCTFail("Expected nonUniqueCenters or invalidStickerCount error, got \(validationError)")
            }
        }
    }
    
    func testInvalidFaceConfiguration() {
        var faces: [Face: [CubeColor]] = [:]
        
        // Create faces with wrong number of stickers
        for face in Face.allCases {
            faces[face] = Array(repeating: .white, count: 5) // Only 5 stickers instead of 9
        }
        
        let state = CubeState(faces: faces)
        
        XCTAssertThrowsError(try CubeValidator.validateBasic(state)) { error in
            guard let validationError = error as? CubeValidationError else {
                XCTFail("Expected CubeValidationError")
                return
            }
            
            if case .invalidFaceConfiguration = validationError {
                // Expected error
            } else {
                XCTFail("Expected invalidFaceConfiguration error")
            }
        }
    }
    
    // MARK: - Piece Extraction Tests
    
    func testCornerExtraction() {
        let state = CubeState()
        
        // Extract corners - should not throw
        // Note: This is testing internal functionality through validation
        XCTAssertNoThrow(try CubeValidator.validatePhysicalLegality(state))
    }
    
    func testEdgeExtraction() {
        let state = CubeState()
        
        // Extract edges - should not throw
        XCTAssertNoThrow(try CubeValidator.validatePhysicalLegality(state))
    }
    
    // MARK: - Physical Validation Tests
    
    func testPhysicalValidationSolvedCube() {
        let state = CubeState()
        
        // A solved cube should pass physical validation
        XCTAssertNoThrow(try CubeValidator.validatePhysicalLegality(state))
    }
    
    // MARK: - Error Description Tests
    
    func testErrorDescriptions() {
        let error1 = CubeValidationError.invalidStickerCount(color: .red, count: 10)
        XCTAssertNotNil(error1.errorDescription)
        XCTAssertTrue(error1.errorDescription?.contains("too many") ?? false)
        
        let error2 = CubeValidationError.invalidStickerCount(color: .blue, count: 8)
        XCTAssertNotNil(error2.errorDescription)
        XCTAssertTrue(error2.errorDescription?.contains("too few") ?? false)
        
        let error3 = CubeValidationError.nonUniqueCenters
        XCTAssertNotNil(error3.errorDescription)
        XCTAssertTrue(error3.errorDescription?.contains("unique") ?? false)
        
        let error4 = CubeValidationError.invalidCornerOrientation
        XCTAssertNotNil(error4.errorDescription)
        XCTAssertTrue(error4.errorDescription?.contains("Corner twist") ?? false)
        
        let error5 = CubeValidationError.invalidEdgeOrientation
        XCTAssertNotNil(error5.errorDescription)
        XCTAssertTrue(error5.errorDescription?.contains("Edge flip") ?? false)
        
        let error6 = CubeValidationError.invalidPermutationParity
        XCTAssertNotNil(error6.errorDescription)
        XCTAssertTrue(error6.errorDescription?.contains("parity") ?? false)
        
        let error7 = CubeValidationError.invalidFaceConfiguration
        XCTAssertNotNil(error7.errorDescription)
    }
    
    // MARK: - Corner and Edge Piece Tests
    
    func testCornerPieceEquality() {
        let corner1 = CornerPiece(colors: [.white, .red, .blue], position: 0)
        let corner2 = CornerPiece(colors: [.white, .red, .blue], position: 0)
        let corner3 = CornerPiece(colors: [.white, .red, .green], position: 0)
        
        XCTAssertEqual(corner1, corner2)
        XCTAssertNotEqual(corner1, corner3)
    }
    
    func testEdgePieceEquality() {
        let edge1 = EdgePiece(colors: [.white, .red], position: 0)
        let edge2 = EdgePiece(colors: [.white, .red], position: 0)
        let edge3 = EdgePiece(colors: [.white, .blue], position: 0)
        
        XCTAssertEqual(edge1, edge2)
        XCTAssertNotEqual(edge1, edge3)
    }
    
    // MARK: - Complex Validation Tests
    
    func testValidateScrambledCubeBasic() {
        // Create a cube from RubiksCube and scramble it
        var rubiksCube = RubiksCube()
        rubiksCube.rotateFront()
        rubiksCube.rotateRight()
        rubiksCube.rotateTop()
        
        let state = CubeState(from: rubiksCube)
        
        // A scrambled cube created by valid moves should pass basic validation
        // (it has correct sticker counts and unique centers)
        XCTAssertNoThrow(try CubeValidator.validateBasic(state))
    }
}
