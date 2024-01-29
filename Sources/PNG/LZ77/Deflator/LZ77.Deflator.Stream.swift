extension LZ77.Deflator
{
    struct Stream
    {
        let format:LZ77.Format
        let search:Search

        var input:In
        //var queued:(run:Int, extend:Int, distance:Int)?
        //var terms:[Term]
        var window:Window
        var matches:Matches
        var output:Out

        init(format:LZ77.Format, level:Int, exponent:Int, hint:Int)
        {
            precondition(8 ..< 16 ~= exponent, "exponent cannot be less than 8 or greater than 15")

            switch level
            {
            case .min ... 0:
                self.search = .greedy(attempts:   1, goal:   6)
            case  1:
                self.search = .greedy(attempts:   2, goal:   8)
            case  2:
                self.search = .greedy(attempts:   4, goal:  10)
            case  3:
                self.search = .greedy(attempts:  40, goal:  24)

            case  4:
                self.search = .lazy(  attempts:  20, goal:  32)
            case  5:
                self.search = .lazy(  attempts:  40, goal:  54)
            case  6:
                self.search = .lazy(  attempts:  64, goal:  80)
            case  7:
                self.search = .lazy(  attempts: 100, goal: 160)

            case  8:
                self.search = .full(  attempts:  14, goal:  20, iterations: 1)
            case  9:
                self.search = .full(  attempts:  20, goal:  32, iterations: 2)
            case 10:
                self.search = .full(  attempts:  30, goal:  50, iterations: 3)
            case 11:
                self.search = .full(  attempts:  60, goal:  80, iterations: 4)
            case 12:
                self.search = .full(  attempts: 100, goal: 133, iterations: 5)
            default:
                self.search = .full(  attempts:.max, goal: 258, iterations: 6)
            }
            // match buffer is either a vector of terms, or a directed-graph
            switch self.search
            {
            case .greedy, .lazy:
                self.matches = .terms(capacity: 1 << 15)
            case .full:
                self.matches = .graph(capacity: 1 << 16)
            }

            self.format = format

            self.input  = .init()
            self.window = .init(exponent: exponent)
            self.output = .init(hint: hint)
        }
    }
}
extension LZ77.Deflator.Stream
{
    mutating
    func start(exponent:Int)
    {
        if case .ios = self.format
        {
            return
        }

        let unpaired:UInt16 = .init(exponent - 8) << 4 | 0x08
        let check:UInt16    = ~((unpaired << 8 | unpaired >> 8) % 31) & 31

        self.output.append(check << 8 | unpaired, count: 16)
    }

