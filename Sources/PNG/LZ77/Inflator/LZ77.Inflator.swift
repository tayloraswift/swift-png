//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

extension LZ77
{
    enum Symbol
    {
    }
}
extension LZ77.Symbol
{
    struct Meta:Pattern
    {
        //  8               0
        //  [c:c:c:s:s:s:s:s]
        //   ~~~~~^~~~~~~~~~^
        //   length    symbol
        private
        let storage:UInt8

        var symbol:UInt8
        {
            self.storage & 0b0001_1111
        }
        var length:Int
        {
            .init(self.storage >> 5)
        }

        init(_ symbol:UInt8, length:Int)
        {
            self.storage = .init(length) << 5 | symbol
        }
    }

    struct RunLiteral:Pattern
    {
        // 16               8               0
        //  [c:c:c:c: : : :s|s:s:s:s:s:s:s:s]
        //   ~~~~~~~^      ~~~~~~~~~~~~~~~~~^
        //     length                  symbol
        private
        let storage:UInt16

        var symbol:UInt16
        {
            self.storage & 0b0000_0001_1111_1111
        }
        var literal:UInt8
        {
            .init(truncatingIfNeeded: self.storage)
        }
        var decade:Int
        {
            .init(self.storage & 0b0000_0000_1111_1111)
        }
        var length:Int
        {
            .init(self.storage >> 12)
        }
        init(_ symbol:UInt16, length:Int)
        {
            self.storage = .init(length) << 12 | symbol
        }
    }
    struct Distance:Pattern
    {
        // 16               8               0
        //  [ : : : :c:c:c:c| : : :s:s:s:s:s]
        //           ~~~~~~~^      ~~~~~~~~~^
        //             length          symbol
        // length goes here because it is probably slightly faster to
        // address the high byte than do a UInt16 bit shift
        private
        let storage:UInt16

        var decade:Int
        {
            .init(self.storage & 0x00ff)
        }
        var length:Int
        {
            .init(self.storage >> 8)
        }
        init(_ symbol:UInt8, length:Int)
        {
            self.storage = .init(length) << 8 | .init(symbol)
        }
    }
}

extension LZ77
{
    struct Inflator
    {
        private
        var state:State
        private
        var stream:Stream
    }
}
extension LZ77.Inflator
{
    init(format:LZ77.Format = .zlib)
    {
        self.state  = .streamStart
        self.stream = .init(format: format)
    }

    // returns `nil` if the stream is finished
    mutating
    func push(_ data:[UInt8]) throws -> Void?
    {
        self.stream.input.rebase(data, pointer: &self.stream.b)
        while let _:Void = try self.advance()
        {
        }
        if case .streamEnd = self.state
        {
            return nil
        }
        else
        {
            return ()
        }
    }
    mutating
    func pull(_ count:Int) -> [UInt8]?
    {
        self.stream.output.exclude()
        return self.stream.output.release(bytes: count)
    }
    mutating
    func pull() -> [UInt8]
    {
        self.stream.output.exclude()
        return self.stream.output.release()
    }

    // returns nil if unable to advance
    private mutating
    func advance() throws -> Void?
    {
        // pool cow-exclusions here instead of checking the reference count
        // on every loop iteration
        self.stream.meta.exclude()
        self.stream.output.exclude()
        switch self.state
        {
        case .streamStart:
            guard let window:Int = try self.stream.start()
            else
            {
                return nil
            }
            self.stream.output.window   = window
            self.state                  = .blockStart

        case .blockStart:
            guard let (final, compression):(Bool, Stream.Compression) =
                try self.stream.blockStart()
            else
            {
                return nil
            }

            switch compression
            {
            case .dynamic(runliterals: let runliterals, distances: let distances):
                self.state = .blockTables(final: final,
                    runliterals: runliterals, distances: distances)

            case .fixed:
                self.state = .blockCompressed(final: final, semistatic: .fixed)

            case .none(bytes: let count):
                // compute endindex
                let end:Int = self.stream.output.endIndex + count
                self.state = .blockUncompressed(final: final, end: end)
            }

            #if DUMP_LZ77_BLOCKS
            print("< \(compression)")
            #endif

        case .blockTables(final: let final, runliterals: let runliterals, distances: let distances):
            guard let (runliteral, distance):(LZ77.Huffman<UInt16>, LZ77.Huffman<UInt8>) =
                try self.stream.blockTables(runliterals: runliterals, distances: distances)
            else
            {
                return nil
            }

            self.state = .blockCompressed(final: final,
                semistatic: .init(runliteral: runliteral, distance: distance))

        case .blockUncompressed(final: let final, end: let end):
            guard let _:Void = try self.stream.blockUncompressed(end: end)
            else
            {
                return nil
            }
            self.state = final ? .streamChecksum : .blockStart

        case .blockCompressed(final: let final, semistatic: let semistatic):
            guard let _:Void = try self.stream.blockCompressed(semistatic: semistatic)
            else
            {
                return nil
            }
            self.state = final ? .streamChecksum : .blockStart

        case .streamChecksum:
            guard let _:Void = try self.stream.checksum()
            else
            {
                return nil
            }
            self.state = .streamEnd
        case .streamEnd:
            return nil
        }

        return ()
    }
}
