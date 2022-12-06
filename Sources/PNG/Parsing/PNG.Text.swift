extension PNG 
{
    /// struct PNG.Text 
    ///     A text comment.
    /// 
    ///     This type models the information stored in a [`(Chunk).tEXt`], 
    ///     [`(Chunk).zTXt`], or [`(Chunk).iTXt`] chunk. 
    /// # [Parsing and serialization](text-parsing-and-serialization)
    /// # [See also](parsed-chunk-types)
    /// ## (parsed-chunk-types) 
    public 
    struct Text 
    {
        /// let PNG.Text.compressed : Swift.Bool 
        ///     Indicates if the text is (or is to be) stored in compressed or 
        ///     uncompressed form within a PNG file.
        /// 
        ///     This flag is `true` if the original text chunk was a 
        ///     [`(Chunk).zTXt`] chunk, and `false` if it was a [`(Chunk).tEXt`] 
        ///     chunk. If the original chunk was an [`(Chunk).iTXt`] chunk, 
        ///     this flag can be either `true` or `false`.
        public 
        let compressed:Bool 
        /// let PNG.Text.keyword : (english:Swift.String, localized:Swift.String)
        ///     A keyword tag, in english, and possibly a non-english language. 
        /// 
        ///     If the text is in english, the `localized` keyword is the empty 
        ///     string `""`.
        public 
        let keyword:(english:String, localized:String), 
        /// let PNG.Text.language : [Swift.String]
        ///     An array representing an [rfc-1766](https://www.ietf.org/rfc/rfc1766.txt) 
        ///     language tag, where each element is a language subtag. 
        /// 
        ///     If this array is empty, then the language is unspecified.
            language:[String]
        /// let PNG.Text.content : Swift.String 
        ///     The text content.
        public 
        let content:String
        
        /// init PNG.Text.init(compressed:keyword:language:content:)
        ///     Creates a text comment.
        /// - compressed : Swift.Bool 
        ///     Indicates if the text is to be stored in compressed or 
        ///     uncompressed form within a PNG file.
        /// - keyword : (english:Swift.String, localized:Swift.String)
        ///     A keyword tag, in english, and possibly a non-english language. 
        /// 
        ///     The english keyword must contain only unicode scalars 
        ///     in the ranges `"\u{20}" ... "\u{7d}"` or `"\u{a1}" ... "\u{ff}"`. 
        ///     Leading, trailing, and consecutive spaces are not allowed. 
        ///     There are no restrictions on the `localized` keyword, other than 
        ///     that it must not contain any null characters.
        /// 
        ///     Passing invalid keyword strings will result in a precondition failure.
        /// 
        ///     If the text is in english, the `localized` keyword should be 
        ///     set to the empty string `""`.
        /// - language : [Swift.String]
        ///     An array representing an [rfc-1766](https://www.ietf.org/rfc/rfc1766.txt) 
        ///     language tag, where each element is a language subtag. 
        /// 
        ///     Each subtag must be a 1–8 character string containing alphabetical 
        ///     ASCII characters only. Passing an invalid language tag array 
        ///     will result in a precondition failure.
        /// 
        ///     If this array is empty, then the language is unspecified.
        /// - content : Swift.String 
        ///     The text content. There are no restrictions on it. It is allowed 
        ///     (but not recommended) to contain null characters.
        public 
        init(compressed:Bool, keyword:(english:String, localized:String), 
            language:[String], content:String)
        {
            guard Self.validate(name: keyword.english.unicodeScalars)
            else 
            {
                PNG.ParsingError.invalidTextEnglishKeyword(keyword.english).fatal 
            }
            guard (keyword.localized.unicodeScalars.allSatisfy{ $0 != "\u{0}" })
            else 
            {
                fatalError("localized keyword must not contain any null characters")
            }
            for tag:String in language
            {
                guard Self.validate(language: tag.unicodeScalars)
                else 
                {
                    PNG.ParsingError.invalidTextLanguageTag(tag).fatal 
                }
            }
            
            self.compressed = compressed 
            self.keyword    = keyword 
            self.language   = language 
            self.content    = content
        }
    }
}
extension PNG.Text 
{
    /// init PNG.Text.init(parsing:unicode:) 
    /// throws 
    ///     Creates a text comment by parsing the given chunk data, interpreting 
    ///     it either as a unicode text chunk, or a latin-1 text chunk.
    /// - data      : [Swift.UInt8]
    ///     The contents of a [`(Chunk).tEXt`], [`(Chunk).zTXt`], or [`(Chunk).iTXt`] 
    ///     chunk to parse. 
    /// - unicode   : Swift.Bool 
    ///     Specifies if the given chunk `data` should be interpreted as a 
    ///     unicode chunk, or a latin-1 chunk. It should be set to `true` if the 
    ///     original text chunk was an [`(Chunk).iTXt`] chunk, and `false` 
    ///     otherwise. The default value is `true`.
    /// 
    ///     If this flag is set to `false`, the text is assumed to be in english, 
    ///     and the [`language`] tag will be set to `["en"]`.
    /// ## (text-parsing-and-serialization)
    public 
    init(parsing data:[UInt8], unicode:Bool = true) throws 
    {
        //  ┌ ╶ ╶ ╶ ╶ ╶ ╶┬───┬───┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┬───┬ ╶ ╶ ╶ ╶ ╶ ╶┐
        //  │   keyword  │ 0 │ C │ M │  language  │ 0 │   keyword  │ 0 │    text    │
        //  └ ╶ ╶ ╶ ╶ ╶ ╶┴───┴───┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┴───┴ ╶ ╶ ╶ ╶ ╶ ╶┘
        //               k  k+1 k+2 k+3           l  l+1           m  m+1
        let k:Int
        (self.keyword.english, k) = try Self.name(parsing: data[...]) 
        {
            PNG.ParsingError.invalidTextEnglishKeyword($0)
        }
        
        // parse iTXt chunk 
        if unicode 
        {
            // assert existence of compression flag and method bytes 
            guard k + 2 < data.endIndex 
            else 
            {
                throw PNG.ParsingError.invalidTextChunkLength(data.count, min: k + 3)
            }
            
            let l:Int 
            // language can be empty, in which case it is unknown 
            (self.language, l) = try Self.language(parsing: data[(k + 3)...]) 
            {
                PNG.ParsingError.invalidTextLanguageTag($0)
            }
            
            guard let m:Int = data[(l + 1)...].firstIndex(of: 0) 
            else 
            {
                throw PNG.ParsingError.invalidTextLocalizedKeyword
            }
            
            let localized:String    = .init(decoding: data[l + 1 ..< m], as: Unicode.UTF8.self)
            self.keyword.localized  = self.keyword.english == localized ? "" : localized
            
            let uncompressed:ArraySlice<UInt8>
            switch data[k + 1] 
            {
            case 0:
                uncompressed    = data[(m + 1)...]
                self.compressed = false
            case 1:
                guard data[k + 2] == 0 
                else 
                {
                    throw PNG.ParsingError.invalidTextCompressionMethodCode(data[k + 2])
                }
                var inflator:LZ77.Inflator = .init()
                guard try inflator.push(.init(data[(m + 1)...])) == nil 
                else 
                {
                    throw PNG.ParsingError.incompleteTextCompressedDatastream
                }
                uncompressed    = inflator.pull()[...]
                self.compressed = true
            case let code: 
                throw PNG.ParsingError.invalidTextCompressionCode(code)
            }
            
            self.content = .init(decoding: uncompressed, as: Unicode.UTF8.self)
        }
        // parse tEXt/zTXt chunk 
        else 
        {
            self.keyword.localized  = ""
            self.language           = ["en"]
            // if the next byte is also null, the chunk uses compression
            let uncompressed:ArraySlice<UInt8>
            if k + 1 < data.endIndex, data[k + 1] == 0
            {
                var inflator:LZ77.Inflator = .init()
                guard try inflator.push(.init(data[(k + 2)...])) == nil 
                else 
                {
                    throw PNG.ParsingError.incompleteTextCompressedDatastream
                }
                uncompressed    = inflator.pull()[...]
                self.compressed = true
            }
            else 
            {
                uncompressed    = data[(k + 1)...]
                self.compressed = false
            }
            
            self.content = .init(uncompressed.map{ Character.init(Unicode.Scalar.init($0)) })
        }
    }
    
