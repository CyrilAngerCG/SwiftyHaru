//
//  ImageDescriptor.swift
//  SwiftyHaru
//
//  Created by Sergej Jaskiewicz on 07.10.16.
//
//

import Foundation
#if SWIFT_PACKAGE
import CLibHaru
#endif

public struct ImageDescriptor: Hashable {
    public var url: URL
    
    public enum Format: Hashable {
        case jpeg, png
    }
    public var format: Format

    public init(url: URL, format: Format) {
        self.url = url
        self.format = format
    }
}
