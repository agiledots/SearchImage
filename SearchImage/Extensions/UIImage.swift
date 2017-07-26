//
//  UIImage.swift
//  SearchImage
//
//  Created by LU XIAOQUAN on 2017/07/26.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit


extension UIImage {
    
    func adjust() -> UIImage {
        
        if let ciImage = CIImage(image: self) {
            let filter1 = CIFilter(name: "CIColorMonochrome")
            filter1?.setValue(ciImage, forKey: kCIInputImageKey)
            filter1?.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: "inputColor")
            filter1?.setValue(NSNumber(floatLiteral: 1.0), forKey: "inputIntensity")
            
            
            let filter2 = CIFilter(name: "CIColorControls")
            filter2?.setValue(filter1?.outputImage, forKey: kCIInputImageKey)
            filter2?.setValue(NSNumber(floatLiteral: 0.0), forKey: "inputSaturation")
            filter2?.setValue(NSNumber(floatLiteral: -1.0), forKey: "inputBrightness")
            filter2?.setValue(NSNumber(floatLiteral: 4.0), forKey: "inputContrast")
            

            let filter3 = CIFilter(name: "CIUnsharpMask")
            filter3?.setValue(filter2?.outputImage, forKey: kCIInputImageKey)
            filter3?.setValue(NSNumber(floatLiteral: 2.5), forKey: "inputRadius")
            filter3?.setValue(NSNumber(floatLiteral: 0.5), forKey: "inputIntensity")
            
            
            let context = CIContext()
            let cgImage = context.createCGImage((filter3?.outputImage)!, from: (filter3?.outputImage?.extent)!)
            
            return UIImage(cgImage: cgImage!)
        }
        
        return self
    }
    
    
}
