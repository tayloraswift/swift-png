import Glibc
import func zlib.crc32

extension Array where Element == UInt8 
{
    /** 
        Loads a misaligned big-endian integer value from the given byte offset 
        and casts it to a desired format.
        - Parameters:
            - bigEndian: The size and type to interpret the data to load as.
            - type: The type to cast the read integer value to.
            - byte: The byte offset to load the big-endian integer from.
        - Returns: The read integer value, cast to `U`.
    */
    fileprivate 
    func load<T, U>(bigEndian:T.Type, as type:U.Type, at byte:Int) -> U 
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(bigEndian: T.self, as: U.self)
    }
    
    /**
        Decomposes the given integer value into its constituent bytes, in big-endian order.
        - Parameters:
            - value: The integer value to decompose.
            - type: The big-endian format `T` to store the given `value` as. The given 
                    `value` is truncated to fit in a `T`.
        - Returns: An array containing the bytes of the given `value`, in big-endian order.
    */
    fileprivate static 
    func store<U, T>(_ value:U, asBigEndian type:T.Type) -> [UInt8]
        where U:BinaryInteger, T:FixedWidthInteger 
    {
        return .init(unsafeUninitializedCapacity: MemoryLayout<T>.size) 
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
            
            let bigEndian:T = T.init(truncatingIfNeeded: value).bigEndian, 
                destination:UnsafeMutableRawBufferPointer = .init(buffer)
            Swift.withUnsafeBytes(of: bigEndian) 
            {
                destination.copyMemory(from: $0)
                count = $0.count
            }
        }
    }
}

extension ArraySlice where Element == UInt8 
{
    /** 
        Loads this array slice as a misaligned big-endian integer value, 
        and casts it to a desired format.
        - Parameters:
            - bigEndian: The size and type to interpret this array slice as.
            - type: The type to cast the read integer value to.
        - Returns: The read integer value, cast to `U`.
    */
    fileprivate
    func load<T, U>(bigEndian:T.Type, as type:U.Type) -> U 
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer 
        {
            (buffer:UnsafeBufferPointer<UInt8>) in
            
            assert(buffer.count >= MemoryLayout<T>.size, 
                "attempt to load \(T.self) from slice of size \(buffer.count)")
            
            var storage:T = .init()
            let value:T   = withUnsafeMutablePointer(to: &storage) 
            {
                $0.deinitialize(count: 1)
                
                let source:UnsafeRawPointer     = .init(buffer.baseAddress!), 
                    raw:UnsafeMutableRawPointer = .init($0)
                
                raw.copyMemory(from: source, byteCount: MemoryLayout<T>.size)
                
                return raw.load(as: T.self)
            }
            
            return U(T(bigEndian: value))
        }
    }
}

/**
    An abstract data source. To provide a custom data source to the library, conform 
    your type to this protocol by implementing the `read(count:)` method.
*/
public 
protocol DataSource
{
    /** 
        Read the specified number of bytes from this data source.
        - Parameters:
            - count: The number of bytes to read.
        - Returns: An array of size `count`, if `count` bytes could be read, and 
            `nil` otherwise.
    */
    mutating 
    func read(count:Int) -> [UInt8]?
}
/**
    An abstract data destination. To specify a custom data destination for the library, 
    conform your type to this protocol by implementing the `write(_:)` method.
*/
public 
protocol DataDestination 
{
    /** 
        Write the given data buffer to this data destination.
        - Parameters:
            - buffer: The data to write.
        - Returns: `()` on success, and `nil` otherwise.
    */
    mutating 
    func write(_ buffer:[UInt8]) -> Void?
}

/**
    A fixed-width integer type which can be packed in groups of four within another 
    integer type. For example, four `UInt8`s may be packed into a single `UInt32`.
*/
public 
protocol FusedVector4Element:FixedWidthInteger & UnsignedInteger 
{
    /**
        A fixed-width integer type which can hold four instances of `Self`.
    */
    associatedtype FusedVector4:FixedWidthInteger & UnsignedInteger 
}
extension UInt8:FusedVector4Element 
{
    public 
    typealias FusedVector4 = UInt32
}
extension UInt16:FusedVector4Element 
{
    public 
    typealias FusedVector4 = UInt64
}

extension PNG.RGBA where Component:FusedVector4Element
{
    /** 
        The components of this pixel value packed into a single unsigned integer in 
        ARGB order, with the alpha component in the high bits.
    */
    @inlinable
    public
    var argb:Component.FusedVector4
    {
        let a:Math<Component.FusedVector4>.V4 = 
            Math.cast(truncatingIfNeeded: (self.a, self.r, self.g, self.b), 
                                      as: Component.FusedVector4.self)
                
        let x:Math<Component.FusedVector4>.V4
        
        x.0 = a.0 << (Component.bitWidth << 1 | Component.bitWidth)
        x.1 = a.1 << (Component.bitWidth << 1)
        x.2 = a.2 << (Component.bitWidth)
        x.3 = a.3
        
        return x.0 | x.1 | x.2 | x.3
    }
}

/**
    Encode and decode image data in the PNG format.
*/
public 
enum PNG
{
    private static 
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
    /** 
        A four-component color value, with components stored in the RGBA color model. 
        This structure has fixed layout, with the red component first, then green, 
        then blue, then alpha. Buffers containing instances of this type may be 
        safely reinterpreted as flat buffers containing interleaved color components.
    */
    @_fixed_layout
    public
    struct RGBA<Component>:Equatable, CustomStringConvertible 
        where Component:FixedWidthInteger & UnsignedInteger
    {
        /// The red component of this color. 
        public
        let r:Component
        /// The green component of this color. 
        public 
        let g:Component
        /// The blue component of this color. 
        public 
        let b:Component
        /// The alpha component of this color. 
        public 
        let a:Component
        
        /// A textual representation of this color.
        public
        var description:String
        {
            return "(\(self.r), \(self.g), \(self.b), \(self.a))"
        }
        
        /** 
            Creates an opaque grayscale color with all color components set to the given 
            value sample, and the alpha component set to `Component.max`. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`. 
            - Parameters:
                - value: The value to initialize all color components to.
        */
        @_specialize(where Component == UInt8)
        @_specialize(where Component == UInt16)
        public
        init(_ value:Component)
        {
            self.init(value, value, value, Component.max)
        }
        
        /** 
            Creates a grayscale color with all color components set to the given 
            value sample, and the alpha component set to the given alpha sample. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`. 
            - Parameters:
                - value: The value to initialize all color components to.
                - alpha: The value to initialize the alpha component to.
        */
        @_specialize(where Component == UInt8)
        @_specialize(where Component == UInt16)
        public
        init(_ value:Component, _ alpha:Component)
        {
            self.init(value, value, value, alpha)
        }
        
        /** 
            Creates an opaque color with the given color samples, and the alpha 
            component set to `Component.max`. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`. 
            - Parameters:
                - red: The value to initialize the red component to.
                - green: The value to initialize the green component to.
                - blue: The value to initialize the blue component to.
        */
        @_specialize(where Component == UInt8)
        @_specialize(where Component == UInt16)
        public
        init(_ red:Component, _ green:Component, _ blue:Component)
        {
            self.init(red, green, blue, Component.max)
        }
        
        /** 
            Creates an opaque color with the given color and alpha samples. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`. 
            - Parameters:
                - red: The value to initialize the red component to.
                - green: The value to initialize the green component to.
                - blue: The value to initialize the blue component to.
                - alpha: The value to initialize the alpha component to.
        */
        @_specialize(where Component == UInt8)
        @_specialize(where Component == UInt16)
        public
        init(_ red:Component, _ green:Component, _ blue:Component, _ alpha:Component)
        {
            self.r = red
            self.g = green
            self.b = blue
            self.a = alpha
        }
        
        /** 
            The color obtained by premultiplying the red, green, and blue components 
            of this color with its alpha component. The resulting component values 
            are accurate to within 1 `Component` unit.
            
            *Inlineable*.
        */
        @inlinable
        public
        var premultiplied:RGBA<Component>
        {
            return .init(RGBA.premultiply(color: self.r, alpha: self.a), 
                         RGBA.premultiply(color: self.g, alpha: self.a), 
                         RGBA.premultiply(color: self.b, alpha: self.a), 
                         self.a)
        }
        
        /**
            Returns the given color sample premultiplied with the given alpha sample.
            
            *Specialized* for `Component` types `UInt8`, `UInt16`. 
            - Parameters:
                - color: A color sample.
                - alpha: An alpha sample.
            - Returns: The product of the given color sample and the given alpha 
                sample. The resulting value is accurate to within 1 `Component` unit.
        */
        @usableFromInline 
        @_specialize(where Component == UInt8)
        @_specialize(where Component == UInt16)
        static 
        func premultiply(color:Component, alpha:Component) -> Component 
        {
            // an overflow-safe way of computing p = (c * (a + 1)) >> p.bitWidth
            let (high, low):(Component, Component.Magnitude) = color.multipliedFullWidth(by: alpha)
            // divide by 255 using this one neat trick!1!!! 
            // value /. 255 == (value + 128 + (value >> 8)) >> 8
            let carries:(Bool, Bool), 
                partialValue:Component.Magnitude
            (partialValue, carries.0) = low.addingReportingOverflow(high.magnitude)
                           carries.1  = partialValue.addingReportingOverflow(Component.Magnitude.max >> 1 + 1).overflow
            return high + (carries.0 ? 1 : 0) + (carries.1 ? 1 : 0)
        }
        
        /**
            Returns a copy of this color with the alpha component set to the given sample.
            - Parameters:
                - a: An alpha sample.
            - Returns: This color with the alpha component set to the given sample.
        */
        func withAlpha(_ a:Component) -> RGBA<Component>
        {
            return .init(self.r, self.g, self.b, a)
        }

        /**
            Returns a boolean value indicating whether the color components of this 
            color are equal to the color components of the given color, ignoring 
            the alpha components.
            - Parameters:
                - other: Another color.
            - Returns: `true` if the red, green, and blue channels of this color and 
                `other` are equal, `false` otherwise.
        */
        func equals(opaque other:RGBA<Component>) -> Bool
        {
            return self.r == other.r && self.g == other.g && self.b == other.b
        }
        
        /**
            Returns this color with its components widened to the given type, preserving 
            their normalized values. 
            
            `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
            - Parameters:
                - type: The type of the components of the new color.
            - Returns: A new color, with the values of its components taken from 
                this color, and normalized to the range of `T`. 
        */
        @inline(__always)
        func upscale<T>(to type:T.Type) -> RGBA<T> where T:FixedWidthInteger & UnsignedInteger
        {
            assert(T.bitWidth >= Component.bitWidth)
            let quantum:T = RGBA<T>.quantum(depth: Component.bitWidth), 
                r:T = .init(truncatingIfNeeded: self.r) * quantum, 
                g:T = .init(truncatingIfNeeded: self.g) * quantum, 
                b:T = .init(truncatingIfNeeded: self.b) * quantum, 
                a:T = .init(truncatingIfNeeded: self.a) * quantum
            return .init(r, g, b, a)
        }
        
        /**
            Returns this color with its components narrowed to the given type, preserving 
            their normalized values. 
            
            `T.bitWidth` must be less than or equal to `Component.bitWidth`.
            - Parameters:
                - type: The type of the components of the new color.
            - Returns: A new color, with the values of its components taken from 
                this color, and normalized to the range of `T`. 
        */
        @inline(__always)
        func downscale<T>(to type:T.Type) -> RGBA<T> where T:FixedWidthInteger & UnsignedInteger
        {
            assert(T.bitWidth <= Component.bitWidth)
            let shift:Int = Component.bitWidth - T.bitWidth, 
                r:T       = .init(truncatingIfNeeded: self.r &>> shift),
                g:T       = .init(truncatingIfNeeded: self.g &>> shift),
                b:T       = .init(truncatingIfNeeded: self.g &>> shift),
                a:T       = .init(truncatingIfNeeded: self.g &>> shift)
            
            return .init(r, g, b, a)
        }
        
        /** 
            Returns the size of one unit in a component of the given depth, in units of 
            this color’s `Component` type. 
            - Parameters:
                - depth: A bit depth less than or equal to `Component.bitWidth`.
            - Returns: The size of one unit in a component of the given bit depth, 
                in units of `Component`. Multiplying this value with the scalar 
                integer value of a component of bit depth `depth` will renormalize 
                it to the range of `Component`.
        */
        @inline(__always)
        static 
        func quantum(depth:Int) -> Component 
        {
            return Component.max / (Component.max &>> (Component.bitWidth - depth))
        }
    }
    