    mutating
    func compress(all:Bool) -> Void?
    {
        //         -3      -2      -1       0       1       2       3       4       5       6
        //          ┌╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬
        //          │  ???  ╎  ???  ╎  ???  ┃       ╎       ╎       ╎       ╎       ╎       ╎
        //          └╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴
        //          a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.0  ╎  x.1  ╎  x.2  ╎  x.3  ╎  x.4  ╎  x.5  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                  n      n-1     n-2     n-3     n-4     n-5     n-6
        //
        //  PROLOGUE (while a < 0)
        //
        // -3      -2      -1       0       1       2       3       4       5       6       7
        //  ┌╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  │  ???  ╎  ???  ╎  ???  ╏  x.0  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  └╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.1  ╎  x.2  ╎  x.3  ╎  x.4  ╎  x.5  ╎  x.6  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-1     n-2     n-3     n-4     n-5     n-6     n-7
        //
        // -2      -1       0       1       2       3       4       5       6       7       8
        //  ┬╴╴╴╴╴╴╴┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  │  ???  ╎  ???  ╏  x.0  ╎  x.1  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  ┴╴╴╴╴╴╴╴┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.2  ╎  x.3  ╎  x.4  ╎  x.5  ╎  x.6  ╎  x.8  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-2     n-3     n-4     n-5     n-6     n-7     n-8
        //
        // -1       0       1       2       3       4       5       6       7       8       9
        //  ┬╴╴╴╴╴╴╴┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  │  ???  ╏  x.0  ╎  x.1  ╎  x.2  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  ┴╴╴╴╴╴╴╴┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.3  ╎  x.4  ╎  x.5  ╎  x.6  ╎  x.7  ╎  x.8  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-3     n-4     n-5     n-6     n-7     n-8     n-9
        //
        //  BODY (while b > 0, match.run <= b)
        //
        //  0       1       2       3       4       5       6       7       8       9      10
        //  ┰───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬
        //  ╏  x.0  ╎  x.1  ╎  x.2  ╎  x.3  │       ╎       ╎       ╎       ╎       ╎       ╎
        //  ┸───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬───────┬───────┬───────┬
        //                                  │  x.4  ╎  x.5  ╎  x.6  ╎  x.7  ╎  x.8  ╎  x.9  ╎
        //                                  └───────┴───────┴───────┴───────┴───────┴───────┴
        //                                 n-4     n-5     n-6     n-7     n-8     n-9     n-10
        //
        //                                  . . .
        //
        //  |<--------- match (6 ..< 11) ---------->|
        //  6       7       8       9      10      11      12      n=13
        //  ┼───────┬───────┬───────┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬
        //  │  x.6  ╎  x.7  ╎  x.8  ╎  x.9  │       │       ╎       │       ╎       ╎       ╎
        //  ┼───────┴───────┴───────┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬
        //                                  │  x.10 ╎  x.11 ╎  x.12 │  ???  ╎  ???  ╎  ???  ╎
        //                                  └───────┴───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴
        //                                 n-10     2       1       0      -1      -2      -3
        //
        //  CONSUME (while a <= match.end)
        //
        //  --- match (6 ..< 11) ---------->|
        //  7       8       9      10      11      12      n=13
        //  ┬───────┬───────┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.7  ╎  x.8  ╎  x.9  ╎  x.10 │       ╎       │       ╎       ╎       ╎       │
        //  ┴───────┴───────┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  x.11 ╎  x.12 │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //                                  └───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                 n-11     1       0      -1      -2      -3      -4
        //
        //    (6 ..< 11) ---------->|
        //  8       9      10      11      12      n=13
        //  ┬───────┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.8  ╎  x.9  ╎  x.10 │  x.11 ╎       │       ╎       ╎       ╎       │
        //  ┴───────┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  x.12 │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //                                  └───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                  1       0      -1      -2      -3      -4
        //
        //       ---------->|
        //  9      10      11      12      n=13
        //  ┬───────┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.9  ╎  x.10 │  x.11 ╎  x.12 │       ╎       ╎       ╎       │
        //  ┴───────┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //                                  └╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                  0      -1      -2      -3      -4
        //
        //  ------->|
        // 10      11      12      n=13
        //  ┬───────┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.10 │  x.11 ╎  x.12 │  ???  ╎       ╎       ╎       │
        //  ┴───────┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2     b-3
        //                                  ┌╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  ???  ╎  ???  ╎  ???  │
        //                                  └╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                 -1      -2      -3      -4
        //
        //  |
        // 11      12      n=13
        //  ┼───────┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  │  x.11 ╎  x.12 │  ???  ╎  ???  ╎       ╎       │
        //  ┼───────┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1     b-2
        //                                  ┌╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //                                  │  ???  ╎  ???  │
        //                                  └╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        //                                 -2      -3      -4
        //
        //  EPILOGUE (while b > -3)
        //
        // 12      n=13
        //  ┬───────┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  ╎  x.12 │  ???  ╎  ???  ╎  ???  ╎       │
        //  ┴───────┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b      b-1
        //                                  ┌╶╶╶╶╶╶╶┐
        //                                  │  ???  │
        //                                  └╶╶╶╶╶╶╶┘
        //                                 -3      -4
        //
        // n=13
        //  ┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┬╶╶╶╶╶╶╶┐
        //  │  ???  ╎  ???  ╎  ???  ╎  ???  │
        //  ┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┴╶╶╶╶╶╶╶┘
        // head     a      a+1     a+2      b
        switch self.search
        {
        case .greedy(attempts: let attempts, goal: let goal):
            let lookahead:Int = all ? 0 : 258
            while   self.window.endIndex < 0,
                    self.input.count > lookahead
            {
                self.window.initialize(with: self.input.dequeue())
            }

            while   self.input.count > lookahead
            {
                guard self.matches.unfilled > 0
                else
                {
                    return ()
                }

                let head:(index:Int, next:UInt16?)  =
                    self.window.update(with: self.input.dequeue())

                if  let match:(run:Int, distance:Int)   =
                    self.window.match(from: head, lookahead: self.input,
                        attempts: attempts, goal: goal)
                {
                    // consume match. this may cause `self.input.count` to go negative
                    // (in which case, garbage values will be written, which is okay.)
                    for _:Int in 1 ..< match.run
                    {
                        self.window.update(with: self.input.dequeue())
                    }

                    self.matches.store(match: match)
                }
                else
                {
                    self.matches.store(literal: self.window.literal)
                }
            }

            guard all
            else
            {
                return nil
            }

            // epilogue: get the matches still sitting in the pipeline
            let epilogue:Int = -3 - min(0, self.window.endIndex)
            while   self.input.count > epilogue
            {
                guard self.matches.unfilled > 0
                else
                {
                    return ()
                }

                self.window.update(with: self.input.dequeue())
                self.matches.store(literal: self.window.literal)
            }


        case .lazy(attempts: let attempts, goal: let goal):
            let lookahead:Int = all ? 0 : 259
            while   self.window.endIndex < 0,
                    self.input.count > lookahead
            {
                self.window.initialize(with: self.input.dequeue())
            }
            while self.input.count > lookahead
            {
                guard self.matches.unfilled > 1
                else
                {
                    return ()
                }

                let head:(index:Int, next:UInt16?)  =
                    self.window.update(with: self.input.dequeue())
                let first:UInt8                     =
                    self.window.literal

                if  let eager:(run:Int, distance:Int)   =
                    self.window.match(from: head, lookahead: self.input,
                        attempts: attempts, goal: goal)
                {
                    // save the literal at `head`
                    let head:(index:Int, next:UInt16?)      =
                        self.window.update(with: self.input.dequeue())
                    // look for a better match at offset a+1
                    if  let lazy:(run:Int, distance:Int)    =
                        self.window.match(from: head, lookahead: self.input,
                            attempts: attempts, goal: goal),
                        eager.run < lazy.run
                    {
                        // found a longer match. emit the leading literal, and the
                        // improved match.
                        self.matches.store(literal: first)
                        self.matches.store(match: lazy)
                        for _:Int in 1 ..< lazy.run
                        {
                            self.window.update(with: self.input.dequeue())
                        }
                    }
                    else
                    {
                        self.matches.store(match: eager)
                        for _:Int in 2 ..< eager.run
                        {
                            self.window.update(with: self.input.dequeue())
                        }
                    }
                }
                else
                {
                    self.matches.store(literal: first)
                }
            }

            guard all
            else
            {
                return nil
            }

            let epilogue:Int = -3 - min(0, self.window.endIndex)
            while   self.input.count > epilogue
            {
                guard self.matches.unfilled > 0
                else
                {
                    return ()
                }

                self.window.update(with: self.input.dequeue())
                self.matches.store(literal: self.window.literal)
            }

        case .full(attempts: let attempts, goal: let goal, iterations: _):
            let lookahead:Int = all ? 0 : 258
            while   self.window.endIndex < 0,
                    self.input.count > lookahead
            {
                self.window.initialize(with: self.input.dequeue())
            }
            while   self.input.count > lookahead
            {
                guard self.matches.unfilled > 0
                else
                {
                    return ()
                }

                // must save base index because this call increments the endindex
                let head:(index:Int, next:UInt16?)  =
                    self.window.update(with: self.input.dequeue())

                let index:Int   = self.matches.store(vertex: self.window.literal)
                var extent:Int  = 1
                self.window.match(from: head, lookahead: self.input,
                    attempts: attempts, goal: goal)
                {
                    (run:Int, distance:Int) in

                    extent = max(extent, run)
                    self.matches.set(edge: (run: run, distance: distance), at: index)
                }

                // for long matches, skip some of the intermediate vertices
                // to avoid degenerate behavior
                for _:Int in 0 ..< max(0, min(extent - 100, self.matches.unfilled))
                {
                    self.window.update(with: self.input.dequeue())
                    self.matches.store(vertex: self.window.literal)
                }
            }

            guard all
            else
            {
                return nil
            }

            let epilogue:Int = -3 - min(0, self.window.endIndex)
            while   self.input.count > epilogue
            {
                guard self.matches.unfilled > 0
                else
                {
                    return ()
                }

                self.window.update(with: self.input.dequeue())
                self.matches.store(vertex: self.window.literal)
            }
        }

        return nil
    }