    static 
    func name<E>(parsing data:ArraySlice<UInt8>, else error:(String?) -> E) throws 
        -> (name:String, offset:Int)
        where E:Swift.Error 
    {
        guard let offset:Int = data.firstIndex(of: 0)
        else 
        {
            throw error(nil)
        }
        
        let scalars:LazyMapSequence<ArraySlice<UInt8>, Unicode.Scalar> = 
            data[..<offset].lazy.map(Unicode.Scalar.init(_:))
            
        let name:String = .init(scalars.map(Character.init(_:)))
        guard Self.validate(name: scalars) 
        else 
        {
            throw error(name)
        }
        
        return (name, offset)
    }
    static 
    func validate<C>(name scalars:C) -> Bool 
        where C:Collection, C.Element == Unicode.Scalar 
    {
        // `count` in range `1 ... 80`
        guard var previous:Unicode.Scalar = scalars.first, scalars.count <= 80
        else 
        {
            return false
        }
        
        for scalar:Unicode.Scalar in scalars
        {
            guard   "\u{20}" ... "\u{7d}" ~= scalar || 
                    "\u{a1}" ... "\u{ff}" ~= scalar,
                    // no multiple spaces, also checks for no leading spaces 
                    (previous, scalar) != (" ", " ")
            else 
            {
                return false 
            }
            
            previous = scalar 
        }
        // no trailing spaces 
        return previous != " "
    }
    
