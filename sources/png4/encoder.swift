extension PNG.Data.Rectangular 
{
    func collect<C>(scanline:inout C, at base:(x:Int, y:Int), stride:Int)
        where   C:RandomAccessCollection & MutableCollection, 
                C.Index == Int, C.Element == UInt8
    {
        let indices:EnumeratedSequence<StrideTo<Int>> = 
            Swift.stride(from: base.x, to: self.size.x, by: stride).enumerated()
        switch self.layout.format 
        {
        // 0 x 1 
        case .v1, .indexed1:
            for (i, x):(Int, Int) in indices
            {
                let a:Int    =   i >> 3 &+ scanline.startIndex, 
                    b:Int    =  ~i & 0b111
                scanline[a] |= (self.storage[base.y &* self.size.x &+ x] & 0b0001) &<< b 
            }
        
        case .v2, .indexed2:
            for (i, x):(Int, Int) in indices
            {
                let a:Int    =   i >> 2 &+ scanline.startIndex, 
                    b:Int    = (~i & 0b011) << 1
                scanline[a] |= (self.storage[base.y &* self.size.x &+ x] & 0b0011) &<< b 
            }
        
        case .v4, .indexed4:
            for (i, x):(Int, Int) in indices
            {
                let a:Int    =   i >> 1 &+ scanline.startIndex, 
                    b:Int    = (~i & 0b001) << 2
                scanline[a] |= (self.storage[base.y &* self.size.x &+ x] & 0b1111) &<< b
            }
        
        // 1 x 1
        case .v8, .indexed8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = i &+ scanline.startIndex, 
                    d:Int = base.y &* self.size.x &+ x
                scanline[a] = self.storage[d]
            }
        // 1 x 2, 2 x 1
        case .va8, .v16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 2 &* i &+ scanline.startIndex, 
                    d:Int = 2 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
            }
        // 1 x 3
        case .rgb8:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 3 &* i &+ scanline.startIndex, 
                    d:Int = 3 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
            }
        // 1 x 4, 2 x 2
        case .rgba8, .va16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 4 &* i &+ scanline.startIndex, 
                    d:Int = 4 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
                scanline[a &+ 3] = self.storage[d &+ 3]
            }
        // 2 x 3
        case .rgb16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 6 &* i &+ scanline.startIndex, 
                    d:Int = 6 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
                scanline[a &+ 3] = self.storage[d &+ 3]
                scanline[a &+ 4] = self.storage[d &+ 4]
                scanline[a &+ 5] = self.storage[d &+ 5]
            }
        // 2 x 4
        case .rgba16:
            for (i, x):(Int, Int) in indices
            {
                let a:Int = 8 &* i &+ scanline.startIndex, 
                    d:Int = 8 &* (base.y &* self.size.x &+ x)
                scanline[a     ] = self.storage[d     ]
                scanline[a &+ 1] = self.storage[d &+ 1]
                scanline[a &+ 2] = self.storage[d &+ 2]
                scanline[a &+ 3] = self.storage[d &+ 3]
                scanline[a &+ 4] = self.storage[d &+ 4]
                scanline[a &+ 5] = self.storage[d &+ 5]
                scanline[a &+ 6] = self.storage[d &+ 6]
                scanline[a &+ 7] = self.storage[d &+ 7]
            }
        }
    }
}