    private mutating
    func blockStart(final:Bool, runliterals:Int, distances:Int, metatree:LZ77.HuffmanTree<UInt8>)
    {
        let codelengths:[UInt16] = .init(unsafeUninitializedCapacity: 19)
        {
            $0.initialize(repeating: 0)
            for (length, level):(UInt16, Range<Int>) in zip(1 ... 8, metatree.levels)
            {
                for symbol:UInt8 in metatree.symbols[level]
                {
                    let z:Int =
                    [
                        3, 17, 15, 13, 11,  9,  7,  5,
                        4,  6,  8, 10, 12, 14, 16, 18,
                        0, 1, 2
                    ][.init(symbol)]

                    $0[z] = length
                }
            }
            // max(4, _) because HCLEN cannot be less than 4
            $1 = max(4, $0.reversed().drop{ $0 == 0 }.count)
        }

        self.output.append(final ? 0b10_1 : 0b10_0,        count: 3)

        self.output.append(.init(runliterals       - 257), count: 5)
        self.output.append(.init(distances         -   1), count: 5)
        self.output.append(.init(codelengths.count -   4), count: 4)
        for codelength:UInt16 in codelengths
        {
            self.output.append(codelength, count: 3)
        }
    }

    private mutating
    func blockTables(_ metaterms:[LZ77.Deflator.Term.Meta], semistatic:LZ77.Deflator.Semistatic)
    {
        for metaterm:LZ77.Deflator.Term.Meta in metaterms
        {
            let codeword:LZ77.Codeword = semistatic[meta: metaterm.symbol]
            self.output.append(codeword.bits, count: codeword.length)
            self.output.append(metaterm.bits, count: codeword.extra)
        }
    }

