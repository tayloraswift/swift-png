#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

import func zlib.crc32

extension Array where Element == UInt8 
{
    /** Loads a misaligned big-endian integer value from the given byte offset 
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
    
    /** Decomposes the given integer value into its constituent bytes, in big-endian order.
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

public 
protocol _VAColor
{
    associatedtype Component:FixedWidthInteger & UnsignedInteger
    var v:Component 
    {
        get 
    }
    var a:Component 
    {
        get 
    }
}
public 
protocol _RGBAColor 
{
    associatedtype Component:FixedWidthInteger & UnsignedInteger
    var r:Component 
    {
        get 
    }
    var g:Component 
    {
        get 
    }
    var b:Component 
    {
        get 
    }
    var a:Component 
    {
        get 
    }
}

extension Array where Element:_VAColor
{
    /** Converts this matrix of grayscale-alpha colors into a planar representation.
        
        *Inlinable*.
        
        - Returns: An array of the value components of this matrix, in row-major 
            order, followed by the components samples of this matrix, also in row-major 
            order.
    */
    @inlinable
    public 
    func planar() -> [Element.Component] 
    {
        var planar:[Element.Component] = []
            planar.reserveCapacity(self.count << 1)
        for pixel:Element in self 
        {
            planar.append(pixel.v)
        }
        for pixel:Element in self 
        {
            planar.append(pixel.a)
        }
        return planar
    }
    
    /** Flattens this matrix of grayscale-alpha colors into an unstructured array 
        of its interleaved components.
        
        *Inlinable*.
        
        - Returns: An unstructured array containing interleaved color components 
            in value, alpha order.
        
        - Note: In most cases, it is better to temporarily rebind a structured pixel 
            matrix to a flattened array type than to convert it to interleaved form.
    */
    @inlinable
    public 
    func interleaved() -> [Element.Component] 
    {
        // flatMap is too slow sadly 
        var flattened:[Element.Component] = []
            flattened.reserveCapacity(self.count << 1)
        for pixel:Element in self 
        {
            flattened.append(pixel.v)
            flattened.append(pixel.a)
        }
        return flattened
    }
}
extension Array where Element:_RGBAColor
{
    /** Converts this matrix of RGBA colors into a planar representation.
        
        - Returns: An array of the red components of this matrix, followed by the 
            green, blue, and alpha components of this matrix, all in row-major order.
    */
    @inlinable
    public 
    func planar() -> [Element.Component] 
    {
        var planar:[Element.Component] = []
            planar.reserveCapacity(self.count << 2)
        for pixel:Element in self 
        {
            planar.append(pixel.r)
        }
        for pixel:Element in self 
        {
            planar.append(pixel.g)
        }
        for pixel:Element in self 
        {
            planar.append(pixel.b)
        }
        for pixel:Element in self 
        {
            planar.append(pixel.a)
        }
        return planar
    }
    
    /** Flattens this matrix of grayscale-alpha colors into an unstructured array 
        of its interleaved components.
        
        *Inlinable*.
        
        - Returns: An unstructured array containing interleaved color components 
            in red, green, blue, alpha order.
        
        - Note: In most cases, it is better to temporarily rebind a structured pixel 
            matrix to a flattened array type than to convert it to interleaved form.
    */
    @inlinable
    public 
    func interleaved() -> [Element.Component] 
    {
        // flatMap is too slow sadly 
        var flattened:[Element.Component] = []
            flattened.reserveCapacity(self.count << 2)
        for pixel:Element in self 
        {
            flattened.append(pixel.r)
            flattened.append(pixel.g)
            flattened.append(pixel.b)
            flattened.append(pixel.a)
        }
        return flattened
    }
}

extension ArraySlice where Element == UInt8 
{
    /** Loads this array slice as a misaligned big-endian integer value, 
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

/** An abstract data source. To provide a custom data source to the library, conform 
    your type to this protocol by implementing the `read(count:)` method. */
public 
protocol DataSource
{
    /** Read the specified number of bytes from this data source.
        - Parameters:
            - count: The number of bytes to read.
        - Returns: An array of size `count`, if `count` bytes could be read, and 
            `nil` otherwise.
    */
    mutating 
    func read(count:Int) -> [UInt8]?
}
/** An abstract data destination. To specify a custom data destination for the library, 
    conform your type to this protocol by implementing the `write(_:)` method. */
public 
protocol DataDestination 
{
    /** Write the given data buffer to this data destination.
        - Parameters:
            - buffer: The data to write.
        - Returns: `()` on success, and `nil` otherwise.
    */
    mutating 
    func write(_ buffer:[UInt8]) -> Void?
}

/** A fixed-width integer type which can be packed in groups of four within another 
    integer type. For example, four `UInt8`s may be packed into a single `UInt32`. */
public 
protocol FusedVector4Element:FixedWidthInteger & UnsignedInteger 
{
    /// A fixed-width integer type which can hold four instances of `Self`.
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
    /** The components of this pixel value packed into a single unsigned integer in 
        ARGB order, with the alpha component in the high bits. 
        
        *Inlinable*. */
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

/// Encode and decode image data in the PNG format.
public 
enum PNG
{
    private static 
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
    /** A two-component color value, with components stored in the grayscale-alpha 
        color model. This structure has fixed layout, with the value component first, 
        then alpha. Buffers containing instances of this type may be safely reinterpreted 
        as flat buffers containing interleaved components. */
    @_fixed_layout 
    public 
    struct VA<Component>:Equatable, CustomStringConvertible, _VAColor
        where Component:FixedWidthInteger & UnsignedInteger 
    {
        /// The value component of this color.
        public 
        let v:Component 
        /// The alpha component of this color.
        public 
        let a:Component
        
        /// A textual representation of this color.
        public
        var description:String
        {
            return "(\(self.v), \(self.a))"
        }
        
        /** Creates an opaque grayscale color with the value component set to the 
            given value sample, and the alpha component set to `Component.max`. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - value: The value to initialize the value component to.
        */
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
        public
        init(_ value:Component)
        {
            self.init(value, Component.max)
        }
        
        /** Creates a grayscale color with the value component set to the given 
            value sample, and the alpha component set to the given alpha sample. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - value: The value to initialize the value component to.
                - alpha: The value to initialize the alpha component to.
        */
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
        public
        init(_ value:Component, _ alpha:Component)
        {
            self.v = value 
            self.a = alpha
        }
        
        /** Returns a copy of this color with the alpha component set to the given sample.
            - Parameters:
                - a: An alpha sample.
            - Returns: This color with the alpha component set to the given sample.
        */
        func withAlpha(_ a:Component) -> VA<Component>
        {
            return .init(self.v, a)
        }
        
        /** The color obtained by premultiplying the value component of this color 
            with its alpha component. The resulting component values are accurate 
            to within 1 `Component` unit.
            
            *Inlinable*.
        */
        @inlinable
        public
        var premultiplied:VA<Component>
        {
            return .init(VA.premultiply(color: self.v, alpha: self.a), self.a)
        }
        
        
        /** Returns the given color sample premultiplied with the given alpha sample.
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - color: A color sample.
                - alpha: An alpha sample.
            - Returns: The product of the given color sample and the given alpha 
                sample. The resulting value is accurate to within 1 `Component` unit.
        */
        @usableFromInline 
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
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
        
        
        /** Returns the size of one unit in a component of the given depth, in units of 
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
        
        
        /** Returns this color with its components widened to the given type, preserving 
            their normalized values. 
            
            `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
            - Parameters:
                - type: The type of the components of the new color.
            - Returns: A new color, with the values of its components taken from 
                this color, and normalized to the range of `T`. 
        */
        @inline(__always)
        func upscale<T>(to type:T.Type) -> VA<T> where T:FixedWidthInteger & UnsignedInteger
        {
            assert(T.bitWidth >= Component.bitWidth)
            let quantum:T = VA<T>.quantum(depth: Component.bitWidth), 
                v:T = .init(truncatingIfNeeded: self.v) * quantum, 
                a:T = .init(truncatingIfNeeded: self.a) * quantum
            return .init(v, a)
        }
        
        /** Returns this color with its components narrowed to the given type, preserving 
            their normalized values. 
            
            `T.bitWidth` must be less than or equal to `Component.bitWidth`.
            - Parameters:
                - type: The type of the components of the new color.
            - Returns: A new color, with the values of its components taken from 
                this color, and normalized to the range of `T`. 
        */
        @inline(__always)
        func downscale<T>(to type:T.Type) -> VA<T> where T:FixedWidthInteger & UnsignedInteger
        {
            assert(T.bitWidth <= Component.bitWidth)
            let shift:Int = Component.bitWidth - T.bitWidth, 
                v:T       = .init(truncatingIfNeeded: self.v &>> shift),
                a:T       = .init(truncatingIfNeeded: self.a &>> shift)
            
            return .init(v, a)
        }
    }
    
    /** A four-component color value, with components stored in the RGBA color model. 
        This structure has fixed layout, with the red component first, then green, 
        then blue, then alpha. Buffers containing instances of this type may be 
        safely reinterpreted as flat buffers containing interleaved components. */
    @_fixed_layout
    public
    struct RGBA<Component>:Equatable, CustomStringConvertible, _RGBAColor
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
        
        /** Creates an opaque grayscale color with all color components set to the given 
            value sample, and the alpha component set to `Component.max`. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - value: The value to initialize all color components to.
        */
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
        public
        init(_ value:Component)
        {
            self.init(value, value, value, Component.max)
        }
        
        /** Creates a grayscale color with all color components set to the given 
            value sample, and the alpha component set to the given alpha sample. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - value: The value to initialize all color components to.
                - alpha: The value to initialize the alpha component to.
        */
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
        public
        init(_ value:Component, _ alpha:Component)
        {
            self.init(value, value, value, alpha)
        }
        
        /** Creates an opaque color with the given color samples, and the alpha 
            component set to `Component.max`. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - red: The value to initialize the red component to.
                - green: The value to initialize the green component to.
                - blue: The value to initialize the blue component to.
        */
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
        public
        init(_ red:Component, _ green:Component, _ blue:Component)
        {
            self.init(red, green, blue, Component.max)
        }
        
