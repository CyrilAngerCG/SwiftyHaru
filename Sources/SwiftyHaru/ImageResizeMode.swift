//
//  ImageResizeMode.swift
//  SwiftyHaru
//
//  Created by Sergej Jaskiewicz on 04.06.2017.
//
//

#if SWIFT_PACKAGE
import CLibHaru
#endif

/// The resize mode of image to use in the `DrawingContext.draw(image:in:resizeMode:alignment:)` method.
public enum ImageResizeMode {
    case aspectFit, aspectFill
}