    private mutating
    func blockCompressed(semistatic:LZ77.Deflator.Semistatic)
    {
        switch self.search
        {
        case .greedy, .lazy:
            for index:Int in self.matches.indices
            {
                let term:LZ77.Deflator.Term = .init(storage: self.matches[offset: index])

                let symbol:(runliteral:UInt16, distance:UInt8) = term.symbol
                let codeword:(runliteral:LZ77.Codeword, distance:LZ77.Codeword)

                codeword.runliteral = semistatic[runliteral: symbol.runliteral]

                self.output.append(codeword.runliteral.bits, count: codeword.runliteral.length)

                if symbol.runliteral > 256
                {
                    // there are extra bits and a distance code to follow
                    let bits:(run:UInt16, distance:UInt16) = term.bits

                    codeword.distance = semistatic[distance: symbol.distance]

                    self.output.append(bits.run,               count: codeword.runliteral.extra)
                    self.output.append(codeword.distance.bits, count: codeword.distance.length)
                    self.output.append(bits.distance,          count: codeword.distance.extra)
                }
            }

            // end-of-block symbol
            let end:LZ77.Codeword = semistatic[runliteral: 256]
            self.output.append(end.bits, count: end.length)

            self.matches.resetTerms()

        case .full:
            var index:Int = self.matches.startIndex
            while index < self.matches.endIndex
            {
                let upstream:UInt32 = self.matches[offset: index << 5]
                let count:Int       = .init(upstream >> 16)
                if count == 1
                {
                    let literal:UInt16 = .init(upstream & 0x00_00_00_ff)
                    let codeword:LZ77.Codeword = semistatic[runliteral: literal]
                    self.output.append(codeword.bits, count: codeword.length)
                }
                else
                {
                    let decade:(run:UInt8, distance:UInt8) =
                    (
                        run:        LZ77.Decades[run: count],
                        distance:   .init(truncatingIfNeeded: upstream >> 8)
                    )
                    let offset:UInt16 =
                        .init(self.matches[offset: index << 5 | (2 + .init(decade.distance))] >> 16)

                    let bits:(run:UInt16, distance:UInt16) =
                    (
                        run:        .init(count) - LZ77.Composites[run: decade.run].base,
                        distance:   offset - LZ77.Composites[distance: decade.distance].base
                    )

                    let codeword:(run:LZ77.Codeword, distance:LZ77.Codeword) =
                    (
                        run:        semistatic[runliteral:  256 | .init(decade.run)],
                        distance:   semistatic[distance:    decade.distance]
                    )

                    self.output.append(codeword.run.bits,      count: codeword.run.length)
                    self.output.append(bits.run,               count: codeword.run.extra)
                    self.output.append(codeword.distance.bits, count: codeword.distance.length)
                    self.output.append(bits.distance,          count: codeword.distance.extra)
                }

                index += count
            }
            // emit end-of-block code
            let end:LZ77.Codeword = semistatic[runliteral: 256]
            self.output.append(end.bits, count: end.length)

            self.matches.resetGraph()
        }
    }

