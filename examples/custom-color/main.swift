import PNG 

struct HSVA 
{
    var h:UInt32 
    var s:UInt16 
    var v:UInt8 
    var a:UInt8 
    
    init(h:UInt32, s:UInt16, v:UInt8, a:UInt8)
    {
        self.h = h 
        self.s = s 
        self.v = v 
        self.a = a
    }
    
    init(r:UInt8, g:UInt8, b:UInt8, a:UInt8) 
    {
        let sorted:(min:UInt8, mid:UInt8, max:UInt8) 
        let sector:UInt32
        switch (r < g, g < b, r < b) 
        {
        case (true , true , _    ): sorted = (r, g, b); sector = 3
        case (false, true , true ): sorted = (g, r, b); sector = 4
        case (false, true , false): sorted = (g, b, r); sector = 5
        case (true , false, true ): sorted = (r, b, g); sector = 2
        case (true , false, false): sorted = (b, r, g); sector = 1
        case (false, false, _    ): sorted = (b, g, r); sector = 0
        }
        let d:UInt32 = .init(sorted.max - sorted.min)
        if d > 0 
        {
            let f:UInt32 = .init(sorted.mid - sorted.min) << 16 / d + 1, 
                r:UInt32 = sector & 1 == 0 ? f : 65537 - f
            
            self.h = 65537 * sector + r
            self.s = .init((d << 16 - 1) / .init(sorted.max))
        }
        else 
        {
            self.h = 0 
            self.s = 0
        }
        
        self.v = sorted.max 
        self.a = a
    }
    
    var rgba:PNG.RGBA<UInt8> 
    {
        guard self.s > 0, self.v > 0 
        else 
        {
            return .init(self.v, self.v, self.v, self.a)
        }
        
        let (sector, r):(UInt32, UInt32) = 
            self.h.quotientAndRemainder(dividingBy: 65537)
        let f:UInt32 = sector & 1 == 0 ? r : 65537 - r
        let d:UInt32 = (.init(self.s) * .init(self.v)) >> 16 + 1
        
        let x:UInt8 = self.v, 
            y:UInt8 = x - .init(d),
            z:UInt8 = .init((f * d) >> 16) + y
        
        switch sector 
        {
        case 0: return .init(x, z, y, self.a)
        case 1: return .init(z, x, y, self.a)
        case 2: return .init(y, x, z, self.a)
        case 3: return .init(y, z, x, self.a)
        case 4: return .init(z, y, x, self.a)
        case 5: return .init(x, y, z, self.a)
        default: fatalError("unreachable")
        }
    }
}

extension HSVA:PNG.Color 
{
    typealias Aggregate = (UInt8, UInt8, UInt8, UInt8)
    