    /** 
        A namespace for file IO functionality.
    */
    public 
    enum File
    {
        private 
        typealias Descriptor = UnsafeMutablePointer<FILE>
        
        /** 
            Read data from files on disk.
        */
        public 
        struct Source:DataSource 
        {
            private 
            let descriptor:Descriptor
            
            /** 
                Calls a closure with an interface for reading from the specified file.
                
                This method automatically closes the file when its function argument returns. 
                - Parameters:
                    - path: A path to the file to open.
                    - body: A closure with a `Source` parameter from which data in 
                        the specified file can be read. This interface is only valid 
                        for the duration of the method’s execution. The closure is 
                        only executed if the specified file could be successfully 
                        opened, otherwise `nil` is returned. If `body` has a return 
                        value and the specified file could be opened, its return 
                        value is returned as the return value of the `open(path:body:)` 
                        method. 
                - Returns: `nil` if the specified file could not be opened, or the 
                    return value of the function argument otherwise.
            */
            public static 
            func open<Result>(path:String, _ body:(inout Source) throws -> Result) 
                rethrows -> Result? 
            {
                guard let descriptor:Descriptor = fopen(path, "rb")
                else
                {
                    return nil
                }
                
                var file:Source = .init(descriptor: descriptor)
                defer 
                {
                    fclose(file.descriptor)
                }
                
                return try body(&file)
            }
            
            /** 
                Read the specified number of bytes from this file interface.
                
                This method only returns an array if the exact number of bytes 
                specified could be read. This method advances the file pointer.
                
                - Parameters:
                    - capacity: The number of bytes to read.
                - Returns: An array containing the read data, or `nil` if the specified 
                    number of bytes could not be read.
            */
            public 
            func read(count capacity:Int) -> [UInt8]?
            {
                let buffer:[UInt8] = .init(unsafeUninitializedCapacity: capacity) 
                {
                    (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in 
                    
                    count = fread(buffer.baseAddress, MemoryLayout<UInt8>.stride, 
                        capacity, self.descriptor)
                }
                
                guard buffer.count == capacity
                else 
                {
                    return nil
                }
                
                return buffer
            }
        }
        
        /** 
            Write data to files on disk.
        */
        public 
        struct Destination:DataDestination 
        {
            private 
            let descriptor:Descriptor
            
            /** 
                Calls a closure with an interface for writing to the specified file.
                
                This method automatically closes the file when its function argument returns. 
                - Parameters:
                    - path: A path to the file to open.
                    - body: A closure with a `Destination` parameter representing 
                        the specified file to which data can be written to. This 
                        interface is only valid for the duration of the method’s 
                        execution. The closure is only executed if the specified 
                        file could be successfully opened, otherwise `nil` is returned. 
                        If `body` has a return value and the specified file could 
                        be opened, its return value is returned as the return value 
                        of the `open(path:body:)` method. 
                - Returns: `nil` if the specified file could not be opened, or the 
                    return value of the function argument otherwise.
            */
            public static 
            func open<Result>(path:String, body:(inout Destination) throws -> Result) 
                rethrows -> Result? 
            {
                guard let descriptor:Descriptor = fopen(path, "wb")
                else
                {
                    return nil
                }
                
                var file:Destination = .init(descriptor: descriptor)
                defer 
                {
                    fclose(file.descriptor)
                }
                
                return try body(&file)
            }
            
            /** 
                Write the bytes in the given array to this file interface.
                
                This method only returns `()` if the entire array argument could 
                be written. This method advances the file pointer.
                
                - Parameters:
                    - buffer: The data to write.
                - Returns: `()` if the entire array argument could be written, or 
                    `nil` otherwise.
            */
            public 
            func write(_ buffer:[UInt8]) -> Void? 
            {
                let count:Int = buffer.withUnsafeBufferPointer 
                {
                    fwrite($0.baseAddress, MemoryLayout<UInt8>.stride, 
                        $0.count, self.descriptor)
                }
                
                guard count == buffer.count 
                else 
                {
                    return nil 
                }
                
                return ()
            }
        }
    }
    
    /** 
        Returns the value of the paeth filter function with the given parameters.
    */
    private static 
    func paeth(_ a:UInt8, _ b:UInt8, _ c:UInt8) -> UInt8
    {
        let v:Math<Int16>.V3 = Math.cast(truncatingIfNeeded: (a, b, c), as: Int16.self), 
            p:Int16          = v.x + v.y - v.z
        let d:Math<Int16>.V3 = Math.abs(Math.sub((p, p, p), v))

        if d.x <= d.y && d.x <= d.z
        {
            return a
        }
        else if d.y <= d.z
        {
            return b
        }
        else 
        {
            return c
        }
    }
    