    mutating
    func block(final:Bool)
    {
        let tree:
        (
            runliteral:LZ77.HuffmanTree<UInt16>,
            distance:LZ77.HuffmanTree<UInt8>,
            meta:LZ77.HuffmanTree<UInt8>
        )

        switch self.search
        {
        case .greedy, .lazy:
            (tree.runliteral, tree.distance) = self.matches.trees()
        case .full(attempts: _, goal: _, iterations: let iterations):
            (tree.runliteral, tree.distance) = self.matches.trees(iterations: iterations)
        }

        // there really should be a maximum of 316 combined symbols, not
        // 318, but the rfc 1951 specifies 218 for some reason
        var lengths:[UInt8] = .init(repeating: 0, count: 318)

        for (length, level):(UInt8, Range<Int>) in
            zip(1 ... 15, tree.runliteral.levels)
        {
            for symbol:UInt16 in tree.runliteral.symbols[level]
            {
                lengths[      .init(symbol)] = length
            }
        }
        // minimum of 257 runliteral codes
        let r:Int = max(257, lengths.prefix(286).reversed().drop{ $0 == 0 }.count)
        for (length, level):(UInt8, Range<Int>) in
            zip(1 ... 15, tree.distance.levels)
        {
            for symbol:UInt8 in tree.distance.symbols[level]
            {
                lengths[r + .init(symbol)] = length
            }
        }
        // minimum of 1 distance code
        let d:Int = max(1, lengths.dropFirst(r).prefix(32).reversed().drop{ $0 == 0 }.count)

        // segment into metaterms
        var repetitions:Int = 1,
            last:UInt8      = lengths[0]
        var iterator:ArraySlice<UInt8>.Iterator = lengths[1 ..< r + d].makeIterator(),
            terms:[LZ77.Deflator.Term.Meta]     = []
        while true
        {
            let current:UInt8? = iterator.next()

            if let literal:UInt8 = current, literal == last
            {
                repetitions += 1
            }
            else
            {
                if last == 0
                {
                    while repetitions > 138
                    {
                        terms.append(.zeros(count: 138))
                        repetitions -= 138
                    }
                    if repetitions > 2
                    {
                        terms.append(.zeros(count: repetitions))
                    }
                    else
                    {
                        terms.append(contentsOf:
                            repeatElement(.literal(last), count: repetitions))
                    }
                }
                else
                {
                    terms.append(.literal(last))
                    repetitions -= 1
                    while repetitions > 6
                    {
                        terms.append(.repeat(count: 6))
                        repetitions -= 6
                    }
                    if repetitions > 2
                    {
                        terms.append(.repeat(count: repetitions))
                    }
                    else
                    {
                        terms.append(contentsOf:
                            repeatElement(.literal(last), count: repetitions))
                    }
                }

                guard let literal:UInt8 = current
                else
                {
                    break
                }

                last        = literal
                repetitions = 1
            }
        }

        // construct metatree
        var frequencies:[Int] = .init(repeating: 0, count: 19)
        for term:LZ77.Deflator.Term.Meta in terms
        {
            frequencies[.init(term.symbol)] += 1
        }

        tree.meta = .init(frequencies: frequencies, limit: 7)

        self.blockStart(final: final, runliterals: r, distances: d, metatree: tree.meta)

        let semistatic:LZ77.Deflator.Semistatic = .init(
            runliteral: tree.runliteral,
            distance: tree.distance,
            meta: tree.meta)

        self.blockTables(terms, semistatic: semistatic)
        self.blockCompressed(semistatic: semistatic)

        /* let dicing:LZ77.Deflator.Dicing = .init(self.terms, unit: 1 << 12)
        self.block(dicing.startIndex, dicing: dicing, last: last)
        // empty literal buffer
        self.terms.removeAll(keepingCapacity: true) */
    }

