//
//  FontDescriptor.swift
//  SwiftyHaru
//
//  Created by Sergej Jaskiewicz on 07.10.16.
//
//

import Foundation
#if SWIFT_PACKAGE
import CLibHaru
#endif

public struct FontDescriptor: Hashable {
    public var url: URL
    
    public enum Format: Hashable {
        case ttf
        case ttc(Int)
    }
    public var format: Format
    
    public var size: Float
    public func size(_ size: Float) -> Self {
        var descriptor = self
        descriptor.size = size
        return descriptor
    }
    
    public var textLeading: Float
    public func textLeading(_ textLeading: Float) -> Self {
        var descriptor = self
        descriptor.textLeading = textLeading
        return descriptor
    }
    
    public init(url: URL, format: Format, size: Float = DrawingContext.defaultFontSize, textLeading: Float = DrawingContext.defaultTextLeading) {
        self.url = url
        self.format = format
        self.size = size
        self.textLeading = textLeading
    }
}
