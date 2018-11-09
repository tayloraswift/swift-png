###### Generic Structure

# `RGBA`

A normalized color unit consisting of four color samples.

------

## Symbols

### Initializers

#### `init(_ r:Sample, _ g:Sample, _ b:Sample, _ a:Sample)`

> Creates an instance with the given sample values.

### Instance properties

#### `let r:Sample`

> The red channel of the RGBA color.

#### `let g:Sample`

> The green channel of the RGBA color.

#### `let b:Sample`

> The blue channel of the RGBA color.

#### `let a:Sample`

> The alpha channel of the RGBA color.

#### `var description:String { get }`

> A textual description of the RGBA color.

### Operator functions

#### `static func == (_ lhs:`[`RGBA`](rgba.md)`<Sample>, _ rhs:`[`RGBA`](rgba.md)`<Sample>) -> Bool`

> Returns a Boolean value indicating whether all four samples in each of two RGBA colors are equal.

### Extensions

#### `var premultiplied:`[`RGBA`](rgba.md)`<UInt8> { get }`

> Returns a copy of the instance with premultiplied alpha. The red, green, and blue samples are premultiplied with the alpha according to this formula:

>     premultiplied_sample = (sample * (alpha + 1)) >> 8

> Only available when `Sample` is `UInt8`.

#### `var premultiplied:`[`RGBA`](rgba.md)`<UInt16> { get }`

> Returns a copy of the instance with premultiplied alpha. The red, green, and blue samples are premultiplied with the alpha according to this formula:

>     premultiplied_sample = (sample * (alpha + 1)) >> 16

> Only available when `Sample` is `UInt16`.

#### `var argb32:UInt32 { get }`

> Returns the RGBA color encoded as a 32 bit unsigned integer. The alpha sample lives in the 8 most significant bits, followed by the red sample, the green sample, and then the blue sample. This value is [compatible](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-format-t) with the Cairo graphics library, independent of endianess. This computed property does *not* premultiply alpha; use it in combination with the [`premultiplied`](#var-premultipliedrgbauint8--get-) property to perform both operations. Only available when `Sample` is `UInt8`.

#### `var argb64:UInt64 { get }`

> Returns the RGBA color encoded as a 64 bit unsigned long integer. The alpha sample lives in the 16 most significant bits, followed by the red sample, the green sample, and then the blue sample. This value is [compatible](https://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-format-t) with the Cairo graphics library, independent of endianess. This computed property does *not* premultiply alpha; use it in combination with the [`premultiplied`](#var-premultipliedrgbauint16--get-) property to perform both operations. Only available when `Sample` is `UInt16`.

## Relationships

### Generic constraints

#### `Sample:`[`UnsignedInteger`](https://developer.apple.com/reference/swift/unsignedinteger)

### Conforms to

#### [`Equatable`](https://developer.apple.com/reference/swift/equatable), [`CustomStringConvertible`](https://developer.apple.com/reference/swift/customstringconvertible)