    /* private mutating
    func block(_ index:Int, dicing:LZ77.Deflator.Dicing, last:Bool)
    {
        let semistatic:LZ77.Deflator.Semistatic,
            range:Range<Int>
        switch dicing[index]
        {
        case .interior(prefix: let a, suffix: let b):
            self.block(a, dicing: dicing, last: false)
            self.block(b, dicing: dicing, last: last)
            return

        case .leaf(terms: let terms, dynamic: nil):
            // fixed compression
            semistatic  = .fixed
            range       = terms
            self.output.append(last ? 0b01_1 : 0b01_0, count: 3)

        case .leaf(terms: let terms, dynamic:
            (
                codelengths:    let codelengths,
                runliterals:    let runliterals,
                distances:      let distances,
                metaterms:      let metaterms,
                tree:           let tree
            )?):
            // dynamic compression
            semistatic  = .init(runliteral: tree.runliteral, distance: tree.distance,
                meta: tree.meta)
            range       = terms
            self.output.append(last ? 0b10_1 : 0b10_0,  count: 3)

            self.output.append(.init(runliterals       - 257), count: 5)
            self.output.append(.init(distances         -   1), count: 5)
            self.output.append(.init(codelengths.count -   4), count: 4)
            for codelength:UInt16 in codelengths
            {
                self.output.append(codelength, count: 3)
            }
            for metaterm:LZ77.Deflator.Term.Meta in metaterms
            {
                let codeword:LZ77.Codeword = semistatic[meta: metaterm.symbol]
                self.output.append(codeword.bits, count: codeword.length)
                self.output.append(metaterm.bits, count: codeword.extra)
            }
        }

        for term:LZ77.Deflator.Term in self.terms[range]
        {
            let symbol:(runliteral:UInt16, distance:UInt8) = term.symbol
            let codeword:(runliteral:LZ77.Codeword, distance:LZ77.Codeword)

            codeword.runliteral = semistatic[runliteral: symbol.runliteral]

            self.output.append(codeword.runliteral.bits, count: codeword.runliteral.length)

            if symbol.runliteral > 256
            {
                // there are extra bits and a distance code to follow
                let bits:(run:UInt16, distance:UInt16) = term.bits

                codeword.distance = semistatic[distance: symbol.distance]

                self.output.append(bits.run,               count: codeword.runliteral.extra)
                self.output.append(codeword.distance.bits, count: codeword.distance.length)
                self.output.append(bits.distance,          count: codeword.distance.extra)
            }
        }

        // end-of-block symbol
        let end:LZ77.Codeword = semistatic[runliteral: 256]
        self.output.append(end.bits, count: end.length)
    } */

    mutating
    func checksum()
    {
        if case .ios = self.format
        {
            return
        }
        // checksum is written big-endian, which means it has to go into the
        // bitstream msb-first
        let checksum:UInt32 = self.input.checksum().byteSwapped
        self.output.pad(to: UInt8.self)
        self.output.append(.init(truncatingIfNeeded: checksum       ), count: 16)
        self.output.append(.init(                    checksum >>  16), count: 16)
    }
}
