//
//  DrawingContext.swift
//  SwiftyHaru
//
//  Created by Sergej Jaskiewicz on 02.10.16.
//
//

#if SWIFT_PACKAGE
import CLibHaru
#endif
import Foundation

/// The `DrawingContext` class represents a PDF drawing destination.
///
/// You cannot initialize the context directly. You need to call the `PDFDocument.addPage(_:)` method; an instance
/// of `DrawingContext` will be passed to the provided closure. That instance is only valid during the lifetime
/// of that closure.
///
/// Each instance of `DrawingContext` is bound to some `PDFPage`, hence you can use it to perform
/// drawing operations on only one page.
public final class DrawingContext {

    /// The page this context is bound to.
    public let page: PDFPage

    private let _document: PDFDocument
    internal var _isInvalidated = false

    private var _documentHandle: HPDF_Doc {
        return _document._documentHandle
    }

    private var _page: HPDF_Page {
        precondition(
            !_isInvalidated,
            """
            The context is invalidated. It is possible that it is being used outside of the closure it has been \
            passed to.
            """
        )
        return page._pageHandle
    }

    internal init(page: PDFPage, document: PDFDocument) {
        self.page = page
        _document = document
    }

    /// Puts the `drawable` visualization onto the page at the specified position.
    ///
    /// - parameter drawable: The entity to draw.
    /// - parameter position: The position to put the `drawable` at. The meaning of this property depends
    ///                       on the `drawable`'s implementation.
    @inlinable
    public func draw(_ drawable: Drawable, position: Point) throws {
        try drawable.draw(in: self, position: position)
    }

    /// Puts the `drawable` visualization onto the page at the specified position.
    ///
    /// - parameter drawable: The entity to draw.
    /// - parameter x:        The x coordinate of the position to put the `drawable` at.
    /// - parameter y:        The y coordinate of the position.
    @inlinable
    public func draw(_ drawable: Drawable, x: Float, y: Float) throws {
        try draw(drawable, position: Point(x: x, y: y))
    }
    
    // MARK: - Graphics state

    /// The default line width.
    public static let defaultLineWidth = Float(HPDF_DEF_LINEWIDTH)
    
    /// The current line width for path painting of the page. Must be nonegative.
    /// Default value is `DrawingContext.defaultLineWidth`.
    public var lineWidth: Float {
        get {
            return HPDF_Page_GetLineWidth(_page)
        }
        set {
            precondition(newValue >= 0, "Line width must be nonnegative")
            HPDF_Page_SetLineWidth(_page, newValue)
        }
    }
    
    /// The dash pattern for lines in the page. Default value is `DashStyle.straightLine`.
    public var dashStyle: DashStyle {
        get {
            return DashStyle(HPDF_Page_GetDash(_page))
        }
        set {
            let pattern = newValue.pattern.map(UInt16.init(_:))
            HPDF_Page_SetDash(_page,
                              pattern,
                              HPDF_UINT(pattern.count),
                              HPDF_UINT(pattern.isEmpty ? 0 : newValue.phase))
        }
    }
    
    /// The shape to be used at the ends of lines. Default value is `LineCap.butt`.
    public var lineCap: LineCap {
        get {
            return LineCap(HPDF_Page_GetLineCap(_page))
        }
        set {
            HPDF_Page_SetLineCap(_page, HPDF_LineCap(rawValue: newValue.rawValue))
        }
    }
    
    /// The line join style in the page. Default value is `LineJoin.miter`.
    public var lineJoin: LineJoin {
        get {
            return LineJoin(HPDF_Page_GetLineJoin(_page))
        }
        set {
            HPDF_Page_SetLineJoin(_page, HPDF_LineJoin(rawValue: newValue.rawValue))
        }
    }

    /// The default miter limit for the joins of connected lines.
    public static let defaultMiterLimit = Float(HPDF_DEF_MITERLIMIT)
    
    /// The miter limit for the joins of connected lines. Minimum value is 1.
    /// Default value is `DrawingContext.defaultMiterLimit`.
    public var miterLimit: Float {
        get {
            return HPDF_Page_GetMiterLimit(_page)
        }
        set {
            precondition(newValue >= 1, "The minimum value of miterLimit is 1.0.")
            HPDF_Page_SetMiterLimit(_page, newValue)
        }
    }
    
    /// The number of the page's graphics state stack.
    ///
    /// This number is increased whenever you call `withNewGState(_:)` or
    /// `clip(to:rule:_:)` and decreased as soon as such a function returns.
    ///
    /// The value of this property must not be greater than `DrawingContext.maxGraphicsStateDepth`.
    public var graphicsStateDepth: Int {
        return Int(HPDF_Page_GetGStateDepth(_page))
    }
    