    /**
        The global properties of a PNG image.
    */
    public 
    struct Properties
    {
        /** 
            A pixel format used to encode the color values of a PNG. 
            
            Pixel formats consist of a color format, and a color depth. 
            
            Color formats can have multiple components, one for each independent 
            dimension pixel values encoded in this format have. A grayscale format, 
            for example, has one component (value), while an RGBA format has four 
            (red, green, blue, alpha).
            
            Components are separate from channels, which are the independent values 
            needed to *encode*a pixel value in a PNG image. An indexed pixel format, 
            for example, has only one channel — a scalar index into a palette table — 
            but has three components, as the entries in the palette table encode 
            red, green, and blue components.
            
            Color depth refers to the number of bits of precision used to encode 
            each channel. 
            
            Not all combinations of color formats and color depths are allowed. 
            
            | *depth* |  indexed   |   grayscale   | grayscale-alpha |   RGB   |   RGBA   |
            | ------- | ---------- | ------------- | --------------- | ------- | -------- |
            |    1    | `indexed1` | `grayscale1`  | 
            |    2    | `indexed2` | `grayscale2`  | 
            |    4    | `indexed4` | `grayscale4`  | 
            |    8    | `indexed8` | `grayscale8`  | `grayscale_a8`  | `rgb8`  | `rgba8`  |
            |    16   |            | `grayscale16` | `grayscale_a16` | `rgb16` | `rgba16` |
            
        */
        public 
        enum Format:UInt16 
        {
            // bitfield contains depth in upper byte, then code in lower byte
            case grayscale1     = 0x01_00,
                 grayscale2     = 0x02_00,
                 grayscale4     = 0x04_00,
                 grayscale8     = 0x08_00,
                 grayscale16    = 0x10_00,
                 rgb8           = 0x08_02,
                 rgb16          = 0x10_02,
                 indexed1       = 0x01_03,
                 indexed2       = 0x02_03,
                 indexed4       = 0x04_03,
                 indexed8       = 0x08_03,
                 grayscale_a8   = 0x08_04,
                 grayscale_a16  = 0x10_04,
                 rgba8          = 0x08_06,
                 rgba16         = 0x10_06
            
            /**
                A boolean value indicating if this pixel format has indexed color.
                
                `true` if `self` is `indexed1`, `indexed2`, `indexed4`, or `indexed8`. 
                `false` otherwise.
            */
            public 
            var isIndexed:Bool 
            {
                return self.rawValue & 1 != 0
            }
            
            /**
                A boolean value indicating if this pixel format has at least three 
                color components.
                
                `true` if `self` is `indexed1`, `indexed2`, `indexed4`, `indexed8`, 
                `rgb8`, `rgb16`, `rgba8`, or `rgba16`. `false` otherwise.
            */
            public 
            var hasColor:Bool 
            {
                return self.rawValue & 2 != 0
            }
            
            /**
                A boolean value indicating if this pixel format has an alpha channel.
                
                `true` if `self` is `grayscale_a8`, `grayscale_a16`, `rgba8`, or 
                `rgba16`. `false` otherwise.
            */
            public 
            var hasAlpha:Bool 
            {
                return self.rawValue & 4 != 0
            }
            
            /**
                The bit depth of each channel of this pixel format.
            */
            public 
            var depth:Int
            {
                return .init(self.rawValue >> 8)
            }
            
            /** 
                The number of channels encoded by this pixel format.
            */
            public 
            var channels:Int
            {
                switch self
                {
                case .grayscale1, .grayscale2, .grayscale4, .grayscale8, .grayscale16,
                    .indexed1, .indexed2, .indexed4, .indexed8:
                    return 1
                case .grayscale_a8, .grayscale_a16:
                    return 2
                case .rgb8, .rgb16:
                    return 3
                case .rgba8, .rgba16:
                    return 4
                }
            }
            
            /** 
                The total number of bits needed to encode all channels of this pixel 
                format.
            */
            var volume:Int 
            {
                return self.depth * self.channels 
            }
            
            /** 
                The number of components represented by this pixel format.
            */
            public 
            var components:Int 
            {
                //        base +     2 × colored     +    alpha
                return .init(1 + (self.rawValue & 2) + (self.rawValue & 4) >> 2)
            }
            
            /** 
                Returns the shape of a buffer just large enough to contain an image 
                of the given size, stored in this color format.
            */
            func shape(from size:Math<Int>.V2) -> Shape 
            {
                let scanlineBitCount:Int = size.x * self.channels * self.depth
                                                // ceil(scanlineBitCount / 8)
                let pitch:Int = scanlineBitCount >> 3 + (scanlineBitCount & 7 == 0 ? 0 : 1)
                return .init(pitch: pitch, size: size)
            }
        }
        
        struct Shape 
        {
            let pitch:Int, 
                size:Math<Int>.V2
            
            var byteCount:Int 
            {
                return self.pitch * self.size.y
            }
        }
        
        enum Interlacing 
        {
            struct SubImage 
            {
                let shape:Shape, 
                    strider:Math<StrideTo<Int>>.V2
            }
            
            // don’t store whole-image shape in .none case since we still need 
            // it in the .adam7 case
            case none, 
                 adam7([SubImage])
            
            static 
            func computeAdam7Ranges(_ subImages:[SubImage]) -> [Range<Int>]
            {
                var accumulator:Int = 0
                return subImages.map
                {
                    let upper:Int = accumulator + $0.shape.byteCount 
                    defer 
                    {
                        accumulator = upper 
                    }
                    
                    return accumulator ..< upper
                }
            }
        }
        
        struct Pitches:Sequence, IteratorProtocol 
        {
            private 
            let footprints:[(pitch:Int, height:Int)]
            
            private 
            var f:Int         = 0, 
                scanlines:Int = 0
            
            init(subImages:[Interlacing.SubImage]) 
            {
                self.footprints = subImages.map 
                {
                    ($0.shape.pitch, $0.shape.size.y)
                }
            }
            
            init(shape:Shape)
            {
                self.footprints = [(shape.pitch, shape.size.y)]
            }
            
            mutating 
            func next() -> Int?? 
            {
                let f:Int = self.f
                while self.scanlines == 0  
                {
                    guard self.f < self.footprints.count
                    else 
                    {
                        return nil  
                    }
                    
                    if self.footprints[self.f].pitch == 0 
                    {
                        self.scanlines = 0
                    }
                    else 
                    {
                        self.scanlines = self.footprints[self.f].height
                    }
                    
                    self.f += 1
                }
                
                self.scanlines -= 1 
                return self.f != f ? self.footprints[self.f - 1].pitch : .some(nil)
            }
        }
        
        // stored properties 
        public 
        let format:Format
        
        public 
        var palette:[RGBA<UInt8>]?,
            chromaKey:RGBA<UInt16>? // the alpha sample is ignored by the library
        
        let shape:Shape, 
            interlacing:Interlacing
        
        // computed properties 
        public 
        var interlaced:Bool
        {
            if case .adam7 = self.interlacing 
            {
                return true 
            }
            else 
            {
                return false
            }
        }
        
        // don’t use this within the library, use `.shape.size` directly
        public 
        var size:(x:Int, y:Int)
        {
            return self.shape.size
        }
        
        var pitches:Pitches 
        {
            switch self.interlacing 
            {
                case .none:
                    return .init(shape: self.shape)
                
                case .adam7(let subImages):
                    return .init(subImages: subImages)
            }
        }
        
        var byteCount:Int 
        {
            switch self.interlacing
            {
                case .none:
                    return self.shape.byteCount 
                
                case .adam7(let subImages):
                    return subImages.reduce(0) 
                    {
                        $0 + $1.shape.byteCount
                    }
            }
        }
        
        public 
        init(size:(x:Int, y:Int), format:Format, interlaced:Bool, 
            palette:[RGBA<UInt8>]? = nil, chromaKey:RGBA<UInt16>? = nil)
        {
            self.format = format
            self.shape  = format.shape(from: size)
            
            if interlaced 
            {
                // calculate size of interlaced subimages
                // 0: (w + 7) >> 3 , (h + 7) >> 3
                // 1: (w + 3) >> 3 , (h + 7) >> 3
                // 2: (w + 3) >> 2 , (h + 3) >> 3
                // 3: (w + 1) >> 2 , (h + 3) >> 2
                // 4: (w + 1) >> 1 , (h + 1) >> 2
                // 5: (w) >> 1     , (h + 1) >> 1
                // 6: (w)          , (h) >> 1
                let sizes:[Math<Int>.V2] = 
                [
                    ((size.x + 7) >> 3, (size.y + 7) >> 3),
                    ((size.x + 3) >> 3, (size.y + 7) >> 3),
                    ((size.x + 3) >> 2, (size.y + 3) >> 3),
                    ((size.x + 1) >> 2, (size.y + 3) >> 2),
                    ((size.x + 1) >> 1, (size.y + 1) >> 2),
                    ( size.x      >> 1, (size.y + 1) >> 1),
                    ( size.x      >> 0,  size.y      >> 1)
                ]
                
                let striders:[Math<StrideTo<Int>>.V2] = 
                [
                    (stride(from: 0, to: size.x, by: 8), stride(from: 0, to: size.y, by: 8)),
                    (stride(from: 4, to: size.x, by: 8), stride(from: 0, to: size.y, by: 8)),
                    (stride(from: 0, to: size.x, by: 4), stride(from: 4, to: size.y, by: 8)),
                    (stride(from: 2, to: size.x, by: 4), stride(from: 0, to: size.y, by: 4)),
                    (stride(from: 0, to: size.x, by: 2), stride(from: 2, to: size.y, by: 4)),
                    (stride(from: 1, to: size.x, by: 2), stride(from: 0, to: size.y, by: 2)),
                    (stride(from: 0, to: size.x, by: 1), stride(from: 1, to: size.y, by: 2))
                ]
                
                let subImages:[Interlacing.SubImage] = zip(sizes, striders).map
                {
                    (size:Math<Int>.V2, strider:Math<StrideTo<Int>>.V2) in 
                    
                    return .init(shape: format.shape(from: size), strider: strider)
                }
                
                self.interlacing = .adam7(subImages)
            }
            else 
            {
                self.interlacing = .none
            }
            
            self.palette   = palette 
            self.chromaKey = chromaKey
        }
        
        
        public 
        func decoder() throws -> Decoder
        {
            let inflator:LZ77.Inflator = try .init(), 
                stride:Int             = max(1, self.format.volume >> 3)
            return .init(stride: stride, pitches: self.pitches, inflator: inflator)
        }
        public 
        func encoder(level:Int) throws -> Encoder
        {
            let deflator:LZ77.Deflator = try .init(level: level), 
                stride:Int             = max(1, self.format.volume >> 3)
            return .init(stride: stride, pitches: self.pitches, deflator: deflator)
        }
        
