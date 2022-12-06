extension PNG 
{
    /// struct PNG.Layout 
    ///     An image layout. 
    /// 
    ///     This type stores all the information in an image that is not strictly 
    ///     metadata, or image content.
    /// ## (1:images)
    public 
    struct Layout 
    {
        /// let PNG.Layout.format : Format 
        ///     The image color format.
        public 
        let format:PNG.Format 
        /// let PNG.Layout.interlaced : Swift.Bool 
        ///     Indicates if the image uses interlacing or not.
        public 
        let interlaced:Bool
        
        /// init PNG.Layout.init(format:interlaced:)
        ///     Creates an image layout. 
        /// 
        ///     This initializer will validate the fields of the given color 
        ///     `format`. Passing an invalid `format` will result in a 
        ///     precondition failure.
        /// - format : Format 
        ///     A color format. 
        /// - interlaced : Swift.Bool 
        ///     Specifies if the image uses interlacing. The default value is 
        ///     `false`.
        public 
        init(format:PNG.Format, interlaced:Bool = false) 
        {
            self.format     = format.validate()
            self.interlaced = interlaced
        }
    }
}
extension PNG.Layout 
{
    init?(standard:PNG.Standard, pixel:PNG.Format.Pixel, 
        palette:PNG.Palette?, 
        background:PNG.Background?, 
        transparency:PNG.Transparency?, 
        interlaced:Bool) 
    {
        guard let format:PNG.Format = .recognize(standard: standard, pixel: pixel, 
            palette: palette, background: background, transparency: transparency) 
        else 
        {
            // if all the inputs have been consistently validated by the parsing 
            // APIs, the only error condition is a missing palette for an indexed 
            // image. otherwise, it returns `nil` on any input chunk inconsistency
            return nil 
        }
        
        self.init(format: format, interlaced: interlaced)
    }
}

// encoding
extension PNG.Layout 
{
    var palette:PNG.Palette? 
    {
        switch self.format 
        {
        case    .v1, .v2, .v4, .v8, .v16, .va8, .va16:
            return nil 
        
        case    .rgb8       (palette: let palette, fill: _, key: _),
                .rgb16      (palette: let palette, fill: _, key: _), 
                .rgba8      (palette: let palette, fill: _),
                .rgba16     (palette: let palette, fill: _):
            // should be impossible for self.format to have invalid palettes
            return palette.isEmpty ? nil : .init(entries: palette)
        
        case    .bgr8       (palette: let palette, fill: _, key: _),
                .bgra8      (palette: let palette, fill: _):
            return palette.isEmpty ? nil : .init(entries: palette.map 
            {
                ($0.r, $0.g, $0.b)
            })
        
        case    .indexed1   (palette: let palette, fill: _),
                .indexed2   (palette: let palette, fill: _),
                .indexed4   (palette: let palette, fill: _),
                .indexed8   (palette: let palette, fill: _):
            return .init(entries: palette.map
            { 
                ($0.r, $0.g, $0.b) 
            })
        }
    }
    var transparency:PNG.Transparency? 
    {
        let c:PNG.Transparency.Case 
        switch self.format 
        {
        case    .v1         (fill: _, key: nil), 
                .v2         (fill: _, key: nil), 
                .v4         (fill: _, key: nil), 
                .v8         (fill: _, key: nil), 
                .v16        (fill: _, key: nil),
                .va8        (fill: _),
                .va16       (fill: _),
                .bgr8       (palette: _, fill: _, key: nil),
                .rgb8       (palette: _, fill: _, key: nil),
                .bgra8      (palette: _, fill: _), 
                .rgba8      (palette: _, fill: _), 
                .rgb16      (palette: _, fill: _, key: nil),
                .rgba16     (palette: _, fill: _):
            return nil 
        
        case    .v1         (fill: _, key: let k?), 
                .v2         (fill: _, key: let k?), 
                .v4         (fill: _, key: let k?), 
                .v8         (fill: _, key: let k?):
            c = .v(key: .init(k))
        
        case    .v16        (fill: _, key: let k?):
            c = .v(key: k)
            
        case    .bgr8       (palette: _, fill: _, key: let k?):
            c = .rgb(key: (r: .init(k.r), g: .init(k.g), b: .init(k.b)))
        case    .rgb8       (palette: _, fill: _, key: let k?):
            c = .rgb(key: (r: .init(k.r), g: .init(k.g), b: .init(k.b)))
        
        case    .rgb16      (palette: _, fill: _, key: let k?):
            c = .rgb(key: k)
        
        case    .indexed1   (palette: let palette, fill: _),
                .indexed2   (palette: let palette, fill: _),
                .indexed4   (palette: let palette, fill: _),
                .indexed8   (palette: let palette, fill: _):
            guard let last:Int = (palette.lastIndex{ $0.a != .max })
            else 
            {
                return nil 
            }
            c = .palette(alpha: palette.prefix(last + 1).map(\.a))
        }
        return .init(case: c)
    }
    var background:PNG.Background? 
    {
        let c:PNG.Background.Case 
        switch self.format 
        {
        case    .v1         (fill: nil, key: _), 
                .v2         (fill: nil, key: _), 
                .v4         (fill: nil, key: _), 
                .v8         (fill: nil, key: _), 
                .v16        (fill: nil, key: _),
                .va8        (fill: nil),
                .va16       (fill: nil),
                .bgr8       (palette: _, fill: nil, key: _),
                .rgb8       (palette: _, fill: nil, key: _),
                .bgra8      (palette: _, fill: nil), 
                .rgba8      (palette: _, fill: nil), 
                .rgb16      (palette: _, fill: nil, key: _),
                .rgba16     (palette: _, fill: nil),
                .indexed1   (palette: _, fill: nil),
                .indexed2   (palette: _, fill: nil),
                .indexed4   (palette: _, fill: nil),
                .indexed8   (palette: _, fill: nil):
            return nil 
        
        case    .v1         (fill: let f?, key: _), 
                .v2         (fill: let f?, key: _), 
                .v4         (fill: let f?, key: _), 
                .v8         (fill: let f?, key: _), 
                .va8        (fill: let f?):
            c = .v(.init(f))
        
        case    .v16        (fill: let f?, key: _), 
                .va16       (fill: let f?):
            c = .v(f)
            
        case    .bgr8       (palette: _, fill: let f?, key: _),
                .bgra8      (palette: _, fill: let f?):
            c = .rgb((r: .init(f.r), g: .init(f.g), b: .init(f.b)))
        case    .rgb8       (palette: _, fill: let f?, key: _),
                .rgba8      (palette: _, fill: let f?):
            c = .rgb((r: .init(f.r), g: .init(f.g), b: .init(f.b)))
        
        case    .rgb16      (palette: _, fill: let f?, key: _),
                .rgba16     (palette: _, fill: let f?):
            c = .rgb(f)
        
        case    .indexed1   (palette: _, fill: let i?),
                .indexed2   (palette: _, fill: let i?),
                .indexed4   (palette: _, fill: let i?),
                .indexed8   (palette: _, fill: let i?):
            c = .palette(index: i)
        }
        return .init(case: c)
    }
}
