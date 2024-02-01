//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

extension LZ77
{
    @frozen public
    struct Deflator
    {
        private
        var buffers:DeflatorBuffers<LZ77.Format>

        public
        init(format:LZ77.Format = .zlib, level:Int, exponent:Int = 15, hint:Int = 1 << 12)
        {
            self.buffers = .init(format: format, level: level, exponent: exponent, hint: hint)
        }
    }
}
extension LZ77.Deflator
{
    public mutating
    func push(_ data:ArraySlice<UInt8>, last:Bool = false)
    {
        self.buffers.push(data, last: last)
    }

    /// Returns a block of compressed data from this deflator, if available. If no compressed
    /// data blocks have been completed yet, this method flushes and returns the incomplete
    /// block.
    public mutating
    func pull() -> [UInt8]?
    {
        self.buffers.pull()
    }

    /// Removes and returns a complete block of compressed data from this deflator, if
    /// available.
    public mutating
    func pop() -> [UInt8]?
    {
        self.buffers.pop()
    }
}