    /// The maximum depth of the graphics state stack.
    public static let maxGraphicsStateDepth = Int(HPDF_LIMIT_MAX_GSTATE)

    /// Saves the page's current graphics state to the stack, then executes `body`,
    /// then restores the saved graphics state.
    ///
    /// - Precondition: The value of `graphicsStateDepth` must be less than
    ///                 `static DrawingContext.maxGraphicsStateDepth`.
    ///
    /// - Important: Inside the provided block the value of `graphicsStateDepth` is incremented.
    ///              Check it to prevent the precondition failure.
    ///
    /// The parameters that are saved at the beginning of the call and restored at the end are:
    ///
    ///    - Character Spacing
    ///    - Clipping Path
    ///    - Dash Mode
    ///    - Filling Color
    ///    - Flatness
    ///    - Font
    ///    - Font Size
    ///    - Horizontal Scalling
    ///    - Line Width
    ///    - Line Cap Style
    ///    - Line Join Style
    ///    - Miter Limit
    ///    - Rendering Mode
    ///    - Stroking Color
    ///    - Text Leading
    ///    - Text Rise
    ///    - Transformation Matrix
    ///    - Word Spacing
    ///
    ///
    /// Example:
    /// ```swift
    /// assert(context.fillColor == .red)
    ///
    /// try context.withNewGState {
    ///
    ///    context.fillColor = .blue
    ///    assert(context.fillColor == .blue)
    /// }
    ///
    /// assert(context.fillColor == .red)
    /// ```
    ///
    /// - Parameter body: The code to execute using a new graphics state.
    ///                   rethrows errors thrown by `body`.
    public func withNewGState(_ body: () throws -> Void) rethrows {
        
        let status = HPDF_Page_GSave(_page)
        
        precondition(
            status == UInt(HPDF_OK),
            "The graphics state stack depth must not be greater than `DrawingContext.maxGraphicsStateDepth`."
        )

        currentFontDescriptor = nil

        try body()

        currentFontDescriptor = nil

        HPDF_Page_GRestore(_page)
    }
    
    // MARK: Transforms
    
    /// The transformation matrix for the current graphics state
    public var currentTransform: AffineTransform {
        return AffineTransform(HPDF_Page_GetTransMatrix(_page))
    }
    
    /// Rotates the coordinate system of the page.
    ///
    /// You can call this method inside the `withNewGState(_:)` block, thereby being able to use the
    /// old coordinate system after `withNewGState(_:)` returns.
    ///
    /// - Parameter angle: The angle, in radians, by which to rotate the coordinate space.
    ///                    Positive values rotate counterclockwise and negative values rotate clockwise.
    @inlinable
    public func rotate(byAngle angle: Float) {
        concatenate(AffineTransform(rotationAngle: angle))
    }
    
    /// Changes the scale of the coordinate system of the page.
    ///
    /// For example, to change the coordinate system of the page to 300 dpi:
    /// ```swift
    /// context.scale(byX: 72.0 / 300.0, y: 72.0 / 300)
    /// ```
    ///
    /// You can call this method inside the `withNewGState(_:)` block, thereby being able to use the
    /// old coordinate system after `withNewGState(_:)` returns.
    ///
    /// - Parameters:
    ///   - sx: The factor by which to scale the x-axis of the coordinate space.
    ///   - sy: The factor by which to scale the y-axis of the coordinate space.
    @inlinable
    public func scale(byX sx: Float, y sy: Float) {
        concatenate(AffineTransform(scaleX: sx, y: sy))
    }
    
    /// Changes the origin of the coordinate system of the page.
    ///
    /// You can call this method inside the `withNewGState(_:)` block, thereby being able to use the
    /// old coordinate system after `withNewGState(_:)` returns.
    ///
    /// - Parameters:
    ///   - tx: The amount to displace the x-axis of the coordinate space.
    ///   - ty: The amount to displace the y-axis of the coordinate space.
    @inlinable
    public func translate(byX tx: Float, y ty: Float) {
        concatenate(AffineTransform(translationX: tx, y: ty))
    }
    
    /// Concatenates the page's current transformation matrix and the specified matrix.
    ///
    /// When you call this function, it concatenates (that is, it combines) two matrices,
    /// by multiplying them together. The order in which matrices are concatenated is important,
    /// as the operations are not commutative.
    ///
    /// You can call this method inside the `withNewGState(_:)` block, thereby being able to use the
    /// old coordinate system after `withNewGState(_:)` returns.
    ///
    /// - Parameter transform: The transformation to apply to the page's current transformation.
    public func concatenate(_ transform: AffineTransform) {
        HPDF_Page_Concat(_page, transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty)
    }
    
