#if os(macOS)
import func Darwin.fopen
import func Darwin.fread
import func Darwin.fwrite
import func Darwin.fclose
import struct Darwin.FILE

#elseif os(Linux)
import func Glibc.fopen
import func Glibc.fread
import func Glibc.fwrite
import func Glibc.fclose
import struct Glibc.FILE

#else
    #error("unsupported or untested platform (please open an issue at https://github.com/kelvin13/png/issues)")
#endif

import func zlib.crc32

struct Bitfield<Storage> where Storage:FixedWidthInteger & UnsignedInteger
{
    private
    var storage:Storage

    init()
    {
        self.storage = .init()
    }

    subscript(index:Int) -> Bool
    {
        get
        {
            return self.storage & (1 << index) != 0
        }

        set(value)
        {
            if value
            {
                self.storage |=  (1 &<< index)
            }
            else
            {
                self.storage &= ~(1 &<< index)
            }
        }
    }

    mutating
    func testAndSet(_ index:Int) -> Bool
    {
        defer
        {
            self[index] = true
        }

        return self[index]
    }
}

extension Array where Element == UInt8
{
    /// Loads a misaligned big-endian integer value from the given byte offset
    /// and casts it to a desired format.
    /// - Parameters:
    ///     - bigEndian: The size and type to interpret the data to load as.
    ///     - type: The type to cast the read integer value to.
    ///     - byte: The byte offset to load the big-endian integer from.
    /// - Returns: The read integer value, cast to `U`.
    fileprivate
    func load<T, U>(bigEndian:T.Type, as type:U.Type, at byte:Int) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[byte ..< byte + MemoryLayout<T>.size].load(bigEndian: T.self, as: U.self)
    }

    /// Decomposes the given integer value into its constituent bytes, in big-endian order.
    /// - Parameters:
    ///     - value: The integer value to decompose.
    ///     - type: The big-endian format `T` to store the given `value` as. The given
    ///             `value` is truncated to fit in a `T`.
    /// - Returns: An array containing the bytes of the given `value`, in big-endian order.
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

    fileprivate mutating
    func append(bigEndian:UInt16)
    {
        self.append(.init(truncatingIfNeeded: bigEndian >> 8))
        self.append(.init(truncatingIfNeeded: bigEndian     ))
    }
}

extension ArraySlice where Element == UInt8
{
    /// Loads this array slice as a misaligned big-endian integer value,
    /// and casts it to a desired format.
    /// - Parameters:
    ///     - bigEndian: The size and type to interpret this array slice as.
    ///     - type: The type to cast the read integer value to.
    /// - Returns: The read integer value, cast to `U`.
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

/// An abstract data source. To provide a custom data source to the library, conform
/// your type to this protocol by implementing the `read(count:)` method.
public
protocol DataSource
{
    /// Read the specified number of bytes from this data source.
    /// - Parameters:
    ///     - count: The number of bytes to read.
    /// - Returns: An array of size `count`, if `count` bytes could be read, and
    ///     `nil` otherwise.
    mutating
    func read(count:Int) -> [UInt8]?
}
/// An abstract data destination. To specify a custom data destination for the library,
/// conform your type to this protocol by implementing the `write(_:)` method.
public
protocol DataDestination
{
    /// Write the given data buffer to this data destination.
    /// - Parameters:
    ///     - buffer: The data to write.
    /// - Returns: `()` on success, and `nil` otherwise.
    mutating
    func write(_ buffer:[UInt8]) -> Void?
}

public
protocol FixedLayoutColor:RandomAccessCollection, Hashable, CustomStringConvertible
    where Index == Int
{
    static
    var components:Int
    {
        get
    }
}
extension FixedLayoutColor
{
    @inlinable
    public
    var startIndex:Int
    {
        0
    }
    @inlinable
    public
    var endIndex:Int
    {
        Self.components
    }
}

/// A fixed-width integer type which can be packed in groups of four within another
/// integer type. For example, four `UInt8`s may be packed into a single `UInt32`.
public
protocol FusedVector4Element:FixedWidthInteger & UnsignedInteger & SIMDScalar
{
    /// A fixed-width integer type which can hold four instances of `Self`.
    associatedtype FusedVector4:FixedWidthInteger & UnsignedInteger & SIMDScalar
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
    /// The components of this pixel value packed into a single unsigned integer in
    /// ARGB order, with the alpha component in the high bits.
    /// 
    /// *Inlinable*.
    @inlinable
    public
    var argb:Component.FusedVector4
    {
        .init(self.a) << (Component.bitWidth * 3) | 
        .init(self.r) << (Component.bitWidth * 2) | 
        .init(self.g) << (Component.bitWidth    ) | 
        .init(self.b) 
    }
}

/// Encode and decode image data in the PNG format.
public
enum PNG
{
    private static
    let signature:[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    
    /// Returns the size of one unit in a component of the given depth, in units of
    /// this color’s `Component` type.
    /// - Parameters:
    ///     - depth: A bit depth less than or equal to `Component.bitWidth`.
    /// - Returns: The size of one unit in a component of the given bit depth,
    ///     in units of `Component`. Multiplying this value with the scalar
    ///     integer value of a component of bit depth `depth` will renormalize
    ///     it to the range of `Component`.
    @inline(__always)
    static
    func quantum<Component>(depth:Int) -> Component 
        where Component:FixedWidthInteger & UnsignedInteger
    {
        return Component.max / (Component.max &>> (Component.bitWidth - depth))
    }
    
    /// Returns the given color sample premultiplied with the given alpha sample.
    /// 
    /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
    ///     and `UInt`.
    /// - Parameters:
    ///     - color: A color sample.
    ///     - alpha: An alpha sample.
    /// - Returns: The product of the given color sample and the given alpha
    ///     sample. The resulting value is accurate to within 1 `Component` unit.
    @usableFromInline
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    static
    func premultiply<Component>(color:Component, alpha:Component) -> Component 
        where Component:FixedWidthInteger & UnsignedInteger
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
    
    /// Returns the given component widened to the given type, preserving its normalized 
    /// value.
    /// 
    /// `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - component: The component to upscale.
    ///     - type: The destination type.
    /// - Returns: The given component, normalized to the range of `T`.
    @inline(__always)
    static 
    func upscale<Component, T>(_ component:Component, to type:T.Type) -> T 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        assert(T.bitWidth >= Component.bitWidth)
        return .init(truncatingIfNeeded: component) * quantum(depth: Component.bitWidth)
    }

    /// Returns the given component narrowed to the given type, preserving its normalized 
    /// value.
    /// 
    /// `T.bitWidth` must be less than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - component: The component to downscale.
    ///     - type: The destination type.
    /// - Returns: The given component, normalized to the range of `T`.
    @inline(__always)
    static 
    func downscale<Component, T>(_ component:Component, to type:T.Type) -> T 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        assert(T.bitWidth <= Component.bitWidth)
        return .init(truncatingIfNeeded: component &>> (Component.bitWidth - T.bitWidth))
    }
    