        public 
        struct Decoder 
        {
            private 
            var reference:[UInt8]?, 
                scanline:[UInt8] = []
            
            private 
            let stride:Int
            
            private   
            var pitches:Pitches, 
                inflator:LZ77.Inflator
            
            init(stride:Int, pitches:Pitches, inflator:LZ77.Inflator)
            {
                self.stride   = stride 
                self.pitches  = pitches
                self.inflator = inflator
                
                guard let pitch:Int = self.pitches.next() ?? nil
                else 
                {
                    return 
                }
                
                self.reference = .init(repeating: 0, count: pitch + 1)
            }
            
            public mutating 
            func forEachScanline(decodedFrom data:[UInt8], body:(ArraySlice<UInt8>) throws -> ()) throws
            {
                self.inflator.push(data)
                
                while let reference:[UInt8] = self.reference  
                {
                    let remainder:Int = try self.inflator.pull(extending: &self.scanline, 
                                                                capacity: reference.count)
                    
                    guard self.scanline.count == reference.count 
                    else 
                    {
                        break
                    }
                    
                    self.defilter(&self.scanline, reference: reference)
                    
                    try body(self.scanline.dropFirst())
                    
                    // transfer scanline to reference line 
                    if let pitch:Int? = self.pitches.next() 
                    {
                        if let pitch:Int = pitch 
                        {
                            self.reference = .init(repeating: 0, count: pitch + 1)
                        }
                        else 
                        {
                            self.reference = self.scanline 
                        }
                    }
                    else 
                    {
                        self.reference = nil 
                    }
                    
                    self.scanline = []
                    
                    guard remainder > 0 
                    else 
                    {
                        // no input (encoded data) left
                        break
                    }
                }
            }
            
            private  
            func defilter(_ scanline:inout [UInt8], reference:[UInt8])
            {
                let filter:UInt8              = scanline[scanline.startIndex] 
                scanline[scanline.startIndex] = 0
                switch filter
                {
                    case 0:
                        break 
                    
                    case 1: // sub 
                        for i:Int in scanline.indices.dropFirst(self.stride)
                        {
                            scanline[i] = scanline[i] &+ scanline[i - self.stride]
                        }
                    
                    case 2: // up 
                        for i:Int in scanline.indices
                        {
                            scanline[i] = scanline[i] &+ reference[i]
                        }
                    
                    case 3: // average 
                        for i:Int in scanline.indices.prefix(self.stride)
                        {
                            scanline[i] = scanline[i] &+ reference[i] >> 1
                        }
                        for i:Int in scanline.indices.dropFirst(self.stride) 
                        {
                            let total:UInt16  = UInt16(scanline[i - self.stride]) + 
                                                UInt16(reference[i])
                            scanline[i] = scanline[i] &+ UInt8(truncatingIfNeeded: total >> 1)
                        }
                    
                    case 4: // paeth 
                        for i:Int in scanline.indices.prefix(self.stride)
                        {
                            scanline[i] = scanline[i] &+ paeth(0, reference[i], 0)
                        }
                        for i:Int in scanline.indices.dropFirst(self.stride) 
                        {
                            let p:UInt8 =  paeth(scanline[i - self.stride], 
                                                reference[i              ], 
                                                reference[i - self.stride])
                            scanline[i] = scanline[i] &+ p
                        }
                    
                    default:
                        break // invalid
                }
            }
        }
        
        public 
        struct Encoder 
        {
            // unlike the `Decoder`, here, it’s more efficient for `reference` to 
            // *not* contain the filter byte prefix
            private 
            var reference:[UInt8]?
            
            private 
            let stride:Int 
            
            private 
            var pitches:Pitches, 
                deflator:LZ77.Deflator
            
            init(stride:Int, pitches:Pitches, deflator:LZ77.Deflator) 
            {
                self.stride   = stride 
                self.pitches  = pitches 
                self.deflator = deflator
                
                guard let pitch:Int = self.pitches.next() ?? nil
                else 
                {
                    return 
                }
                
                self.reference = .init(repeating: 0, count: pitch)
            }
            
            public mutating 
            func consolidate(extending data:inout [UInt8], capacity:Int, 
                scanlinesFrom generator:() -> ArraySlice<UInt8>?) throws 
            {
                while let reference:[UInt8] = self.reference
                {
                    guard try self.deflator.pull(extending: &data, capacity: capacity) == 0 
                    else 
                    {
                        // some input (encoded data) left, usually this means 
                        // the `data` buffer is full too 
                        return
                    }
                    
                    guard let row:ArraySlice<UInt8> = generator()
                    else 
                    {
                        return
                    }
                     
                    guard row.count == reference.count 
                    else 
                    {
                        throw WriteError.bufferCount
                    }
                    
                    let scanline:[UInt8] = self.filter(row, reference: reference)
                    
                    self.deflator.push(scanline)
                    
                    if let pitch:Int? = self.pitches.next() 
                    {
                        if let pitch:Int = pitch 
                        {
                            self.reference = .init(repeating: 0, count: pitch)
                        }
                        else 
                        {
                            self.reference = .init(row)
                        }
                    }
                    else 
                    {
                        self.reference = nil 
                    }
                }
            }
            
            // once this is called, `consolidate(extending:capacity:scanlinesFrom:)` can’t 
            // be called again after it
            public 
            func consolidate(extending data:inout [UInt8], capacity:Int) throws
            {
                assert(data.count <= capacity)
                try self.deflator.finish(extending: &data, capacity: capacity)
            }
            
            private  
            func filter(_ current:ArraySlice<UInt8>, reference:[UInt8]) -> [UInt8]
            {
                // filtering can be done in parallel 
                let candidates:(sub:[UInt8], up:[UInt8], average:[UInt8], paeth:[UInt8])
                candidates.sub =        [1] +
                current.prefix(self.stride) 
                + 
                zip(current, current.dropFirst(self.stride)).map 
                {
                    $0.1   &- $0.0
                }
                
                candidates.up =         [2] + 
                zip(reference, 
                    current).map 
                {
                    $0.1   &- $0.0
                }
                
                candidates.average =    [3] + 
                zip(reference, 
                    current).prefix(self.stride).map 
                {
                    $0.1   &- $0.0 >> 1
                } 
                + 
                zip(           reference.dropFirst(self.stride), 
                    zip(current, current.dropFirst(self.stride))).map 
                {
                    $0.1.1 &- UInt8(truncatingIfNeeded: (UInt16($0.1.0) &+ UInt16($0.0)) >> 1)
                }

                candidates.paeth =      [4] + 
                zip(reference, 
                    current).prefix(self.stride).map 
                {
                    $0.1   &- paeth(0, $0.0, 0)
                } 
                + 
                zip(zip(reference, reference.dropFirst(self.stride)), 
                    zip(current,     current.dropFirst(self.stride))).map 
                {
                    $0.1.1 &- paeth($0.1.0, $0.0.1, $0.0.0)
                }
                
                let scores:[Int] = 
                [
                    Encoder.score(current),
                    Encoder.score(candidates.0.dropFirst()),
                    Encoder.score(candidates.1.dropFirst()),
                    Encoder.score(candidates.2.dropFirst()),
                    Encoder.score(candidates.3.dropFirst())
                ]
                
                // i don’t know why this isn’t in the standard library 
                var filter:Int  = 0, 
                    minimum:Int = .max
                for (i, score) in scores.enumerated() 
                {
                    if score < minimum 
                    {
                        minimum = score 
                        filter  = i
                    }
                }
                
                switch filter 
                {
                    case 0:
                        return [0] + current 
                        
                    case 1:
                        return candidates.0
                    case 2:
                        return candidates.1
                    case 3:
                        return candidates.2
                    case 4:
                        return candidates.3
                    
                    default:
                        fatalError("unreachable: 0 <= filter < 5")
                }
            }
            
            private static 
            func score(_ filtered:ArraySlice<UInt8>) -> Int
            {
                return zip(filtered, filtered.dropFirst()).count
                {
                    $0.0 != $0.1
                }
            } 
        }
        
        public static 
        func decodeIHDR(_ data:[UInt8]) throws -> Properties
        {
            guard data.count == 13 
            else 
            {
                throw ReadError.syntaxError(message: "png header length is \(data.count), expected 13")
            }
            
            let colorcode:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 8)
            guard let format:Format = Format.init(rawValue: colorcode)
            else 
            {
                throw ReadError.syntaxError(message: "color format bytes have invalid values (\(data[8]), \(data[9]))")
            }
            