    // MARK: - Color
    
    /// The current value of the page's stroking color space. Default value is `PDFColorSpace.deviceGray`
    public var strokingColorSpace: PDFColorSpace {
        return PDFColorSpace(haruEnum: HPDF_Page_GetStrokingColorSpace(_page))
    }
    
    /// The current value of the page's filling color space. Default value is `PDFColorSpace.deviceGray`
    public var fillingColorSpace: PDFColorSpace {
        return PDFColorSpace(haruEnum: HPDF_Page_GetFillingColorSpace(_page))
    }
    
    /// The current value of the page's stroking color. Default is black in the `deviceGray` color space.
    public var strokeColor: Color {
        get {
            switch strokingColorSpace {
            case .deviceRGB:
                return Color(HPDF_Page_GetRGBStroke(_page))
            case .deviceCMYK:
                return Color(HPDF_Page_GetCMYKStroke(_page))
            case .deviceGray:
                return Color(gray: HPDF_Page_GetGrayStroke(_page))!
            default:
                return .white
            }
        }
        set {
            switch newValue._wrapped {
            case .cmyk(let color):
                HPDF_Page_SetCMYKStroke(_page,
                                        color.cyan,
                                        color.magenta,
                                        color.yellow,
                                        color.black)

            case .rgb(let color):
                HPDF_Page_SetRGBStroke(_page,
                                       color.red,
                                       color.green,
                                       color.blue)
            case .gray(let color):
                HPDF_Page_SetGrayStroke(_page, color)
            }

            // Alpha
            let state = HPDF_CreateExtGState(_documentHandle)
            HPDF_ExtGState_SetAlphaStroke(state, newValue.alpha)
            HPDF_Page_SetExtGState(_page, state)
        }
    }
    
    /// The current value of the page's filling color. Default is black in the `deviceGray` color space.
    public var fillColor: Color {
        get {
            switch fillingColorSpace {
            case .deviceRGB:
                return Color(HPDF_Page_GetRGBFill(_page))
            case .deviceCMYK:
                return Color(HPDF_Page_GetCMYKFill(_page))
            case .deviceGray:
                return Color(gray: HPDF_Page_GetGrayFill(_page))!
            default:
                return .white
            }
        }
        set {
            switch newValue._wrapped {
            case .cmyk(let color):
                HPDF_Page_SetCMYKFill(_page,
                                      color.cyan,
                                      color.magenta,
                                      color.yellow,
                                      color.black)
            case .rgb(let color):
                HPDF_Page_SetRGBFill(_page,
                                     color.red,
                                     color.green,
                                     color.blue)
            case .gray(let color):
                HPDF_Page_SetGrayFill(_page, color)
            }

            // Alpha
            let state = HPDF_CreateExtGState(_documentHandle)
            HPDF_ExtGState_SetAlphaFill(state, newValue.alpha)
            HPDF_Page_SetExtGState(_page, state)
        }
    }
    
    
    // MARK: - Path construction
    
    // In LibHaru we use state maching to switch between construction state and general state.
    // In SwiftyHaru calling path construction methods defers actual construction operations
    // until the moment the path is about to be drawn. It makes it easier for the end user.
    
    private func _construct(_ path: Path) {
        
        for operation in path._pathConstructionSequence {
            
            switch operation {
            case .moveTo(let point):
                HPDF_Page_MoveTo(_page, point.x, point.y)
            case .lineTo(let point):
                HPDF_Page_LineTo(_page, point.x, point.y)
            case .closePath:
                HPDF_Page_ClosePath(_page)
            case .arc(let center, let radius, let beginningAngle, let endAngle):
                HPDF_Page_Arc(_page, center.x, center.y, radius, beginningAngle, endAngle)
            case .circle(let center, let radius):
                HPDF_Page_Circle(_page, center.x, center.y, radius)
            case .rectangle(let rectangle):
                HPDF_Page_Rectangle(_page,
                                    rectangle.origin.x, rectangle.origin.y,
                                    rectangle.width, rectangle.height)
            case .curve(let controlPoint1, let controlPoint2, let endPoint):
                HPDF_Page_CurveTo(_page,
                                  controlPoint1.x, controlPoint1.y,
                                  controlPoint2.x, controlPoint2.y,
                                  endPoint.x, endPoint.y)
            case .curve2(let controlPoint2, let endPoint):
                HPDF_Page_CurveTo2(_page, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y)
            case .curve3(let controlPoint1, let endPoint):
                HPDF_Page_CurveTo3(_page, controlPoint1.x, controlPoint1.y, endPoint.x, endPoint.y)
            case .ellipse(let center, let xRadius, let yRadius):
                HPDF_Page_Ellipse(_page, center.x, center.y, xRadius, yRadius)
            }
        }
        
        assert(path.currentPosition.x - HPDF_Page_GetCurrentPos(_page).x < 0.001 &&
               path.currentPosition.y - HPDF_Page_GetCurrentPos(_page).y < 0.001,
               """
               The value of property `currentPosition` (\(path.currentPosition)) is not equal to \
               the value returned from the function \
               `HPDF_Page_GetCurrentPos` (\(HPDF_Page_GetCurrentPos(_page)))
               """)
        
        HPDF_Page_MoveTo(_page, 0, 0)
    }
    