        /** Creates an opaque color with the given color and alpha samples. 
            
            *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64, 
                and `UInt`. 
            - Parameters:
                - red: The value to initialize the red component to.
                - green: The value to initialize the green component to.
                - blue: The value to initialize the blue component to.
                - alpha: The value to initialize the alpha component to.
        */
        @_specialize(exported: true, where Component == UInt8) 
        @_specialize(exported: true, where Component == UInt16) 
        @_specialize(exported: true, where Component == UInt32) 
        @_specialize(exported: true, where Component == UInt64) 
        @_specialize(exported: true, where Component == UInt)
        public
        init(_ red:Component, _ green:Component, _ blue:Component, _ alpha:Component)
        {
            self.r = red
            self.g = green
            self.b = blue
            self.a = alpha
        }
        
        /** The color obtained by premultiplying the red, green, and blue components 
            of this color with its alpha component. The resulting component values 
            are accurate to within 1 `Component` unit.
            
            *Inlinable*.
        */
        @inlinable
        public
        var premultiplied:RGBA<Component>
        {
            return .init(VA.premultiply(color: self.r, alpha: self.a), 
                         VA.premultiply(color: self.g, alpha: self.a), 
                         VA.premultiply(color: self.b, alpha: self.a), 
                         self.a)
        }
        
        /** The red, and alpha components of this color, stored as a grayscale-alpha 
            color.
            
            *Inlinable*.
        */
        @inlinable
        public
        var va:VA<Component>
        {
            return .init(self.r, self.a)
        }
        
        /** Returns a copy of this color with the alpha component set to the given sample.
            - Parameters:
                - a: An alpha sample.
            - Returns: This color with the alpha component set to the given sample.
        */
        func withAlpha(_ a:Component) -> RGBA<Component>
        {
            return .init(self.r, self.g, self.b, a)
        }

        /** Returns a boolean value indicating whether the color components of this 
            color are equal to the color components of the given color, ignoring 
            the alpha components.
            - Parameters:
                - other: Another color.
            - Returns: `true` if the red, green, and blue components of this color 
                and `other` are equal, `false` otherwise.
        */
        func equals(opaque other:RGBA<Component>) -> Bool
        {
            return self.r == other.r && self.g == other.g && self.b == other.b
        }
        
        /** Returns this color with its components widened to the given type, preserving 
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
            let quantum:T = VA<T>.quantum(depth: Component.bitWidth), 
                r:T = .init(truncatingIfNeeded: self.r) * quantum, 
                g:T = .init(truncatingIfNeeded: self.g) * quantum, 
                b:T = .init(truncatingIfNeeded: self.b) * quantum, 
                a:T = .init(truncatingIfNeeded: self.a) * quantum
            return .init(r, g, b, a)
        }
        
        /** Returns this color with its components narrowed to the given type, preserving 
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
                b:T       = .init(truncatingIfNeeded: self.b &>> shift),
                a:T       = .init(truncatingIfNeeded: self.a &>> shift)
            
            return .init(r, g, b, a)
        }
    }
    
    /// A namespace for file IO functionality.
    public 
    enum File
    {
        private 
        typealias Descriptor = UnsafeMutablePointer<FILE>
        
        public 
        enum Error:Swift.Error 
        {
            /// A file could not be opened. 
            ///
            /// This error is not thrown by any `File` methods, but is used by users 
            /// of these APIs.
            case couldNotOpen
        }
        
        /// Read data from files on disk.
        public 
        struct Source:DataSource 
        {
            private 
            let descriptor:Descriptor
            
            /** Calls a closure with an interface for reading from the specified file.
                
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
            
            /** Read the specified number of bytes from this file interface.
                
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
        
        /// Write data to files on disk.
        public 
        struct Destination:DataDestination 
        {
            private 
            let descriptor:Descriptor
            
            /** Calls a closure with an interface for writing to the specified file.
                
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
            
            /** Write the bytes in the given array to this file interface.
                
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
    
    /// Returns the value of the paeth filter function with the given parameters.
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
    
    /// The global properties of a PNG image.
    public 
    struct Properties
    {
        /** A pixel format used to encode the color values of a PNG. 
            
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
            |    1    | `indexed1` | `v1`          | 
            |    2    | `indexed2` | `v2`          | 
            |    4    | `indexed4` | `v4`          | 
            |    8    | `indexed8` | `v8`          | `va8`           | `rgb8`  | `rgba8`  |
            |    16   |            | `v16`         | `va16`          | `rgb16` | `rgba16` |
            
        */
        public 
        enum Format:UInt16 
        {
            // bitfield contains depth in upper byte, then code in lower byte
            case v1         = 0x01_00,
                 v2         = 0x02_00,
                 v4         = 0x04_00,
                 v8         = 0x08_00,
                 v16        = 0x10_00,
                 rgb8       = 0x08_02,
                 rgb16      = 0x10_02,
                 indexed1   = 0x01_03,
                 indexed2   = 0x02_03,
                 indexed4   = 0x04_03,
                 indexed8   = 0x08_03,
                 va8        = 0x08_04,
                 va16       = 0x10_04,
                 rgba8      = 0x08_06,
                 rgba16     = 0x10_06
            
            /** A boolean value indicating if this pixel format has indexed color.
                
                `true` if `self` is `indexed1`, `indexed2`, `indexed4`, or `indexed8`. 
                `false` otherwise.
            */
            public 
            var isIndexed:Bool 
            {
                return self.rawValue & 1 != 0
            }
            
            /** A boolean value indicating if this pixel format has at least three 
                color components.
                
                `true` if `self` is `indexed1`, `indexed2`, `indexed4`, `indexed8`, 
                `rgb8`, `rgb16`, `rgba8`, or `rgba16`. `false` otherwise.
            */
            public 
            var hasColor:Bool 
            {
                return self.rawValue & 2 != 0
            }
            
            /** A boolean value indicating if this pixel format has an alpha channel.
                
                `true` if `self` is `va8`, `va16`, `rgba8`, or 
                `rgba16`. `false` otherwise. 
            */
            public 
            var hasAlpha:Bool 
            {
                return self.rawValue & 4 != 0
            }
            
            /// The bit depth of each channel of this pixel format.
            public 
            var depth:Int
            {
                return .init(self.rawValue >> 8)
            }
            
            /// The number of channels encoded by this pixel format.
            public 
            var channels:Int
            {
                switch self
                {
                case .v1, .v2, .v4, .v8, .v16,
                    .indexed1, .indexed2, .indexed4, .indexed8:
                    return 1
                case .va8, .va16:
                    return 2
                case .rgb8, .rgb16:
                    return 3
                case .rgba8, .rgba16:
                    return 4
                }
            }
            
            /** The total number of bits needed to encode all channels of this pixel 
                format. */
            var volume:Int 
            {
                return self.depth * self.channels 
            }
            
            /// The number of components represented by this pixel format.
            public 
            var components:Int 
            {
                //        base +     2 × colored     +    alpha
                return .init(1 + (self.rawValue & 2) + (self.rawValue & 4) >> 2)
            }
            
            /** Returns the shape of a buffer just large enough to contain an image 
                of the given size, stored in this color format. */
            func shape(from size:Math<Int>.V2) -> Data.Shape 
            {
                let scanlineBitCount:Int = size.x * self.channels * self.depth
                                                // ceil(scanlineBitCount / 8)
                let pitch:Int = scanlineBitCount >> 3 + (scanlineBitCount & 7 == 0 ? 0 : 1)
                return .init(pitch: pitch, size: size)
            }
        }
        
        /// An interlacing algorithm used to arrange the stored pixels in a PNG image.
        enum Interlacing 
        {
            /// A sub-image of a PNG image using the Adam7 interlacing algorithm. 
            struct SubImage 
            {
                /// The shape of a two-dimensional array containing this sub-image.
                let shape:Data.Shape
                /** Two sequences of two-dimensional coordinates representing the 
                    logical positions of each pixel in this sub-image, when deinterlaced 
                    with its other sub-images. */
                let strider:Math<StrideTo<Int>>.V2
            }
            
            /// No interlacing.
            case none 
            /// [Adam7](https://en.wikipedia.org/wiki/Adam7_algorithm) interlacing.
            case adam7([SubImage])
            
            /** Returns the index ranges containing each Adam7 sub-image when all 
                sub-images are packed back-to-back in a single buffer, starting 
                with the smallest sub-image. */
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
        
        /// The sequence of scanline pitches forming the data buffer of a PNG image.
        struct Pitches:Sequence, IteratorProtocol 
        {
            private 
            let footprints:[(pitch:Int, height:Int)]
            
            private 
            var f:Int         = 0, 
                scanlines:Int = 0
            
            /** Creates the pitch sequence for an Adam7 interlaced PNG with the 
                given sub-images. 
                
                - Parameters:
                    - subImages: The sub-images of an interlaced image.
            */
            init(subImages:[Interlacing.SubImage]) 
            {
                self.footprints = subImages.map 
                {
                    ($0.shape.pitch, $0.shape.size.y)
                }
            }
            
            /** Creates the pitch sequence for a non-interlaced PNG with the given 
                shape. 
                
                - Parameters:
                    - shape: The shape of a non-interlaced image.
            */
            init(shape:Data.Shape)
            {
                self.footprints = [(shape.pitch, shape.size.y)]
            }
            
            /** Returns the pitch of the next scanline, if it is different from 
                the pitch of the previous scanline.
                
                - Returns: The pitch of the next scanline, if it is different from 
                    that of the previous scanline, `nil` in the inner optional if 
                    it is the same as that of the previous scanline, and `nil` in 
                    the outer optional if there should be no more scanlines left 
                    in the image.
            */
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
        
        /// The pixel format of this PNG image.
        public 
        let format:Format
        
        /// The color palette of this PNG image, if it has one.
        public 
        var palette:[RGBA<UInt8>]?
        
        /** The chroma key of this PNG image, if it has one. 
            
            The alpha component of this property is ignored by the library.
        */
        public 
        var chromaKey:RGBA<UInt16>? // the alpha sample is ignored by the library
        
        /// The shape of a two-dimensional array containing this PNG image.
        let shape:Data.Shape
        /// The interlacing algorithm used by this PNG image.
        let interlacing:Interlacing
        
        /// A boolean value indicating if this PNG image uses an interlacing algorithm.
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
        
        /// The pixel dimensions of this PNG image.
        public 
        var size:(x:Int, y:Int)
        {
            return self.shape.size
        }
        
