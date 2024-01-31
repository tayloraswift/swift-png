//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

extension LZ77
{
    @frozen public
    struct Inflator
    {
        typealias Format = DeflateFormat

        private
        let format:DeflateFormat
        private
        var stream:Stream<MRC32>
        private
        var state:InflatorState
    }
}
extension LZ77.Inflator
{
    public
    init(format:LZ77.DeflateFormat = .zlib)
    {
        self.format = format
        self.stream = .init()
        self.state  = .streamStart
    }
}
extension LZ77.Inflator
{
    // returns `nil` if the stream is finished
    public mutating
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
    public mutating
    func pull(_ count:Int) -> [UInt8]?
    {
        self.stream.output.exclude()
        return self.stream.output.release(bytes: count)
    }
    public mutating
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
            guard
            let header:Format.Header = try self.format.begin(inflating: &self.stream.input,
                at: &self.stream.b)
            else
            {
                return nil
            }
            self.stream.output.window   = header.window
            self.state                  = .blockStart

        case .blockStart:
            guard
            let (final, type):(Bool, LZ77.BlockType) = try self.stream.blockStart()
            else
            {
                return nil
            }

            switch type
            {
            case .dynamic(runliterals: let runliterals, distances: let distances):
                self.state = .blockTables(final: final,
                    runliterals: runliterals, distances: distances)

            case .fixed:
                self.state = .blockCompressed(final: final, semistatic: .fixed)

            case .bytes(let count):
                // compute endindex
                let end:Int = self.stream.output.endIndex + count
                self.state = .blockUncompressed(final: final, end: end)
            }

            #if DUMP_LZ77_BLOCKS
            print("< \(type)")
            #endif

        case .blockTables(final: let final, runliterals: let runliterals, distances: let distances):
            guard
            let (runliteral, distance):(LZ77.HuffmanTree<UInt16>, LZ77.HuffmanTree<UInt8>) =
                try self.stream.blockTables(runliterals: runliterals, distances: distances)
            else
            {
                return nil
            }

            self.state = .blockCompressed(final: final,
                semistatic: .init(runliteral: runliteral, distance: distance))

        case .blockUncompressed(final: let final, end: let end):
            guard
            let _:Void = try self.stream.blockUncompressed(end: end)
            else
            {
                return nil
            }
            self.state = final ? .streamChecksum : .blockStart

        case .blockCompressed(final: let final, semistatic: let semistatic):
            guard
            let _:Void = try self.stream.blockCompressed(semistatic: semistatic)
            else
            {
                return nil
            }
            self.state = final ? .streamChecksum : .blockStart

        case .streamChecksum:
            guard
            let declared:UInt32? = self.format.check(inflating: &self.stream.input,
                at: &self.stream.b)
            else
            {
                return nil
            }

            try self.stream.check(declared: declared)
            self.state = .streamEnd

        case .streamEnd:
            return nil
        }

        return ()
    }
}