    // MARK: - Path painting
    
    /// Sets the clipping area for drawing.
    ///
    /// - Precondition: The value of `graphicsStateDepth` must be less than
    ///                 `static DrawingContext.maxGraphicsStateDepth`.
    ///
    /// - Important: Inside the provided block the value of `graphicsStateDepth` is incremented.
    ///              Check it to prevent the precondition failure.
    ///
    /// - Important: Graphics parameters that are set inside the `drawInsideClippingArea` closure do not
    ///              persist outside the call of that closure. I. e. if, for example, the context's fill color
    ///              had been black
    ///              and then was set to red inside the `drawInsideClippingArea` closure, after the closure
    ///              returns it is black again.
    ///
    /// - parameter path:                   The path that constraints the clipping area. Must be closed.
    /// - parameter rule:                   The rule for determining which areas to treat as the interior
    ///                                     of the path. Default value is `.winding`.
    /// - parameter drawInsideClippingArea: All that is drawn inside this closure is clipped to the
    ///                                     provided `path`.
    public func clip(to path: Path, rule: Path.FillRule = .winding,
                     _ drawInsideClippingArea: () throws -> Void) rethrows {
        
        try withNewGState {
            
            _construct(path)
            
            HPDF_Page_ClosePath(_page)
            
            switch rule {
            case .evenOdd:
                HPDF_Page_Eoclip(_page)
            case .winding:
                HPDF_Page_Clip(_page)
            }
            
            HPDF_Page_EndPath(_page)
            
            try drawInsideClippingArea()
        }
    }
    
    /// Fills the `path`.
    ///
    /// - parameter path:        The path to fill.
    /// - parameter rule:        The rule for determining which areas to treat as the interior
    ///                          of the path. Default value is `.winding`.
    /// - parameter stroke:      If specified `true`, also paints the path itself. Default value is `false`.
    public func fill(_ path: Path, rule: Path.FillRule = .winding, stroke: Bool = false) {
        
        assert(Int32(HPDF_Page_GetGMode(_page)) == HPDF_GMODE_PAGE_DESCRIPTION)
        
        _construct(path)
        
        assert(Int32(HPDF_Page_GetGMode(_page)) == HPDF_GMODE_PATH_OBJECT)
        
        switch (rule, stroke) {
        case (.evenOdd, true):
            HPDF_Page_EofillStroke(_page)
        case (.evenOdd, false):
            HPDF_Page_Eofill(_page)
        case (.winding, true):
            HPDF_Page_FillStroke(_page)
        case (.winding, false):
            HPDF_Page_Fill(_page)
        }
        
        assert(Int32(HPDF_Page_GetGMode(_page)) == HPDF_GMODE_PAGE_DESCRIPTION)
    }
    
    /// Paints the `path`.
    ///
    /// - parameter path: The path to paint.
    public func stroke(_ path: Path) {
        
        assert(Int32(HPDF_Page_GetGMode(_page)) == HPDF_GMODE_PAGE_DESCRIPTION)
        
        _construct(path)
        
        assert(Int32(HPDF_Page_GetGMode(_page)) == HPDF_GMODE_PATH_OBJECT)
        
        HPDF_Page_Stroke(_page)
        
        assert(Int32(HPDF_Page_GetGMode(_page)) == HPDF_GMODE_PAGE_DESCRIPTION)
    }
    
    // MARK: - Text state

