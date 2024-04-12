//
//  PDFAnnotation.swift
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
public final class PDFAnnotation {
    let handle: HPDF_Annotation
    
    /// Creates a `PDFAnnotation` from its LibHaru handle. Doesn't take the ownership of the handle.
    init(handle: HPDF_Annotation) {
        self.handle = handle
    }
}