        /// The scanline iterator for this PNG image.
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
        
        /** The number of bytes needed to store the encoded image data of this PNG 
            image. */
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
        
        /** Creates a PNG metadata record with the given properties.
            
            - Parameters:
                - size: A pair of pixel dimensions.
                - format: A pixel format.
                - interlaced: A boolean value indicating if an interlacing algorithm 
                    will be used.
                - palette: A color palette, or `nil`. The default is `nil`.
                - chromaKey: A chroma key, or `nil`. The default is `nil`.
        */
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
        
        /** Initializes and returns a PNG `Decoder`. 
            - Returns: An image `Decoder` in its initial state.
        */
        public 
        func decoder() throws -> Decoder
        {
            let inflator:LZ77.Inflator = try .init(), 
                stride:Int             = max(1, self.format.volume >> 3)
            return .init(stride: stride, pitches: self.pitches, inflator: inflator)
        }
        
        /** Initializes and returns a PNG `Encoder`. 
            - Parameters:
                - level: The compression level the returned `Encoder` will use.
                    Must be in the range `0 ... 9`, where 0 is no compression, and 
                    9 is the highest possible amount of compression.
            - Returns: An image `Encoder` in its initial state.
        */
        public 
        func encoder(level:Int) throws -> Encoder
        {
            let deflator:LZ77.Deflator = try .init(level: level), 
                stride:Int             = max(1, self.format.volume >> 3)
            return .init(stride: stride, pitches: self.pitches, deflator: deflator)
        }
        
        /** A low level API for receiving and processing decompressed and decoded 
            PNG image data at the scanline level. */
        public 
        struct Decoder 
        {
            /** The decoded pixels of the previous scanline decoded. Initialized 
                to all zeroes before decoding the first scanline of a (sub-)image. */
            private 
            var reference:[UInt8]?
            /** The decoded pixels of the current scanline. Can be partially filled 
                if individual image data blocks do not contain a whole number of 
                scanlines. */
            private 
            var scanline:[UInt8] = []
            
            /** The filter delay used by this image `Decoder`. This value is computed 
                from the volume of a PNG pixel format, but has no meaning itself. */
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
            
            /** Calls the given closure for each complete scanline decoded from 
                the given compressed image data, passing the decoded contents of 
                the scanline to the closure.
                
                Individual data blocks can produce incomplete scanlines. These 
                scanlines are stored and will be completed by subsequent data blocks, 
                when they will be passed as full scanlines to the closures given 
                in the later `forEachScanline(decodedFrom:_:)` calls.
                - Parameters:
                    - data: Compressed image data.
                    - body: A closure which takes as an argument a decoded scanline.
                - Returns: `true` if this `Decoder`’s LZ77 stream expects more input 
                    data, and `false` otherwise.
                
                - Warning: Do not call this method again on the same instance after 
                    it has returned `false`. Doing so will result in undefined behavior.
            */
            
            public mutating 
            func forEachScanline(decodedFrom data:[UInt8], _ body:(ArraySlice<UInt8>) throws -> ()) 
                throws -> Bool
            {
                self.inflator.push(data)
                
                while let reference:[UInt8] = self.reference  
                {
                    let streamContinue:Bool = try self.inflator.pull(  extending: &self.scanline, 
                                                                        capacity: reference.count)
                    
                    if self.scanline.count == reference.count 
                    {
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
                    }
                    
                    guard streamContinue 
                    else 
                    {
                        return false 
                    }
                    
                    guard self.inflator.unprocessedCount > 0 
                    else 
                    {
                        // no input (encoded data) left
                        return true
                    }
                }
                
                return try self.inflator.test()
            }
            
