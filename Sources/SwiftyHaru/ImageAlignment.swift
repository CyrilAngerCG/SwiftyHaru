//
//  ImageAlignment.swift
//  SwiftyHaru
//
//  Created by Sergej Jaskiewicz on 04.06.2017.
//
//

#if SWIFT_PACKAGE
import CLibHaru
#endif

/// The alignment of image to use in the `DrawingContext.draw(image:in:resizeMode:alignment:)` method.
public enum ImageAlignment {
    case topLeading, top, topTrailing
    case leading, center, trailing
    case bottomLeading, bottom, bottomTrailing
}