    /// Returns the given component scaled to the given type, preserving its normalized 
    /// value.
    /// 
    /// - Parameters:
    ///     - component: The component to rescale.
    ///     - type: The destination type.
    /// - Returns: The given component, normalized to the range of `T`.
    @inline(__always)
    static 
    func rescale<Component, T>(_ component:Component, to type:T.Type) -> T 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        // this branch should be gone in specialized form. it seems to be
        // effectively free.
        if T.bitWidth > Component.bitWidth
        {
            return upscale(component, to: T.self)
        }
        else
        {
            return downscale(component, to: T.self)
        }
    }
    
    
    /// Returns the given color with its components widened to the given type, preserving
    /// their normalized values.
    /// 
    /// `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - va: A grayscale-alpha color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static 
    func upscale<Component, T>(_ va:VA<Component>, to type:T.Type) -> VA<T> 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(upscale(va.v, to: T.self), upscale(va.a, to: T.self))
    }
    
    /// Returns the given color with its components narrowed to the given type, preserving
    /// their normalized values.
    /// 
    /// `T.bitWidth` must be less than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - va: A grayscale-alpha color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static 
    func downscale<Component, T>(_ va:VA<Component>, to type:T.Type) -> VA<T> 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(downscale(va.v, to: T.self), downscale(va.a, to: T.self))
    }
    
    /// Returns the given color with its components scaled to the given type, preserving
    /// their normalized values.
    /// 
    /// - Parameters:
    ///     - va: A grayscale-alpha color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static 
    func rescale<Component, T>(_ va:VA<Component>, to type:T.Type) -> VA<T> 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        if T.bitWidth > Component.bitWidth
        {
            return upscale(va, to: T.self)
        }
        else
        {
            return downscale(va, to: T.self)
        }
    }
    
    
    /// Returns the given color with its components narrowed to the given type, preserving
    /// their normalized values.
    /// 
    /// `T.bitWidth` must be less than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static 
    func downscale<Component, T>(_ rgba:RGBA<Component>, to type:T.Type) -> RGBA<T> 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(   downscale(rgba.r, to: T.self), 
                        downscale(rgba.g, to: T.self),
                        downscale(rgba.b, to: T.self),
                        downscale(rgba.a, to: T.self))
    }
    
    /// Returns the given color with its components widened to the given type, preserving
    /// their normalized values.
    /// 
    /// `T.bitWidth` must be greater than or equal to `Component.bitWidth`.
    /// - Parameters:
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static 
    func upscale<Component, T>(_ rgba:RGBA<Component>, to type:T.Type) -> RGBA<T> 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        return .init(   upscale(rgba.r, to: T.self), 
                        upscale(rgba.g, to: T.self),
                        upscale(rgba.b, to: T.self),
                        upscale(rgba.a, to: T.self))
    }
    
    /// Returns the given color with its components scaled to the given type, preserving
    /// their normalized values.
    /// 
    /// - Parameters:
    ///     - rgba: An RGBA color.
    ///     - type: The type of the components of the new color.
    /// - Returns: A new color, with the values of its components taken from
    ///     the given color, and normalized to the range of `T`.
    @inline(__always)
    static 
    func rescale<Component, T>(_ rgba:RGBA<Component>, to type:T.Type) -> RGBA<T> 
        where Component:FixedWidthInteger & UnsignedInteger, T:FixedWidthInteger & UnsignedInteger
    {
        if T.bitWidth > Component.bitWidth
        {
            return upscale(rgba, to: T.self)
        }
        else
        {
            return downscale(rgba, to: T.self)
        }
    }
    
    
    /// A two-component color value, with components stored in the grayscale-alpha
    /// color model. This structure has fixed layout, with the value component first,
    /// then alpha. Buffers containing instances of this type may be safely reinterpreted
    /// as flat buffers containing interleaved components.
    @frozen
    public
    struct VA<Component>:Hashable where Component:FixedWidthInteger & UnsignedInteger
    {
        /// The value component of this color.
        public
        var v:Component
        /// The alpha component of this color.
        public
        var a:Component

        /// Creates an opaque grayscale color with the value component set to the
        /// given value sample, and the alpha component set to `Component.max`.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize the value component to.
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

        /// Creates a grayscale color with the value component set to the given
        /// value sample, and the alpha component set to the given alpha sample.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize the value component to.
        ///     - alpha: The value to initialize the alpha component to.
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

        /// Returns a copy of this color with the alpha component set to the given sample.
        /// - Parameters:
        ///     - a: An alpha sample.
        /// - Returns: This color with the alpha component set to the given sample.
        func withAlpha(_ a:Component) -> VA<Component>
        {
            return .init(self.v, a)
        }

        /// The color obtained by premultiplying the value component of this color
        /// with its alpha component. The resulting component values are accurate
        /// to within 1 `Component` unit.
        /// 
        /// *Inlinable*.
        @inlinable
        public
        var premultiplied:VA<Component>
        {
            .init(premultiply(color: self.v, alpha: self.a), self.a)
        }
    }

    /// A four-component color value, with components stored in the RGBA color model.
    /// This structure has fixed layout, with the red component first, then green,
    /// then blue, then alpha. Buffers containing instances of this type may be
    /// safely reinterpreted as flat buffers containing interleaved components.
    @frozen
    public
    struct RGBA<Component>:Hashable where Component:FixedWidthInteger & UnsignedInteger
    {
        /// The red component of this color.
        public
        var r:Component
        /// The green component of this color.
        public
        var g:Component
        /// The blue component of this color.
        public
        var b:Component
        /// The alpha component of this color.
        public
        var a:Component

        /// Creates an opaque grayscale color with all color components set to the given
        /// value sample, and the alpha component set to `Component.max`.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize all color components to.
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

        /// Creates a grayscale color with all color components set to the given
        /// value sample, and the alpha component set to the given alpha sample.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - value: The value to initialize all color components to.
        ///     - alpha: The value to initialize the alpha component to.
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

        /// Creates an opaque color with the given color samples, and the alpha
        /// component set to `Component.max`.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - red: The value to initialize the red component to.
        ///     - green: The value to initialize the green component to.
        ///     - blue: The value to initialize the blue component to.
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

        /// Creates an opaque color with the given color and alpha samples.
        /// 
        /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`, UInt64,
        ///     and `UInt`.
        /// - Parameters:
        ///     - red: The value to initialize the red component to.
        ///     - green: The value to initialize the green component to.
        ///     - blue: The value to initialize the blue component to.
        ///     - alpha: The value to initialize the alpha component to.
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
        
        init(_ va:VA<Component>)
        {
            self.init(va.v, va.a)
        }

        /// The color obtained by premultiplying the red, green, and blue components
        /// of this color with its alpha component. The resulting component values
        /// are accurate to within 1 `Component` unit.
        /// 
        /// *Inlinable*.
        @inlinable
        public
        var premultiplied:RGBA<Component>
        {
            .init(  premultiply(color: self.r, alpha: self.a),
                    premultiply(color: self.g, alpha: self.a),
                    premultiply(color: self.b, alpha: self.a),
                    self.a)
        }

        /// The red, and alpha components of this color, stored as a grayscale-alpha
        /// color.
        /// 
        /// *Inlinable*.
        @inlinable
        public
        var va:VA<Component>
        {
            .init(self.r, self.a)
        }

        /// Returns a copy of this color with the alpha component set to the given sample.
        /// - Parameters:
        ///     - a: An alpha sample.
        /// - Returns: This color with the alpha component set to the given sample.
        func withAlpha(_ a:Component) -> RGBA<Component>
        {
            return .init(self.r, self.g, self.b, a)
        }

        /// Returns a boolean value indicating whether the color components of this
        /// color are equal to the color components of the given color, ignoring
        /// the alpha components.
        /// - Parameters:
        ///     - other: Another color.
        /// - Returns: `true` if the red, green, and blue components of this color
        ///     and `other` are equal, `false` otherwise.
        func equals(opaque other:RGBA<Component>) -> Bool
        {
            return self.r == other.r && self.g == other.g && self.b == other.b
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

            /// Calls a closure with an interface for reading from the specified file.
            /// 
            /// This method automatically closes the file when its function argument returns.
            /// - Parameters:
            ///     - path: A path to the file to open.
            ///     - body: A closure with a `Source` parameter from which data in
            ///         the specified file can be read. This interface is only valid
            ///         for the duration of the method’s execution. The closure is
            ///         only executed if the specified file could be successfully
            ///         opened, otherwise `nil` is returned. If `body` has a return
            ///         value and the specified file could be opened, its return
            ///         value is returned as the return value of the `open(path:body:)`
            ///         method.
            /// - Returns: `nil` if the specified file could not be opened, or the
            ///     return value of the function argument otherwise.
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

            /// Read the specified number of bytes from this file interface.
            /// 
            /// This method only returns an array if the exact number of bytes
            /// specified could be read. This method advances the file pointer.
            /// 
            /// - Parameters:
            ///     - capacity: The number of bytes to read.
            /// - Returns: An array containing the read data, or `nil` if the specified
            ///     number of bytes could not be read.
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

            /// Calls a closure with an interface for writing to the specified file.
            /// 
            /// This method automatically closes the file when its function argument returns.
            /// - Parameters:
            ///     - path: A path to the file to open.
            ///     - body: A closure with a `Destination` parameter representing
            ///         the specified file to which data can be written to. This
            ///         interface is only valid for the duration of the method’s
            ///         execution. The closure is only executed if the specified
            ///         file could be successfully opened, otherwise `nil` is returned.
            ///         If `body` has a return value and the specified file could
            ///         be opened, its return value is returned as the return value
            ///         of the `open(path:body:)` method.
            /// - Returns: `nil` if the specified file could not be opened, or the
            ///     return value of the function argument otherwise.
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

            /// Write the bytes in the given array to this file interface.
            /// 
            /// This method only returns `()` if the entire array argument could
            /// be written. This method advances the file pointer.
            /// 
            /// - Parameters:
            ///     - buffer: The data to write.
            /// - Returns: `()` if the entire array argument could be written, or
            ///     `nil` otherwise.
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
        let v:SIMD3<Int16> = .init(truncatingIfNeeded: .init(a, b, c)),
            d:SIMD3<Int16> = v.x + v.y - v.z &- v
        let f:(x:Int16, y:Int16, z:Int16) = (abs(d.x), abs(d.y), abs(d.z))

        if f.x <= f.y && f.x <= f.z
        {
            return a
        }
        else if f.y <= f.z
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
        /// A pixel format used to encode the color values of a PNG.
        /// 
        /// Pixel formats consist of a color format, and a color depth.
        /// 
        /// Color formats can have multiple components, one for each independent
        /// dimension pixel values encoded in this format have. A grayscale format,
        /// for example, has one component (value), while an RGBA format has four
        /// (red, green, blue, alpha).
        /// 
        /// Components are separate from channels, which are the independent values
        /// needed to *encode*a pixel value in a PNG image. An indexed pixel format,
        /// for example, has only one channel — a scalar index into a palette table —
        /// but has three components, as the entries in the palette table encode
        /// red, green, and blue components.
        /// 
        /// Color depth refers to the number of bits of precision used to encode
        /// each channel.
        /// 
        /// Not all combinations of color formats and color depths are allowed.
        /// 
        /// | *depth* |  indexed   |   grayscale   | grayscale-alpha |   RGB   |   RGBA   |
        /// | ------- | ---------- | ------------- | --------------- | ------- | -------- |
        /// |    1    | `indexed1` | `v1`          |
        /// |    2    | `indexed2` | `v2`          |
        /// |    4    | `indexed4` | `v4`          |
        /// |    8    | `indexed8` | `v8`          | `va8`           | `rgb8`  | `rgba8`  |
        /// |    16   |            | `v16`         | `va16`          | `rgb16` | `rgba16` |
        public
        enum Format
        {
            case    v1,
                    v2,
                    v4,
                    v8,
                    v16,
                    rgb8(_ palette:[RGBA<UInt8>]?),
                    rgb16(_ palette:[RGBA<UInt8>]?),
                    indexed1(_ palette:[RGBA<UInt8>]),
                    indexed2(_ palette:[RGBA<UInt8>]),
                    indexed4(_ palette:[RGBA<UInt8>]),
                    indexed8(_ palette:[RGBA<UInt8>]),
                    va8,
                    va16,
                    rgba8(_ palette:[RGBA<UInt8>]?),
                    rgba16(_ palette:[RGBA<UInt8>]?)

            public
            enum Code:UInt16
            {
                case    v1          = 0x01_00,
                        v2          = 0x02_00,
                        v4          = 0x04_00,
                        v8          = 0x08_00,
                        v16         = 0x10_00,
                        rgb8        = 0x08_02,
                        rgb16       = 0x10_02,
                        indexed1    = 0x01_03,
                        indexed2    = 0x02_03,
                        indexed4    = 0x04_03,
                        indexed8    = 0x08_03,
                        va8         = 0x08_04,
                        va16        = 0x10_04,
                        rgba8       = 0x08_06,
                        rgba16      = 0x10_06

                /// The bit depth of each channel of this pixel format.
                @inlinable
                public
                var depth:Int
                {
                    .init(self.rawValue >> 8)
                }

                /// A boolean value indicating if this pixel format has indexed color.
                /// 
                /// `true` if `self` is `indexed1`, `indexed2`, `indexed4`, or `indexed8`.
                /// `false` otherwise.
                @inlinable
                public
                var isIndexed:Bool
                {
                    self.rawValue & 1 != 0
                }

                /// A boolean value indicating if this pixel format has at least three
                /// color components.
                /// 
                /// `true` if `self` is `indexed1`, `indexed2`, `indexed4`, `indexed8`,
                /// `rgb8`, `rgb16`, `rgba8`, or `rgba16`. `false` otherwise.
                @inlinable
                public
                var hasColor:Bool
                {
                    self.rawValue & 2 != 0
                }

                /// A boolean value indicating if this pixel format has an alpha channel.
                /// 
                /// `true` if `self` is `va8`, `va16`, `rgba8`, or
                /// `rgba16`. `false` otherwise.
                @inlinable
                public
                var hasAlpha:Bool
                {
                    self.rawValue & 4 != 0
                }

                /// The number of channels encoded by this pixel format.
                @inlinable
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

                /// The total number of bits needed to encode all channels of this pixel
                /// format.
                @inlinable
                var volume:Int
                {
                    self.depth * self.channels
                }

                /// The number of components represented by this pixel format.
                @inlinable
                public
                var components:Int
                {
                    switch self
                    {
                    case .v1, .v2, .v4, .v8, .v16:
                        return 1
                    case .va8, .va16:
                        return 2
                    case .rgb8, .rgb16:
                        return 3
                    case .rgba8, .rgba16,
                        .indexed1, .indexed2, .indexed4, .indexed8:
                        return 4
                    }
                }

                /// Returns the shape of a buffer just large enough to contain an image
                /// of the given size, stored in this color format.
                func shape(from size:(x:Int, y:Int)) -> Data.Shape
                {
                    let scanlineBitCount:Int = size.x * self.channels * self.depth
                                                    // ceil(scanlineBitCount / 8)
                    let pitch:Int = scanlineBitCount >> 3 + (scanlineBitCount & 7 == 0 ? 0 : 1)
                    return .init(pitch: pitch, size: size)
                }
            }

            @inlinable
            public
            var code:Code
            {
                switch self
                {
                    case .v1:
                        return .v1
                    case .v2:
                        return .v2
                    case .v4:
                        return .v4
                    case .v8:
                        return .v8
                    case .v16:
                        return .v16
                    case .rgb8:
                        return .rgb8
                    case .rgb16:
                        return .rgb16
                    case .indexed1:
                        return .indexed1
                    case .indexed2:
                        return .indexed2
                    case .indexed4:
                        return .indexed4
                    case .indexed8:
                        return .indexed8
                    case .va8:
                        return .va8
                    case .va16:
                        return .va16
                    case .rgba8:
                        return .rgba8
                    case .rgba16:
                        return .rgba16
                }
            }

            /// The palette associated with this color format, if applicable.
            public
            var palette:[RGBA<UInt8>]?
            {
                switch self
                {
                    case    let .indexed1(palette),
                            let .indexed2(palette),
                            let .indexed4(palette),
                            let .indexed8(palette):
                        return palette

                    case    let .rgb8(option),
                            let .rgb16(option),
                            let .rgba8(option),
                            let .rgba16(option):
                        return option
                    default:
                        return nil
                }
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
                /// Two sequences of two-dimensional coordinates representing the
                /// logical positions of each pixel in this sub-image, when deinterlaced
                /// with its other sub-images.
                let strider:(x:StrideTo<Int>, y:StrideTo<Int>)
            }

            /// No interlacing.
            case none
            /// [Adam7](https://en.wikipedia.org/wiki/Adam7_algorithm) interlacing.
            case adam7([SubImage])

            /// Returns the index ranges containing each Adam7 sub-image when all
            /// sub-images are packed back-to-back in a single buffer, starting
            /// with the smallest sub-image.
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

            /// Creates the pitch sequence for an Adam7 interlaced PNG with the
            /// given sub-images.
            /// 
            /// - Parameters:
            ///     - subImages: The sub-images of an interlaced image.
            init(subImages:[Interlacing.SubImage])
            {
                self.footprints = subImages.map
                {
                    ($0.shape.pitch, $0.shape.size.y)
                }
            }

            /// Creates the pitch sequence for a non-interlaced PNG with the given
            /// shape.
            /// 
            /// - Parameters:
            ///     - shape: The shape of a non-interlaced image.
            init(shape:Data.Shape)
            {
                self.footprints = [(shape.pitch, shape.size.y)]
            }

            /// Returns the pitch of the next scanline, if it is different from
            /// the pitch of the previous scanline.
            /// 
            /// - Returns: The pitch of the next scanline, if it is different from
            ///     that of the previous scanline, `nil` in the inner optional if
            ///     it is the same as that of the previous scanline, and `nil` in
            ///     the outer optional if there should be no more scanlines left
            ///     in the image.
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

        public
        struct Header
        {
            public
            let size:(x:Int, y:Int)
            public
            let code:Format.Code
            public
            let interlaced:Bool

            /// Decodes the data of an IHDR chunk as a `Properties` record.
            /// 
            /// - Parameters:
            ///     - data: IHDR chunk data.
            /// - Returns: A `Properties` object containing the information encoded by
            ///     the given IHDR chunk.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If any of the IHDR chunk fields contain
            ///         an invalid value.
            public static
            func decodeIHDR(_ data:[UInt8]) throws -> Header
            {
                guard data.count == 13
                else
                {
                    throw DecodingError.invalidChunk(message: "png header length is \(data.count), expected 13")
                }

                let colorcode:UInt16 = data.load(bigEndian: UInt16.self, as: UInt16.self, at: 8)
                guard let code:Format.Code = Format.Code.init(rawValue: colorcode)
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

                return .init(size: (width, height), code: code, interlaced: interlaced)
            }

            /// Decodes the data of a PLTE chunk, validates, and returns it as an
            /// array of `PNG.RGBA<UInt8>` entries.
            /// 
            /// - Parameters:
            ///     - data: PLTE chunk data. Must not contain more entries than this
            ///         PNG’s color depth can uniquely encode.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given palette data does not contain
            ///         a whole number of palette entries, or if it contains more than
            ///         `1 << format.depth` entries
            ///     - DecodingError.unexpectedChunk: If this PNG does not have
            ///         a three-color format.
            public
            func decodePLTE(_ data:[UInt8]) throws -> [RGBA<UInt8>]
            {
                guard self.code.hasColor
                else
                {
                    throw DecodingError.unexpectedChunk(.core(.palette))
                }

                guard data.count.isMultiple(of: 3)
                else
                {
                    throw DecodingError.invalidChunk(message: "palette does not contain a whole number of entries (\(data.count) bytes)")
                }

                // check number of palette entries
                let maxEntries:Int = 1 << self.code.depth
                guard data.count <= maxEntries * 3
                else
                {
                    throw DecodingError.invalidChunk(message: "palette contains too many entries (found \(data.count / 3), expected\(maxEntries))")
                }

                return stride(from: data.startIndex, to: data.endIndex, by: 3).map
                {
                    let r:UInt8 = data[$0    ],
                        g:UInt8 = data[$0 + 1],
                        b:UInt8 = data[$0 + 2]
                    return .init(r, g, b)
                }
            }

            /// Decodes the data of a tRNS chunk, validates, and modifies the given
            /// palette table.
            /// 
            /// This method should only be called if the PNG has an indexed pixel format.
            /// 
            /// - Parameters:
            ///     - data: tRNS chunk data. It must not contain more transparency
            ///         values than the PNG’s color depth can uniquely encode.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given transparency data
            ///         contains more than `palette.count` trasparency values.
            ///     - DecodingError.unexpectedChunk: If the PNG does not have an
            ///         indexed color format.
            public
            func decodetRNS(_ data:[UInt8], palette:inout [RGBA<UInt8>]) throws
            {
                guard self.code.isIndexed
                else
                {
                    throw DecodingError.unexpectedChunk(.core(.transparency))
                }

                guard data.count <= palette.count
                else
                {
                    throw DecodingError.invalidChunk(message: "indexed image contains too many transparency entries (\(data.count), expected \(palette.count))")
                }

                palette = zip(palette, data).map
                {
                    $0.0.withAlpha($0.1)
                }
                +
                palette.dropFirst(data.count)
            }

            /// Decodes the data of a tRNS chunk, validates, and returns a chroma key.
            /// 
            /// This method should only be called if the PNG has an RGB or grayscale
            /// pixel format.
            /// 
            /// - Parameters:
            ///     - data: tRNS chunk data. If this PNG has a grayscale pixel format,
            ///         it must contain one value sample. If this PNG has an RGB pixel
            ///         format, it must contain three samples, red, green, and blue.
            /// - Throws:
            ///     - DecodingError.invalidChunk: If the given transparency data does not
            ///         contain the correct number of samples.
            ///     - DecodingError.unexpectedChunk: If the PNG does not have an
            ///         opaque color format.
            public
            func decodetRNS(_ data:[UInt8]) throws -> RGBA<UInt16>
            {
                switch self.code
                {
                    case .v1, .v2, .v4, .v8, .v16:
                        guard data.count == 2
                        else
                        {
                            throw DecodingError.invalidChunk(message: "grayscale chroma key has wrong size (\(data.count) bytes, expected 2 bytes)")
                        }

                        let q:UInt16 = quantum(depth: self.code.depth),
                            v:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0)
                        return .init(v)

                    case .rgb8, .rgb16:
                        guard data.count == 6
                        else
                        {
                            throw DecodingError.invalidChunk(message: "rgb chroma key has wrong size (\(data.count) bytes, expected 6 bytes)")
                        }

                        let q:UInt16 = quantum(depth: self.code.depth),
                            r:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 0),
                            g:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 2),
                            b:UInt16 = q * data.load(bigEndian: UInt16.self, as: UInt16.self, at: 4)
                        return .init(r, g, b)

                    default:
                        throw DecodingError.unexpectedChunk(.core(.transparency))
                }
            }
        }

        /// The pixel format of this PNG image, and its associated color palette,
        /// if applicable.
        public
        let format:Format

        /// The chroma key of this PNG image, if it has one.
        /// 
        /// The alpha component of this property is ignored by the library.
        public
        var chromaKey:RGBA<UInt16>?

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
            self.shape.size
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

        /// The number of bytes needed to store the encoded image data of this PNG
        /// image.
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

        /// Creates a PNG `Properties` record with the given properties.
        ///
        /// - Parameters:
        ///     - size: A pair of pixel dimensions.
        ///     - format: A pixel format.
        ///     - interlaced: A boolean value indicating if an interlacing algorithm
        ///         will be used. The default is `false`.
        ///     - chromaKey: A chroma key, or `nil`. The default is `nil`.
        public
        init(size:(x:Int, y:Int), format:Format, interlaced:Bool = false,
            chromaKey:RGBA<UInt16>? = nil)
        {
            self.format = format
            self.shape  = format.code.shape(from: size)

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
                let sizes:[(Int, Int)] =
                [
                    ((size.x + 7) >> 3, (size.y + 7) >> 3),
                    ((size.x + 3) >> 3, (size.y + 7) >> 3),
                    ((size.x + 3) >> 2, (size.y + 3) >> 3),
                    ((size.x + 1) >> 2, (size.y + 3) >> 2),
                    ((size.x + 1) >> 1, (size.y + 1) >> 2),
                    ( size.x      >> 1, (size.y + 1) >> 1),
                    ( size.x      >> 0,  size.y      >> 1)
                ]

                let striders:[(StrideTo<Int>, StrideTo<Int>)] =
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
                    (size:(Int, Int), strider:(StrideTo<Int>, StrideTo<Int>)) in

                    return .init(shape: format.code.shape(from: size), strider: strider)
                }

                self.interlacing = .adam7(subImages)
            }
            else
            {
                self.interlacing = .none
            }

            self.chromaKey = chromaKey
        }

        /// Initializes and returns a PNG `Decoder`.
        /// - Returns: An image `Decoder` in its initial state.
        public
        func decoder() throws -> Decoder
        {
            let inflator:LZ77.Inflator = try .init(),
                stride:Int             = max(1, self.format.code.volume >> 3)
            return .init(stride: stride, pitches: self.pitches, inflator: inflator)
        }

        /// Initializes and returns a PNG `Encoder`.
        /// - Parameters:
        ///     - level: The compression level the returned `Encoder` will use.
        ///         Must be in the range `0 ... 9`, where 0 is no compression, and
        ///         9 is the highest possible amount of compression.
        /// - Returns: An image `Encoder` in its initial state.
        public
        func encoder(level:Int) throws -> Encoder
        {
            let deflator:LZ77.Deflator = try .init(level: level),
                stride:Int             = max(1, self.format.code.volume >> 3)
            return .init(stride: stride, pitches: self.pitches, deflator: deflator)
        }

        /// A low level API for receiving and processing decompressed and decoded
        /// PNG image data at the scanline level.
        public
        struct Decoder
        {
            /// The decoded pixels of the previous scanline decoded. Initialized
            /// to all zeroes before decoding the first scanline of a (sub-)image.
            private
            var reference:[UInt8]?
            
            /// The decoded pixels of the current scanline. Can be partially filled
            /// if individual image data blocks do not contain a whole number of
            /// scanlines.
            private
            var scanline:[UInt8] = []

            /// The filter delay used by this image `Decoder`. This value is computed
            /// from the volume of a PNG pixel format, but has no meaning itself.
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

            /// Calls the given closure for each complete scanline decoded from
            /// the given compressed image data, passing the decoded contents of
            /// the scanline to the closure.
            /// 
            /// Individual data blocks can produce incomplete scanlines. These
            /// scanlines are stored and will be completed by subsequent data blocks,
            /// when they will be passed as full scanlines to the closures given
            /// in the later `forEachScanline(decodedFrom:_:)` calls.
            /// - Parameters:
            ///     - data: Compressed image data.
            ///     - body: A closure which takes as an argument a decoded scanline.
            /// - Returns: `true` if this `Decoder`’s LZ77 stream expects more input
            ///     data, and `false` otherwise.
            /// 
            /// - Warning: Do not call this method again on the same instance after
            ///     it has returned `false`. Doing so will result in undefined behavior.
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

            /// Defilters the given filtered scanline in-place, using the given
            /// reference scanline.
            /// 
            /// - Parameters:
            ///     - scanline: The scanline to defilter in-place. The first byte
            ///         of the scanline is interpreted as the filter byte, and this
            ///         byte is set to 0 upon defiltering.
            ///     - reference: The defiltered scanline assumed to be immediately
            ///         above the given filtered scanline. This scanline should
            ///         contain all zeroes if the filtered scanline is logically
            ///         the first scanline in its (sub-)image. The first byte of
            ///         this scanline should always be a bogus padding byte corresponding
            ///         to the filter byte of a filtered scanline, such that
            ///         `reference.count == scanline.count`.
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

        /// A low level API for filtering and compressing PNG image data at the
        /// scanline level.
        public
        struct Encoder
        {
            // unlike the `Decoder`, here, it’s more efficient for `reference` to
            // *not* contain the filter byte prefix

            /// The unfiltered pixels of the previous scanline encoded. Initialized
            /// to all zeroes before encoding the first scanline of a (sub-)image.
            private
            var reference:[UInt8]?

            /// The filter delay used by this image `Encoder`. This value is computed
            /// from the volume of a PNG pixel format, but has no meaning itself.
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

            /// Filters and compresses scanlines returned by the given closure,
            /// appending the compressed data to the given data buffer.
            /// 
            /// *Specialized* for `RAC` types `[UInt8]`, `ArraySlice<UInt8>`, `UnsafeBufferPointer<UInt8>`,
            /// `Slice<UnsafeBufferPointer<UInt8>>`, and `Slice<UnsafeMutableBufferPointer<UInt8>>`.
            /// 
            /// - Parameters:
            ///     - data: A data buffer to append compressed scanline data to.
            ///     - capacity: The maximum size `data` is allowed to reach before
            ///         this method will stop outputting data to it.
            ///     - generator: A closure which, when called repeatedly, returns
            ///         scanlines to filter and compress, and `nil` when there
            ///         are no more scanlines to encode.
            /// 
            /// - Returns: `true` if `data.count` was filled to the specified capacity,
            ///     or if `generator` returned `nil`. `false` if this `Encoder`
            ///     is finished encoding data. Once this method returns `false`,
            ///     it should not be called again on the same instance.
            /// - Throws: `EncodingError.bufferCount`, if `generator` returns a scanline
            ///     that does not have the expected size.
            @_specialize(where RAC == [UInt8])
            @_specialize(where RAC == ArraySlice<UInt8>)
            @_specialize(where RAC == UnsafeBufferPointer<UInt8>)
            @_specialize(where RAC == UnsafeMutableBufferPointer<UInt8>)
            @_specialize(where RAC == Slice<UnsafeBufferPointer<UInt8>>)
            @_specialize(where RAC == Slice<UnsafeMutableBufferPointer<UInt8>>)
            public mutating
            func consolidate<RAC>(extending data:inout [UInt8], capacity:Int,
                scanlinesFrom generator:() -> RAC?) throws -> Bool
                where RAC:RandomAccessCollection, RAC.Element == UInt8
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

                    guard let row:RAC = generator()
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

            /// Returns the given scanline filtered based on the given reference
            /// scanline, with a filter chosen by heuristic to optimize compressibility.
            /// 
            /// - Parameters:
            ///     - current: A scanline to filter. This scanline is *not* prefixed
            ///         by a bogus filter byte.
            ///     - reference: The unfiltered scanline assumed to be immediately
            ///         above the given filtered scanline. This scanline should
            ///         contain all zeroes if the scanline to be filtered is logically
            ///         the first scanline in its (sub-)image. This scanline is
            ///         *not* prefixed by a bogus filter byte. `reference.count`
            ///         must be equal to `scanline.count`.
            /// - Returns: The filtered scanline, prefixed by a filter byte indicating
            ///     the filter chosen by the library.
            private
            func filter<S>(_ current:S, reference:[UInt8]) -> [UInt8]
                where S:Sequence, S.Element == UInt8
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

                candidates.average =   ([3] +
                zip(reference,
                    current).prefix(self.stride).map
                {
                    $0.1   &- $0.0 >> 1
                } as [UInt8])
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

            /// Scores the compressibility of the given filtered scanline candidate.
            /// 
            /// - Parameters:
            ///     - filtered: A filtered scanline to score.
            /// - Returns: A score rating the compressibility of the given filtered
            ///     scanline candidate. A higher score indicates less compressibility.
            private static
            func score<S>(_ filtered:S) -> Int
                where S:Sequence, S.Element == UInt8
            {
                return zip(filtered, filtered.dropFirst()).count
                {
                    $0.0 != $0.1
                }
            }
        }

        /// Encodes the header fields of this `Properties` record as the chunk data
        /// of an IHDR chunk.
        /// 
        /// - Returns: An array containing IHDR chunk data. The chunk header, length,
        ///     and crc32 tail are not included.
        public
        func encodeIHDR() -> [UInt8]
        {
            let header:[UInt8] =
            [UInt8].store(self.shape.size.x,         asBigEndian: UInt32.self) +
            [UInt8].store(self.shape.size.y,         asBigEndian: UInt32.self) +
            [UInt8].store(self.format.code.rawValue, asBigEndian: UInt16.self) +
            [0, 0, self.interlaced ? 1 : 0]

            return header
        }

        /// Encodes this PNG’s palette as the chunk data of a PLTE chunk, if it
        /// has one.
        /// 
        /// This method always returns valid PLTE chunk data. If this `Properties`
        /// record has more palette entries than can be encoded with its color depth,
        /// only the first `1 << format.depth` entries are encoded. This method
        /// does not remove palette entries from this metatada record itself.
        /// 
        /// - Returns: An array containing PLTE chunk data, or `nil` if this PNG
        ///     does not have a palette. The chunk header, length,
        ///     and crc32 tail are not included.
        public
        func encodePLTE() -> [UInt8]?
        {
            return self.format.palette?.prefix(1 << self.format.code.depth).flatMap
            {
                [$0.r, $0.g, $0.b]
            }
        }

        /// Encodes this PNG’s transparency information as the chunk data of a tRNS
        /// chunk, if it has any.
        /// 
        /// This method always returns valid tRNS chunk data. If this PNG has an
        /// indexed pixel format, and this `Properties` record has more palette entries
        /// than can be encoded with its color depth, then only the first `1 << format.depth`
        /// transparency values are encoded. This method does not remove palette
        /// entries from this `Properties` record itself.
        /// 
        /// - Returns: An array containing tRNS chunk data, or `nil` if this PNG
        ///     does not have an transparency information. The chunk header, length,
        ///     and crc32 tail are not included. The chunk data consists of a single
        ///     grayscale chroma key value, narrowed to this PNG’s color depth,
        ///     if it has an opaque grayscale pixel format, an RGB chroma key triple,
        ///     narrowed to this PNG’s color depth, if it has an opaque RGB pixel
        ///     format, and the transparency values in this PNG’s color palette,
        ///     if it has an indexed color format. In the indexed color case, trailing
        ///     opaque palette entries are trimmed from the outputted sequence of
        ///     transparency values. If all palette entries are opaque, or this
        ///     `Properties` record has not been assigned a palette, `nil` is returned.
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
                    let quantization:Int = UInt16.bitWidth - self.format.code.depth
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
                    let quantization:Int = UInt16.bitWidth - self.format.code.depth
                    return
                        [
                            key.r >> quantization,
                            key.g >> quantization,
                            key.b >> quantization
                        ].flatMap
                        {
                            [UInt8].store($0, asBigEndian: UInt16.self)
                        }

                case    let .indexed1(palette),
                        let .indexed2(palette),
                        let .indexed4(palette),
                        let .indexed8(palette):

                    var alphas:[UInt8] = palette.prefix(1 << self.format.code.depth).map{ $0.a }
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
        public 
        typealias Ancillaries = (unique:[Chunk.Unique: [UInt8]], repeatable:[(Chunk.Repeatable, [UInt8])])
        
        /// A PNG image that has been decompressed, but not necessarily deinterlaced.
        public
        struct Uncompressed
        {
            /// The global image `Properties` of this PNG image.
            public
            let properties:Properties
            
            /// The buffer containing this PNG’s decoded, but not necessarily
            /// deinterlaced, image data.
            public
            let data:[UInt8]
            
            /// Additional chunks not parsed by the library.
            public 
            let ancillaries:Ancillaries 

            /// Creates an uncompressed PNG image with the given pixel buffer and
            /// `Properties` record.
            /// 
            /// - Parameters:
            ///     - data: A pixel buffer.
            ///     - properties: A `Properties` record.
            ///     - ancillaries: Additional chunks to include in the image. Empty 
            ///         by default.
            /// - Returns: An uncompressed PNG image. If the size of the given
            ///     pixel buffer is not consistent with the size and format information
            ///     in the given `properties`, a fatal error will occur.
            public
            init(rawData data:[UInt8], properties:Properties, ancillaries:Ancillaries = ([:], []))
            {
                guard data.count == properties.byteCount
                else
                {
                    fatalError("rawData array count doesn’t match dimensions given by properties parameter")
                }

                self.properties     = properties
                self.data           = data
                self.ancillaries    = ancillaries
            }

            /// Decomposes this uncompressed image into its constituent sub-images,
            /// if this image is interlaced.
            /// 
            /// - Returns: The seven sub-images making up this image, if it uses
            ///     the Adam7 interlacing algorithm, and `nil` otherwise.
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

                    return .init(rawData: .init(self.data[range]), properties: properties)
                }
            }

            /// Returns the pixels of this uncompressed image, organized into a
            /// rectangular row-major pixel matrix.
            /// 
            /// This method deinterlaces the pixel data from this uncompressed image,
            /// if it uses an interlacing algorithm. Otherwise, it simply repackages
            /// this image’s already-rectangular `data`.
            ///
            /// - Returns: A rectangular row-major pixel matrix.
            public
            func deinterlaced() -> Rectangular
            {
                guard case .adam7(let subImages) = self.properties.interlacing
                else
                {
                    // image is not interlaced at all, return it transparently
                    return .init(   rawData: self.data, 
                                 properties: self.properties, 
                                ancillaries: self.ancillaries)
                }

                let properties:Properties = .init(size: self.properties.shape.size,
                                                format: self.properties.format,
                                            interlaced: false,
                                             chromaKey: self.properties.chromaKey)

                let deinterlaced:[UInt8] = .init(unsafeUninitializedCapacity: properties.byteCount)
                {
                    (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

                    let volume:Int = properties.format.code.volume
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

                return .init(   rawData: deinterlaced, 
                             properties: properties, 
                            ancillaries: self.ancillaries)
            }

            /// Compresses this image, and outputs the compressed PNG file to the given
            /// data destination.
            /// 
            /// Excessively small chunk sizes may harm image compression. Higher
            /// compression levels produce smaller PNG files, but take longer to
            /// run.
            /// 
            /// - Parameters:
            ///     - destination: A data destination to write the contents of the
            ///         compressed file to.
            ///     - chunkSize: The maximum IDAT chunk size to use. The default
            ///         is 65536 bytes.
            ///     - level: The level of LZ77 compression to use. Must be in the
            ///         range `0 ... 9`, where 0 is no compression, and 9 is maximal
            ///         compression.
            public
            func compress<Destination>(to destination:inout Destination,
                chunkSize:Int = 1 << 16, level:Int = 9) throws
                where Destination:DataDestination
            {
                precondition(chunkSize >= 1, "chunk size must be positive")
                
                // partition ancillary chunks 
                // before PLTE
                var leaders:[(Chunk, [UInt8])]  = self.ancillaries.repeatable.map 
                {
                    (.repeatable($0.0), $0.1)
                } 
                // after PLTE (before IDAT)
                var trailers:[(Chunk, [UInt8])] = [] 
                for (unique, contents):(Chunk.Unique, [UInt8]) in self.ancillaries.unique 
                {
                    switch unique  
                    {
                        case .background, .histogram: 
                            trailers.append((.unique(unique), contents)) 
                        
                        default:
                            leaders.append((.unique(unique), contents))
                    }
                }
                
                guard var iterator:ChunkIterator<Destination> =
                    ChunkIterator.begin(destination: &destination)
                else
                {
                    throw EncodingError.notAcceptingData
                }

                @inline(__always)
                func _next(_ chunk:Chunk, _ contents:[UInt8] = []) throws
                {
                    guard let _:Void = iterator.next(chunk.tag, contents, destination: &destination)
                    else
                    {
                        throw EncodingError.notAcceptingData
                    }
                }
                
                // IHDR
                try _next(.core(.header), self.properties.encodeIHDR())
                
                // [leaders...]
                for (chunk, contents):(Chunk, [UInt8]) in leaders 
                {
                    try _next(chunk, contents)
                }
                
                // PLTE
                try self.properties.encodePLTE().map
                {
                    try _next(.core(.palette), $0)
                }
                // tRNS
                try self.properties.encodetRNS().map
                {
                    try _next(.core(.transparency), $0)
                }
                
                // [trailers...]
                for (chunk, contents):(Chunk, [UInt8]) in trailers 
                {
                    try _next(chunk, contents)
                }
                
                // [IDAT...]
                var pitches:Properties.Pitches = self.properties.pitches,
                encoder:Properties.Encoder = try self.properties.encoder(level: level)
                
                var pitch:Int?,
                base:Int = self.data.startIndex
                while true
                {
                    var output:[UInt8] = []
                    let more:Bool = try encoder.consolidate(extending: &output, capacity: chunkSize)
                    {
                        () -> ArraySlice<UInt8>? in

                        guard   let update:Int? = pitches.next(),
                                let count:Int   = update ?? pitch
                        else
                        {
                            return nil
                        }

                        let end:Int      = self.data.index(base, offsetBy: count),
                        range:Range<Int> = base ..< end

                        base  = end
                        pitch = count

                        return self.data[range]
                    }

                    try _next(.core(.data), output)

                    guard more
                    else
                    {
                        break
                    }
                }

                try _next(.core(.end))
            }
            
            private
            enum DecompressionStage
            {
                case i                             // initial
                case ii(header:Properties.Header)  // IHDR sighted
                case iii(header:Properties.Header, palette:[RGBA<UInt8>]) // PLTE sighted
                case iv(properties:Properties, decoder:Properties.Decoder) // IDAT sighted
                case v(properties:Properties)      // IDAT ended
            }
            
            /// Decompresses a PNG file from the given data source, and returns
            /// it as an `Uncompressed` image.
            /// 
            /// - Parameters:
            ///     - source: A data source yielding a PNG file.
            /// - Returns: An uncompressed PNG image.
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

                    guard let tag:Chunk.Tag = Chunk.Tag.init(name)
                    else
                    {
                        throw DecodingError.invalidName(name)
                    }
                    
                    let chunk:Chunk = .init(tag)

                    guard let contents:[UInt8] = data
                    else
                    {
                        throw DecodingError.corruptedChunk(chunk)
                    }

                    return (chunk, contents)
                }

                var chromaKey:RGBA<UInt16>? = nil,
                    data:[UInt8]            = [], 
                    ancillaries:Ancillaries = ([:], [])

                var (chunk, contents):(Chunk, [UInt8])  = try _next(),
                    stage:DecompressionStage            = .i,
                    seen:Bitfield<UInt16>               = .init()
                while true
                {
                    switch (chunk, stage)
                    {
                        case    (.core(.header), .i):
                            stage   = .ii(header: try .decodeIHDR(contents))
                            seen[0] = true
                        case    (_, .i):
                            throw DecodingError.missingChunk(.header)

                        case    (.core(.palette), .ii(let header)):
                            // call will throw if header does not have a color format
                            stage = .iii(header: header, palette: try header.decodePLTE(contents))
                        
                        case    (.core(.palette), .iv):
                            throw DecodingError.unexpectedChunk(.core(.palette))

                        case    (.core(.data), .ii(let header)):
                            let format:Properties.Format
                            switch header.code
                            {
                                case .v1:
                                    format = .v1
                                case .v2:
                                    format = .v2
                                case .v4:
                                    format = .v4
                                case .v8:
                                    format = .v8
                                case .v16:
                                    format = .v16
                                case .rgb8:
                                    format = .rgb8(nil)
                                case .rgb16:
                                    format = .rgb16(nil)
                                case .indexed1, .indexed2, .indexed4, .indexed8:
                                    throw DecodingError.missingChunk(.palette)
                                case .va8:
                                    format = .va8
                                case .va16:
                                    format = .va16
                                case .rgba8:
                                    format = .rgba8(nil)
                                case .rgba16:
                                    format = .rgba16(nil)
                            }

                            let properties:Properties = .init(size: header.size,
                                                            format: format,
                                                        interlaced: header.interlaced,
                                                         chromaKey: chromaKey
                                                            )
                            data.reserveCapacity(properties.byteCount)
                            stage = .iv(properties: properties, decoder: try properties.decoder())
                            continue

                        case    (.core(.data), .iii(let header, let palette)):
                            let format:Properties.Format
                            switch header.code
                            {
                                case .rgb8:
                                    format = .rgb8(palette)
                                case .rgb16:
                                    format = .rgb16(palette)
                                case .indexed1:
                                    format = .indexed1(palette)
                                case .indexed2:
                                    format = .indexed2(palette)
                                case .indexed4:
                                    format = .indexed4(palette)
                                case .indexed8:
                                    format = .indexed8(palette)
                                case .rgba8:
                                    format = .rgba8(palette)
                                case .rgba16:
                                    format = .rgba16(palette)
                                case .v1, .v2, .v4, .v8, .v16, .va8, .va16:
                                    fatalError("unreachable: `case (.PLTE, .ii(let header)):` should have blocked off this state")
                            }

                            let properties:Properties = .init(size: header.size,
                                                            format: format,
                                                        interlaced: header.interlaced,
                                                         chromaKey: chromaKey
                                                            )
                            data.reserveCapacity(properties.byteCount)
                            stage = .iv(properties: properties, decoder: try properties.decoder())
                            continue

                        case    (.core(.data), .iv(let properties, var decoder)):
                            let streamContinue:Bool = try decoder.forEachScanline(decodedFrom: contents)
                            {
                                data.append(contentsOf: $0)
                            }

                            stage = streamContinue ?
                                .iv(properties: properties, decoder: decoder) :
                                .v(properties: properties)

                        case    (_, .iv):
                            throw DecodingError.unexpectedChunk(chunk)

                        case    (.core(.end), .v(let properties)):
                            guard data.count == properties.byteCount
                            else
                            {
                                // not enough data
                                throw DecodingError.inconsistentMetadata
                            }

                            return .init(rawData: data, properties: properties, ancillaries: ancillaries)

                        case    (.core(.end), .ii),
                                (.core(.end), .iii):
                            throw DecodingError.missingChunk(.data)

                        case    (.core(.transparency), .ii(let header)):
                            // call will throw if header does not have a v or rgb format
                            chromaKey = try header.decodetRNS(contents)
                        case    (.core(.transparency), .iii(let header, var palette)):
                            // call will throw if header does not have a v or rgb format
                            try header.decodetRNS(contents, palette: &palette)
                            stage = .iii(header: header, palette: palette)

                        case    (.unique(.background), .ii(let header)):
                            guard !header.code.isIndexed
                            else
                            {
                                throw DecodingError.missingChunk(.palette)
                            }

                        case    (.unique(.histogram),           .ii):
                            throw DecodingError.missingChunk(.palette)

                        case    (.core(.header),                .iii),
                                (.unique(.chromaticity),        .iii),
                                (.unique(.gamma),               .iii),
                                (.unique(.profile),             .iii),
                                (.unique(.srgb),                .iii),

                                (.core(.header),                .v),
                                (.core(.palette),               .v),
                                (.core(.data),                  .v),
                                (.unique(.chromaticity),        .v),
                                (.unique(.gamma),               .v),
                                (.unique(.profile),             .v),
                                (.unique(.srgb),                .v),

                                (.unique(.physicalDimensions),  .v),
                                (.repeatable(.suggestedPalette),.v),

                                (.unique(.background),          .v),
                                (.unique(.histogram),           .v),
                                (.core(.transparency),          .v):
                            throw DecodingError.unexpectedChunk(chunk)

                        default:
                            break
                    }
                    
                    // record unrecognized ancillary chunks 
                    switch chunk 
                    {
                        case .core:
                            break 
                        case .unique(let unique):
                            ancillaries.unique[unique] = contents 
                        case .repeatable(let repeatable):
                            ancillaries.repeatable.append((repeatable, contents))
                    }
                    
                    (chunk, contents) = try _next()

                    // make sure certain chunks don’t duplicate
                    let index:Int
                    switch chunk
                    {
                        case .core(.header):
                            index = 0
                        case .core(.palette):
                            index = 1
                        case .core(.end):
                            index = 2
                        case .unique(.chromaticity):
                            index = 3
                        case .unique(.gamma):
                            index = 4
                        case .unique(.profile):
                            index = 5
                        case .unique(.significantBits):
                            index = 6
                        case .unique(.srgb):
                            index = 7
                        case .unique(.background):
                            index = 8
                        case .unique(.histogram):
                            index = 9
                        case .core(.transparency):
                            index = 10
                        case .unique(.physicalDimensions):
                            index = 11
                        case .unique(.time):
                            index = 12
                        default:
                            continue
                    }

                    guard !seen.testAndSet(index)
                    else
                    {
                        throw DecodingError.duplicateChunk(chunk)
                    }
                }
            }

            /// Compresses and saves this PNG image at the given file path.
            /// 
            /// Excessively small chunk sizes may harm image compression. Higher
            /// compression levels produce smaller PNG files, but take longer to
            /// run.
            /// 
            /// - Parameters:
            ///     - outputPath: A file path.
            ///     - chunkSize: The maximum IDAT chunk size to use. The default
            ///         is 65536 bytes.
            ///     - level: The level of LZ77 compression to use. Must be in the
            ///         range `0 ... 9`, where 0 is no compression, and 9 is maximal
            ///         compression.
            /// - Returns: `nil` if the given file could not be opened.
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

            /// Decompresses a PNG file at the given file path, and returns it as 
            /// an `Uncompressed` image.
            /// 
            /// - Parameters:
            ///     - inputPath: A path to a PNG file.
            /// - Returns: An uncompressed PNG image, or `nil` if the given file
            ///     could not be opened.
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
            
            /// Converts the given indexed-representation RGBA image to the specified 
            /// target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - indices: An array of indices into the given `palette`, representing 
            ///         an image. No index may be greater than `palette.count`.
            ///     - palette: A palette of RGBA colors. 
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `indices.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `indices` array is the 
            ///         wrong size.
            ///     - ConversionError.indexOutOfRange: if a pixel index references 
            ///         a nonexistent palette entry.
            ///     - ConversionError.paletteOverflow: if the provided `palette` 
            ///         contains too many entries to be encoded in a specified 
            ///         indexing format.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public static
            func convert<Component>(indices:[Int], palette:[RGBA<Component>], 
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed 
                where Component:FixedWidthInteger & UnsignedInteger
            {
                // make sure pixel array is correct size
                guard indices.count == size.x * size.y
                else 
                {
                    throw ConversionError.pixelCount
                }
                
                guard indices.max() ?? 0 <= palette.count 
                else 
                {
                    throw ConversionError.indexOutOfRange
                }

                if code.isIndexed 
                {
                    let properties:Properties, 
                        data:[UInt8]
                    
                    guard palette.count <= 1 << code.depth
                    else
                    {
                        throw ConversionError.paletteOverflow
                    }
                    
                    let iu8:[UInt8]      = indices.map(UInt8.init(truncatingIfNeeded:)), 
                        p8:[RGBA<UInt8>] = palette.map{ downscale($0, to: UInt8.self) }
                    
                    switch code
                    {
                        case .indexed1:
                            properties  = .init(size: size, format: .indexed1(p8))
                            data        = compact(iu8, size: size, code: code)
                        case .indexed2:
                            properties  = .init(size: size, format: .indexed2(p8))
                            data        = compact(iu8, size: size, code: code)
                        case .indexed4:
                            properties  = .init(size: size, format: .indexed4(p8))
                            data        = compact(iu8, size: size, code: code)
                        case .indexed8:
                            properties  = .init(size: size, format: .indexed8(p8))
                            data        = iu8
                        default:
                            fatalError("unreachable")
                    }
                    
                    return .init(rawData: data, properties: properties, ancillaries: ancillaries)
                }
                else 
                {
                    let image:[RGBA<Component>] = indices.map{ palette[$0] }
                    return try convert(rgba: image, size: size, to: code, 
                        chromaKey: chromaKey, ancillaries: ancillaries)
                }
            }
            
            /// Converts the given grayscale image to the specified target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - v: An array of grayscale pixel values, representing 
            ///         an image.
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `v.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `v` array is the wrong
            ///         size.
            ///     - ConversionError.paletteOverflow: if the provided image contains
            ///         too many distinct colors to be encoded in a specified 
            ///         indexing format.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public static
            func convert<Component>(v:[Component],
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed
                where Component:FixedWidthInteger & UnsignedInteger
            {
                // make sure pixel array is correct size
                guard v.count == size.x * size.y
                else 
                {
                    throw ConversionError.pixelCount
                }
                
                let properties:Properties
                var data:[UInt8]

                let shift:Int = Component.bitWidth - code.depth
                switch code
                {
                    case .v1:
                        properties = .init(size: size, format: .v1, chromaKey: chromaKey)
                        data  = compact(v.map{ .init(truncatingIfNeeded: $0 &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v2:
                        properties = .init(size: size, format: .v2, chromaKey: chromaKey)
                        data  = compact(v.map{ .init(truncatingIfNeeded: $0 &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v4:
                        properties = .init(size: size, format: .v4, chromaKey: chromaKey)
                        data  = compact(v.map{ .init(truncatingIfNeeded: $0 &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v8:
                        properties = .init(size: size, format: .v8, chromaKey: chromaKey)
                        data = v.map{ .init(truncatingIfNeeded: $0 &>> shift) }

                    case .v16:
                        properties = .init(size: size, format: .v16, chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:UInt16 = rescale(pixel, to: UInt16.self)
                            data.append(bigEndian: s)
                        }

                    case .va8:
                        properties = .init(size: size, format: .va8)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:VA<UInt8> = .init(downscale(pixel, to: UInt8.self))
                            data.append(s.v)
                            data.append(s.a)
                        }

                    case .va16:
                        properties = .init(size: size, format: .va16)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:VA<UInt16> = .init(rescale(pixel, to: UInt16.self))
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.a)
                        }

                    case .rgb8:
                        properties = .init(size: size, format: .rgb8(nil), chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:UInt8 = downscale(pixel, to: UInt8.self)
                            data.append(s)
                            data.append(s)
                            data.append(s)
                        }

                    case .rgb16:
                        properties = .init(size: size, format: .rgb16(nil), chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:UInt16 = rescale(pixel, to: UInt16.self)
                            data.append(bigEndian: s)
                            data.append(bigEndian: s)
                            data.append(bigEndian: s)
                        }

                    case .rgba8:
                        properties = .init(size: size, format: .rgba8(nil))
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:VA<UInt8> = .init(downscale(pixel, to: UInt8.self))
                            data.append(s.v)
                            data.append(s.v)
                            data.append(s.v)
                            data.append(s.a)
                        }

                    case .rgba16:
                        properties = .init(size: size, format: .rgba16(nil))
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:Component in v
                        {
                            let s:VA<UInt16> = .init(rescale(pixel, to: UInt16.self))
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.a)
                        }

                    case .indexed8, .indexed4, .indexed2, .indexed1:
                        guard let (indexed, palette):([UInt8], [RGBA<UInt8>]) =
                            (v.map{ .init(downscale($0, to: UInt8.self)) }.indexPalette()),
                            palette.count <= 1 << code.depth
                        else
                        {
                            throw ConversionError.paletteOverflow
                        }
                        
                        switch code
                        {
                            case .indexed1:
                                properties  = .init(size: size, format: .indexed1(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed2:
                                properties  = .init(size: size, format: .indexed2(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed4:
                                properties  = .init(size: size, format: .indexed4(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed8:
                                properties  = .init(size: size, format: .indexed8(palette))
                                data        = indexed
                            default:
                                fatalError("unreachable")
                        }
                }
                
                return .init(rawData: data, properties: properties, ancillaries: ancillaries)
            }
            
            /// Converts the given grayscale–alpha image to the specified target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - va: An array of grayscale–alpha pixel values, representing 
            ///         an image.
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `va.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `va` array is the wrong
            ///         size.
            ///     - ConversionError.paletteOverflow: if the provided image contains
            ///         too many distinct colors to be encoded in a specified 
            ///         indexing format.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public static
            func convert<Component>(va:[VA<Component>],
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed
                where Component:FixedWidthInteger & UnsignedInteger
            {
                // make sure pixel array is correct size
                guard va.count == size.x * size.y
                else 
                {
                    throw ConversionError.pixelCount
                }
                
                let properties:Properties
                var data:[UInt8]

                let shift:Int = Component.bitWidth - code.depth
                switch code
                {
                    case .v1:
                        properties = .init(size: size, format: .v1, chromaKey: chromaKey)
                        data  = compact(va.map{ .init(truncatingIfNeeded: $0.v &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v2:
                        properties = .init(size: size, format: .v2, chromaKey: chromaKey)
                        data  = compact(va.map{ .init(truncatingIfNeeded: $0.v &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v4:
                        properties = .init(size: size, format: .v4, chromaKey: chromaKey)
                        data  = compact(va.map{ .init(truncatingIfNeeded: $0.v &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v8:
                        properties = .init(size: size, format: .v8, chromaKey: chromaKey)
                        data = va.map{ .init(truncatingIfNeeded: $0.v &>> shift) }

                    case .v16:
                        properties = .init(size: size, format: .v16, chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:UInt16 = rescale(pixel.v, to: UInt16.self)
                            data.append(bigEndian: s)
                        }

                    case .va8:
                        properties = .init(size: size, format: .va8)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:VA<UInt8> = downscale(pixel, to: UInt8.self)
                            data.append(s.v)
                            data.append(s.a)
                        }

                    case .va16:
                        properties = .init(size: size, format: .va16)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:VA<UInt16> = rescale(pixel, to: UInt16.self)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.a)
                        }

                    case .rgb8:
                        properties = .init(size: size, format: .rgb8(nil), chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:UInt8 = downscale(pixel.v, to: UInt8.self)
                            data.append(s)
                            data.append(s)
                            data.append(s)
                        }

                    case .rgb16:
                        properties = .init(size: size, format: .rgb16(nil), chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:UInt16 = rescale(pixel.v, to: UInt16.self)
                            data.append(bigEndian: s)
                            data.append(bigEndian: s)
                            data.append(bigEndian: s)
                        }

                    case .rgba8:
                        properties = .init(size: size, format: .rgba8(nil))
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:VA<UInt8> = downscale(pixel, to: UInt8.self)
                            data.append(s.v)
                            data.append(s.v)
                            data.append(s.v)
                            data.append(s.a)
                        }

                    case .rgba16:
                        properties = .init(size: size, format: .rgba16(nil))
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:VA<Component> in va
                        {
                            let s:VA<UInt16> = rescale(pixel, to: UInt16.self)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.a)
                        }

                    case .indexed8, .indexed4, .indexed2, .indexed1:
                        guard let (indexed, palette):([UInt8], [RGBA<UInt8>]) =
                            (va.map{ .init(downscale($0, to: UInt8.self)) }.indexPalette()),
                            palette.count <= 1 << code.depth
                        else
                        {
                            throw ConversionError.paletteOverflow
                        }
                        
                        switch code
                        {
                            case .indexed1:
                                properties  = .init(size: size, format: .indexed1(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed2:
                                properties  = .init(size: size, format: .indexed2(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed4:
                                properties  = .init(size: size, format: .indexed4(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed8:
                                properties  = .init(size: size, format: .indexed8(palette))
                                data        = indexed
                            default:
                                fatalError("unreachable")
                        }
                }
                
                return .init(rawData: data, properties: properties, ancillaries: ancillaries)
            }
            
            /// Converts the given RGBA image to the specified target format.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - rgba: An array of RGBA pixel values, representing an image.
            ///     - size: The size of the given image. The value `size.x * size.y` 
            ///         must be the same as `rgba.count`.
            ///     - code: The color format to convert the input image to. All 
            ///         cases are valid, but some may result in data narrowing.
            ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
            ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
            ///         by default.
            ///
            /// - Returns: An `Uncompressed` image of the given color format.
            /// 
            /// - Throws: 
            ///     - ConversionError.pixelCount: if the `rgba` array is the wrong
            ///         size.
            ///     - ConversionError.paletteOverflow: if the provided image contains
            ///         too many distinct colors to be encoded in a specified 
            ///         indexing format.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public static
            func convert<Component>(rgba:[RGBA<Component>],
                size:(x:Int, y:Int), to code:Properties.Format.Code, 
                chromaKey:RGBA<UInt16>? = nil, ancillaries:Ancillaries = ([:], []))
                throws -> Uncompressed
                where Component:FixedWidthInteger & UnsignedInteger
            {
                // make sure pixel array is correct size
                guard rgba.count == size.x * size.y
                else 
                {
                    throw ConversionError.pixelCount
                }
                
                let properties:Properties
                var data:[UInt8]

                let shift:Int = Component.bitWidth - code.depth
                switch code
                {
                    case .v1:
                        properties = .init(size: size, format: .v1, chromaKey: chromaKey)
                        data  = compact(rgba.map{ .init(truncatingIfNeeded: $0.r &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v2:
                        properties = .init(size: size, format: .v2, chromaKey: chromaKey)
                        data  = compact(rgba.map{ .init(truncatingIfNeeded: $0.r &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v4:
                        properties = .init(size: size, format: .v4, chromaKey: chromaKey)
                        data  = compact(rgba.map{ .init(truncatingIfNeeded: $0.r &>> shift) },
                                        size: size,
                                        code: code
                                        )
                    case .v8:
                        properties = .init(size: size, format: .v8, chromaKey: chromaKey)
                        data = rgba.map{ .init(truncatingIfNeeded: $0.r &>> shift) }

                    case .v16:
                        properties = .init(size: size, format: .v16, chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let s:UInt16 = rescale(pixel.r, to: UInt16.self)
                            data.append(bigEndian: s)
                        }

                    case .va8:
                        properties = .init(size: size, format: .va8)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let s:VA<UInt8> = downscale(pixel.va, to: UInt8.self)
                            data.append(s.v)
                            data.append(s.a)
                        }

                    case .va16:
                        properties = .init(size: size, format: .va16)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let s:VA<UInt16> = rescale(pixel.va, to: UInt16.self)
                            data.append(bigEndian: s.v)
                            data.append(bigEndian: s.a)
                        }

                    case .rgb8:
                        properties = .init(size: size, format: .rgb8(nil), chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let s:RGBA<UInt8> = downscale(pixel, to: UInt8.self)
                            data.append(s.r)
                            data.append(s.g)
                            data.append(s.b)
                        }

                    case .rgb16:
                        properties = .init(size: size, format: .rgb16(nil), chromaKey: chromaKey)
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let scaled:RGBA<UInt16> = rescale(pixel, to: UInt16.self)
                            data.append(bigEndian: scaled.r)
                            data.append(bigEndian: scaled.g)
                            data.append(bigEndian: scaled.b)
                        }

                    case .rgba8:
                        properties = .init(size: size, format: .rgba8(nil))
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let scaled:RGBA<UInt8> = downscale(pixel, to: UInt8.self)
                            data.append(scaled.r)
                            data.append(scaled.g)
                            data.append(scaled.b)
                            data.append(scaled.a)
                        }

                    case .rgba16:
                        properties = .init(size: size, format: .rgba16(nil))
                        data = []
                        data.reserveCapacity(properties.byteCount)
                        for pixel:RGBA<Component> in rgba
                        {
                            let scaled:RGBA<UInt16> = rescale(pixel, to: UInt16.self)
                            data.append(bigEndian: scaled.r)
                            data.append(bigEndian: scaled.g)
                            data.append(bigEndian: scaled.b)
                            data.append(bigEndian: scaled.a)
                        }

                    case .indexed8, .indexed4, .indexed2, .indexed1:
                        guard let (indexed, palette):([UInt8], [RGBA<UInt8>]) =
                            (rgba.map{ downscale($0, to: UInt8.self) }.indexPalette()),
                            palette.count <= 1 << code.depth
                        else
                        {
                            throw ConversionError.paletteOverflow
                        }

                        switch code
                        {
                            case .indexed1:
                                properties  = .init(size: size, format: .indexed1(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed2:
                                properties  = .init(size: size, format: .indexed2(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed4:
                                properties  = .init(size: size, format: .indexed4(palette))
                                data        = compact(indexed, size: size, code: code)
                            case .indexed8:
                                properties  = .init(size: size, format: .indexed8(palette))
                                data        = indexed
                            default:
                                fatalError("unreachable")
                        }
                }

                return .init(rawData: data, properties: properties, ancillaries: ancillaries)
            }

            private static
            func compact(_ scalars:[UInt8], size:(x:Int, y:Int), code:Properties.Format.Code)
                -> [UInt8]
            {
                let shape:Data.Shape = code.shape(from: size)
                var opaque:[UInt8]   = []
                    opaque.reserveCapacity(shape.byteCount)

                let population:Int = 8 / code.depth,
                    extras:Int     = size.x % population

                for base:Int in stride(from: scalars.startIndex,
                                        to:  scalars.endIndex,
                                        by:  size.x)
                {
                    for group:Int in stride(from: base,
                                            to: base + size.x - extras,
                                            by: population)
                    {
                        var byte:UInt8 = 0
                        for scalar in scalars[group ..< group + population]
                        {
                            byte = byte &<< code.depth | scalar
                        }
                        opaque.append(byte)
                    }

                    if extras > 0
                    {
                        var byte:UInt8 = 0
                        for scalar in scalars[base + size.x - extras ..< base + size.x]
                        {
                            byte = byte &<< code.depth | scalar
                        }

                        opaque.append(byte << (code.depth * (population - extras)))
                    }
                }

                return opaque
            }
        }

        /// A PNG image that has been deinterlaced, but may still have multiple
        /// pixels packed per byte, or indirect (indexed) pixels.
        public
        struct Rectangular
        {
            /// The global image `Properties` of this PNG image.
            public
            let properties:Properties
            
            /// A rectangular row-major matrix containing this PNG’s pixel data.
            /// This buffer is untyped, and each byte may contain multiple, or
            /// fractional, pixels. Logical image scanlines are padded to a whole
            /// number of bytes.
            public
            let data:[UInt8]
            
            /// Additional chunks not parsed by the library.
            public 
            let ancillaries:Ancillaries 

            /// Creates a fully decoded PNG image with the given pixel matrix and
            /// `Properties` record.
            /// 
            /// - Parameters:
            ///     - data: An untyped, padded data buffer containing a row-major
            ///         pixel matrix.
            ///     - properties: A `Properties` record.
            ///     - ancillaries: Additional chunks to include in the image. Empty 
            ///         by default.
            /// - Returns: A fully decoded PNG image. The size of the given pixel
            ///     matrix must be consistent with the size and format information
            ///     in the given image `properties`.
            public 
            init(rawData data:[UInt8], properties:Properties, ancillaries:Ancillaries = ([:], []))
            {
                guard !properties.interlaced
                else
                {
                    fatalError("can’t make Rectangular image with interlacing, use Uncompressed type instead")
                }
                guard data.count == properties.byteCount
                else
                {
                    fatalError("rawData array count doesn’t match dimensions given by properties parameter")
                }

                self.properties     = properties
                self.data           = data
                self.ancillaries    = ancillaries
            }

            /// Decompresses and deinterlaces a PNG file at the given file path,
            /// and returns it as a `Rectangular` row-major pixel matrix.
            /// 
            /// If the PNG file is not interlaced, no deinterlacing is performed.
            /// 
            /// - Parameters:
            ///     - inputPath: A path to a PNG file.
            /// - Returns: A rectangular row-major pixel matrix, or `nil` if the
            ///     given file could not be opened.
            public static
            func decompress(path inputPath:String) throws -> Rectangular
            {
                return try Uncompressed.decompress(path: inputPath).deinterlaced()
            }

            /// Checks if the given integer type has enough bits to represent the
            /// channels of this image.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: `true` if `Sample` has enough bits to represent the channels
            ///     of this image, `false` otherwise.
            @inline(__always)
            private
            func checkWidth<Sample>(of type:Sample.Type) -> Bool
                where Sample:FixedWidthInteger
            {
                return Sample.bitWidth >= self.properties.format.code.depth
            }

            /// Calls the given closure on each single-channel pixel in this PNG 
            /// image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly one channel, or `Sample` does not have enough bits to represent
            /// its channel. The samples passed to the closure are raw, unnormalized
            /// scalars, cast to the inferred integer type.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt`, and `Int`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes one channel of one pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image has more than one channel, or `Sample`
            ///     does not have enough bits to represent its channel.
            @_specialize(exported: true, kind: partial, where Sample == UInt8)
            @_specialize(exported: true, kind: partial, where Sample == UInt16)
            @_specialize(exported: true, kind: partial, where Sample == UInt32)
            @_specialize(exported: true, kind: partial, where Sample == UInt64)
            @_specialize(exported: true, kind: partial, where Sample == UInt)
            @_specialize(exported: true, kind: partial, where Sample ==  Int)
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

            /// Calls the given closure on the normalized intensity of each
            /// single-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly one channel. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes one normalized channel of one pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image has more than one channel.
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

            /// Calls the given closure on the normalized intensity of each
            /// two-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly two channels. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes two normalized channels of one pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image does not have exactly two channels.
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

            /// Calls the given closure on the normalized intensity of each
            /// three-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this PNG image does not have
            /// exactly three channels. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes three normalized channels of one
            ///         pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image does not have exactly three channels.
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

            /// Calls the given closure on the normalized intensity of each
            /// four-channel pixel in this PNG image.
            /// 
            /// The given closure is not called if this image does not have
            /// exactly four channels. The samples passed to the closure are normalized
            /// values in the range `0 ... Sample.max`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - body: A closure that takes four normalized channels of one
            ///         pixel.
            /// 
            /// - Returns: An array of the return values of the given closure, or
            ///     `nil`, if this PNG image does not have exactly four channels.
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

            /// Returns a row-major matrix of the first components of all the pixels
            /// in this PNG image, normalized to the range of the given component type.
            /// 
            /// If this image has more than one component per pixel, the first
            /// component of each pixel is returned. If this image has indexed color,
            /// the components returned are the first components of the RGB palette
            /// colors of those pixels. This method ignores the transparency and
            /// chroma keys of this image.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
            /// `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of pixel values, normalized to its
            ///     `Component` type, or `nil` if this image requires a palette, and
            ///     it does not have one.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public
            func v<Component>(of type:Component.Type) -> [Component]
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

                    case    .indexed1(let palette),
                            .indexed2(let palette),
                            .indexed4(let palette):
                        // map over raw sample values instead of scaled values
                        return self.mapBits
                        {
                            (index:Int) in

                            // palette component type is always UInt8 so all Swift
                            // unsigned integer types can be used as an unscaling
                            // target
                            return upscale(palette[index].r, to: Component.self)
                        }

                    case    .indexed8(let palette):
                        // same as above except loading byte-size samples
                        return self.map(from: UInt8.self)
                        {
                            (index:Int) in

                            return upscale(palette[index].r, to: Component.self)
                        }
                }
            }

            /// Returns the given color with its alpha component set to 0 if its
            /// color value matches this PNG image’s chroma key, and the given color
            /// unchanged otherwise.
            /// 
            /// - Parameters:
            ///     - color: An RGBA color to test.
            /// - Returns: The given color, with its alpha component set to 0 if its
            ///         color value matches this PNG image’s chroma key.
            @inline(__always)
            private
            func greenscreen<Component>(_ color:RGBA<Component>) -> RGBA<Component>
            {
                // hope this gets inlined
                guard let key:RGBA<Component> = Component.bitWidth > 16 ?
                    (self.properties.chromaKey.map{ upscale(  $0, to: Component.self) }) :
                    (self.properties.chromaKey.map{ downscale($0, to: Component.self) })
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

            /// Returns the given color as a grayscale-alpha color with its alpha
            /// component set to 0 if its RGB color value matches this PNG image’s
            /// chroma key, and `Component.max` otherwise.
            /// 
            /// - Parameters:
            ///     - color: A grayscale-alpha color to test.
            /// - Returns: The given color, with its alpha component set to 0 if its
            ///         color value matches this PNG image’s chroma key.
            @inline(__always)
            private
            func greenscreen<Component>(_ color:RGBA<Component>) -> VA<Component>
            {
                // hope this gets inlined
                guard let key:RGBA<Component> = Component.bitWidth > 16 ?
                    (self.properties.chromaKey.map{ upscale(  $0, to: Component.self) }) :
                    (self.properties.chromaKey.map{ downscale($0, to: Component.self) })
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

            /// Returns a row-major matrix of the grayscale-alpha color values represented
            /// by all the pixels in this PNG image, normalized to the range of
            /// the given component type.
            /// 
            /// If this image has grayscale color, the grayscale-alpha colors returned
            /// share the value component, and have `Component.max` in the alpha
            /// component. If this image has RGB color, the grayscale-alpha colors
            /// have the red component in the value component, and have `Component.max`
            /// in the alpha component. If this image has RGBA color, the grayscale-alpha
            /// colors share the alpha component in addition.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
            /// `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of grayscale-alpha pixel colors, normalized
            ///     to the given `Component` type, or `nil` if this image requires
            ///     a palette, and it does not have one.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public
            func va<Component>(of type:Component.Type) -> [VA<Component>]
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

                    case    .indexed1(let palette),
                            .indexed2(let palette),
                            .indexed4(let palette):

                        // map over raw sample values instead of scaled values
                        return self.mapBits
                        {
                            (index:Int) in
                            return upscale(palette[index].va, to: Component.self)
                        }

                    case    .indexed8(let palette):
                        return self.map(from: UInt8.self)
                        {
                            (index:Int) in

                            return upscale(palette[index].va, to: Component.self)
                        }
                }
            }

            /// Returns a row-major matrix of the RGBA color values represented
            /// by all the pixels in this PNG image, normalized to the range of
            /// the given component type.
            /// 
            /// If this image has grayscale color, the RGBA colors returned have
            /// the value component in the red, green, and blue components, and
            /// `Component.max` in the alpha component. If this image has grayscale-alpha
            /// color, the RGBA colors returned share the alpha component in addition.
            /// If this image has RGB color, the RGBA colors share the red, green,
            /// and blue components, and have `Component.max` in the alpha component.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8`, `UInt16`, `UInt32`,
            /// `UInt64`, and `UInt`.
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of RGBA pixel colors, normalized to
            ///     the given `Component` type, or `nil` if this image requires
            ///     a palette, and it does not have one.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            @_specialize(exported: true, where Component == UInt32)
            @_specialize(exported: true, where Component == UInt64)
            @_specialize(exported: true, where Component == UInt)
            public
            func rgba<Component>(of type:Component.Type) -> [RGBA<Component>]
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

                    case    .indexed1(let palette),
                            .indexed2(let palette),
                            .indexed4(let palette):
                        // map over raw sample values instead of scaled values
                        return self.mapBits
                        {
                            (index:Int) in

                            // palette component type is always UInt8 so all Swift
                            // unsigned integer types can be used as an unscaling
                            // target
                            return upscale(palette[index], to: Component.self)
                        }

                    case    .indexed8(let palette):
                        // same as above except loading byte-size samples
                        return self.map(from: UInt8.self)
                        {
                            (index:Int) in

                            return upscale(palette[index], to: Component.self)
                        }
                }
            }

            /// Returns a row-major matrix of the RGBA color values represented
            /// by all the pixels in this PNG image, normalized to the range of
            /// the given component type and encoded as integer slugs containing
            /// four components in ARGB order. The alpha components are premultiplied
            /// into the colors.
            /// 
            /// If this image has grayscale color, the RGBA colors returned have
            /// the value component in the red, green, and blue components, and
            /// `Component.max` in the alpha component. If this image has grayscale-alpha
            /// color, the RGBA colors returned share the alpha component in addition.
            /// If this image has RGB color, the RGBA colors share the red, green,
            /// and blue components, and have `Component.max` in the alpha component.
            /// The RGBA colors are packed into four-component integer slugs of a
            /// type large enough to hold four instances of the given type, if one
            /// exists. The color components are packed in ARGB order, with alpha
            /// in the high bits.
            /// 
            /// Allowed `Component` types by default are `UInt8`, and `UInt16`.
            /// Custom `Component` types can be used by conforming them to the
            /// `FusedVector4Element` protocol and supplying the `FusedVector4`
            /// associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
            /// 
            /// To avoid information loss, you may want to check if this image’s
            /// component type has too many bits to be represented by the destination
            /// component type. This method should not be called using an integer
            /// type less than 8 bits wide.
            /// 
            /// *Specialized* for `Component` types `UInt8` and `UInt16`.
            /// (`Component.FusedVector4` types `UInt32` and `UInt64`.)
            /// 
            /// - Parameters:
            ///     - type: An integer type.
            /// - Returns: A row-major matrix of RGBA pixel colors, normalized to
            ///     the given `Component` type, and encoded as four-component integer
            ///     slugs, or `nil` if this image requires a palette, and
            ///     it does not have one.
            @_specialize(exported: true, where Component == UInt8)
            @_specialize(exported: true, where Component == UInt16)
            public
            func argbPremultiplied<Component>(of type:Component.Type)
                -> [Component.FusedVector4] where Component:FusedVector4Element
            {
                // *all* color formats can produce pixels with alpha, so we might
                // as well call the `rgba(of:)` function and let map fusion
                // optimize it
                return self.rgba(of: Component.self).map
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
                return rescale(self.load(bigEndian: T.self, at: index, as: T.self), to: Sample.self)
            }

            private
            func mapBits<Sample, Result>(_ body:(Sample) -> Result) -> [Result]
                where Sample:FixedWidthInteger
            {
                assert(self.properties.format.code.depth < Sample.bitWidth)

                return withoutActuallyEscaping(body)
                {
                    (body:@escaping (Sample) -> Result) in

                    let depth:Int = self.properties.format.code.depth,
                        count:Int = self.properties.format.code.volume * self.properties.shape.size.x
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
                assert(self.properties.format.code.depth == Atom.bitWidth)

                return (0 ..< self.properties.shape.count).map
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
                    return body($0 * quantum(depth: self.properties.format.code.depth))
                }
            }

            private
            func mapIntensity<Atom, Sample, Result>(from _:Atom.Type,
                                                    _ body:(Sample) -> Result) -> [Result]
                 where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                assert(self.properties.format.code.depth == Atom.bitWidth)

                return (0 ..< self.properties.shape.count).map
                {
                    return body(self.scale(bigEndian: Atom.self, at: $0, to: Sample.self))
                }
            }

            private
            func mapIntensity<Atom, Sample, Result>(from _:Atom.Type,
                                                    _ body:(Sample, Sample) -> Result) -> [Result]
                 where Atom:FixedWidthInteger & UnsignedInteger, Sample:FixedWidthInteger & UnsignedInteger
            {
                assert(self.properties.format.code.depth == Atom.bitWidth)

                return (0 ..< self.properties.shape.count).map
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
                assert(self.properties.format.code.depth == Atom.bitWidth)

                return (0 ..< self.properties.shape.count).map
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
                assert(self.properties.format.code.depth == Atom.bitWidth)

                return (0 ..< self.properties.shape.count).map
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
                self.pitch * self.size.y
            }
            
            var count:Int 
            {
                self.size.x * self.size.y
            }
        }
    }

    // single stage functions

    /// Returns a row-major matrix of the first components of all the pixels
    /// in this PNG file, normalized to the range of the given component type.
    /// 
    /// If this image has more than one component per pixel, the first
    /// component of each pixel is returned. If this image has indexed color,
    /// the components returned are the first components of the RGB palette
    /// colors of those pixels. This method ignores the transparency and
    /// chroma keys of this image.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and the logical pixel dimensions of the matrix.
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

        return (image.v(of: Component.self), image.properties.size)
    }

    /// Returns a row-major matrix of the grayscale-alpha color values represented
    /// by all the pixels in this PNG file, normalized to the range of
    /// the given component type.
    /// 
    /// If this image has grayscale color, the grayscale-alpha colors returned
    /// share the value component, and have `Component.max` in the alpha
    /// component. If this image has RGB color, the grayscale-alpha colors
    /// have the red component in the value component, and have `Component.max`
    /// in the alpha component. If this image has RGBA color, the grayscale-alpha
    /// colors share the alpha component in addition.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and the logical pixel dimensions of the matrix.
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

        return (image.va(of: Component.self), image.properties.size)
    }

    /// Returns a row-major matrix of the RGBA color values represented
    /// by all the pixels in this PNG file, normalized to the range of
    /// the given component type.
    /// 
    /// If this image has grayscale color, the RGBA colors returned have
    /// the value component in the red, green, and blue components, and
    /// `Component.max` in the alpha component. If this image has grayscale-alpha
    /// color, the RGBA colors returned share the alpha component in addition.
    /// If this image has RGB color, the RGBA colors share the red, green,
    /// and blue components, and have `Component.max` in the alpha component.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and the logical pixel dimensions of the matrix.
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

        return (image.rgba(of: Component.self), image.properties.size)
    }

    /// Returns a row-major matrix of the RGBA color values represented
    /// by all the pixels in this PNG file, normalized to the range of
    /// the given component type and encoded as integer slugs containing
    /// four components in ARGB order. The alpha components are premultiplied
    /// into the colors.
    /// 
    /// If this image has grayscale color, the RGBA colors returned have
    /// the value component in the red, green, and blue components, and
    /// `Component.max` in the alpha component. If this image has grayscale-alpha
    /// color, the RGBA colors returned share the alpha component in addition.
    /// If this image has RGB color, the RGBA colors share the red, green,
    /// and blue components, and have `Component.max` in the alpha component.
    /// The RGBA colors are packed into four-component integer slugs of a
    /// type large enough to hold four instances of the given type, if one
    /// exists. The color components are packed in ARGB order, with alpha
    /// in the high bits.
    /// 
    /// Allowed `Component` types by default are `UInt8`, and `UInt16`.
    /// Custom `Component` types can be used by conforming them to the
    /// `FusedVector4Element` protocol and supplying the `FusedVector4`
    /// associatedtype. This type must satisfy `Self.bitWidth == Component.bitWidth << 2`.
    /// 
    /// To avoid information loss, you may want to check if this image’s
    /// component type has too many bits to be represented by the destination
    /// component type. This method should not be called using an integer
    /// type less than 8 bits wide.
    /// 
    /// - Parameters:
    ///     - path: A path to a PNG file.
    ///     - type: An integer type.
    /// - Returns: A tuple containing a row-major matrix of pixel components, normalized
    ///     to its `Component` type, and encoded as four-component integer slugs,
    ///     and the logical pixel dimensions of the matrix.
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

        return (image.argbPremultiplied(of: Component.self), image.properties.size)
    }

    static
    func encode<Component, Destination>(indices:[Int], palette:[RGBA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        destination:inout Destination, level:Int) throws
        where Component:FixedWidthInteger & UnsignedInteger, Destination:DataDestination
    {
        let uncompressed:Data.Uncompressed = 
            try .convert(indices: indices, palette: palette, size: size, to: code, chromaKey: chromaKey)
        try uncompressed.compress(to: &destination, level: level)
    }
    
    static
    func encode<Component, Destination>(v:[Component], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        destination:inout Destination, level:Int) throws
        where Component:FixedWidthInteger & UnsignedInteger, Destination:DataDestination
    {
        let uncompressed:Data.Uncompressed = 
            try .convert(v: v, size: size, to: code, chromaKey: chromaKey)
        try uncompressed.compress(to: &destination, level: level)
    }

    static
    func encode<Component, Destination>(va:[VA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        destination:inout Destination, level:Int) throws
        where Component:FixedWidthInteger & UnsignedInteger, Destination:DataDestination
    {
        let uncompressed:Data.Uncompressed = 
            try .convert(va: va, size: size, to: code, chromaKey: chromaKey)
        try uncompressed.compress(to: &destination, level: level)
    }

    static
    func encode<Component, Destination>(rgba:[RGBA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        destination:inout Destination, level:Int) throws
        where Component:FixedWidthInteger & UnsignedInteger, Destination:DataDestination
    {
        // we used to have a fast-path for RGBA<UInt8>, but the fast path turned out 
        // to be slower than the unified path
        let uncompressed:PNG.Data.Uncompressed = 
            try .convert(rgba: rgba, size: size, to: code, chromaKey: chromaKey)
        try uncompressed.compress(to: &destination, level: level)
    }
    
    /// Encodes the given indexed-representation RGBA image in the specified 
    /// target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - indices: An array of indices into the given `palette`, representing 
    ///         an image. No index may be greater than `palette.count`.
    ///     - palette: A palette of RGBA colors. 
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `indices.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    ///
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `indices` array is the 
    ///         wrong size.
    ///     - ConversionError.indexOutOfRange: if a pixel index references 
    ///         a nonexistent palette entry.
    ///     - ConversionError.paletteOverflow: if the provided `palette` 
    ///         contains too many entries to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public static
    func encode<Component>(indices:[Int], palette:[RGBA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let _:Void =
        (
            try File.Destination.open(path: outputPath)
            {
                try encode(  indices: indices, 
                             palette: palette, 
                                size: size,
                                  as: code,
                           chromaKey: chromaKey,
                         destination: &$0,
                               level: level)
            }
        )
        else
        {
            throw File.Error.couldNotOpen
        }
    }
    
    /// Encodes the given grayscale image in the specified target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - v: An array of grayscale pixel values, representing 
    ///         an image.
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `v.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    /// 
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `v` array is the wrong
    ///         size.
    ///     - ConversionError.paletteOverflow: if the provided image contains
    ///         too many distinct colors to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public static
    func encode<Component>(v:[Component], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let _:Void =
        (
            try File.Destination.open(path: outputPath)
            {
                try encode(v: v,
                        size: size,
                          as: code,
                   chromaKey: chromaKey,
                 destination: &$0,
                       level: level)
            }
        )
        else
        {
            throw File.Error.couldNotOpen
        }
    }
    
    /// Converts the given grayscale–alpha image to the specified target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - va: An array of grayscale–alpha pixel values, representing 
    ///         an image.
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `va.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    /// 
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `va` array is the wrong
    ///         size.
    ///     - ConversionError.paletteOverflow: if the provided image contains
    ///         too many distinct colors to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public static
    func encode<Component>(va:[VA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let _:Void =
        (
            try File.Destination.open(path: outputPath)
            {
                try encode(   va: va,
                            size: size,
                              as: code,
                       chromaKey: chromaKey,
                     destination: &$0,
                           level: level)
            }
        )
        else
        {
            throw File.Error.couldNotOpen
        }
    }
    
    /// Converts the given RGBA image to the specified target format.
    /// 
    /// *Specialized* for `Sample` types `UInt8`, `UInt16`, `UInt32`, `UInt64`, and `UInt`.
    /// 
    /// - Parameters:
    ///     - rgba: An array of RGBA pixel values, representing an image.
    ///     - size: The size of the given image. The value `size.x * size.y` 
    ///         must be the same as `rgba.count`.
    ///     - code: The color format to convert the input image to. All 
    ///         cases are valid, but some may result in data narrowing.
    ///     - chromaKey: A chroma key, or `nil`. The default is `nil`. 
    ///     - path: A file path to write the encoded PNG file to.
    ///     - ancillaries: Extra PNG chunks to include in the image. Empty 
    ///         by default.
    /// 
    /// - Throws: 
    ///     - ConversionError.pixelCount: if the `rgba` array is the wrong
    ///         size.
    ///     - ConversionError.paletteOverflow: if the provided image contains
    ///         too many distinct colors to be encoded in a specified 
    ///         indexing format.
    ///     - File.Error.couldNotOpen: if the file at the given `path` could not 
    ///         be found or opened.
    @_specialize(exported: true, where Component == UInt8)
    @_specialize(exported: true, where Component == UInt16)
    @_specialize(exported: true, where Component == UInt32)
    @_specialize(exported: true, where Component == UInt64)
    @_specialize(exported: true, where Component == UInt)
    public static
    func encode<Component>(rgba:[RGBA<Component>], size:(x:Int, y:Int),
        as code:Properties.Format.Code, chromaKey:RGBA<UInt16>? = nil,
        path outputPath:String, level:Int = 9) throws
        where Component:FixedWidthInteger & UnsignedInteger
    {
        guard let _:Void =
        (
            try File.Destination.open(path: outputPath)
            {
                try encode( rgba: rgba,
                            size: size,
                              as: code,
                       chromaKey: chromaKey,
                     destination: &$0,
                           level: level)
            }
        )
        else
        {
            throw File.Error.couldNotOpen
        }
    }
    
    /// A PNG chunk type.
    public 
    enum Chunk 
    {
        /// A PNG chunk type recognized and parsed by the library.
        public 
        enum Core 
        {
            case    header, 
                    palette, 
                    data, 
                    end, 
                    transparency 
            
            var tag:Tag 
            {
                switch self 
                {
                    case .header:
                        return .IHDR 
                    case .palette:
                        return .PLTE 
                    case .data:
                        return .IDAT 
                    case .end:
                        return .IEND 
                    case .transparency:
                        return .tRNS
                }
            }
        }
        
        /// A PNG chunk type not parsed by the library, which can only occur 
        /// once in a PNG file.
        public 
        enum Unique 
        {
            case    chromaticity, 
                    gamma, 
                    profile, 
                    significantBits, 
                    srgb, 
                    background, 
                    histogram, 
                    physicalDimensions, 
                    time 
            
            var tag:Tag 
            {
                switch self 
                {
                    case .chromaticity:
                        return .cHRM
                    case .gamma:
                        return .gAMA
                    case .profile:
                        return .iCCP
                    case .significantBits:
                        return .sBIT
                    case .srgb:
                        return .sRGB
                    case .background:
                        return .bKGD
                    case .histogram:
                        return .hIST
                    case .physicalDimensions:
                        return .pHYs
                    case .time:
                        return .tIME
                }
            }
            
            /// Whether or not this chunk is safe to copy over if image data has 
            /// been modified.
            public 
            var safeToCopy:Bool 
            {
                switch self 
                {
                    case .physicalDimensions: 
                        return true 
                    default:
                        return false
                }
            }
        }
        
        /// A PNG chunk type not parsed by the library, which can occur multiple 
        /// times in a PNG file.
        public 
        enum Repeatable 
        {
            case    suggestedPalette, 
                    textUTF8, 
                    textLatin1, 
                    textLatin1Compressed, 
                    other(Other) 
            
            /// A non-standard private PNG chunk type.
            public 
            struct Other 
            {
                /// This chunk’s tag 
                public 
                let tag:Tag 
                
                /// Creates a private PNG chunk type identifier from the given 
                /// tag bytes. 
                /// 
                /// This initializer will trap if the given bytes do not form 
                /// a valid chunk tag, or if the tag represents a chunk type 
                /// defined by the library. To handle these situations, use the 
                /// `Chunk(_:)` initializer and switch on its enumeration cases 
                /// instead.
                /// 
                /// - Parameters:
                ///     - name: The four bytes of this PNG chunk type’s name.
                public 
                init(_ name:(UInt8, UInt8, UInt8, UInt8)) 
                {
                    guard let tag:Tag = Tag.init(name) 
                    else 
                    {
                        let string:String = .init(decoding: [name.0, name.1, name.2, name.3],
                                                        as: Unicode.ASCII.self)
                        fatalError("'\(string)' is not a valid chunk tag")
                    }
                    
                    switch Chunk.init(tag) 
                    {
                        case .repeatable(.other(let instance)):
                            self = instance 
                        
                        default:
                            fatalError("'\(tag)' is a reserved chunk tag")
                    }
                }
                
                init(_tag tag:Tag) 
                {
                    self.tag = tag
                }
            }
            
            var tag:Tag 
            {
                switch self 
                {
                    case .suggestedPalette:
                        return .sPLT
                    case .textUTF8:
                        return .iTXt
                    case .textLatin1:
                        return .tEXt
                    case .textLatin1Compressed:
                        return .zTXt
                    case .other(let other):
                        return other.tag
                }
            }
            
            /// Whether or not this chunk is safe to copy over if image data has 
            /// been modified.
            public 
            var safeToCopy:Bool 
            {
                switch self 
                {
                    case .textUTF8, .textLatin1, .textLatin1Compressed: 
                        return true 
                    case .other(let other):
                        return other.tag.name.3 & (1 << 5) != 0
                    case .suggestedPalette:
                        return false
                }
            }
        }
        
        case    core(Core), 
                unique(Unique), 
                repeatable(Repeatable)
        
        var tag:Tag 
        {
            switch self 
            {
                case .core(let core):
                    return core.tag 
                case .unique(let unique):
                    return unique.tag 
                case .repeatable(let repeatable):
                    return repeatable.tag
            }
        }
        
        /// Classifies the given chunk tag. 
        /// 
        /// - Parameters:
        ///     - tag: A PNG chunk tag.
        public 
        init(_ tag:Tag) 
        {
            switch tag 
            {
                case .IHDR: 
                    self = .core(.header)
                case .PLTE:
                    self = .core(.palette)
                case .IDAT:
                    self = .core(.data)
                case .IEND:
                    self = .core(.end)
                case .tRNS:
                    self = .core(.transparency)
                
                case .cHRM:
                    self = .unique(.chromaticity)
                case .gAMA:
                    self = .unique(.gamma)
                case .iCCP:
                    self = .unique(.profile)
                case .sBIT:
                    self = .unique(.significantBits)
                case .sRGB:
                    self = .unique(.srgb)
                case .bKGD:
                    self = .unique(.background)
                case .hIST:
                    self = .unique(.histogram)
                case .pHYs:
                    self = .unique(.physicalDimensions)
                case .tIME:
                    self = .unique(.time)
                
                case .sPLT:
                    self = .repeatable(.suggestedPalette)
                case .iTXt:
                    self = .repeatable(.textUTF8)
                case .tEXt:
                    self = .repeatable(.textLatin1)
                case .zTXt:
                    self = .repeatable(.textLatin1Compressed)
                
                default:
                    self = .repeatable(.other(.init(_tag: tag)))
            }
        }
        
        /// A four-byte PNG chunk type identifier.
        public
        struct Tag:Hashable, Equatable, CustomStringConvertible
        {
            /// The four-byte name of this PNG chunk type.
            let name:(UInt8, UInt8, UInt8, UInt8)

            /// A string displaying the ASCII representation of this PNG chunk type’s name.
            public
            var description:String
            {
                .init(decoding: [self.name.0, self.name.1, self.name.2, self.name.3],
                            as: Unicode.ASCII.self)
            }

            private
            init(_ a:UInt8, _ p:UInt8, _ r:UInt8, _ c:UInt8)
            {
                self.name = (a, p, r, c)
            }

            /// Creates the chunk type with the given name bytes, if they are valid.
            /// Returns `nil` if the ancillary bit (in byte 0) is set or the reserved
            /// bit (in byte 2) is set, and the ASCII name is not one of `IHDR`, `PLTE`,
            /// `IDAT`, `IEND`, `cHRM`, `gAMA`, `iCCP`, `sBIT`, `sRGB`, `bKGD`, `hIST`,
            /// `tRNS`, `pHYs`, `sPLT`, `tIME`, `iTXt`, `tEXt`, or `zTXt`.
            /// 
            /// - Parameters:
            ///     - name: The four bytes of this PNG chunk type’s name.
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

            /// Returns a Boolean value indicating whether two PNG chunk types are equal.
            /// 
            /// Equality is the inverse of inequality. For any values `a` and `b`, `a == b`
            /// implies that `a != b` is `false`.
            /// 
            /// - Parameters:
            ///     - lhs: A value to compare.
            ///     - rhs: Another value to compare.
            public static
            func == (a:Tag, b:Tag) -> Bool
            {
                return a.name == b.name
            }

            /// Hashes the name of this PNG chunk type by feeding it into the given
            /// hasher.
            /// 
            /// - Parameters:
            ///     - hasher: The hasher to use when combining the components of this
            ///         instance.
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
            let IHDR:Tag = .init(73, 72, 68, 82)
            /// The PNG palette chunk type.
            public static
            let PLTE:Tag = .init(80, 76, 84, 69)
            /// The PNG image data chunk type.
            public static
            let IDAT:Tag = .init(73, 68, 65, 84)
            /// The PNG image end chunk type.
            public static
            let IEND:Tag = .init(73, 69, 78, 68)

            /// The PNG chromaticity chunk type.
            public static
            let cHRM:Tag = .init(99, 72, 82, 77)
            /// The PNG gamma chunk type.
            public static
            let gAMA:Tag = .init(103, 65, 77, 65)
            /// The PNG embedded ICC chunk type.
            public static
            let iCCP:Tag = .init(105, 67, 67, 80)
            /// The PNG significant bits chunk type.
            public static
            let sBIT:Tag = .init(115, 66, 73, 84)
            /// The PNG *s*RGB chunk type.
            public static
            let sRGB:Tag = .init(115, 82, 71, 66)
            /// The PNG background chunk type.
            public static
            let bKGD:Tag = .init(98, 75, 71, 68)
            /// The PNG histogram chunk type.
            public static
            let hIST:Tag = .init(104, 73, 83, 84)
            /// The PNG transparency chunk type.
            public static
            let tRNS:Tag = .init(116, 82, 78, 83)

            /// The PNG physical dimensions chunk type.
            public static
            let pHYs:Tag = .init(112, 72, 89, 115)

            /// The PNG suggested palette chunk type.
            public static
            let sPLT:Tag = .init(115, 80, 76, 84)
            /// The PNG time chunk type.
            public static
            let tIME:Tag = .init(116, 73, 77, 69)

            /// The PNG UTF-8 text chunk type.
            public static
            let iTXt:Tag = .init(105, 84, 88, 116)
            /// The PNG Latin-1 text chunk type.
            public static
            let tEXt:Tag = .init(116, 69, 88, 116)
            /// The PNG compressed Latin-1 text chunk type.
            public static
            let zTXt:Tag = .init(122, 84, 88, 116)
        }
    }

    /// Errors that can occur while reading, decompressing, or decoding PNG files.
    public
    enum DecodingError:Error
    {
        /// A PNG file is missing its magic signature.
        case missingSignature

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

        /// A PNG chunk has been encountered that is of the same type as a previously
        /// encountered chunk, and is of a type which cannot appear multiple times
        /// in the same PNG file.
        case duplicateChunk(Chunk)
        /// A prerequisite PNG chunk is missing.
        case missingChunk(Chunk.Core)
    }
    
    public 
    enum ConversionError:Error 
    {
        /// An input pixel array has the wrong size 
        case pixelCount
        /// An image being encoded has too many colors to index.
        case paletteOverflow
        /// An indexed pixel references a palette entry that doesn’t exist.
        case indexOutOfRange
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
    
    /// A low-level API for deconstructing a PNG file into its constituent untyped
    /// chunks, or constructing a PNG file out of a sequence of typed chunks.
    public
    struct ChunkIterator<DataInterface>
    {
    }
}

extension PNG.ChunkIterator where DataInterface:DataSource
{
    /// Begins the process of loading untyped PNG chunks from the given data source.
    /// 
    /// The main operation performed this method is checking for the PNG magic file
    /// signature. This method will pull 8 bytes of data from the given data source.
    /// 
    /// - Parameters:
    ///     - source: A data source yielding a PNG file. The source is assumed to
    ///         pointing to the very beginning of the PNG file.
    /// - Returns: A chunk iterator, if the PNG magic signature was read from the
    ///     given data source, and `nil` otherwise.
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

    /// Loads the an untyped PNG chunk from the given data source.
    /// 
    /// This method performs no chunk name validation, nor does it interpret the chunk.
    /// This method does, however, perform crc32 validation on the chunk, as this
    /// is universal to all PNG chunks.
    /// 
    /// To aid diagnostics, the name bytes of the chunk are returned even if the
    /// chunk’s data is corrupted.
    /// 
    /// This method pulls 12 bytes from the given data source, plus the length encoded
    /// in the chunk header.
    /// 
    /// - Parameters:
    ///     - source: A data source yielding a PNG file.
    /// - Returns: A tuple containing the name bytes of the read chunk and its data,
    ///     or `nil` if enough data could not be pulled from the given data source.
    ///     The chunk `data` field of the tuple is `nil` if the chunk’s data could
    ///     be successfully read, but failed to match the chunk’s crc32 checksum.
    /// 
    /// - Note: Some chunks may have a length of 0, and such produce an empty `data`
    ///     array. This is not an error.
    public mutating
    func next(source:inout DataInterface) -> (name:(UInt8, UInt8, UInt8, UInt8), data:[UInt8]?)?
    {
        guard let header:[UInt8] = source.read(count: 8)
        else
        {
            return nil
        }

        let length:Int = header.prefix(4).load(bigEndian: UInt32.self, as: Int.self),
            name:(UInt8, UInt8, UInt8, UInt8) = (header[4], header[5], header[6], header[7])

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
    /// Begins the process of storing untyped PNG chunks into the given data destination.
    /// 
    /// The main operation performed this method is writing the PNG magic file signature.
    /// This method will push 8 bytes of data to the given data destination.
    /// 
    /// - Parameters:
    ///     - source: A data destination to write a PNG file to. The destination
    ///         is assumed to pointing to the very beginning of the file.
    /// - Returns: A chunk iterator, or `nil` if the signature could not be written.
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

    /// Serializes a PNG chunk of the given type and with the given raw data, and
    /// stores it into the given data destination.
    /// 
    /// This method does not interpret the given chunk data. This method automatically
    /// computes its crc32 checksum, and chunk length, and stores them in its serialized
    /// in-file representation.
    /// 
    /// This method pushes 12 bytes to the given data destination, plus the given
    /// `data` array.
    /// 
    /// - Parameters:
    ///     - tag: A chunk tag.
    ///     - data: An array containing chunk data. The default is `[]`.
    ///     - source: A data destination to write a PNG file to.
    /// - Returns: `nil` if the chunk could not be written.
    public mutating
    func next(_ tag:PNG.Chunk.Tag, _ data:[UInt8] = [], destination:inout DataInterface)
        -> Void?
    {
        let header:[UInt8] = .store(data.count, asBigEndian: UInt32.self)
        +
        [tag.name.0, tag.name.1, tag.name.2, tag.name.3]

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

// `RandomAccessCollection` conformance helps the optimizer speed up a lot of operations
//  using color types
extension PNG.VA:FixedLayoutColor 
{
    /// A textual representation of this color.
    public
    var description:String
    {
        "(\(self.v), \(self.a))"
    }
    
    /// The number of components in this grayscale-alpha color, always 2.
    @inlinable
    public static
    var components:Int
    {
        2
    }
    
    /// The `index`th component of this color. The 0th component is the grayscale 
    /// component, and the 1st component is the alpha component.
    @inlinable
    public
    subscript(index:Int) -> Component
    {
        switch index
        {
            case 0:
                return self.v
            case 1:
                return self.a
            default:
                fatalError("(VA) index \(index) out of range")
        }
    }
}

extension PNG.RGBA:FixedLayoutColor
{
    /// A textual representation of this color.
    public
    var description:String
    {
        "(\(self.r), \(self.g), \(self.b), \(self.a))"
    }

    @inlinable
    public static
    var components:Int
    {
        4
    }

    @inlinable
    public
    subscript(index:Int) -> Component
    {
        switch index
        {
            case 0:
                return self.r
            case 1:
                return self.g
            case 2:
                return self.b
            case 3:
                return self.a
            default:
                fatalError("(RGBA) index \(index) out of range")
        }
    }
} 

extension Array where Element:FixedLayoutColor
{
    /// Converts this array of color values to a palette table and an array of indices.
    /// 
    /// - Returns: A tuple containing the indices of the colors in this array, and
    ///     a table of color palette entries, or `nil` if this array of color values
    ///     could not be indexed into 256 or fewer palette entries.
    public
    func indexPalette() -> (indexed:[UInt8], palette:[Element])?
    {
        var indexed:[UInt8]          = [],
            palette:[Element: UInt8] = [:]
            indexed.reserveCapacity(self.count)
            palette.reserveCapacity(1 << UInt8.bitWidth)
        for color:Element in self
        {
            if let index:UInt8 = palette[color]
            {
                indexed.append(index)
            }
            else
            {
                guard let index:UInt8 = UInt8.init(exactly: palette.count)
                else
                {
                    return nil
                }

                palette[color] = index
                indexed.append(index)
            }
        }

        // invert the palette dictionary
        let table:[Element] = .init(unsafeUninitializedCapacity: palette.count)
        {
            (buffer:inout UnsafeMutableBufferPointer<Element>, count:inout Int) in

            for (color, index):(Element, UInt8) in palette
            {
                buffer[Int(index)] = color
            }

            count = palette.count
        }

        return (indexed, table)
    }

    /// Temporarily view this color matrix as a flattened buffer of interleaved
    /// color components.
    /// 
    /// *Inlinable*
    ///
    /// - Parameters:
    ///     - body: A closure taking a buffer pointer to this color matrix, viewed
    ///         as a flat buffer of interleaved color components.
    /// - Returns: The return value of `body`, if it has one.
    /// 
    /// - Note: The buffer passed to the closure is only valid for the execution
    ///     of that closure.
    @inlinable
    public
    func withUnsafeBufferPointerToComponents<Result>(_ body:(UnsafeBufferPointer<Element.Element>) throws -> Result)
        rethrows -> Result
    {
        return try self.withUnsafeBufferPointer
        {
            (buffer:UnsafeBufferPointer<Element>) in

            let raw:UnsafeRawBufferPointer = .init(buffer)
            defer
            {
                raw.bindMemory(to: Element.self)
            }
            return try body(raw.bindMemory(to: Element.Element.self))
        }
    }
    
    /// Converts this array of colorvectors into a planar representation. Other 
    /// frameworks may call this operation “unzip”.
    /// 
    /// *Inlinable*.
    /// 
    /// - Returns: If the original array contains colorvectors 
    ///     `[(a1, b1, c1, ...), (a2, b2, c2, ...), (a3, b3, c3, ...), ..., (an, bn, cn, ...)]`, 
    ///     the result will be an array of colorvector components 
    ///     `[a1, a2, a3, ..., an, b1, b2, b3, ..., bn, c1, c2, c3, ..., cn, ...]`.
    @inlinable
    public  
    func planar() -> [Element.Element]
    {
        return (0 ..< Element.components).flatMap 
        {
            (ci:Int) in
            
            self.map{ $0[ci] }
        }
    }

    /// Flattens this array of colorvectors into an unstructured array of their 
    /// interleaved components.
    /// 
    /// *Inlinable*.
    /// 
    /// - Returns: If the original array contains colorvectors 
    ///     `[(a1, b1, c1, ...), (a2, b2, c2, ...), (a3, b3, c3, ...), ..., (an, bn, cn, ...)]`, 
    ///     the result will be an array of colorvector components 
    ///     `[a1, b1, c1, ..., a2, b2, c2, ..., a3, b3, c3, ..., an, bn, cn, ...]`.
    /// 
    /// - Note: In most cases, it is better to temporarily rebind a structured pixel
    ///     array to a flattened array type than to convert it to interleaved form.
    @inlinable
    public  
    func interleaved() -> [Element.Element]
    {
        return self.flatMap{ $0 }
    }
}
