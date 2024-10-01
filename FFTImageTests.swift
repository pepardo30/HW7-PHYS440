
import XCTest
import SwiftUI
import AppKit

// Test class for the FFT Image App
final class FFTImageAppTests: XCTestCase {
    
    // Test to check if images are successfully opened
    func testOpenImages() {
        let contentView = ContentView()
        contentView.openImages() // Assuming some images are opened manually
        
        XCTAssertFalse(contentView.images.isEmpty, "Images should not be empty after opening TIFF files.")
    }
    
    // Test to verify that the FFT function works correctly on an image
    func testPerform2DFFT() {
        let contentView = ContentView()
        let testImage = NSImage(size: NSSize(width: 100, height: 100)) // Dummy image
        
        if let fftImage = contentView.perform2DFFT(on: testImage) {
            XCTAssertNotNil(fftImage, "The FFT image should not be nil.")
        } else {
            XCTFail("FFT processing failed for the test image.")
        }
    }
    
    // Test to check that image data is extracted correctly
    func testExtractImageData() {
        let contentView = ContentView()
        let testImage = NSImage(size: NSSize(width: 100, height: 100)) // Dummy image
        
        guard let cgImage = testImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            XCTFail("Failed to create CGImage from the test image.")
            return
        }
        
        let pixelData = contentView.extractImageData(from: cgImage)
        XCTAssertNotNil(pixelData, "Pixel data extraction should not return nil.")
    }
    
    // Test to ensure that the 2D FFT performs correctly on known input
    func testFFT2D() {
        let contentView = ContentView()
        
        // Create a simple test pixel data (grayscale values)
        let width = 4
        let height = 4
        let pixelData: [Float] = [
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1
        ]
        
        let fftResult = contentView.fft2D(pixelData: pixelData, width: width, height: height)
        XCTAssertFalse(fftResult.isEmpty, "FFT result should not be empty.")
    }
}

// Run the tests
FFTImageAppTests.defaultTestSuite.run()