    /// The current font of the context. Default value is `Font.helvetica`
    ///
    /// You can only set fonts that has previously been loaded in the document using
    /// `loadTrueTypeFont(from:embeddingGlyphData:)` or
    /// `loadTrueTypeFontFromCollection(from:index:embeddingGlyphData:)` methods, or
    /// ones predefined in the `Font` struct.
    public var font: Font {
        get {
            let fontHandle = HPDF_Page_GetCurrentFont(_page)
            return fontHandle.map { Font(name: String(cString: HPDF_Font_GetFontName($0))) } ?? .helvetica
        }
        set {
            guard let font = HPDF_GetFont(_documentHandle, newValue.name, encoding.name) else {
                
                switch _document._error {
                case PDFError.invalidFontName:
                    preconditionFailure("""
                    Font \(newValue) must be loaded in the document using \
                    loadTrueTypeFont(from:embeddingGlyphData:) or \
                    loadTrueTypeFontFromCollection(from:index:embeddingGlyphData:) methods.
                    """)
                default:
                    preconditionFailure(_document._error.description)
                }
            }
            
            HPDF_Page_SetFontAndSize(_page, font, fontSize)

            currentFontDescriptor = nil
        }
    }
    
    /// The maximum size of a font that can be set.
    public static let maximumFontSize = Float(HPDF_MAX_FONTSIZE)

    public static let defaultFontSize: Float = 11
    
    /// The size of the current font of the context. Valid values are positive numbers up to
    /// `DrawingContext.maximumFontSize`.
    /// Default value is `DrawingContext.defaultFontSize`.
    public var fontSize: Float {
        get {
            let fontSize = HPDF_Page_GetCurrentFontSize(_page)
            return fontSize > 0 ? fontSize : DrawingContext.defaultFontSize
        }
        set {
            
            precondition(newValue > 0 && newValue < DrawingContext.maximumFontSize,
                         "Valid values for fontSize are positive numbers up to `DrawingContext.maximumFontSize`.")
            
            let font = HPDF_GetFont(_documentHandle, self.font.name, encoding.name)
            
            HPDF_Page_SetFontAndSize(_page, font, newValue)

            currentFontDescriptor = nil
        }
    }
    
    /// The encoding to use for a text. If the encoding cannot be used with the specified font, does nothing.
    public var encoding: Encoding {
        get {
            return HPDF_Page_GetCurrentFont(_page)
                .flatMap(HPDF_Font_GetEncodingName)
                .map { Encoding(name: String(cString: $0)) } ?? .standard
        }
        set {
            _enableMultibyteEncoding(for: newValue)
            
            let font = HPDF_GetFont(_documentHandle, self.font.name, newValue.name)
            
            if let font = font {
                HPDF_Page_SetFontAndSize(_page, font, fontSize)
            } else {
                HPDF_ResetError(_documentHandle)
            }

            currentFontDescriptor = nil
        }
    }
    
    private func _enableMultibyteEncoding(for encoding: Encoding) {
        
        switch encoding {
        case .gbEucCnHorisontal,
             .gbEucCnVertical,
             .gbkEucHorisontal,
             .gbkEucVertical:
            
            _document._useCNSEncodings()
            
        case .eTenB5Vertical,
             .eTenB5Horisontal:
            
            _document._useCNTEncodings()
            
        case .rksjHorisontal,
             .rksjVertical,
             .rksjHorisontalProportional,
             .eucHorisontal,
             .eucVertical:
            
            _document._useJPEncodings()
            
        case .kscEucHorisontal,
             .kscEucVertical,
             .kscMsUhcProportional,
             .kscMsUhsVerticalFixedWidth,
             .kscMsUhsHorisontalFixedWidth:
            
            _document._useKREncodings()
            
        case .utf8:
            
            _document._useUTFEncodings()
            
        default:
            break
        }
    }
    
    /// Active font descriptor.
    private var currentFontDescriptor: FontDescriptor?

    /// Changes the font.
    ///
    /// - parameter fontDescriptor: The descriptor of the font.
    public func setFont(_ fontDescriptor: FontDescriptor) throws {
        guard currentFontDescriptor != fontDescriptor else {
            return
        }
        font = switch fontDescriptor.format {
        case .ttf: try _document.loadTrueTypeFont(at: fontDescriptor.url)
        case let .ttc(index): try _document.loadTrueTypeFontFromCollection(at: fontDescriptor.url, index: index)
        }
        encoding = .utf8
        fontSize = fontDescriptor.size
        textLeading = fontDescriptor.textLeading
        currentFontDescriptor = fontDescriptor
    }
    
    /// Gets the width of the text in the current fontsize, character spacing and word spacing. If the text
    /// is multiline, returns the width of the longest line.
    ///
    /// - parameter text:  The text to get width of.
    ///
    /// - returns: The width of the text in current fontsize, character spacing and word spacing.
    public func textWidth(for text: String) -> Float {

        _setFontIfNeeded()
        
        let lines = text.components(separatedBy: .newlines)
        
        return lines.map { HPDF_Page_TextWidth(_page, $0) }.max()!
    }