            // validate other fields 
            guard data[10] == 0 
            else 
            {
                throw ReadError.syntaxError(message: "compression byte has value \(data[10]), expected 0")
            }
            guard data[11] == 0 
            else 
            {
                throw ReadError.syntaxError(message: "filter byte has value \(data[11]), expected 0")
            }
            
            let interlaced:Bool 
            switch data[12]
            {
                case 0:
                    interlaced = false 
                case 1: 
                    interlaced = true 
                default:
                    throw ReadError.syntaxError(message: "interlacing byte has invalid value \(data[12])")
            }
            
            let width:Int  = data.load(bigEndian: UInt32.self, as: Int.self, at: 0), 
                height:Int = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
            
            return .init(size: (width, height), format: format, interlaced: interlaced)
        }
        
        public 
        func encodeIHDR() -> [UInt8] 
        {
            let header:[UInt8] = 
            [UInt8].store(self.shape.size.x,         asBigEndian: UInt32.self) + 
            [UInt8].store(self.shape.size.y,         asBigEndian: UInt32.self) + 
            [UInt8].store(self.format.rawValue, asBigEndian: UInt16.self) + 
            [0, 0, self.interlaced ? 1 : 0]
            
            return header
        }
        
        public mutating 
        func decodePLTE(_ data:[UInt8]) throws
        {
            guard data.count.isMultiple(of: 3)
            else
            {
                throw ReadError.syntaxError(message: "palette does not contain a whole number of entries (\(data.count) bytes)")
            }
            
            // check number of palette entries 
            let maxEntries:Int = 1 << self.format.depth
            guard data.count <= maxEntries * 3
            else 
            {
                throw ReadError.syntaxError(message: "palette contains too many entries (found \(data.count / 3), expected\(maxEntries))")
            }

            self.palette = stride(from: data.startIndex, to: data.endIndex, by: 3).map
            {
                let r:UInt8 = data[$0    ],
                    g:UInt8 = data[$0 + 1],
                    b:UInt8 = data[$0 + 2]
                return .init(r, g, b)
            }
        }
        
        public 
        func encodePLTE() -> [UInt8]?
        {
            guard   self.format.hasColor, 
                    let palette:[RGBA<UInt8>] = self.palette 
            else 
            {
                return nil 
            }
            
            return palette.prefix(256).flatMap 
            {
                [$0.r, $0.g, $0.b]
            }
        }
        
        public mutating 
        func decodetRNS(_ data:[UInt8]) throws
        {
            switch self.format
            {
                case .grayscale1, .grayscale2, .grayscale4, .grayscale8, .grayscale16:
                    guard data.count == 2
                    else
                    {
                        throw ReadError.syntaxError(message: "grayscale chroma key has wrong size (\(data.count) bytes, expected 2 bytes)")
                    }
                    
                    let quantum:UInt16 = RGBA<UInt16>.quantum(depth: self.format.depth), 
                        v:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
                    self.chromaKey = .init(v)
                
                case .rgb8, .rgb16:
                    guard data.count == 6
                    else
                    {
                        throw ReadError.syntaxError(message: "rgb chroma key has wrong size (\(data.count) bytes, expected 6 bytes)")
                    }
                    
                    let quantum:UInt16 = RGBA<UInt16>.quantum(depth: self.format.depth), 
                        r:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0), 
                        g:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2), 
                        b:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
                    self.chromaKey = .init(r, g, b)
                
                case .indexed1, .indexed2, .indexed4, .indexed8:
                    guard let palette:[RGBA<UInt8>] = self.palette
                    else
                    {
                        throw ReadError.missingChunk(.PLTE)
                    }

                    guard data.count <= palette.count
                    else
                    {
                        throw ReadError.syntaxError(message: "indexed image contains too many transparency entries (\(data.count), expected \(palette.count))")
                    }
                    
                    self.palette = zip(palette, data).map 
                    {
                        $0.0.withAlpha($0.1)
                    } 
                    + 
                    palette.dropFirst(data.count)
                    
                    self.chromaKey = nil
                
