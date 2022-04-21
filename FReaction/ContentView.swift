//
//  ContentView.swift
//  FReaction
//
//  Created by Mohammed Alsaleh on 20/09/1443 AH.
//

import SwiftUI

struct ContentView: View {
    @State var result = ""
    @State var ShowImagePicker = false
    @State var image : UIImage?
    @Environment(\.colorScheme) var ColorScheme
    var body: some View {
        NavigationView {
        VStack {
            if image != nil {
                Button {
                    self.ShowImagePicker = true
                } label: {
                Image(uiImage: image!)
                        .resizable()
                        .frame(width: 200, height: 200)
                        .cornerRadius(30)
                }
            } else {
                Button {
                    self.ShowImagePicker = true
                } label: {
                    RoundedRectangle(cornerRadius: 30).stroke(lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .overlay(Text("Add Image").font(.largeTitle))
                }
                
            }
            Text("Result : \(result)")
                .font(.title)
            Button {
                self.ML()
            } label: {
                Text("Get Result!!")
                    .bold()
                    .font(.title)
                    .foregroundColor(ColorScheme == .light ? .white : .black)
                    .frame(width: UIScreen.main.bounds.width - 70 , height:  50)
                    .background(RoundedRectangle(cornerRadius: 30).foregroundColor(ColorScheme == .dark ? .white : .black))
            }

        }.navigationTitle("Machine Learning")
        }.navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $ShowImagePicker) {
            ImagePickerView(selectedImage: $image, sourceType: .photoLibrary)
        }
    }
    private func ML() {
        let Model = FaceReaction()
        guard let img = image , let resizeImage = img.scaleImage(toSize: CGSize(width: 299, height: 299)) , let Buffer = resizeImage.ConvertToBuffer() else {
            return
        }
        let output = try? Model.prediction(image: Buffer)
        
        if let output = output {
            self.result = output.classLabel
        }
    }
}

extension UIImage {
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        var newImage: UIImage?
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(cgImage, in: newRect)
            if let img = context.makeImage() {
                newImage = UIImage(cgImage: img)
            }
            UIGraphicsEndImageContext()
        }
        return newImage
    }
    func ConvertToBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            
            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            
            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            return pixelBuffer
        }
        
        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