            /** Defilters the given filtered scanline in-place, using the given 
                reference scanline.
                
                - Parameters:
                    - scanline: The scanline to defilter in-place. The first byte 
                        of the scanline is interpreted as the filter byte, and this 
                        byte is set to 0 upon defiltering.
                    - reference: The defiltered scanline assumed to be immediately 
                        above the given filtered scanline. This scanline should 
                        contain all zeroes if the filtered scanline is logically 
                        the first scanline in its (sub-)image. The first byte of 
                        this scanline should always be a bogus padding byte corresponding 
                        to the filter byte of a filtered scanline, such that 
                        `reference.count == scanline.count`.
            */
            private  
            func defilter(_ scanline:inout [UInt8], reference:[UInt8])
            {
                assert(scanline.count == reference.count)
                
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
        
        /** A low level API for filtering and compressing PNG image data at the 
            scanline level. */
        public 
        struct Encoder 
        {
            // unlike the `Decoder`, here, it’s more efficient for `reference` to 
            // *not* contain the filter byte prefix
            
            /** The unfiltered pixels of the previous scanline encoded. Initialized 
                to all zeroes before encoding the first scanline of a (sub-)image. */
            private 
            var reference:[UInt8]?
            
            /** The filter delay used by this image `Encoder`. This value is computed 
                from the volume of a PNG pixel format, but has no meaning itself. */
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
            
            /** Filters and compresses scanlines returned by the given closure,  
                appending the compressed data to the given data buffer. 
                
                - Parameters:
                    - data: A data buffer to append compressed scanline data to.
                    - capacity: The maximum size `data` is allowed to reach before 
                        this method will stop outputting data to it.
                    - generator: A closure which, when called repeatedly, returns 
                        scanlines to filter and compress, and `nil` when there 
                        are no more scanlines to encode.
                
                - Returns: `true` if `data.count` was filled to the specified capacity, 
                    or if `generator` returned `nil`. `false` if this `Encoder` 
                    is finished encoding data. Once this method returns `false`, 
                    it should not be called again on the same instance.
                - Throws: `EncodingError.bufferCount`, if `generator` returns a scanline 
                    that does not have the expected size.
            */
            public mutating 
            func consolidate(extending data:inout [UInt8], capacity:Int, 
                scanlinesFrom generator:() -> ArraySlice<UInt8>?) throws -> Bool
            {
                while let reference:[UInt8] = self.reference
                {
                    try self.deflator.pull(extending: &data, capacity: capacity)
                    guard self.deflator.unprocessedCount == 0 
                    else 
                    {
                        // some input (encoded data) left
                        assert(data.count == capacity)
                        return true 
                    }
                    
                    guard let row:ArraySlice<UInt8> = generator()
                    else 
                    {
                        return true
                    }
                     
                    guard row.count == reference.count 
                    else 
                    {
                        throw EncodingError.bufferCount
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
                
                assert(data.count <= capacity)
                return try self.deflator.finish(extending: &data, capacity: capacity)
            }
            
            /** Returns the given scanline filtered based on the given reference 
                scanline, with a filter chosen by heuristic to optimize compressibility.
                
                - Parameters:
                    - current: A scanline to filter. This scanline is *not* prefixed 
                        by a bogus filter byte.
                    - reference: The unfiltered scanline assumed to be immediately 
                        above the given filtered scanline. This scanline should 
                        contain all zeroes if the scanline to be filtered is logically 
                        the first scanline in its (sub-)image. This scanline is 
                        *not* prefixed by a bogus filter byte. `reference.count` 
                        must be equal to `scanline.count`.
                - Returns: The filtered scanline, prefixed by a filter byte indicating 
                    the filter chosen by the library.
            */
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
            
            /** Scores the compressibility of the given filtered scanline candidate.
                
                - Parameters:
                    - filtered: A filtered scanline to score.
                - Returns: A score rating the compressibility of the given filtered 
                    scanline candidate. A higher score indicates less compressibility.
            */
            private static 
            func score(_ filtered:ArraySlice<UInt8>) -> Int
            {
                return zip(filtered, filtered.dropFirst()).count
                {
                    $0.0 != $0.1
                }
            } 
        }
        
        /** Decodes the data of an IHDR chunk as a `Properties` record.
            
            - Parameters:
                - data: IHDR chunk data.
            - Returns: A `Properties` object containing the information encoded by 
                the given IHDR chunk.
            - Throws:
                - DecodingError.invalidChunk: If any of the IHDR chunk fields contain 
                    an invalid value. 
        */
        public static 
        func decodeIHDR(_ data:[UInt8]) throws -> Properties
        {
            guard data.count == 13 
            else 
            {
                throw DecodingError.invalidChunk(message: "png header length is \(data.count), expected 13")
            }
            
            let colorcode:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 8)
            guard let format:Format = Format.init(rawValue: colorcode)
            else 
            {
                throw DecodingError.invalidChunk(message: "color format bytes have invalid values (\(data[8]), \(data[9]))")
            }
            
            // validate other fields 
            guard data[10] == 0 
            else 
            {
                throw DecodingError.invalidChunk(message: "compression byte has value \(data[10]), expected 0")
            }
            guard data[11] == 0 
            else 
            {
                throw DecodingError.invalidChunk(message: "filter byte has value \(data[11]), expected 0")
            }
            
            let interlaced:Bool 
            switch data[12]
            {
                case 0:
                    interlaced = false 
                case 1: 
                    interlaced = true 
                default:
                    throw DecodingError.invalidChunk(message: "interlacing byte has invalid value \(data[12])")
            }
            
            let width:Int  = data.load(bigEndian: UInt32.self, as: Int.self, at: 0), 
                height:Int = data.load(bigEndian: UInt32.self, as: Int.self, at: 4)
            
            return .init(size: (width, height), format: format, interlaced: interlaced)
        }
        
        /** Encodes the information in this PNG metadata record as the chunk data 
            of an IHDR chunk.
            
            - Returns: An array containing IHDR chunk data. The chunk header, length, 
                and crc32 tail are not included.
        */
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
        
        /** Decodes the data of a PLTE chunk, validates, and stores it in this PNG 
            metadata record.
            
            - Parameters: 
                - data: PLTE chunk data. Must not contain more entries than this 
                    PNG’s color depth can uniquely encode.
            - Throws: 
                - DecodingError.invalidChunk: If the given palette data does not contain 
                    a whole number of palette entries, or if it contains more than 
                    `1 << format.depth` entries.
        */
        public mutating 
        func decodePLTE(_ data:[UInt8]) throws
        {
            guard data.count.isMultiple(of: 3)
            else
            {
                throw DecodingError.invalidChunk(message: "palette does not contain a whole number of entries (\(data.count) bytes)")
            }
            
            // check number of palette entries 
            let maxEntries:Int = 1 << self.format.depth
            guard data.count <= maxEntries * 3
            else 
            {
                throw DecodingError.invalidChunk(message: "palette contains too many entries (found \(data.count / 3), expected\(maxEntries))")
            }

            self.palette = stride(from: data.startIndex, to: data.endIndex, by: 3).map
            {
                let r:UInt8 = data[$0    ],
                    g:UInt8 = data[$0 + 1],
                    b:UInt8 = data[$0 + 2]
                return .init(r, g, b)
            }
        }
        
        /** Encodes this PNG’s palette as the chunk data of a PLTE chunk, if it 
            has one.
            
            This method always returns valid PLTE chunk data. If this metadata 
            record has more palette entries than can be encoded with its color depth, 
            only the first `1 << format.depth` entries are encoded. This method 
            does not remove palette entries from this metatada record itself.
            
            - Returns: An array containing PLTE chunk data, or `nil` if this PNG 
                does not have a palette. The chunk header, length, 
                and crc32 tail are not included.
        */
        public 
        func encodePLTE() -> [UInt8]?
        {
            guard   self.format.hasColor, 
                    let palette:[RGBA<UInt8>] = self.palette 
            else 
            {
                return nil 
            }
            
            return palette.prefix(1 << self.format.depth).flatMap 
            {
                [$0.r, $0.g, $0.b]
            }
        }
        
        /** Decodes the data of a tRNS chunk, validates, and modifies this PNG 
            metadata record’s palette entries, or chroma key, as appropriate.
            
            This method should only be called if this PNG has an opaque pixel format, 
            and only after `decodePLTE(_:)` has been called on this metadata record. 
            If this PNG has a transparent pixel format, this method returns immediately 
            with no effects.
            
            This method sets the `chromaKey` property if this PNG has an opaque 
            grayscale or RGB pixel format. It instead modifies the color palette 
            if this PNG has an indexed pixel format.
            
            - Parameters: 
                - data: tRNS chunk data. If this PNG has a grayscale pixel format, 
                    it must contain one value sample. If this PNG has an RGB pixel 
                    format, it must contain three samples, red, green, and blue. 
                    If this PNG has an indexed pixel format, it must not contain 
                    more transparency values than this PNG’s color depth can uniquely 
                    encode.
            - Throws: 
                - DecodingError.invalidChunk: If the given transparency data does not 
                    contain the correct number of samples, or, in the case of indexed 
                    color, if it contains more than `1 << format.depth` trasparency 
                    values.
                - DecodingError.missingPalette: If this PNG has an indexed color format, 
                    and this metadata record has not been assigned a palette, either 
                    through a `decodePLTE(_:)` call, or by manual assignment to 
                    the `palette` property.
        */
        public mutating 
        func decodetRNS(_ data:[UInt8]) throws
        {
            switch self.format
            {
                case .v1, .v2, .v4, .v8, .v16:
                    guard data.count == 2
                    else
                    {
                        throw DecodingError.invalidChunk(message: "grayscale chroma key has wrong size (\(data.count) bytes, expected 2 bytes)")
                    }
                    
                    let quantum:UInt16 = VA<UInt16>.quantum(depth: self.format.depth), 
                        v:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
                    self.chromaKey = .init(v)
                
                case .rgb8, .rgb16:
                    guard data.count == 6
                    else
                    {
                        throw DecodingError.invalidChunk(message: "rgb chroma key has wrong size (\(data.count) bytes, expected 6 bytes)")
                    }
                    
                    let quantum:UInt16 = VA<UInt16>.quantum(depth: self.format.depth), 
                        r:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0), 
                        g:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2), 
                        b:UInt16   = quantum * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
                    self.chromaKey = .init(r, g, b)
                
                case .indexed1, .indexed2, .indexed4, .indexed8:
                    guard let palette:[RGBA<UInt8>] = self.palette
                    else
                    {
                        throw DecodingError.missingPalette
                    }

                    guard data.count <= palette.count
                    else
                    {
                        throw DecodingError.invalidChunk(message: "indexed image contains too many transparency entries (\(data.count), expected \(palette.count))")
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
        
        /** Encodes this PNG’s transparency information as the chunk data of a tRNS 
            chunk, if it has any.
            
            This method always returns valid tRNS chunk data. If this PNG has an 
            indexed pixel format, and this metadata record has more palette entries 
            than can be encoded with its color depth, then only the first `1 << format.depth` 
            transparency values are encoded. This method does not remove palette 
            entries from this metatada record itself.
            
            - Returns: An array containing tRNS chunk data, or `nil` if this PNG 
                does not have an transparency information. The chunk header, length, 
                and crc32 tail are not included. The chunk data consists of a single 
                grayscale chroma key value, narrowed to this PNG’s color depth, 
                if it has an opaque grayscale pixel format, an RGB chroma key triple, 
                narrowed to this PNG’s color depth, if it has an opaque RGB pixel 
                format, and the transparency values in this PNG’s color palette, 
                if it has an indexed color format. In the indexed color case, trailing 
                opaque palette entries are trimmed from the outputted sequence of 
                transparency values. If all palette entries are opaque, or this 
                metadata record has not been assigned a palette, `nil` is returned.
        */
        public 
        func encodetRNS() -> [UInt8]? 
        {
            switch self.format 
            {
                case .v1, .v2, .v4, .v8, .v16:
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
                    
                    var alphas:[UInt8] = palette.prefix(1 << self.format.depth).map{ $0.a } 
                    guard let last:Int = alphas.lastIndex(where: { $0 != UInt8.max })
                    else 
                    {
                        // palette is empty 
                        return nil
                    }
                    
                    alphas.removeLast(alphas.count - last - 1)
                    return alphas.isEmpty ? nil : alphas
                
                default:
                    return nil
            }
        }
    }
    
    /// A namespace for PNG image data container types. 
    public 
    enum Data 
    {
        /// A PNG image that has been decompressed, but not necessarily deinterlaced.
        public 
        struct Uncompressed 
        {
            /// The global image metadata of this PNG image.
            public 
            let properties:Properties
            /** The buffer containing this PNG’s decoded, but not necessarily 
                deinterlaced, image data. */
            public 
            let data:[UInt8]
            
            /** Creates an uncompressed PNG image with the given pixel buffer and 
                metadata record.
                
                - Parameters: 
                    - data: A pixel buffer. 
                    - properties: A metadata record.
                - Returns: An uncompressed PNG image, if the size of the given 
                    pixel buffer is consistent with the size and format information 
                    in the given `properties`, and `nil` otherwise.
            */
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
            
            /** Decomposes this uncompressed image into its constituent sub-images, 
                if this image is interlaced. 
                
                - Returns: The seven sub-images making up this image, if it uses 
                    the Adam7 interlacing algorithm, and `nil` otherwise.
            */
            public 
            func decomposed() -> [Rectangular]?
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
            
            /** Returns the pixels of this uncompressed image, organized into a 
                rectangular row-major pixel matrix.
                
                This method deinterlaces the pixel data from this uncompressed image, 
                if it uses an interlacing algorithm. Otherwise, it simply repackages 
                this image’s already-rectangular `data`.
                
                - Returns: A rectangular row-major pixel matrix.
            */
            public 
            func deinterlaced() -> Rectangular 
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
            
            /** Compresses this image, and outputs the compressed PNG file to the given 
                data destination.
                
                Excessively small chunk sizes may harm image compression. Higher 
                compression levels produce smaller PNG files, but take longer to 
                run.
                
                - Parameters:
                    - destination: A data destination to write the contents of the 
                        compressed file to.
                    - chunkSize: The maximum IDAT chunk size to use. The default 
                        is 65536 bytes.
                    - level: The level of LZ77 compression to use. Must be in the 
                        range `0 ... 9`, where 0 is no compression, and 9 is maximal 
                        compression.
            */
            public  
            func compress<Destination>(to destination:inout Destination, 
                chunkSize:Int = 1 << 16, level:Int = 9) throws 
                where Destination:DataDestination
            {
                precondition(chunkSize >= 1, "chunk size must be positive")
                
                guard var iterator:ChunkIterator<Destination> = 
                    ChunkIterator.begin(destination: &destination)
                else 
                {
                    throw EncodingError.notAcceptingData
                }
                
                @inline(__always)
                func _next(_ chunk:Chunk, _ contents:[UInt8] = []) throws 
                {
                    guard let _:Void = iterator.next(chunk, contents, destination: &destination) 
                    else 
                    {
                        throw EncodingError.notAcceptingData
                    }
                }
                
                try _next(.IHDR, self.properties.encodeIHDR())
                try self.properties.encodePLTE().map 
                {
                    try _next(.PLTE, $0)
                }
                try self.properties.encodetRNS().map 
                {
                    try _next(.tRNS, $0)
                }
                
                var pitches:Properties.Pitches = self.properties.pitches, 
                    encoder:Properties.Encoder = try self.properties.encoder(level: level)
                
                var pitch:Int?, 
                    base:Int     = self.data.startIndex
                while true  
                {
                    var data:[UInt8] = []
                    let more:Bool = try encoder.consolidate(extending: &data, capacity: chunkSize) 
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
                    
                    try _next(.IDAT, data)
                    
                    guard more 
                    else  
                    {
                        break
                    }
                } 
                
                try _next(.IEND)
            }
            
            /** Decompresses a PNG file from the given data source, and returns 
                it as an `Uncompressed` image.
                
                - Parameters:
                    - source: A data source yielding a PNG file.
                - Returns: An uncompressed PNG image.
            */
            public static 
            func decompress<Source>(from source:inout Source) throws -> Uncompressed 
                where Source:DataSource
            {
                guard var iterator:ChunkIterator<Source> = 
                    ChunkIterator.begin(source: &source)
                else 
                {
                    throw DecodingError.missingSignature 
                }
                                
                @inline(__always)
                func _next() throws -> (chunk:Chunk, contents:[UInt8])
                {
                    guard let (name, data):((UInt8, UInt8, UInt8, UInt8), [UInt8]?) = 
                        iterator.next(source: &source) 
                    else 
                    {
                        throw DecodingError.dataUnavailable
                    }
                    
                    guard let chunk:Chunk = Chunk.init(name)
                    else 
                    {
                        throw DecodingError.invalidName(name)
                    }
                    
                    guard let contents:[UInt8] = data 
                    else 
                    {
                        throw DecodingError.corruptedChunk(chunk)
                    }
                    
                    return (chunk, contents)
                }
                
                
                // first chunk must be IHDR 
                let (first, header):(Chunk, [UInt8]) = try _next()
                guard first == .IHDR
                else 
                {
                    throw DecodingError.missingChunk(.IHDR)
                }
                
                var properties:Properties      = try .decodeIHDR(header), 
                    decoder:Properties.Decoder = try properties.decoder()
                
                var validator:Chunk.OrderingValidator = .init(format: properties.format)
                
                var data:[UInt8] = []
                    data.reserveCapacity(properties.byteCount)
                
                var streamContinue:Bool = true
                
                while true 
                {
                    let (chunk, contents):(Chunk, [UInt8]) = try _next()
                    
                    // validate chunk ordering 
                    if let error:DecodingError = validator.push(chunk)
                    {
                        throw error 
                    }

                    switch chunk 
                    {
                        case .IHDR:
                            fatalError("unreachable: validator enforces no duplicate IHDR chunks")
                        
                        case .IDAT:
                            guard streamContinue 
                            else 
                            {
                                throw DecodingError.unexpectedChunk(.IDAT)
                            }
                            
                            streamContinue = try decoder.forEachScanline(decodedFrom: contents) 
                            {
                                data.append(contentsOf: $0)
                            }
                        
                        case .PLTE:
                            try properties.decodePLTE(contents)
                        
                        case .tRNS:
                            try properties.decodetRNS(contents)
                        
                        case .IEND:
                            guard !streamContinue 
                            else 
                            {
                                throw DecodingError.unexpectedChunk(.IEND)
                            }
                            
                            guard let uncompressed:Uncompressed = 
                                Uncompressed.init(data, properties: properties)
                            else 
                            {
                                // not enough data 
                                throw DecodingError.inconsistentMetadata
                            }
                            
                            return uncompressed
                        
                        default:
                            break
                    }
                }
            }
            
            /** Compresses and saves this PNG image at the given file path.
                
                Excessively small chunk sizes may harm image compression. Higher 
                compression levels produce smaller PNG files, but take longer to 
                run.
                
                - Parameters:
                    - outputPath: A file path.
                    - chunkSize: The maximum IDAT chunk size to use. The default 
                        is 65536 bytes.
                    - level: The level of LZ77 compression to use. Must be in the 
                        range `0 ... 9`, where 0 is no compression, and 9 is maximal 
                        compression.
                - Returns: `nil` if the given file could not be opened.
            */
            public  
            func compress(path outputPath:String, chunkSize:Int = 1 << 16, level:Int = 9) throws
            {
                guard let _:Void = 
                (
                    try File.Destination.open(path: outputPath) 
                    {
                        try self.compress(to: &$0, chunkSize: chunkSize, level: level)
                    }
                )
                else 
                {
                    throw File.Error.couldNotOpen
                }
            }
            
            /** Decompresses a PNG file at the given file path, and returns 
                it as an `Uncompressed` image.
                
                - Parameters:
                    - inputPath: A path to a PNG file.
                - Returns: An uncompressed PNG image, or `nil` if the given file 
                    could not be opened.
            */
            public static 
            func decompress(path inputPath:String) throws -> Uncompressed
            {
                guard let uncompressed:Uncompressed = 
                (
                    try File.Source.open(path: inputPath) 
                    {
                        try self.decompress(from: &$0)
                    }
                )
                else 
                {
                    throw File.Error.couldNotOpen
                }
                
                return uncompressed
            }
        }
        
        /** A PNG image that has been deinterlaced, but may still have multiple 
            pixels packed per byte, or indirect (indexed) pixels. */
        public 
        struct Rectangular 
        {
            /// The global image metadata of this PNG image.
            public 
            let properties:Properties
            /** A rectangular row-major matrix containing this PNG’s pixel data.
                This buffer is untyped, and each byte may contain multiple, or 
                fractional, pixels. Logical image scanlines are padded to a whole 
                number of bytes. */
            public 
            let data:[UInt8]
            
            /** Creates a fully decoded PNG image with the given pixel matrix and 
                metadata record.
                
                - Parameters: 
                    - data: An untyped, padded data buffer containing a row-major 
                        pixel matrix. 
                    - properties: A metadata record.
                - Returns: A fully decoded PNG image. The size of the given pixel 
                    matrix must be consistent with the size and format information 
                    in the given image `properties`.
            */
            init(_ data:[UInt8], properties:Properties) 
            {
                assert(!properties.interlaced)
                assert(data.count == properties.byteCount)
                
                self.properties = properties
                self.data       = data 
            }
            
            /** Decompresses and deinterlaces a PNG file at the given file path, 
                and returns it as a `Rectangular` row-major pixel matrix.
                
                If the PNG file is not interlaced, no deinterlacing is performed.
                
                - Parameters:
                    - inputPath: A path to a PNG file.
                - Returns: A rectangular row-major pixel matrix, or `nil` if the 
                    given file could not be opened.
            */
            public static 
            func decompress(path inputPath:String) throws -> Rectangular
            {
                return try Uncompressed.decompress(path: inputPath).deinterlaced()
            }
            
            /** Checks if the given integer type has enough bits to represent the 
                channels of this image.
                
                - Parameters:
                    - type: An integer type.
                - Returns: `true` if `Sample` has enough bits to represent the channels 
                    of this image, `false` otherwise.
            */
            @inline(__always)
            private 
            func checkWidth<Sample>(of type:Sample.Type) -> Bool 
                where Sample:FixedWidthInteger
            {
                return Sample.bitWidth >= self.properties.format.depth
            }
            
            /** Calls the given closure on each single-channel pixel in this 
                PNG image.
                
                The given closure is not called if this image does not have 
                exactly one channel, or `Sample` does not have enough bits to represent 
                its channel. The samples passed to the closure are raw, unnormalized 
                scalars, cast to the inferred integer type.
                
                *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
                
                - Parameters:
                    - body: A closure that takes one channel of one pixel.
                
                - Returns: An array of the return values of the given closure, or 
                    `nil`, if this PNG image has more than one channel, or `Sample` 
                    does not have enough bits to represent its channel.
            */
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
                    case .v1, .v2, .v4, 
                         .indexed1,   .indexed2,   .indexed4:
                        return self.mapBits(body) 
                    
                    case .v8, .indexed8:
                        return self.map(from: UInt8.self, body) 
                    
                    case .v16:
                        return self.map(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            
            /** Calls the given closure on the normalized intensity of each 
                single-channel pixel in this PNG image.
                
                The given closure is not called if this image does not have 
                exactly one channel. The samples passed to the closure are normalized 
                values in the range `0 ... Sample.max`.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
                
                - Parameters:
                    - body: A closure that takes one normalized channel of one pixel.
                
                - Returns: An array of the return values of the given closure, or 
                    `nil`, if this PNG image has more than one channel.
            */
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {                
                switch self.properties.format 
                {
                    case .v1, .v2, .v4, 
                         .indexed1,   .indexed2,   .indexed4:
                        return self.mapBitIntensity(body) 
                    
                    case .v8, .indexed8:
                        return self.mapIntensity(from: UInt8.self, body) 
                    
                    case .v16:
                        return self.mapIntensity(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            
            /** Calls the given closure on the normalized intensity of each 
                two-channel pixel in this PNG image.
                
                The given closure is not called if this image does not have 
                exactly two channels. The samples passed to the closure are normalized 
                values in the range `0 ... Sample.max`.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
                
                - Parameters:
                    - body: A closure that takes two normalized channels of one pixel.
                
                - Returns: An array of the return values of the given closure, or 
                    `nil`, if this PNG image does not have exactly two channels.
            */
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {                
                switch self.properties.format 
                {
                    case .va8:
                        return self.mapIntensity(from: UInt8.self, body) 
                    
                    case .va16:
                        return self.mapIntensity(from: UInt16.self, body) 
                    
                    default: 
                        return nil
                }
            }
            
            /** Calls the given closure on the normalized intensity of each 
                three-channel pixel in this PNG image.
                
                The given closure is not called if this PNG image does not have 
                exactly three channels. The samples passed to the closure are normalized 
                values in the range `0 ... Sample.max`.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
                
                - Parameters:
                    - body: A closure that takes three normalized channels of one 
                        pixel.
                
                - Returns: An array of the return values of the given closure, or 
                    `nil`, if this PNG image does not have exactly three channels.
            */
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
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
            
            /** Calls the given closure on the normalized intensity of each 
                four-channel pixel in this PNG image.
                
                The given closure is not called if this image does not have 
                exactly four channels. The samples passed to the closure are normalized 
                values in the range `0 ... Sample.max`.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
                
                - Parameters:
                    - body: A closure that takes four normalized channels of one 
                        pixel.
                
                - Returns: An array of the return values of the given closure, or 
                    `nil`, if this PNG image does not have exactly four channels.
            */
            @_specialize(exported: true, kind: partial, where Sample == UInt8) 
            @_specialize(exported: true, kind: partial, where Sample == UInt16) 
            @_specialize(exported: true, kind: partial, where Sample == UInt32) 
            @_specialize(exported: true, kind: partial, where Sample == UInt64) 
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            public 
            func mapIntensity<Sample, Result>(_ body:(Sample, Sample, Sample, Sample) -> Result) -> [Result]?
                where Sample:FixedWidthInteger & UnsignedInteger
            {
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
            
            /** Returns a row-major matrix of the first components of all the pixels 
                in this PNG image, normalized to the range of the given component type.
                
                If this image has more than one component per pixel, the first 
                component of each pixel is returned. If this image has indexed color, 
                the components returned are the first components of the RGB palette 
                colors of those pixels. This method ignores the transparency and 
                chroma keys of this image.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, 
                `UInt64`, and `UInt`.
                
                - Parameters:
                    - type: An integer type.
                - Returns: A row-major matrix of pixel values, normalized to its 
                    `Component` type, or `nil` if this image requires a palette, and 
                    it does not have one.
            */
            @_specialize(exported: true, where Component == UInt8) 
            @_specialize(exported: true, where Component == UInt16) 
            @_specialize(exported: true, where Component == UInt32) 
            @_specialize(exported: true, where Component == UInt64) 
            @_specialize(exported: true, where Component == UInt)
            public 
            func v<Component>(of type:Component.Type) -> [Component]?
                where Component:FixedWidthInteger & UnsignedInteger
            {
                switch self.properties.format 
                {
                    case .v1, .v2, .v4:
                        return self.mapBitIntensity{ $0 }
                    
                    case .v8:
                        return self.mapIntensity(from: UInt8.self){ $0 }
                    
                    case .v16:
                        return self.mapIntensity(from: UInt16.self){ $0 }
                    
                    case .va8:
                        return self.mapIntensity(from: UInt8.self)
                        { 
                            (v:Component, _:Component) in v
                        }
                    
                    case .va16:
                        return self.mapIntensity(from: UInt16.self)
                        { 
                            (v:Component, _:Component) in v
                        }
                    
                    case .rgb8:
                        return self.mapIntensity(from: UInt8.self)
                        { 
                            (r:Component, _:Component, _:Component) in r
                        }
                    
                    case .rgb16:
                        return self.mapIntensity(from: UInt16.self)
                        { 
                            (r:Component, _:Component, _:Component) in r
                        }
                    
                    case .rgba8:
                        return self.mapIntensity(from: UInt8.self)
                        { 
                            (r:Component, _:Component, _:Component, _:Component) in r
                        }
                    
                    case .rgba16:
                        return self.mapIntensity(from: UInt16.self)
                        { 
                            (r:Component, _:Component, _:Component, _:Component) in r
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

                            // palette component type is always UInt8 so all Swift 
                            // unsigned integer types can be used as an unscaling 
                            // target
                            return palette[index].upscale(to: Component.self).r
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
                            
                            return palette[index].upscale(to: Component.self).r
                        }
                }
            }
            
            /** Returns the given color with its alpha component set to 0 if its 
                color value matches this PNG image’s chroma key, and the given color 
                unchanged otherwise.
                
                - Parameters:
                    - color: An RGBA color to test.
                - Returns: The given color, with its alpha component set to 0 if its 
                        color value matches this PNG image’s chroma key.
            */
            @inline(__always) 
            private 
            func greenscreen<Component>(_ color:RGBA<Component>) -> RGBA<Component> 
            {
                // hope this gets inlined
                guard let key:RGBA<Component> = Component.bitWidth > 16 ? 
                    self.properties.chromaKey?.upscale(  to: Component.self) :  
                    self.properties.chromaKey?.downscale(to: Component.self) 
                else 
                {
                    return color
                }
                
                return color.equals(opaque: key) ? color.withAlpha(0) : color
            }
            
            @inline(__always) 
            private 
            func greenscreen<Component>(v:Component) -> RGBA<Component> 
            {
                return self.greenscreen(.init(v))
            }
            
            @inline(__always) 
            private 
            func greenscreen<Component>(r:Component, g:Component, b:Component) 
                -> RGBA<Component> 
            {
                return self.greenscreen(.init(r, g, b))
            }
            
            /** Returns the given color as a grayscale-alpha color with its alpha 
                component set to 0 if its RGB color value matches this PNG image’s 
                chroma key, and `Component.max` otherwise.
                
                - Parameters:
                    - color: A grayscale-alpha color to test.
                - Returns: The given color, with its alpha component set to 0 if its 
                        color value matches this PNG image’s chroma key.
            */
            @inline(__always) 
            private 
            func greenscreen<Component>(_ color:RGBA<Component>) -> VA<Component> 
            {
                // hope this gets inlined
                guard let key:RGBA<Component> = Component.bitWidth > 16 ? 
                    self.properties.chromaKey?.upscale(  to: Component.self) :  
                    self.properties.chromaKey?.downscale(to: Component.self) 
                else 
                {
                    return color.va
                }
                
                return color.equals(opaque: key) ? color.va.withAlpha(0) : color.va
            }
            
            @inline(__always) 
            private 
            func greenscreen<Component>(v:Component) -> VA<Component> 
            {
                return self.greenscreen(.init(v))
            }
            
            @inline(__always) 
            private 
            func greenscreen<Component>(r:Component, g:Component, b:Component) 
                -> VA<Component> 
            {
                return self.greenscreen(.init(r, g, b))
            }
            
            /** Returns a row-major matrix of the grayscale-alpha color values represented 
                by all the pixels in this PNG image, normalized to the range of 
                the given component type.
                
                If this image has grayscale color, the grayscale-alpha colors returned 
                share the value component, and have `Component.max` in the alpha 
                component. If this image has RGB color, the grayscale-alpha colors 
                have the red component in the value component, and have `Component.max` 
                in the alpha component. If this image has RGBA color, the grayscale-alpha 
                colors share the alpha component in addition.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, 
                `UInt64`, and `UInt`.
                
                - Parameters:
                    - type: An integer type.
                - Returns: A row-major matrix of grayscale-alpha pixel colors, normalized 
                    to the given `Component` type, or `nil` if this image requires 
                    a palette, and it does not have one.
            */
            @_specialize(exported: true, where Component == UInt8) 
            @_specialize(exported: true, where Component == UInt16) 
            @_specialize(exported: true, where Component == UInt32) 
            @_specialize(exported: true, where Component == UInt64) 
            @_specialize(exported: true, where Component == UInt)
            public 
            func va<Component>(of type:Component.Type) -> [VA<Component>]? 
                where Component:FixedWidthInteger & UnsignedInteger
            {
                switch self.properties.format 
                {
                    case .v1, .v2, .v4:
                        return self.mapBitIntensity(self.greenscreen(v:)) 
                    
                    case .v8:
                        return self.mapIntensity(from: UInt8.self,  self.greenscreen(v:)) 
                    
                    case .v16:
                        return self.mapIntensity(from: UInt16.self, self.greenscreen(v:)) 
                    
                    case .va8:
                        return self.mapIntensity(from: UInt8.self,  VA.init(_:_:)) 
                    
                    case .va16:
                        return self.mapIntensity(from: UInt16.self, VA.init(_:_:)) 
                    
                    case .rgb8:
                        return self.mapIntensity(from: UInt8.self,  self.greenscreen(r:g:b:)) 
                    
                    case .rgb16:
                        return self.mapIntensity(from: UInt16.self, self.greenscreen(r:g:b:)) 
                    
                    case .rgba8:
                        return self.mapIntensity(from: UInt8.self) 
                        {
                            .init($0, $3)
                        }
                    
                    case .rgba16:
                        return self.mapIntensity(from: UInt16.self)
                        {
                            .init($0, $3)
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
                            return palette[index].va.upscale(to: Component.self)
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
                            
                            return palette[index].va.upscale(to: Component.self)
                        }
                }
            }
            
            /** Returns a row-major matrix of the RGBA color values represented 
                by all the pixels in this PNG image, normalized to the range of 
                the given component type.
                
                If this image has grayscale color, the RGBA colors returned have 
                the value component in the red, green, and blue components, and 
                `Component.max` in the alpha component. If this image has grayscale-alpha 
                color, the RGBA colors returned share the alpha component in addition.
                If this image has RGB color, the RGBA colors share the red, green, 
                and blue components, and have `Component.max` in the alpha component.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, 
                `UInt64`, and `UInt`.
                
                - Parameters:
                    - type: An integer type.
                - Returns: A row-major matrix of RGBA pixel colors, normalized to 
                    the given `Component` type, or `nil` if this image requires 
                    a palette, and it does not have one.
            */
            @_specialize(exported: true, where Component == UInt8) 
            @_specialize(exported: true, where Component == UInt16) 
            @_specialize(exported: true, where Component == UInt32) 
            @_specialize(exported: true, where Component == UInt64) 
            @_specialize(exported: true, where Component == UInt)
            public 
            func rgba<Component>(of type:Component.Type) -> [RGBA<Component>]? 
                where Component:FixedWidthInteger & UnsignedInteger
            {
                switch self.properties.format 
                {
                    case .v1, .v2, .v4:
                        return self.mapBitIntensity(self.greenscreen(v:)) 
                    
                    case .v8:
                        return self.mapIntensity(from: UInt8.self,  self.greenscreen(v:)) 
                    
                    case .v16:
                        return self.mapIntensity(from: UInt16.self, self.greenscreen(v:)) 
                    
                    case .va8:
                        return self.mapIntensity(from: UInt8.self,  RGBA.init(_:_:)) 
                    
                    case .va16:
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

                            // palette component type is always UInt8 so all Swift 
                            // unsigned integer types can be used as an unscaling 
                            // target
                            return palette[index].upscale(to: Component.self)
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
                            
                            return palette[index].upscale(to: Component.self)
                        }
                }
            }
            
            /** Returns a row-major matrix of the RGBA color values represented 
                by all the pixels in this PNG image, normalized to the range of 
                the given component type and encoded as integer slugs containing 
                four components in ARGB order. The alpha components are premultiplied 
                into the colors.
                
                If this image has grayscale color, the RGBA colors returned have 
                the value component in the red, green, and blue components, and 
                `Component.max` in the alpha component. If this image has grayscale-alpha 
                color, the RGBA colors returned share the alpha component in addition.
                If this image has RGB color, the RGBA colors share the red, green, 
                and blue components, and have `Component.max` in the alpha component. 
                The RGBA colors are packed into four-component integer slugs of a 
                type large enough to hold four instances of the given type, if one 
                exists. The color components are packed in ARGB order, with alpha 
                in the high bits.
                
                Allowed `Component` types by default are `UInt8`, and `UInt16`. 
                Custom `Component` types can be used by conforming them to the 
                `FusedVector4Element` protocol and supplying the `FusedVector4` 
                associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
                
                To avoid information loss, you may want to check if this image’s 
                component type has too many bits to be represented by the destination 
                component type. This method should not be called using an integer 
                type less than 8 bits wide.
                
                *Specialized* for `Component` types `UInt8` and `UInt16`. 
                (`Component.FusedVector4` types `UInt32` and `UInt64`.)
                
                - Parameters:
                    - type: An integer type.
                - Returns: A row-major matrix of RGBA pixel colors, normalized to 
                    the given `Component` type, and encoded as four-component integer 
                    slugs, or `nil` if this image requires a palette, and 
                    it does not have one.
            */
            @_specialize(exported: true, where Component == UInt8) 
            @_specialize(exported: true, where Component == UInt16) 
            public 
            func argbPremultiplied<Component>(of type:Component.Type) 
                -> [Component.FusedVector4]? where Component:FusedVector4Element
            {
                // *all* color formats can produce pixels with alpha, so we might 
                // as well call the `rgba(of:)` function and let map fusion 
                // optimize it
                return self.rgba(of: Component.self)?.map 
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
                // this branch should be gone in specialized form. it seems to be 
                // effectively free.
                if Sample.bitWidth > T.bitWidth
                {
                    let scalar:Sample = self.load(bigEndian: T.self, at: index, as: Sample.self)
                    return scalar * VA<Sample>.quantum(depth: self.properties.format.depth)
                }
                else 
                {
                    let scalar:T = self.load(bigEndian: T.self, at: index, as: T.self)
                    return .init(truncatingIfNeeded: scalar &>> (T.bitWidth - Sample.bitWidth))
                }
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
                assert(Sample.bitWidth >= 8)
                return self.mapBits 
                {
                    return body($0 * VA<Sample>.quantum(depth: self.properties.format.depth))
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
        
        /// The shape of an image stored in a two-dimensional array.
        struct Shape 
        {
            let pitch:Int, 
                size:(x:Int, y:Int)
            
            var byteCount:Int 
            {
                return self.pitch * self.size.y
            }
        }
    }
    
    // single stage functions 
    
    /** Returns a row-major matrix of the first components of all the pixels 
        in this PNG file, normalized to the range of the given component type.
        
        If this image has more than one component per pixel, the first 
        component of each pixel is returned. If this image has indexed color, 
        the components returned are the first components of the RGB palette 
        colors of those pixels. This method ignores the transparency and 
        chroma keys of this image.
        
        To avoid information loss, you may want to check if this image’s 
        component type has too many bits to be represented by the destination 
        component type. This method should not be called using an integer 
        type less than 8 bits wide.
        
        *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, 
        and `UInt`.
        
        - Parameters:
            - path: A path to a PNG file.
            - type: An integer type.
        - Returns: A tuple containing a row-major matrix of pixel components, normalized 
            to its `Component` type, and the logical pixel dimensions of the matrix.
    */
    @_specialize(exported: true, where Component == UInt8) 
    @_specialize(exported: true, where Component == UInt16) 
    @_specialize(exported: true, where Component == UInt32) 
    @_specialize(exported: true, where Component == UInt64) 
    @_specialize(exported: true, where Component == UInt)
    public static 
    func v<Component>(path:String, of type:Component.Type) throws 
        -> (pixels:[Component], size:(x:Int, y:Int))
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let image:Data.Rectangular = try .decompress(path: path) 
        else 
        {
            throw File.Error.couldNotOpen
        }
        
        guard let pixels:[Component] = image.v(of: Component.self)
        else 
        {
            throw DecodingError.missingPalette
        }
        
        return (pixels, image.properties.size)
    } 
    
    /** Returns a row-major matrix of the grayscale-alpha color values represented 
        by all the pixels in this PNG file, normalized to the range of 
        the given component type.
        
        If this image has grayscale color, the grayscale-alpha colors returned 
        share the value component, and have `Component.max` in the alpha 
        component. If this image has RGB color, the grayscale-alpha colors 
        have the red component in the value component, and have `Component.max` 
        in the alpha component. If this image has RGBA color, the grayscale-alpha 
        colors share the alpha component in addition.
        
        To avoid information loss, you may want to check if this image’s 
        component type has too many bits to be represented by the destination 
        component type. This method should not be called using an integer 
        type less than 8 bits wide.
        
        *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, 
        and `UInt`.
        
        - Parameters:
            - path: A path to a PNG file.
            - type: An integer type.
        - Returns: A tuple containing a row-major matrix of pixel components, normalized 
            to its `Component` type, and the logical pixel dimensions of the matrix.
    */
    @_specialize(exported: true, where Component == UInt8) 
    @_specialize(exported: true, where Component == UInt16) 
    @_specialize(exported: true, where Component == UInt32) 
    @_specialize(exported: true, where Component == UInt64) 
    @_specialize(exported: true, where Component == UInt)
    public static 
    func va<Component>(path:String, of type:Component.Type) throws 
        -> (pixels:[VA<Component>], size:(x:Int, y:Int))
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let image:Data.Rectangular = try .decompress(path: path) 
        else 
        {
            throw File.Error.couldNotOpen
        }

        guard let pixels:[VA<Component>] = image.va(of: Component.self)
        else 
        {
            throw DecodingError.missingPalette
        }
        
        return (pixels, image.properties.size)
    }
    
    /** Returns a row-major matrix of the RGBA color values represented 
        by all the pixels in this PNG file, normalized to the range of 
        the given component type.
        
        If this image has grayscale color, the RGBA colors returned have 
        the value component in the red, green, and blue components, and 
        `Component.max` in the alpha component. If this image has grayscale-alpha 
        color, the RGBA colors returned share the alpha component in addition.
        If this image has RGB color, the RGBA colors share the red, green, 
        and blue components, and have `Component.max` in the alpha component.
        
        To avoid information loss, you may want to check if this image’s 
        component type has too many bits to be represented by the destination 
        component type. This method should not be called using an integer 
        type less than 8 bits wide.
        
        *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, 
        `UInt64`, and `UInt`.
        
        - Parameters:
            - path: A path to a PNG file.
            - type: An integer type.
        - Returns: A tuple containing a row-major matrix of pixel components, normalized 
            to its `Component` type, and the logical pixel dimensions of the matrix.
    */
    @_specialize(exported: true, where Component == UInt8) 
    @_specialize(exported: true, where Component == UInt16) 
    @_specialize(exported: true, where Component == UInt32) 
    @_specialize(exported: true, where Component == UInt64) 
    @_specialize(exported: true, where Component == UInt)
    public static 
    func rgba<Component>(path:String, of type:Component.Type) throws 
        -> (pixels:[RGBA<Component>], size:(x:Int, y:Int))
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let image:Data.Rectangular = try .decompress(path: path) 
        else 
        {
            throw File.Error.couldNotOpen
        }
        
        guard let pixels:[RGBA<Component>] = image.rgba(of: Component.self)
        else 
        {
            throw DecodingError.missingPalette
        }
        
        return (pixels, image.properties.size)
    }
    
    /** Returns a row-major matrix of the RGBA color values represented 
        by all the pixels in this PNG file, normalized to the range of 
        the given component type and encoded as integer slugs containing 
        four components in ARGB order. The alpha components are premultiplied 
        into the colors.
        
        If this image has grayscale color, the RGBA colors returned have 
        the value component in the red, green, and blue components, and 
        `Component.max` in the alpha component. If this image has grayscale-alpha 
        color, the RGBA colors returned share the alpha component in addition.
        If this image has RGB color, the RGBA colors share the red, green, 
        and blue components, and have `Component.max` in the alpha component. 
        The RGBA colors are packed into four-component integer slugs of a 
        type large enough to hold four instances of the given type, if one 
        exists. The color components are packed in ARGB order, with alpha 
        in the high bits.
        
        Allowed `Component` types by default are `UInt8`, and `UInt16`. 
        Custom `Component` types can be used by conforming them to the 
        `FusedVector4Element` protocol and supplying the `FusedVector4` 
        associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
        
        To avoid information loss, you may want to check if this image’s 
        component type has too many bits to be represented by the destination 
        component type. This method should not be called using an integer 
        type less than 8 bits wide.
        
        *Specialized* for `Component` types `UInt8` and `UInt16`. 
        (`Component.FusedVector4` types `UInt32` and `UInt64`.)
        
        - Parameters:
            - path: A path to a PNG file.
            - type: An integer type.
        - Returns: A tuple containing a row-major matrix of pixel components, normalized 
            to its `Component` type, and encoded as four-component integer slugs, 
            and the logical pixel dimensions of the matrix.
    */
    @_specialize(exported: true, where Component == UInt8) 
    @_specialize(exported: true, where Component == UInt16) 
    public static 
    func argbPremultiplied<Component>(path:String, of type:Component.Type) throws 
        -> (pixels:[Component.FusedVector4], size:(x:Int, y:Int))
        where Component:FusedVector4Element
    {
        guard let image:Data.Rectangular = try .decompress(path: path) 
        else 
        {
            throw File.Error.couldNotOpen
        }
        
        guard let pixels:[Component.FusedVector4] = image.argbPremultiplied(of: Component.self)
        else 
        {
            throw DecodingError.missingPalette
        }
        
        return (pixels, image.properties.size)
    }
    
    /// A four-byte PNG chunk type identifier.
    public 
    struct Chunk:Hashable, Equatable, CustomStringConvertible
    {
        /// The four-byte name of this PNG chunk type.
        let name:Math<UInt8>.V4
        
        /// A string displaying the ASCII representation of this PNG chunk type’s name.
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
        
        /** Creates the chunk type with the given name bytes, if they are valid. 
            Returns `nil` if the ancillary bit (in byte 0) is set or the reserved 
            bit (in byte 2) is set, and the ASCII name is not one of `IHDR`, `PLTE`, 
            `IDAT`, `IEND`, `cHRM`, `gAMA`, `iCCP`, `sBIT`, `sRGB`, `bKGD`, `hIST`, 
            `tRNS`, `pHYs`, `sPLT`, `tIME`, `iTXt`, `tEXt`, or `zTXt`.
            
            - Parameters:
                - name: The four bytes of this PNG chunk type’s name.
        */
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
        
        /** Returns a Boolean value indicating whether two PNG chunk types are equal. 
            
            Equality is the inverse of inequality. For any values `a` and `b`, `a == b` 
            implies that `a != b` is `false`.
            
            - Parameters: 
                - lhs: A value to compare.
                - rhs: Another value to compare.
        */
        public static 
        func == (a:Chunk, b:Chunk) -> Bool 
        {
            return a.name == b.name
        }
        
        /** Hashes the name of this PNG chunk type by feeding it into the given 
            hasher. 
            
            - Parameters:
                - hasher: The hasher to use when combining the components of this 
                    instance.
        */
        public 
        func hash(into hasher:inout Hasher) 
        {
            hasher.combine( self.name.0 << 24 | 
                            self.name.1 << 16 | 
                            self.name.2 <<  8 | 
                            self.name.3)
        }
        
        /// The PNG header chunk type.
        public static 
        let IHDR:Chunk = .init(73, 72, 68, 82)
        /// The PNG palette chunk type.
        public static 
        let PLTE:Chunk = .init(80, 76, 84, 69)
        /// The PNG image data chunk type.
        public static     
        let IDAT:Chunk = .init(73, 68, 65, 84)
        /// The PNG image end chunk type.
        public static     
        let IEND:Chunk = .init(73, 69, 78, 68)
    
        /// The PNG chromaticity chunk type.
        public static 
        let cHRM:Chunk = .init(99, 72, 82, 77)
        /// The PNG gamma chunk type.
        public static     
        let gAMA:Chunk = .init(103, 65, 77, 65)
        /// The PNG embedded ICC chunk type.
        public static     
        let iCCP:Chunk = .init(105, 67, 67, 80)
        /// The PNG significant bits chunk type.
        public static     
        let sBIT:Chunk = .init(115, 66, 73, 84)
        /// The PNG *s*RGB chunk type.
        public static     
        let sRGB:Chunk = .init(115, 82, 71, 66)
        /// The PNG background chunk type.
        public static     
        let bKGD:Chunk = .init(98, 75, 71, 68)
        /// The PNG histogram chunk type.
        public static     
        let hIST:Chunk = .init(104, 73, 83, 84)
        /// The PNG transparency chunk type., 
        public static     
        let tRNS:Chunk = .init(116, 82, 78, 83)
            
        /// The PNG physical dimensions chunk type. 
        public static     
        let pHYs:Chunk = .init(112, 72, 89, 115)
            
        /// The PNG suggested palette chunk type.
        public static     
        let sPLT:Chunk = .init(115, 80, 76, 84)
        /// The PNG time chunk type.
        public static     
        let tIME:Chunk = .init(116, 73, 77, 69)
            
        /// The PNG UTF-8 text chunk type.
        public static     
        let iTXt:Chunk = .init(105, 84, 88, 116)
        /// The PNG Latin-1 text chunk type.
        public static     
        let tEXt:Chunk = .init(116, 69, 88, 116)
        /// The PNG compressed Latin-1 text chunk type.
        public static     
        let zTXt:Chunk = .init(122, 84, 88, 116)
        
        /// A validator that checks for chunk ordering and presence.
        struct OrderingValidator 
        {
            private 
            var format:Properties.Format, 
                last:Chunk, 
                seen:Set<Chunk>
            
            /** Initialize this validator to the state of just having seen an IHDR 
                chunk. 
                
                - Parameters:
                    - format: The pixel format from a PNG image header.
            */
            init(format:Properties.Format) 
            {
                self.format = format 
                self.last   =  .IHDR
                self.seen   = [.IHDR] 
            }
            
            /** Registers the given chunk type as having been seen, returning an 
                error if the recorded chunk sequence has become invalid.
                
                - Parameters:
                    chunk: A PNG chunk type.
                - Returns: A `DecodingError` case, if the given chunk type was out of place 
                    or a necessary prerequisite chunk was missing, `nil` otherwise. 
            */
            mutating 
            func push(_ chunk:Chunk) -> DecodingError? 
            {                
                guard self.last != .IEND
                else 
                {
                    return .postEndChunk(chunk)
                }
            
                if      chunk ==                                                                  .tRNS
                {
                    guard !self.format.hasAlpha // tRNS forbidden in alpha’d formats
                    else
                    {
                        return .unexpectedChunk(chunk)
                    }
                }
                else if chunk ==   .PLTE
                {
                    // PLTE must come before bKGD, hIST, and tRNS
                    guard self.format.hasColor // PLTE requires non-grayscale format
                    else
                    {
                        return .unexpectedChunk(chunk)
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
    
    /// Errors that can occur while reading, decompressing, or decoding PNG files.
    public 
    enum DecodingError:Error 
    {
        /// A PNG file is missing its magic signature.
        case missingSignature
        
        /// A PNG image is missing a required palette.
        case missingPalette 
        /// A data interface is unable to provide requested data.
        case dataUnavailable
        
        /// An image data buffer does not match the shape specified by an associated 
        /// `Properties` record 
        case inconsistentMetadata
        
        /// A PNG chunk has a type-specific validity error.
        case invalidChunk(message:String)
        /// A PNG chunk has an invalid type name.
        case invalidName((UInt8, UInt8, UInt8, UInt8))
        
        /// A PNG chunk’s crc32 value indicates it has been corrupted.
        case corruptedChunk(Chunk)
        /// A PNG chunk has been encountered which cannot appear assuming a particular 
        /// sequence of preceeding chunks have been encountered.
        case unexpectedChunk(Chunk)
        
        /// A PNG chunk has been encountered that is out of correct order assuming 
        /// a particular sequence of preceeding chunks have been encountered.
        case misplacedChunk(Chunk)
        /// A PNG chunk has been encountered that is of the same type as a previously 
        /// encountered chunk, and is of a type which cannot appear multiple times 
        /// in the same PNG file.
        case duplicateChunk(Chunk)
        /// A prerequisite PNG chunk is missing.
        case missingChunk(Chunk)
        /// A PNG chunk occured in sequence after an IEND chunk.
        case postEndChunk(Chunk)
    }
    
    /// Errors that can occur while writing, compressing, or encoding PNG files.
    public 
    enum EncodingError:Error 
    {
        /// A data interface is unable to accept given data.
        case notAcceptingData 
        /// An input scanline has the wrong size.
        case bufferCount
    }

    // empty struct to namespace our chunk iteration methods. we can’t store the 
    // data source as it may have reference semantics even though implemented as 
    // a struct 
    /** A low-level API for deconstructing a PNG file into its constituent untyped 
        chunks, or constructing a PNG file out of a sequence of typed chunks. */
    public 
    struct ChunkIterator<DataInterface> 
    {
    }
    
    
    // internal benchmarking functions, to measure module boundary overhead 
    public 
    enum _Benchmarks 
    {
        public static 
        func _structuredARGBPremultiplied(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt32] = try? argbPremultiplied(path: path, of: UInt8.self).pixels
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _structuredRGBA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[RGBA<UInt8>] = try? rgba(path: path, of: UInt8.self).pixels
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _planarRGBA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? rgba(path: path, of: UInt8.self).pixels.planar() 
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _interleavedRGBA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? rgba(path: path, of: UInt8.self).pixels.interleaved() 
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _structuredVA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[VA<UInt8>] = try? va(path: path, of: UInt8.self).pixels
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _planarVA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? va(path: path, of: UInt8.self).pixels.planar() 
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _interleavedVA(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? va(path: path, of: UInt8.self).pixels.interleaved() 
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
        public static 
        func _structuredV(_ path:String) -> Int
        {
            let t1:Int = clock()
            guard let _:[UInt8] = try? v(path: path, of: UInt8.self).pixels
            else 
            {
                fatalError("could not open, read, or decode PNG file '\(path)'")
            }
            
            let t:Int = clock() - t1
            return t
        }
    }
}

extension PNG.ChunkIterator where DataInterface:DataSource 
{
    /** Begins the process of loading untyped PNG chunks from the given data source.
        
        The main operation performed this method is checking for the PNG magic file 
        signature. This method will pull 8 bytes of data from the given data source.
        
        - Parameters: 
            - source: A data source yielding a PNG file. The source is assumed to 
                pointing to the very beginning of the PNG file.
        - Returns: A chunk iterator, if the PNG magic signature was read from the 
            given data source, and `nil` otherwise.
    */
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
    
    /** Loads the an untyped PNG chunk from the given data source. 
        
        This method performs no chunk name validation, nor does it interpret the chunk. 
        This method does, however, perform crc32 validation on the chunk, as this 
        is universal to all PNG chunks.
        
        To aid diagnostics, the name bytes of the chunk are returned even if the 
        chunk’s data is corrupted.
        
        This method pulls 12 bytes from the given data source, plus the length encoded 
        in the chunk header.
        
        - Parameters: 
            - source: A data source yielding a PNG file. 
        - Returns: A tuple containing the name bytes of the read chunk and its data, 
            or `nil` if enough data could not be pulled from the given data source. 
            The chunk `data` field of the tuple is `nil` if the chunk’s data could 
            be successfully read, but failed to match the chunk’s crc32 checksum.
        
        - Note: Some chunks may have a length of 0, and such produce an empty `data` 
            array. This is not an error.
    */
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
            return nil
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
    /** Begins the process of storing untyped PNG chunks into the given data destination.
        
        The main operation performed this method is writing the PNG magic file signature. 
        This method will push 8 bytes of data to the given data destination.
        
        - Parameters: 
            - source: A data destination to write a PNG file to. The destination 
                is assumed to pointing to the very beginning of the file.
        - Returns: A chunk iterator, or `nil` if the signature could not be written.
    */
    public static 
    func begin(destination:inout DataInterface) -> PNG.ChunkIterator<DataInterface>?
    {
        guard let _:Void = destination.write(PNG.signature) 
        else 
        {
            return nil
        }
        
        return .init()
    }
    
    /** Serializes a PNG chunk of the given type and with the given raw data, and 
        stores it into the given data destination. 
        
        This method does not interpret the given chunk data. This method automatically 
        computes its crc32 checksum, and chunk length, and stores them in its serialized 
        in-file representation.
        
        This method pushes 12 bytes to the given data destination, plus the given 
        `data` array.
        
        - Parameters: 
            - name: A chunk type.
            - data: An array containing chunk data. The default is `[]`.
            - source: A data destination to write a PNG file to.
        - Returns: `nil` if the chunk could not be written.
    */
    public mutating 
    func next(_ name:PNG.Chunk, _ data:[UInt8] = [], destination:inout DataInterface) 
        -> Void?
    {
        let header:[UInt8] = .store(data.count, asBigEndian: UInt32.self) 
        + 
        [name.name.0, name.name.1, name.name.2, name.name.3]
        
        let partial:UInt = header.suffix(4).withUnsafeBufferPointer 
        {
            crc32(0, $0.baseAddress, 4)
        }
        
        // crc has 32 significant bits, padded out to a UInt
        let crc:UInt = crc32(partial, data, UInt32(data.count))
        
        guard   let _:Void = destination.write(header), 
                let _:Void = destination.write(data), 
                let _:Void = destination.write(.store(crc, asBigEndian: UInt32.self))
        else 
        {
            return nil
        }
        return ()
    }
}
