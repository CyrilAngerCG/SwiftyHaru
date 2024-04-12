//
//  PDFImage.swift
//  SwiftyHaru
//
//  Created by Cyril Anger on 05.04.24.
//
//

import Foundation
#if SWIFT_PACKAGE
import CLibHaru
#endif

/// A handle to operate on an annotation object.
public final class PDFImage {
    let handle: HPDF_Image
    
    /// Creates a `PDFImage` from its LibHaru handle. Doesn't take the ownership of the handle.
    init(handle: HPDF_Image) {
        self.handle = handle
    }
    
    public var width: Int {
        return Int(HPDF_Image_GetWidth(handle))
    }
    
    public var height: Int {
        return Int(HPDF_Image_GetHeight(handle))
    }
}