    /// Calculates the number of UTF8 characters which can be included within the specified width.
    ///
    /// - Parameters:
    ///   - text:     The text to use for calculation.
    ///   - width:    The width of the area to put the text.
    ///   - wordwrap: When there are three words of "ABCDE", "FGH", and "IJKL", and the substring until "J" can be
    ///               included within the width, if `wordwrap` parameter is `false` it returns 12, and if `wordwrap`
    ///               parameter is `true`, it returns 10 (the end of the previous word).
    /// - Returns:
    ///   - `utf8Length`: The byte length which can be included within the specified width in current font size,
    ///                   character spacing and word spacing.
    ///   - `realWidth`:  The real width of the text.
    public func measureText(_ text: String,
                            width: Float,
                            wordwrap: Bool) throws -> (utf8Length: Int, realWidth: Float) {

        _setFontIfNeeded()

        var realWidth: Float = 0
        let utf8Length = HPDF_Page_MeasureText(_page, text, width, wordwrap ? HPDF_TRUE : HPDF_FALSE, &realWidth)

        if HPDF_GetError(_documentHandle) != UInt(HPDF_OK) {
            HPDF_ResetError(_documentHandle)
            throw _document._error
        }

        return (utf8Length: Int(utf8Length), realWidth: realWidth)
    }
    
    /// Gets the bounding box of the text in the current font size and leading. Text can be multiline.
    ///
    /// - parameter text:     The text to get the bounding box of.
    /// - parameter position: The assumed position of the text.
    ///
    /// - returns: The bounding box of the text.
    public func boundingBox(for text: String, atPosition position: Point) -> Rectangle {
        
        let textWidth = self.textWidth(for: text)
        
        let numberOfLines = text.components(separatedBy: .newlines).count
        
        return Rectangle(x: position.x,
                         y: position.y + fontDescent - textLeading * Float(numberOfLines - 1),
                         width: textWidth,
                         height: fontAscent - fontDescent + textLeading * Float(numberOfLines - 1))
    }
    
    /// The vertical ascent of the current font in the current font size.
    public var fontAscent: Float {
        
        let fontHandle = HPDF_GetFont(_documentHandle, font.name, encoding.name)
        
        return Float(HPDF_Font_GetAscent(fontHandle)) * fontSize / 1000
    }
    
    /// The vertical descent of the current font in the current font size. This value is negative.
    public var fontDescent: Float {
        
        let fontHandle = HPDF_GetFont(_documentHandle, font.name, encoding.name)
        
        return Float(HPDF_Font_GetDescent(fontHandle)) * fontSize / 1000
    }
    
    /// The height of lowercase letters reach based on height of lowercase x in the current font and font size;
    /// does not include ascenders or descenders.
    public var fontXHeight: Float {
        
        let fontHandle = HPDF_GetFont(_documentHandle, font.name, encoding.name)
        
        return Float(HPDF_Font_GetXHeight(fontHandle)) * fontSize / 1000
    }
    
    /// The height of a capital letter in the current font and font size measured from the baseline.
    public var fontCapHeight: Float {
        
        let fontHandle = HPDF_GetFont(_documentHandle, font.name, encoding.name)
        
        return Float(HPDF_Font_GetCapHeight(fontHandle)) * fontSize / 1000
    }

    /// The default text leading.
    public static let defaultTextLeading = Float(HPDF_DEF_LEADING)
    
    /// Text leading (line spacing) for text showing. Default value is `DrawingContext.defaultTextLeading`.
    public var textLeading: Float {
        get {
            return HPDF_Page_GetTextLeading(_page)
        }
        set {
            HPDF_Page_SetTextLeading(_page, newValue)

            currentFontDescriptor = nil
        }
    }

    /// The text rendering mode. The initial value of text rendering mode is `TextRenderingMode.fill`.
    public var textRenderingMode: TextRenderingMode {
        get {
            return TextRenderingMode(HPDF_Page_GetTextRenderingMode(_page))
        }
        set {
            HPDF_Page_SetTextRenderingMode(_page, HPDF_TextRenderingMode(newValue.rawValue))
        }
    }

    /// The default character spacing.
    public static let defaultCharacterSpacing = Float(HPDF_DEF_CHARSPACE)

    /// The minimum character spacing.
    public static let minCharacterSpacing = Float(HPDF_MIN_CHARSPACE)

    /// The maximum character spacing.
    public static let maxCharacterSpacing = Float(HPDF_MAX_CHARSPACE)

