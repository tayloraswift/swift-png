extension LZ77.Deflator
{
    struct Window
    {

        private
        var storage:ManagedBuffer<Void, Element>,
            head:General.Dictionary

        private(set)
        var endIndex:Int // absolute index
        private
        var w:UInt32,
            v:UInt32

        private
        let mask:Int
    }
}
extension LZ77.Deflator.Window
{
    init(exponent:Int)
    {
        self.endIndex   = -3
        self.w          = 0
        self.v          = 0
        self.mask       = ~(.max << exponent)

        self.storage    = .create(minimumCapacity: 1 << exponent){ _ in () }
        self.head       = .init(exponent: exponent)
    }

    private
    subscript(modular:Int) -> Element
    {
        get
        {
            self.storage.withUnsafeMutablePointerToElements
            {
                $0[modular]
            }
        }
        set(value)
        {
            self.storage.withUnsafeMutablePointerToElements
            {
                $0[modular] = value
            }
        }
    }

    var literal:UInt8
    {
        .init(self.v >> 24)
    }

    mutating
    func initialize(with v:UInt8)
    {
        assert(self.endIndex < 0)
        // we don’t need to update `self.w` because `self.mask` is always at
        // least 255.
        self.v = self.v << 8 | .init(v)
        //               01..11  00..00  00..01  00..10  00..11
        //  ╴╴╴╴╴╴╴╴┬───────┬───────┰───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
        //          │  ///  ╎  ///  ╏  w.1  ╎  w.0  │       ╎       ╎
        //  ╴╴╴╴╴╴╴╴┴───────┴───────┸───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
        //          a      a+1     a+2      b      b+1
        //                          ┌───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
        //             ///     ///  │  v.1  ╎  v.0  │       ╎       ╎
        //                          └───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
        self.endIndex += 1
    }

    @discardableResult
    mutating
    func update(with v:UInt8) -> (index:Int, next:UInt16?)
    {
        assert(self.endIndex >= 0)

        let a:Int       =  self.endIndex       & self.mask,
            b:Int       = (self.endIndex &+ 3) & self.mask
        let w:UInt8     =  self[b].value

        self.w = self.w << 8 | .init(w)
        self.v = self.v << 8 | .init(v)

        if self.endIndex > self.mask
        {
            //               01..11  10..00  10..01  10..10  10..11
            //  ╴╴╴╴╴╴╴╴┬───────┬───────┰───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
            //          ╎       ╎       ┃  w.3  ╎  w.2  ╎  w.1  ╎  w.0  │
            //  ╴╴╴╴╴╴╴╴┴───────┴───────┸───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
            //                          a      a+1     a+2      b      b+1
            //                          ┌───────┬───────┬───────┬───────┬╶╶╶╶╶╶╶╶
            //                          │  v.3  ╎  v.2  ╎  v.1  ╎  v.0  │
            //                          └───────┴───────┴───────┴───────┴╶╶╶╶╶╶╶╶
            // a match has gone out of range. delete the match corresponding
            // to the key in the window at the current position, but only if
            // it has not already been overwritten with a more recent position.
            self.head.remove(key: self.w, value: .init(a))
        }
        let next:UInt16?    =
            self.head.update(key: self.v, value: .init(a))
        self[a]             = .init(next: next, value: self.literal)

        self.endIndex += 1

        // print("lookup (\(self.v >> 24), \(self.v >> 16 & 0xff), \(self.v >> 8 & 0xff), \(self.v & 0xff)): \(next)")

        return (a, next)
    }

    func match(from head:(index:Int, next:UInt16?), lookahead:LZ77.Deflator.In, attempts:Int, goal:Int)
        -> (run:Int, distance:Int)?
    {
        var best:(run:Int, distance:Int) = (run: 5, distance: 1)
        self.match(from: head, lookahead: lookahead, attempts: attempts, goal: goal)
        {
            (run:Int, distance:Int) in
            if best.run < run
            {
                best = (run: run, distance: distance)
            }
        }
        return best.run > 5 ? best : nil
    }

    func match(from head:(index:Int, next:UInt16?), lookahead:LZ77.Deflator.In,
        attempts:Int, goal:Int, delegate:(_ run:Int, _ distance:Int) -> ())
    {
        lookahead.withUnsafePointer
        {
            (v:UnsafePointer<UInt8>) in

            self.storage.withUnsafeMutablePointerToElements
            {
                (w:UnsafeMutablePointer<Element>) in

                guard let next:UInt16 = head.next
                else
                {
                    return
                }

                let limit:Int       = min(lookahead.count + 4, 258)

                let mask:Int        = self.mask
                var current:Int     = .init(next)
                var distance:Int    = (head.index &- current) & mask
                var remaining:Int   = attempts
                while true
                {
                    var run:Int = 4
                    scan:
                    do
                    {
                        let a:Int = min(distance, limit)
                        while run < a
                        {
                            let i:Int = (current &+ run) & mask
                            guard w[i].value == v[run]
                            else
                            {
                                break scan
                            }
                            run += 1
                        }

                        var i:Int = max(0, 4 - distance)
                        while run < limit, v[i] == v[run]
                        {
                            i   += 1
                            run += 1
                        }
                    }

                    delegate(run, distance)

                    remaining -= 1

                    guard remaining > 0, goal > run
                    else
                    {
                        break
                    }

                    guard let next:UInt16 = self[current].next
                    else
                    {
                        break
                    }

                    let previous:Int    = current
                    current             = .init(next)
                    distance           += (previous &- current) & mask

                    guard distance < mask
                    else
                    {
                        break
                    }
                }
            }
        }
    }
}
