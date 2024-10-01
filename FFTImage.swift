
import SwiftUI
import AppKit
import Accelerate

struct ContentView: View {
    @State private var images: [NSImage] = []
    @State private var fftImages: [NSImage] = []
    
    var body: some View {
        VStack {
            Text("Image and FFT Viewer").font(.largeTitle).padding()
            
            Button("Open Images") {
                openImages()
            }.padding()
            
            HStack {
                ForEach(0..<images.count, id: \.self) { index in
                    VStack {
                        Text("Original Image \(index + 1)").font(.headline)
                        Image(nsImage: images[index])
                            .resizable()
                            .frame(width: 150, height: 150)
                            .padding()
                        
                        Text("FFT Image \(index + 1)").font(.headline)
                        Image(nsImage: fftImages[index])
                            .resizable()
                            .frame(width: 150, height: 150)
                            .padding()
                    }
                }
            }
        }
    }
    
    // Function to open and load TIFF images
    func openImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = ["tiff"]
        
        if panel.runModal() == .OK {
            let selectedFiles = panel.urls
            images = selectedFiles.compactMap { NSImage(contentsOf: $0) }
            
            // Extract image data and perform FFT
            fftImages = images.compactMap { image in
                if let fftImage = perform2DFFT(on: image) {
                    return fftImage
                }
                return nil
            }
        }
    }
    
    // Function to extract image data and perform 2D FFT
    func perform2DFFT(on image: NSImage) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard let pixelData = extractImageData(from: cgImage) else {
            return nil
        }
        
        // Perform 2D FFT using Accelerate
        let fftData = fft2D(pixelData: pixelData, width: width, height: height)
        
        // Convert FFT result into an image and return it
        return imageFromArray(fftData, width: width, height: height)
    }
    
    // Function to extract image data (grayscale)
    func extractImageData(from image: CGImage) -> [Float]? {
        let width = image.width
        let height = image.height
        
        var pixelData = [Float](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        
        guard let ctx = context else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        return pixelData
    }
    
    // Function to perform 2D FFT
    func fft2D(pixelData: [Float], width: Int, height: Int) -> [Float] {
        var real = pixelData
        var imaginary = [Float](repeating: 0.0, count: width * height)
        
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imaginary)
        
        let log2Width = vDSP_Length(log2(Float(width)))
        let log2Height = vDSP_Length(log2(Float(height)))
        
        let fftSetup = vDSP_create_fftsetupD(log2Width, FFTRadix(kFFTRadix2))
        
        vDSP_fft2d_zipD(fftSetup!, &splitComplex, 1, 0, log2Width, log2Height, FFTDirection(FFT_FORWARD))
        
        vDSP_destroy_fftsetupD(fftSetup!)
        
        // Compute magnitude of the FFT
        var magnitude = [Float](repeating: 0.0, count: width * height)
        vDSP_zvmags(&splitComplex, 1, &magnitude, 1, vDSP_Length(width * height))
        
        // Normalize magnitude
        var normalizedMagnitude = [Float](repeating: 0.0, count: width * height)
        var maxMag: Float = 0.0
        vDSP_maxv(magnitude, 1, &maxMag, vDSP_Length(width * height))
        vDSP_vsdiv(magnitude, 1, &maxMag, &normalizedMagnitude, 1, vDSP_Length(width * height))
        
        return normalizedMagnitude
    }
    
    // Convert FFT data (magnitude) back to an image
    func imageFromArray(_ data: [Float], width: Int, height: Int) -> NSImage? {
        let byteData = data.map { UInt8($0 * 255.0) } // Convert to grayscale
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        guard let provider = CGDataProvider(data: Data(byteData) as CFData) else { return nil }
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}

@main
struct FFTImageApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