    /// The current value of the page's character spacing. Default value is `DrawingContext.defaultCharacterSpacing`.
    /// Minimum value is `DrawingContext.minCharacterSpacing`, maximum value is `DrawingContext.maxCharacterSpacing`.
    public var characterSpacing: Float {
        get {
            return HPDF_Page_GetCharSpace(_page)
        }
        set {
            precondition(newValue >= DrawingContext.minCharacterSpacing &&
                         newValue <= DrawingContext.maxCharacterSpacing,
                         """
                         The value of characterSpacing must be between `DrawingContext.minCharacterSpacing` \
                         and `DrawingContext.maxCharacterSpacing`.
                         """)
            if HPDF_Page_SetCharSpace(_page, newValue) != UInt(HPDF_OK) {
                 HPDF_ResetError(_documentHandle)
            }
        }
    }

    /// The default word spacing.
    public static let defaultWordSpacing = Float(HPDF_DEF_WORDSPACE)

    /// The minimum word spacing.
    public static let minWordSpacing = Float(HPDF_MIN_WORDSPACE)

    /// The maximum word spacing.
    public static let maxWordSpacing = Float(HPDF_MAX_WORDSPACE)

    /// The current value of the page's word spacing. Default value is `DrawingContext.defaultWordSpacing`.
    /// Minimum value is `DrawingContext.minWordSpacing`, maximum value is `DrawingContext.maxWordSpacing`.
    public var wordSpacing: Float {
        get {
            return HPDF_Page_GetWordSpace(_page)
        }
        set {
            precondition(newValue >= DrawingContext.minWordSpacing && newValue <= DrawingContext.maxWordSpacing,
                         """
                         The value of wordSpacing must be between `DrawingContext.minWordSpacing` \
                         and `DrawingContext.maxWordSpacing`.
                         """)
            if HPDF_Page_SetWordSpace(_page, newValue) != UInt(HPDF_OK) {
                HPDF_ResetError(_documentHandle)
            }
        }
    }

    // MARK: - Text showing
    
    private func _moveTextPosition(to point: Point) {
        
        let currentTextPosition = Point(HPDF_Page_GetCurrentTextPos(_page))
        let offsetFromCurrentToSpecifiedPosition = point - currentTextPosition
        HPDF_Page_MoveTextPos(_page,
                              offsetFromCurrentToSpecifiedPosition.dx,
                              offsetFromCurrentToSpecifiedPosition.dy)
    }

    private func _setFontIfNeeded() {
        if HPDF_Page_GetCurrentFont(_page) == nil {
            let font = HPDF_GetFont(_documentHandle, Font.helvetica.name, Encoding.standard.name)
            HPDF_Page_SetFontAndSize(_page, font, DrawingContext.defaultFontSize)
        }
    }

    private func _showText(_ text: String) throws {
        _setFontIfNeeded()
        if HPDF_Page_ShowText(_page, text) != UInt(HPDF_OK) {
            HPDF_ResetError(_documentHandle)
            throw _document._error
        }
    }

    private func _showTextNextLine(_ text: String) throws {
        if HPDF_Page_ShowTextNextLine(_page, text) != UInt(HPDF_OK) {
            HPDF_ResetError(_documentHandle)
            throw _document._error
        }
    }
    
    /// Prints the text at the specified position on the page. You can use "\n" to print multiline text.
    ///
    /// - Parameters:
    ///   - text:       The text to print.
    ///   - position:   The position to show the text at.
    ///   - textMatrix: A transformation matrix for text to be drawn in. Default value is `nil`,
    ///                 in which case the identity matrix is used. Must not be degenerate.
    public func show(text: String, atPosition position: Point, textMatrix: AffineTransform? = nil) throws {
        
        HPDF_Page_BeginText(_page)

        if let textMatrix = textMatrix {
            precondition(!textMatrix.isDegenerate, "The text matrix must not be degenerate")
            HPDF_Page_SetTextMatrix(_page,
                                    textMatrix.a,  textMatrix.b,
                                    textMatrix.c,  textMatrix.d,
                                    textMatrix.tx, textMatrix.ty)
        }

        _moveTextPosition(to: position)
        
        let lines = text.components(separatedBy: .newlines)

        try lines.first.map(_showText)

        for line in lines.dropFirst() {
            try _showTextNextLine(line)
        }

        HPDF_Page_EndText(_page)
    }
    
    /// Prints the text at the specified position on the page. You can use "\n" to print multiline text.
    ///
    /// - Parameters:
    ///   - text:       The text to print.
    ///   - x:          x coordinate of the position to show the text at.
    ///   - y:          y coordinate of the position to show the text at.
    ///   - textMatrix: A transformation matrix for text to be drawn in. Default value is `nil`,
    ///                 in which case the identity matrix is used. Must not be degenerate.
    @inlinable
    public func show(text: String, atX x: Float, y: Float, textMatrix: AffineTransform? = nil) throws {
        try show(text: text, atPosition: Point(x: x, y: y), textMatrix: textMatrix)
    }

