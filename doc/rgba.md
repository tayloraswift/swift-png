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

#### `static func == (_ lhs:RGBA<Sample>, _ rhs:RGBA<Sample>) -> Bool`

> Returns a Boolean value indicating whether all four samples in each of two RGBA colors are equal.

## Relationships

### Generic constraints

#### `Sample:`[`UnsignedInteger`](https://developer.apple.com/reference/swift/unsignedinteger)

### Conforms to 

#### [`Equatable`](https://developer.apple.com/reference/swift/equatable), [`CustomStringConvertible`](https://developer.apple.com/reference/swift/customstringconvertible)