                default:
                    break // this is an error, but it should have already been caught by PNGConditions
            }
        }
        
        public 
        func encodetRNS() -> [UInt8]? 
        {
            switch self.format 
            {
                case .grayscale1, .grayscale2, .grayscale4, .grayscale8, .grayscale16:
                    guard let key:RGBA<UInt16> = self.chromaKey 
                    else 
                    {
                        return nil 
                    }
                    let quantization:Int = UInt16.bitWidth - self.format.depth
                    return [key.r >> quantization].flatMap
                        {
                            [UInt8].store($0, asBigEndian: UInt16.self)
                        }
                
                case .rgb8, .rgb16:
                    guard let key:RGBA<UInt16> = self.chromaKey 
                    else 
                    {
                        return nil 
                    }
                    let quantization:Int = UInt16.bitWidth - self.format.depth
                    return 
                        [
                            key.r >> quantization, 
                            key.g >> quantization, 
                            key.b >> quantization
                        ].flatMap
                        {
                            [UInt8].store($0, asBigEndian: UInt16.self)
                        }
                
                case .indexed1, .indexed2, .indexed4, .indexed8:
                    guard let palette:[RGBA<UInt8>] = self.palette
                    else
                    {
                        return nil
                    }
                    
                    var alphas:[UInt8] = palette.map{ $0.a } 
                    guard let last:Int = alphas.lastIndex(where: { $0 != UInt8.max })
                    else 
                    {
                        // palette is empty 
                        return nil
                    }
                    
                    alphas.removeLast(alphas.count - last - 1)
                    return alphas
                
                default:
                    return nil
            }
        }
    }
    
    public 
    enum Data 
    {
        // PNG data that has been decompressed, but not necessarily deinterlaced 
        public 
        struct Uncompressed 
        {
            public 
            let properties:Properties, 
                data:[UInt8]
            
            public 
            init?(_ data:[UInt8], properties:Properties) 
            {
                guard data.count == properties.byteCount 
                else 
                {
                    return nil 
                }
                
                self.properties = properties
                self.data       = data 
            }
            
            public 
            func decompose() -> [Rectangular]?
            {
                guard case .adam7(let subImages) = self.properties.interlacing 
                else 
                {
                    return nil
                }
                
                let ranges:[Range<Int>] = Properties.Interlacing.computeAdam7Ranges(subImages)
                
                return zip(ranges, subImages).map 
                {
                    (range:Range<Int>, subImage:Properties.Interlacing.SubImage) in 
                    
                    let properties:Properties = .init(size: subImage.shape.size, 
                                                    format: self.properties.format, 
                                                interlaced: false)
                    
                    return .init(.init(self.data[range]), properties: properties)
                }
            }
            
            public 
            func deinterlace() -> Rectangular 
            {
                guard case .adam7(let subImages) = self.properties.interlacing 
                else 
                {
                    // image is not interlaced at all, return it transparently 
                    return .init(self.data, properties: self.properties)
                }
                
                let properties:Properties = .init(size: self.properties.shape.size, 
                                                format: self.properties.format, 
                                            interlaced: false, 
                                               palette: self.properties.palette, 
                                             chromaKey: self.properties.chromaKey)
                
                let deinterlaced:[UInt8] = .init(unsafeUninitializedCapacity: properties.byteCount)
                {
                    (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in
                    
                    let volume:Int = properties.format.volume
                    if volume < 8 
                    {
                        // initialize the buffer to 0. this makes it so we can store 
                        // bits into the buffer without needing to mask them out 
                        buffer.initialize(repeating: 0)
                        
                        var base:Int = self.data.startIndex 
                        for subImage:Properties.Interlacing.SubImage in subImages 
                        {
                            for (sy, dy):(Int, Int) in subImage.strider.y.enumerated()
                            {
                                for (sx, dx):(Int, Int) in subImage.strider.x.enumerated()
                                {
                                    // image only has 1 channel 
                                    let si:Int = (sx * volume) >> 3 + subImage.shape.pitch   * sy, 
                                        di:Int = (dx * volume) >> 3 + properties.shape.pitch * dy
                                    let sb:Int = (sx * volume) & 7, 
                                        db:Int = (dx * volume) & 7
                                    
                                    // isolate relevant bits and store them into the destination
                                    let empty:Int  = UInt8.bitWidth - volume, 
                                        bits:UInt8 = (self.data[base + si] &<< sb) &>> empty
                                    buffer[di]    |= bits &<< (empty - db)
                                }
                            }
                            
                            base += subImage.shape.byteCount
                        }
                    }
                    else 
                    {
                        let stride:Int = volume >> 3
                        
                        var base:Int = self.data.startIndex 
                        for subImage:Properties.Interlacing.SubImage in subImages 
                        {
                            for (sy, dy):(Int, Int) in subImage.strider.y.enumerated()
                            {                            
                                for (sx, dx):(Int, Int) in subImage.strider.x.enumerated()
                                {
                                    let si:Int = sx * stride + subImage.shape.pitch   * sy, 
                                        di:Int = dx * stride + properties.shape.pitch * dy
                                    
                                    for b:Int in 0 ..< stride 
                                    {
                                        buffer[di + b] = self.data[base + si + b]
                                    }
                                }
                            }
                            
                            base += subImage.shape.byteCount
                        }
                    }
                    
                    count = properties.byteCount
                }
                
                return .init(deinterlaced, properties: properties)
            }
            
            public  
            func compress<Destination>(to destination:inout Destination, 
                chunkSize:Int = 1 << 16, level:Int = 9) throws 
                where Destination:DataDestination
            {
                precondition(chunkSize >= 1, "chunk size must be positive")
                
                var iterator:ChunkIterator<Destination> = 
                    ChunkIterator.begin(destination: &destination)
                
                iterator.next(.IHDR, self.properties.encodeIHDR(), destination: &destination)
                self.properties.encodePLTE().map 
                {
                    iterator.next(.PLTE, $0, destination: &destination)
                }
                self.properties.encodetRNS().map 
                {
                    iterator.next(.tRNS, $0, destination: &destination)
                }
                
                var pitches:Properties.Pitches = self.properties.pitches, 
                    encoder:Properties.Encoder = try self.properties.encoder(level: level)
                
                var pitch:Int?, 
                    base:Int     = self.data.startIndex
                var data:[UInt8] = []
                while true 
                {
                    try encoder.consolidate(extending: &data, capacity: chunkSize) 
                    {
                        guard let update:Int? = pitches.next(), 
                              let count:Int   = update ?? pitch
                        else 
                        {
                            return nil 
                        }                        
                        defer 
                        {
                            base += count
                            pitch = count 
                        }
                        
                        return self.data[base ..< base + count]
                    }
                    
                    if data.count == chunkSize 
                    {
                        iterator.next(.IDAT, data, destination: &destination)
                        data = []
                    } 
                    else 
                    {
                        break
                    }
                }
                
                while true 
                {
                    try encoder.consolidate(extending: &data, capacity: chunkSize)
                    
                    if data.count == 0 
                    {
                        break
                    }
                    
                    iterator.next(.IDAT, data, destination: &destination)
                    data = []
                }
                
                iterator.next(.IEND, destination: &destination)
            }
            
            public static 
            func decompress<Source>(from source:inout Source) throws -> Uncompressed 
                where Source:DataSource
            {
                guard var iterator:ChunkIterator<Source> = 
                    ChunkIterator.begin(source: &source)
                else 
                {
                    throw ReadError.missingSignature 
                }
                                
                @inline(__always)
                func _next() throws -> (chunk:Chunk, contents:[UInt8])?
                {
                    guard let (name, data):((UInt8, UInt8, UInt8, UInt8), [UInt8]?) = 
                        iterator.next(source: &source) 
                    else 
                    {
                        return nil 
                    }
                    
                    guard let chunk:Chunk = Chunk.init(name)
                    else 
                    {
                        let string:String = .init(decoding: [name.0, name.1, name.2, name.3], 
                                                        as: Unicode.ASCII.self)
                        throw ReadError.syntaxError(message: "chunk '\(string)' has invalid name")
                    }
                    
                    guard let contents:[UInt8] = data 
                    else 
                    {
                        throw ReadError.corruptedChunk
                    }
                    
                    return (chunk, contents)
                }
                
                
                // first chunk must be IHDR 
                guard let (first, header):(Chunk, [UInt8]) = try _next(), 
                           first == .IHDR
                else 
                {
                    throw ReadError.missingChunk(.IHDR)
                }
                
                var properties:Properties      = try .decodeIHDR(header), 
                    decoder:Properties.Decoder = try properties.decoder()
                
                var validator:Chunk.OrderingValidator = .init(format: properties.format)
                
                var data:[UInt8] = []
                    data.reserveCapacity(properties.byteCount)
                
                while let (chunk, contents):(Chunk, [UInt8]) = try _next()
                {
                    // validate chunk ordering 
                    if let error:ReadError = validator.push(chunk)
                    {
                        throw error 
                    }

                    switch chunk 
                    {
                        case .IHDR:
                            fatalError("unreachable: validator enforces no duplicate IHDR chunks")
                        
                        case .IDAT:
                            try decoder.forEachScanline(decodedFrom: contents) 
                            {
                                data.append(contentsOf: $0)
                            }
                        
                        case .PLTE:
                            try properties.decodePLTE(contents)
                        
                        case .tRNS:
                            try properties.decodetRNS(contents)
                        
                        case .IEND:
                            guard let uncompressed:Uncompressed = 
                                Uncompressed.init(data, properties: properties)
                            else 
                            {
                                // not enough data 
                                throw ReadError.missingChunk(.IDAT)
                            }
                            
                            return uncompressed
                        
                        default:
                            break
                    }
                }
                
                throw ReadError.missingChunk(.IEND)
            }
        }
        
        // PNG data that has been deinterlaced, but may still have multiple pixels 
        // packed per byte, or indirect (indexed) pixels
        public 
        struct Rectangular 
        {
            public 
            let properties:Properties, 
                data:[UInt8]
            
            // only called directly from within the library 
            init(_ data:[UInt8], properties:Properties) 
            {
                assert(!properties.interlaced)
                assert(data.count == properties.byteCount)
                
                self.properties = properties
                self.data       = data 
            }
            
            static 
            func index(_ pixels:[RGBA<UInt8>], size:Math<Int>.V2) -> Rectangular 
            {
                fatalError("unimplemented")
            }
            
            // makes sure the passed type parameter (`Sample`) has enough bits to 
            // represent the values in the image
            @inline(__always)
            private 
            func checkWidth<Sample>(of _:Sample.Type) -> Bool 
                where Sample:FixedWidthInteger
            {
                switch self.properties.format 
                {
                    case .indexed1, .indexed2, .indexed4, .indexed8:
                        return Sample.bitWidth >= UInt8.bitWidth 
                    
                    default:
                        return Sample.bitWidth >= self.properties.format.depth
                }
            }
            
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func map<Sample, Result>(_ body:(Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger
            {
                guard self.checkWidth(of: Sample.self) 
                else 
                {
                    return nil
                }
                
                switch self.properties.format 
                {
                    case .grayscale1, .grayscale2, .grayscale4, 
                         .indexed1,   .indexed2,   .indexed4:
                        return self.mapBits(body) 
                    
                    case .grayscale8, .indexed8:
                        return self.map(from: UInt8.self, body) 
                    
                    case .grayscale16:
                        return self.map(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
                guard self.checkWidth(of: Sample.self) 
                else 
                {
                    return nil
                }
                
                switch self.properties.format 
                {
                    case .grayscale1, .grayscale2, .grayscale4, 
                         .indexed1,   .indexed2,   .indexed4:
                        return self.mapBitIntensity(body) 
                    
                    case .grayscale8, .indexed8:
                        return self.mapIntensity(from: UInt8.self, body) 
                    
                    case .grayscale16:
                        return self.mapIntensity(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
                guard self.checkWidth(of: Sample.self) 
                else 
                {
                    return nil
                }
                
                switch self.properties.format 
                {
                    case .grayscale_a8:
                        return self.mapIntensity(from: UInt8.self, body) 
                    
                    case .grayscale_a16:
                        return self.mapIntensity(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
                guard self.checkWidth(of: Sample.self) 
                else 
                {
                    return nil
                }
                
                switch self.properties.format 
                {
                    case .rgb8:
                        return self.mapIntensity(from: UInt8.self, body) 
                    
                    case .rgb16:
                        return self.mapIntensity(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
                guard self.checkWidth(of: Sample.self) 
                else 
                {
                    return nil
                }
                
                switch self.properties.format 
                {
                    case .rgba8:
                        return self.mapIntensity(from: UInt8.self, body) 
                    
                    case .rgba16:
                        return self.mapIntensity(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            
            public 
            func grayscale<Sample>(of _:Sample.Type) -> [Sample]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
                guard self.checkWidth(of: Sample.self)
                else 
                {
                    return nil
                }
                
                switch self.properties.format 
                {
                    case .grayscale1, .grayscale2, .grayscale4:
                        return self.mapBitIntensity{ $0 }
                    
                    case .grayscale8:
                        return self.mapIntensity(from: UInt8.self){ $0 }
                    
                    case .grayscale16:
                        return self.mapIntensity(from: UInt16.self){ $0 }
                    
                    case .grayscale_a8:
                        return self.mapIntensity(from: UInt8.self)
                        { 
                            (v:Sample, _:Sample) in v
                        }
                    
                    case .grayscale_a16:
                        return self.mapIntensity(from: UInt16.self)
                        { 
                            (v:Sample, _:Sample) in v
                        }
                    
                    case .rgb8:
                        return self.mapIntensity(from: UInt8.self)
                        { 
                            (r:Sample, _:Sample, _:Sample) in r
                        }
                    
                    case .rgb16:
                        return self.mapIntensity(from: UInt16.self)
                        { 
                            (r:Sample, _:Sample, _:Sample) in r
                        }
                    
                    case .rgba8:
                        return self.mapIntensity(from: UInt8.self)
                        { 
                            (r:Sample, _:Sample, _:Sample, _:Sample) in r
                        }
                    
                    case .rgba16:
                        return self.mapIntensity(from: UInt16.self)
                        { 
                            (r:Sample, _:Sample, _:Sample, _:Sample) in r
                        }
                        
                    case .indexed1, .indexed2, .indexed4:
                        guard let palette:[RGBA<UInt8>] = self.properties.palette 
                        else 
                        {
                            // missing palette, should never occur in normal circumstances
                            return nil
                        }
                        
                        // map over raw sample values instead of scaled values
                        return self.mapBits 
                        {
                            (index:Int) in 

                            // palette sample type is always UInt8 so all Swift 
                            // unsigned integer types can be used as an unscaling 
                            // target
                            return palette[index].upscale(to: Sample.self).r
                        }
                    
                    case .indexed8:
                        // same as above except loading byte-size samples
                        guard let palette:[RGBA<UInt8>] = self.properties.palette 
                        else 
                        {
                            return nil
                        }
                        
                        return self.map(from: UInt8.self)
                        {
                            (index:Int) in 
                            
                            return palette[index].upscale(to: Sample.self).r
                        }
                }
            }
            
            @inline(__always) 
            private 
            func greenscreen<Sample>(_ color:RGBA<Sample>) -> RGBA<Sample> 
            {
                // all functions that call this should use `checkWidth` to make 
                // sure Sample.bitWidth <= 16
                guard let key:RGBA<Sample> = self.properties.chromaKey?.downscale(to: Sample.self) 
                else 
                {
                    return color
                }
                
                return color.equals(opaque: key) ? color.withAlpha(0) : color
            }
            
            @inline(__always) 
            private 
            func greenscreen<Sample>(v:Sample) -> RGBA<Sample> 
            {
                return self.greenscreen(.init(v))
            }
            
            @inline(__always) 
            private 
            func greenscreen<Sample>(r:Sample, g:Sample, b:Sample) -> RGBA<Sample> 
            {
                return self.greenscreen(.init(r, g, b))
            }
            
            @_specialize(exported: true, where Sample == UInt8) 
            @_specialize(exported: true, where Sample == UInt16) 
            @_specialize(exported: true, where Sample == UInt32) 
            @_specialize(exported: true, where Sample == UInt64) 
            @_specialize(exported: true, where Sample == UInt)
            public 
            func rgba<Sample>(of _:Sample.Type) -> [RGBA<Sample>]? 
                where Sample:FixedWidthInteger & UnsignedInteger
            {
                guard self.checkWidth(of: Sample.self)
                else 
                {
                    return nil
                }
                
                // to make sure chroma keys work 
                switch self.properties.format 
                {
                    case .grayscale1, .grayscale2, .grayscale4, 
                         .grayscale8, 
                         .grayscale16, 
                         .rgb8, 
                         .rgb16:
                        guard Sample.bitWidth <= UInt16.bitWidth 
                        else 
                        {
                            return nil
                        }
                    
                    default:
                        break
                }
                
                switch self.properties.format 
                {
                    case .grayscale1, .grayscale2, .grayscale4:
                        return self.mapBitIntensity(self.greenscreen(v:)) 
                    
                    case .grayscale8:
                        return self.mapIntensity(from: UInt8.self,  self.greenscreen(v:)) 
                    
                    case .grayscale16:
                        return self.mapIntensity(from: UInt16.self, self.greenscreen(v:)) 
                    
                    case .grayscale_a8:
                        return self.mapIntensity(from: UInt8.self,  RGBA.init(_:_:)) 
                    
                    case .grayscale_a16:
                        return self.mapIntensity(from: UInt16.self, RGBA.init(_:_:)) 
                    
                    case .rgb8:
                        return self.mapIntensity(from: UInt8.self,  self.greenscreen(r:g:b:)) 
                    
                    case .rgb16:
                        return self.mapIntensity(from: UInt16.self, self.greenscreen(r:g:b:)) 
                    
                    case .rgba8:
                        return self.mapIntensity(from: UInt8.self,  RGBA.init(_:_:_:_:)) 
                    
                    case .rgba16:
                        return self.mapIntensity(from: UInt16.self, RGBA.init(_:_:_:_:)) 
                        
                    case .indexed1, .indexed2, .indexed4:
                        guard let palette:[RGBA<UInt8>] = self.properties.palette 
                        else 
                        {
                            // missing palette, should never occur in normal circumstances
                            return nil
                        }
                        
                        // map over raw sample values instead of scaled values
                        return self.mapBits 
                        {
                            (index:Int) in 

                            // palette sample type is always UInt8 so all Swift 
                            // unsigned integer types can be used as an unscaling 
                            // target
                            return palette[index].upscale(to: Sample.self)
                        }
                    
                    case .indexed8:
                        // same as above except loading byte-size samples
                        guard let palette:[RGBA<UInt8>] = self.properties.palette 
                        else 
                        {
                            return nil
                        }
                        
                        return self.map(from: UInt8.self)
                        {
                            (index:Int) in 
                            
                            return palette[index].upscale(to: Sample.self)
                        }
                }
            }
            
            public 
            func argbPremultiplied<Sample>(of _:Sample.Type) -> [Sample.FusedVector4]? 
                where Sample:FusedVector4Element
            {
                // *all* color formats can produce pixels with alpha, so we might 
                // as well call the `rgba(of:)` function and let map fusion 
                // optimize it
                return self.rgba(of: Sample.self)?.map 
                {
                    $0.premultiplied.argb
                }
            }
            
            @inline(__always)
            private 
            func load<Sample>(bits:Range<Int>, as _:Sample.Type) -> Sample 
                where Sample:FixedWidthInteger
            {
                let byte:Int      = bits.lowerBound >> 3, 
                    bit:Int       = bits.lowerBound & 7, 
                    offset:Int    = UInt8.bitWidth - bits.count
                return .init(truncatingIfNeeded: (self.data[byte] &<< bit) &>> offset)
            }
            
            @inline(__always)
            private 
            func load<T, Sample>(bigEndian:T.Type, at index:Int, as _:Sample.Type) -> Sample 
                where T:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(T.bitWidth <= Sample.bitWidth)
                
                return self.data.withUnsafeBufferPointer 
                {
                    let offset:Int               = index * MemoryLayout<T>.stride, 
                        raw:UnsafeRawPointer     = .init($0.baseAddress! + offset), 
                        pointer:UnsafePointer<T> = raw.bindMemory(to: T.self, capacity: 1)
                    return .init(truncatingIfNeeded: T(bigEndian: pointer.pointee))
                }
            }
            
            @inline(__always)
            private 
            func scale<T, Sample>(bigEndian:T.Type, at index:Int, to _:Sample.Type) -> Sample 
                where T:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                let scalar:Sample = self.load(bigEndian: T.self, at: index, as: Sample.self)
                return scalar * RGBA<Sample>.quantum(depth: self.properties.format.depth)
            }
            
            private 
            func mapBits<Sample, Result>(_ body:(Sample) -> Result) -> [Result] 
                where Sample:FixedWidthInteger
            {
                assert(self.properties.format.depth < Sample.bitWidth)
                
                return withoutActuallyEscaping(body)
                {
                    (body:@escaping (Sample) -> Result) in
                    
                    let depth:Int = self.properties.format.depth, 
                        count:Int = self.properties.format.volume * self.properties.shape.size.x
                    return stride(from: 0, to: self.data.count, by: self.properties.shape.pitch).flatMap 
                    {
                        (i:Int) -> LazyMapSequence<StrideTo<Int>, Result> in
                        
                        let base:Int = i << 3
                        return stride(from: base, to: base + count, by: depth).lazy.map 
                        {
                            body(self.load(bits: $0 ..< $0 + depth, as: Sample.self))
                        }
                    }
                }
            }
            
            private 
            func map<Atom, Sample, Result>(from _:Atom.Type, _ body:(Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger, Sample:FixedWidthInteger
            {
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(self.load(bigEndian: Atom.self, at: $0, as: Sample.self))
                }
            }
            
            private 
            func mapBitIntensity<Sample, Result>(_ body:(Sample) -> Result) -> [Result] 
                 where Sample:FixedWidthInteger & UnsignedInteger
            {
                return self.mapBits 
                {
                    return body($0 * RGBA<Sample>.quantum(depth: self.properties.format.depth))
                }
            }
            
            private 
            func mapIntensity<Atom, Sample, Result>(from _:Atom.Type, 
                                                    _ body:(Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(self.scale(bigEndian: Atom.self, at: $0, to: Sample.self))
                }
            }
            
            private 
            func mapIntensity<Atom, Sample, Result>(from _:Atom.Type, 
                                                    _ body:(Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.scale(bigEndian: Atom.self, at: $0 << 1,     to: Sample.self), 
                        self.scale(bigEndian: Atom.self, at: $0 << 1 | 1, to: Sample.self))
                }
            }
            
            private 
            func mapIntensity<Atom, Sample, Result>(from _:Atom.Type, 
                                                    _ body:(Sample, Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.scale(bigEndian: Atom.self, at: $0 * 3,      to: Sample.self), 
                        self.scale(bigEndian: Atom.self, at: $0 * 3 + 1,  to: Sample.self), 
                        self.scale(bigEndian: Atom.self, at: $0 * 3 + 2,  to: Sample.self))
                }
            }
            
            private 
            func mapIntensity<Atom, Sample, Result>(from _:Atom.Type, 
                                                    _ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result] 
                 where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                assert(self.properties.format.depth == Atom.bitWidth)
                
                return (0 ..< Math.vol(self.properties.shape.size)).map 
                {
                    return body(
                        self.scale(bigEndian: Atom.self, at: $0 << 2,      to: Sample.self), 
                        self.scale(bigEndian: Atom.self, at: $0 << 2 | 1,  to: Sample.self), 
                        self.scale(bigEndian: Atom.self, at: $0 << 2 | 2,  to: Sample.self), 
                        self.scale(bigEndian: Atom.self, at: $0 << 2 | 3,  to: Sample.self))
                }
            }
        }
    }
    
    public 
    struct Chunk:Hashable, Equatable, CustomStringConvertible
    {
        let name:Math<UInt8>.V4
        
        public
        var description:String 
        {
            return .init( decoding: [self.name.0, self.name.1, self.name.2, self.name.3], 
                                as: Unicode.ASCII.self)
        }
        
        private 
        init(_ a:UInt8, _ p:UInt8, _ r:UInt8, _ c:UInt8)
        {
            self.name = (a, p, r, c)
        }
        
        public  
        init?(_ name:(UInt8, UInt8, UInt8, UInt8))
        {
            self.name = name
            switch self 
            {
                // legal public chunks 
                case .IHDR, .PLTE, .IDAT, .IEND, 
                     .cHRM, .gAMA, .iCCP, .sBIT, .sRGB, .bKGD, .hIST, .tRNS, 
                     .pHYs, .sPLT, .tIME, .iTXt, .tEXt, .zTXt:
                    break 

                default:
                    guard name.0 & 0x20 != 0 
                    else 
                    {
                        return nil
                    }

                    guard name.2 & 0x20 == 0 
                    else 
                    {
                        return nil
                    }
            }
        }
        
        public static 
        func == (a:Chunk, b:Chunk) -> Bool 
        {
            return a.name == b.name
        }
        
        public 
        func hash(into hasher:inout Hasher) 
        {
            hasher.combine( self.name.0 << 24 | 
                            self.name.1 << 16 | 
                            self.name.2 <<  8 | 
                            self.name.3)
        }
        
        public static 
        let IHDR:Chunk = .init(73, 72, 68, 82), 
            PLTE:Chunk = .init(80, 76, 84, 69), 
            IDAT:Chunk = .init(73, 68, 65, 84), 
            IEND:Chunk = .init(73, 69, 78, 68), 
            
            cHRM:Chunk = .init(99, 72, 82, 77), 
            gAMA:Chunk = .init(103, 65, 77, 65), 
            iCCP:Chunk = .init(105, 67, 67, 80), 
            sBIT:Chunk = .init(115, 66, 73, 84), 
            sRGB:Chunk = .init(115, 82, 71, 66), 
            bKGD:Chunk = .init(98, 75, 71, 68), 
            hIST:Chunk = .init(104, 73, 83, 84), 
            tRNS:Chunk = .init(116, 82, 78, 83), 
            
            pHYs:Chunk = .init(112, 72, 89, 115), 
            
            sPLT:Chunk = .init(115, 80, 76, 84), 
            tIME:Chunk = .init(116, 73, 77, 69), 
            
            iTXt:Chunk = .init(105, 84, 88, 116), 
            tEXt:Chunk = .init(116, 69, 88, 116), 
            zTXt:Chunk = .init(122, 84, 88, 116)
        
        // performs chunk ordering and presence validation
        struct OrderingValidator 
        {
            private 
            var format:Properties.Format, 
                last:Chunk, 
                seen:Set<Chunk>
            
            init(format:Properties.Format) 
            {
                self.format = format 
                self.last   =  .IHDR
                self.seen   = [.IHDR] 
            }
            
            mutating 
            func push(_ chunk:Chunk) -> ReadError? 
            {                
                guard self.last != .IEND
                else 
                {
                    return .prematureIEND
                }
            
                if      chunk ==                                                                  .tRNS
                {
                    guard !self.format.hasAlpha // tRNS forbidden in alpha’d formats
                    else
                    {
                        return .illegalChunk(chunk)
                    }
                }
                else if chunk ==   .PLTE
                {
                    // PLTE must come before bKGD, hIST, and tRNS
                    guard self.format.hasColor // PLTE requires non-grayscale format
                    else
                    {
                        return .illegalChunk(chunk)
                    }

                    if self.seen.contains(.bKGD) || self.seen.contains(.hIST) || self.seen.contains(.tRNS)
                    {
                        return .misplacedChunk(chunk)
                    }
                }

                // these chunks must occur before PLTE
                switch chunk
                {
                    case                         .cHRM, .gAMA, .iCCP, .sBIT, .sRGB:
                        if self.seen.contains(.PLTE)
                        {
                            return .misplacedChunk(chunk)
                        }
                        
                        fallthrough 
                    
                    // these chunks (and the ones in previous cases) must occur before IDAT
                    case           .PLTE,                                           .bKGD, .hIST, .tRNS, .pHYs, .sPLT:
                        if self.seen.contains(.IDAT)
                        {
                            return .misplacedChunk(chunk)
                        }
                        
                        fallthrough 
                    
                    // these chunks (and the ones in previous cases) cannot duplicate
                    case    .IHDR,                                                                                     .tIME:
                        if self.seen.contains(chunk)
                        {
                            return .duplicateChunk(chunk)
                        }
                    
                    
                    // IDAT blocks much be consecutive
                    case .IDAT:
                        if  self.last != .IDAT, 
                            self.seen.contains(.IDAT)
                        {
                            return .misplacedChunk(.IDAT)
                        }

                        if  self.format.isIndexed, 
                           !self.seen.contains(.PLTE)
                        {
                            return .missingChunk(.PLTE)
                        }
                        
                    default:
                        break
                }
                
                self.seen.insert(chunk)
                self.last = chunk
                return nil
            }
        }
    }
    
    public 
    enum ReadError:Error
    {
        case incompleteChunk,  
            
             syntaxError(message: String), 
             
             missingSignature, 
             prematureIEND, 
             corruptedChunk, 
             illegalChunk(Chunk), 
             misplacedChunk(Chunk), 
             duplicateChunk(Chunk), 
             missingChunk(Chunk)
    }
    
    public 
    enum WriteError:Error 
    {
        case bufferCount
    }

    // empty struct to namespace our chunk iteration methods. we can’t store the 
    // data source as it may have reference semantics even though implemented as 
    // a struct 
    public 
    struct ChunkIterator<DataInterface> 
    {
    }    
}

extension PNG.ChunkIterator where DataInterface:DataSource 
{
    public static 
    func begin(source:inout DataInterface) -> PNG.ChunkIterator<DataInterface>? 
    {
        guard let bytes:[UInt8] = source.read(count: PNG.signature.count), 
                  bytes == PNG.signature
        else 
        {
            return nil 
        }
        
        return .init()
    }
    
    public mutating 
    func next(source:inout DataInterface) -> (name:(UInt8, UInt8, UInt8, UInt8), data:[UInt8]?)? 
    {
        guard let header:[UInt8] = source.read(count: 8) 
        else 
        {
            return nil 
        }
        
        let length:Int = header.prefix(4).load(bigEndian: UInt32.self, as: Int.self), 
            name:Math<UInt8>.V4 = (header[4], header[5], header[6], header[7]) 
        
        guard var data:[UInt8] = source.read(count: length + MemoryLayout<UInt32>.size)
        else 
        {
            return (name, nil)
        }
        
        let checksum:UInt = data.suffix(4).load(bigEndian: UInt32.self, as: UInt.self)
        
        data.removeLast(4)
        
        let testsum:UInt  = header.suffix(4).withUnsafeBufferPointer
        {
            return crc32(crc32(0, $0.baseAddress, 4), data, UInt32(length))
        } 
        guard testsum == checksum
        else 
        {
            return (name, nil)
        }
        
        return (name, data)
    }
}

extension PNG.ChunkIterator where DataInterface:DataDestination 
{
    public static 
    func begin(destination:inout DataInterface) -> PNG.ChunkIterator<DataInterface> 
    {
        destination.write(PNG.signature)
        return .init()
    }
    
    public mutating 
    func next(_ name:PNG.Chunk, _ data:[UInt8] = [], destination:inout DataInterface) 
    {
        let header:[UInt8] = .store(data.count, asBigEndian: UInt32.self) 
        + 
        [name.name.0, name.name.1, name.name.2, name.name.3]
        
        destination.write(header)
        destination.write(data)
        
        let partial:UInt = header.suffix(4).withUnsafeBufferPointer 
        {
            crc32(0, $0.baseAddress, 4)
        }
        
        // crc has 32 significant bits, padded out to a UInt
        let crc:UInt = crc32(partial, data, UInt32(data.count))
        
        destination.write(.store(crc, asBigEndian: UInt32.self))
    }
}