    /// Prints the text inside the specified region.
    ///
    /// - Parameters:
    ///   - text:      The text to show.
    ///   - rect:      The region to output text.
    ///   - alignment: The alignment of the text.
    /// - Returns:    
    ///     - `isSufficientSpace`: `false` if whole text doesn't fit into declared space.
    ///     - `charactersPrinted`: The number of characters printed in the area.
    @discardableResult
    public func show(text: String,
                     in rect: Rectangle,
                     alignment: TextAlignment) throws -> (isSufficientSpace: Bool, charactersPrinted: Int) {

        HPDF_Page_BeginText(_page)

        defer {
            HPDF_Page_EndText(_page)
        }

        var charactersPrinted: HPDF_UINT = 0

        _setFontIfNeeded()

        let status = HPDF_Page_TextRect(_page,
                                        rect.x, rect.maxY, rect.maxX, rect.y,
                                        text,
                                        HPDF_TextAlignment(rawValue: alignment.rawValue), &charactersPrinted)

        let isInsufficientSpace = status == UInt(HPDF_PAGE_INSUFFICIENT_SPACE)

        if status != UInt(HPDF_OK) && !isInsufficientSpace {

            HPDF_ResetError(_documentHandle)
            throw _document._error
        }

        return (isSufficientSpace: !isInsufficientSpace, charactersPrinted: Int(charactersPrinted))
    }
    
    /// Prints the image at the specified position on the page.
    ///
    /// - Parameters:
    ///   - image: The image to print.
    ///   - rect: The region to output the image.
    public func draw(image: PDFImage, in rect: Rectangle) throws {
        let status = HPDF_Page_DrawImage(_page, image.handle, rect.x, rect.y, rect.width, rect.height)
        if status != UInt(HPDF_OK) {
            HPDF_ResetError(_documentHandle)
            throw _document._error
        }
    }

    /// Prints the image at the specified position on the page.
    ///
    /// - Parameters:
    ///   - image: The image to print.
    ///   - rect: The region to output the image.
    public func draw(image imageDescriptor: ImageDescriptor, in rect: Rectangle, resizeMode: ImageResizeMode = .aspectFit, alignment: ImageAlignment = .center) throws {
        guard rect.size != .zero else {
            return
        }

        // Load image
        let image = switch imageDescriptor.format {
        case .jpeg: try _document.loadJpegImage(at: imageDescriptor.url)
        case .png: try _document.loadPngImage(at: imageDescriptor.url)
        }

        // Compute scale
        var imageRect = rect
        imageRect.size.width = Float(image.width)
        imageRect.size.height = Float(image.height)
        let xScale = imageRect.size.width / rect.size.width
        let yScale = imageRect.size.height / rect.size.height
        let scale = switch resizeMode {
        case .aspectFit: fmax(fmax(xScale, yScale), 1)
        case .aspectFill: fmin(xScale, yScale)
        }
        imageRect.size.width = round(imageRect.size.width / scale)
        imageRect.size.height = round(imageRect.size.height / scale)

        // Horizontal alignment
        switch alignment {
        case .topLeading, .leading, .bottomLeading: break
        case .top, .center, .bottom: imageRect.origin.x += (rect.size.width - imageRect.size.width) / 2
        case .topTrailing, .trailing, .bottomTrailing: imageRect.origin.x += rect.size.width - imageRect.size.width
        }

        // Vertical alignment
        switch alignment {
        case .topLeading, .top, .topTrailing: imageRect.origin.y += rect.size.height - imageRect.size.height
        case .leading, .center, .trailing: imageRect.origin.y += (rect.size.height - imageRect.size.height) / 2
        case .bottomLeading, .bottom, .bottomTrailing: break
        }

        try clip(to: .rectangle(rect)) {
            try draw(image: image, in: imageRect)
        }
    }

    /// Adds an annotation.
    ///
    /// - Parameters:
    ///   - url: The link.
    ///   - rect: The region to output the link.
    /// - Returns: The annotation.
    @discardableResult
    public func addAnnotation(url: URL, in rect: Rectangle) throws -> PDFAnnotation {
        let annotation = HPDF_Page_CreateURILinkAnnot(_page, HPDF_Rect(left: rect.x, bottom: rect.maxY, right: rect.maxX, top: rect.y), url.absoluteString)
        guard let annotation else {
            HPDF_ResetError(_documentHandle)
            throw _document._error
        }
        return PDFAnnotation(handle: annotation)
    }
}
