//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

extension LZ77
{
    @frozen public
    struct Deflator
    {
        private
        var stream:Stream
    }
}
extension LZ77.Deflator
{
    public
    init(format:LZ77.Format = .zlib, level:Int, exponent:Int = 15, hint:Int = 1 << 12)
    {
        let e:Int
        switch format
        {
        case .zlib: e = exponent
        case .ios : e = 15
        }

        self.stream = .init(format: format, level: level, exponent: e, hint: hint)
        self.stream.start(exponent: e)
    }

    public mutating
    func push(_ data:ArraySlice<UInt8>, last:Bool = false)
    {
        // rebase input buffer
        if !data.isEmpty
        {
            self.stream.input.enqueue(contentsOf: data)
        }
        guard self.stream.input.count > 4096 || last
        else
        {
            return
        }

        while let _:Void = self.stream.compress(all: last)
        {
            self.stream.block(final: false)
        }
        if last
        {
            self.stream.block(final: true)
            self.stream.checksum()
        }
    }

    /// Returns a block of compressed data from this deflator, if available. If no compressed
    /// data blocks have been completed yet, this method flushes and returns the incomplete
    /// block.
    public mutating
    func pull() -> [UInt8]?
    {
        if  let complete:[UInt8] = self.pop()
        {
            return complete
        }

        let flushed:[UInt8] = self.stream.output.pull()
        return flushed.isEmpty ? nil : flushed
    }

    /// Removes and returns a complete block of compressed data from this deflator, if
    /// available.
    public mutating
    func pop() -> [UInt8]?
    {
        self.stream.output.pop()
    }
}