    private static 
    func language<E>(parsing data:ArraySlice<UInt8>, else error:(String?) -> E) throws
        -> (language:[String], offset:Int)
        where E:Swift.Error 
    {
        guard let offset:Int = data.firstIndex(of: 0)
        else 
        {
            throw error(nil) 
        }
        
        // check for empty language tag 
        guard offset > data.startIndex 
        else 
        {
            return ([], offset)
        }
        
        // split on '-' 
        let language:[String] = 
            try data[..<offset].split(separator: 0x2d, omittingEmptySubsequences: false).map 
        {
            let scalars:LazyMapSequence<ArraySlice<UInt8>, Unicode.Scalar> = 
                $0.lazy.map(Unicode.Scalar.init(_:))
            let tag:String = .init(scalars.map(Character.init(_:)))
            guard Self.validate(language: scalars) 
            else 
            {
                throw error(tag)
            }
            
            // canonical lowercase 
            return tag.lowercased()
        }
        
        return (language, offset)
    }
    private static 
    func validate<C>(language scalars:C) -> Bool 
        where C:Collection, C.Element == Unicode.Scalar 
    {
        guard 1 ... 8 ~= scalars.count
        else 
        {
            return false 
        }
        
        return scalars.allSatisfy{ "a" ... "z" ~= $0 || "A" ... "Z" ~= $0 }
    }
    /// var PNG.Text.serialized : [Swift.UInt8] { get }
    ///     Encodes this text comment as the contents of a 
    ///     [`(Chunk).iTXt`] chunk. 
    /// 
    ///     This property *always* emits a unicode [`(Chunk).iTXt`] 
    ///     chunk, regardless of the type of the original chunk, if it was parsed 
    ///     from raw chunk data. It is the opinion of the library that the 
    ///     latin-1 chunk types [`(Chunk).tEXt`] and [`(Chunk).zTXt`] are 
    ///     deprecated.
    /// ## (text-parsing-and-serialization)
    public 
    var serialized:[UInt8]
    {
        let size:Int = 5 +
            self.keyword.english.count                      + 
            self.keyword.localized.count                    + 
            self.language.reduce(0){ $0 + $1.count + 1 }    + 
            self.content.utf8.count 
            
        var data:[UInt8] = []
        data.reserveCapacity(size)
        data.append(contentsOf: self.keyword.english.unicodeScalars.map{ .init($0.value) })
        data.append(0)
        data.append(self.compressed ? 1 : 0)
        data.append(0) // compression method
        data.append(contentsOf: self.language.map
        { 
            $0.unicodeScalars.map{ .init($0.value) }
        }.joined(separator: [0x2d]))
        data.append(0)
        if self.keyword.localized != self.keyword.english 
        {
            data.append(contentsOf: self.keyword.localized.utf8)
        }
        data.append(0)
        
        if self.compressed 
        {
            var deflator:LZ77.Deflator = .init(level: 13, exponent: 15, hint: 4096)
            deflator.push(.init(self.content.utf8), last: true)
            while true 
            {
                let segment:[UInt8] = deflator.pull()
                guard !segment.isEmpty 
                else 
                {
                    break 
                }
                
                data.append(contentsOf: segment)
            }
        }
        else 
        {
            data.append(contentsOf: self.content.utf8)
        }
        
        return data
    }
}
extension PNG.Text:CustomStringConvertible 
{
    public 
    var description:String 
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.tEXt) | \(PNG.Chunk.zTXt) | \(PNG.Chunk.iTXt)) 
        {
            compressed  : \(self.compressed)
            language    : '\(self.language.joined(separator: "-"))'
            keyword     : '\(self.keyword.english)', '\(self.keyword.localized)'
            content     : \"\(self.content)\"
        }
        """
    }
}
