//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.

extension LZ77
{
    @frozen public
    struct Inflator
    {
        private
        var buffers:InflatorBuffers<LZ77.Format>
        private
        var state:InflatorState
    }
}
extension LZ77.Inflator
{
    public
    init(format:LZ77.Format = .zlib)
    {
        self.buffers = .init(format: format)
        self.state = .initial
    }
}
extension LZ77.Inflator
{
    /// Pushes **compressed** data to the inflator, returning nil once a complete DEFLATE
    /// stream has been received.
    public mutating
    func push(_ data:ArraySlice<UInt8>) throws -> Void?
    {
        self.buffers.stream.input.rebase(data, pointer: &self.buffers.stream.b)

        advancing:
        do
        {
            switch try self.buffers.advance(state: self.state)
            {
            case .terminal?:
                return nil

            case let next?:
                self.state = next
                continue advancing

            case nil:
                return ()
            }
        }
    }

    public mutating
    func pull(_ count:Int) -> [UInt8]?
    {
        self.buffers.stream.output.exclude()
        return self.buffers.stream.output.release(bytes: count)
    }
    public mutating
    func pull() -> [UInt8]
    {
        self.buffers.stream.output.exclude()
        return self.buffers.stream.output.release()
    }
}