    static 
    func unpack(_ interleaved:[UInt8], of format:PNG.Format, 
        deindexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Int) -> Aggregate) 
        -> [Self] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.convolve(interleaved, dereference: deindexer(palette)) 
            {
                (c:(UInt8, UInt8, UInt8, UInt8)) in 
                .init(r: c.0, g: c.1, b: c.2, a: c.3)
            }
                
        case    .v1(fill: _, key: nil),
                .v2(fill: _, key: nil),
                .v4(fill: _, key: nil),
                .v8(fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth) 
            {
                (v:UInt8, _) in 
                .init(h: 0, s: 0, v: v, a: .max)
            }
        case    .v16(fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (v:UInt8, _) in 
                .init(h: 0, s: 0, v: v, a: .max)
            }
        case    .v1(fill: _, key: let key?),
                .v2(fill: _, key: let key?),
                .v4(fill: _, key: let key?),
                .v8(fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (v:UInt8, k:UInt8 ) in 
                .init(h: 0, s: 0, v: v, a: k == key ? .min : .max)
            }
        case    .v16(fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth) 
            {
                (v:UInt8, k:UInt16) in 
                .init(h: 0, s: 0, v: v, a: k == key ? .min : .max)
            }

        case    .va8(fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8)) in 
                .init(h: 0, s: 0, v: c.0, a: c.1)
            }
        case    .va16(fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(UInt8, UInt8)) in 
                .init(h: 0, s: 0, v: c.0, a: c.1)
            }
        
        case    .bgr8(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8), _) in 
                .init(r: c.2, g: c.1, b: c.0, a: .max)
            }
        case    .bgr8(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8), k:(UInt8,  UInt8,  UInt8 )) in 
                .init(r: c.2, g: c.1, b: c.0, a: k == key ? .min : .max)
            }
    
        case    .rgb8(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8), _) in 
                .init(r: c.0, g: c.1, b: c.2, a: .max)
            }
        case    .rgb16(palette: _, fill: _, key: nil):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8), _) in 
                .init(r: c.0, g: c.1, b: c.2, a: .max)
            }
        case    .rgb8(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8), k:(UInt8,  UInt8,  UInt8 )) in 
                .init(r: c.0, g: c.1, b: c.2, a: k == key ? .min : .max)
            }
        case    .rgb16(palette: _, fill: _, key: let key?):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8), k:(UInt16, UInt16, UInt16)) in 
                .init(r: c.0, g: c.1, b: c.2, a: k == key ? .min : .max)
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8, UInt8)) in 
                .init(r: c.2, g: c.1, b: c.0, a: c.3)
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt8.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8, UInt8)) in 
                .init(r: c.0, g: c.1, b: c.2, a: c.3)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.convolve(interleaved, of: UInt16.self, depth: depth)
            {
                (c:(UInt8, UInt8, UInt8, UInt8)) in 
                .init(r: c.0, g: c.1, b: c.2, a: c.3)
            }
        }
    }
    
    static 
    func pack(_ pixels:[Self], as format:PNG.Format, 
        indexer:([(r:UInt8, g:UInt8, b:UInt8, a:UInt8)]) -> (Aggregate) -> Int) 
        -> [UInt8] 
    {
        let depth:Int = format.pixel.depth 
        switch format 
        {
        case    .indexed1(palette: let palette, fill: _), 
                .indexed2(palette: let palette, fill: _), 
                .indexed4(palette: let palette, fill: _), 
                .indexed8(palette: let palette, fill: _):
            return PNG.deconvolve(pixels, reference: indexer(palette)) 
            {
                (c:Self) -> (UInt8, UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.r, rgba.g, rgba.b, c.a)
            }
                
        case    .v1(fill: _, key: _),
                .v2(fill: _, key: _),
                .v4(fill: _, key: _),
                .v8(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self,  depth: depth, kernel: \.v) 
        case    .v16(fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth, kernel: \.v)

        case    .va8(fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8) in 
                return (c.v, c.a)
            }
        case    .va16(fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8) in 
                return (c.v, c.a)
            }
        
        case    .bgr8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.b, rgba.g, rgba.r)
            }
    
        case    .rgb8(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.r, rgba.g, rgba.b)
            }
        case    .rgb16(palette: _, fill: _, key: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.r, rgba.g, rgba.b)
            }
        
        case    .bgra8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.b, rgba.g, rgba.r, c.a)
            }
        
        case    .rgba8(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt8.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.r, rgba.g, rgba.b, c.a)
            }
        case    .rgba16(palette: _, fill: _):
            return PNG.deconvolve(pixels, as: UInt16.self, depth: depth)
            {
                (c:Self) -> (UInt8, UInt8, UInt8, UInt8) in 
                let rgba:PNG.RGBA<UInt8> = c.rgba 
                return (rgba.r, rgba.g, rgba.b, c.a)
            }
        }
    }
}

let path:String = "examples/custom-color/example"
guard let image:PNG.Data.Rectangular = try .decompress(path: "\(path).png")
else 
{
    fatalError("failed to open file '\(path).png'")
}

let hsva:[HSVA] = image.unpack(as: HSVA.self)

let hue:PNG.Data.Rectangular = .init(
    packing: hsva.map{ HSVA.init(h: $0.h, s: .max / 2, v: .max, a: $0.a) }, 
    size: image.size, layout: image.layout, metadata: image.metadata) 
try hue.compress(path: "\(path)-hue.png")

let saturation:PNG.Data.Rectangular = .init(
    packing: hsva.map{ HSVA.init(h: 370000, s: $0.s, v: .max, a: $0.a) }, 
    size: image.size, layout: image.layout, metadata: image.metadata) 
try saturation.compress(path: "\(path)-saturation.png")

let value:PNG.Data.Rectangular = .init(
    packing: hsva.map{ HSVA.init(h: 0, s: 0, v: $0.v, a: $0.a) }, 
    size: image.size, layout: image.layout, metadata: image.metadata) 
try value.compress(path: "\(path)-value.png")

let new:PNG.Data.Rectangular = .init(packing: hsva, 
    size: image.size, layout: image.layout, metadata: image.metadata)
try new.compress(path: "\(path).png.png")
