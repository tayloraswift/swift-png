#if DEBUG
@testable
import LZ77
import Testing

@Suite
enum CompressionInternals
{
    @Test
    static func BitstreamDecoding()
    {
        var bits:LZ77.InflatorIn = [
            0b1001_1110,
            0b1111_0110,
            0b0010_0011,
        ]
        #expect(bits[ 0] == 0b1111_0110_1001_1110)
        #expect(bits[ 1] == 0b1_1111_0110_1001_111)
        #expect(bits[ 2] == 0b11_1111_0110_1001_11)
        #expect(bits[ 3] == 0b011_1111_0110_1001_1)
        #expect(bits[ 4] == 0b0011_1111_0110_1001)
        #expect(bits[ 5] == 0b0_0011_1111_0110_100)
        #expect(bits[ 6] == 0b10_0011_1111_0110_10)
        #expect(bits[ 7] == 0b010_0011_1111_0110_1)
        #expect(bits[ 8] == 0b0010_0011_1111_0110)
        #expect(bits[ 9] == 0b0_0010_0011_1111_011)
        #expect(bits[23] == 0b0000_0000_0000_0000)

        #expect(bits[0, count:  4, as: Int.self] ==                   0b1110)
        #expect(bits[1, count:  4, as: Int.self] ==                 0b1_111)
        #expect(bits[1, count:  6, as: Int.self] ==               0b001_111)
        #expect(bits[2, count:  6, as: Int.self] ==              0b1001_11)
        #expect(bits[2, count: 16, as: Int.self] == 0b11_1111_0110_1001_11)

        // test rebase
        //                       { 0010_0011, 1111_0110, 1001_1110 }
        //                            ^
        //                          b = 20
        // ->
        // { 0001_1000, 1010_1101, 0010_0011 }
        //                            ^
        //                          b = 4
        var b:Int = 20

        bits.rebase([0b1010_1101, 0b0001_1000], pointer: &b)

        #expect(bits[b    ] == 0b1000_1010_1101_0010)
        #expect(bits[b + 1] == 0b1_1000_1010_1101_001)

        // test rebase
        //                       { 0001_1000, 1010_1101, 0010_0011 }
        //                                                  ^
        //                                                b = 4
        // { 1111_1100, 0011_1111, 0001_1000, 1010_1101, 0010_0011 }
        bits.rebase([0b0011_1111, 0b1111_1100], pointer: &b)

        #expect(bits[b    ] == 0b1000_1010_1101_0010)
        #expect(bits[b + 8] == 0b1111_0001_1000_1010)
    }
    @Test
    static func BitstreamEncoding()
    {
        var bits:LZ77.DeflatorOut = .init(hint: 4)

        bits.append(0b11, count: 2)
        bits.append(0b01_10, count: 4)

        bits.append(0b0110, count: 0)

        bits.append(0b1_1111_11, count: 7)
        bits.append(0b1010_1010_1010_101, count: 15)
        bits.append(0b000, count: 3)
        bits.append(0b0_1101_1, count: 6)
        bits.append(0b1_0000_0000_111, count: 12)

        var encoded:[UInt8] = []

        while let chunk:[UInt8] = bits.pop()
        {
            encoded.append(contentsOf: chunk)
        }

        encoded.append(contentsOf: bits.pull())

        #expect(encoded == [
                0b1101_1011,
                0b1011_1111,
                0b1010_1010,
                0b1000_1010,
                0b1110_1101,
                0b0000_0000,
                0b0000_0001
            ])
    }

    @Test
    static func Matching()
    {
        let segments:[[UInt8]] = [
            [1, 2, 3, 3, 1, 2, 3, 3, 1, 2, 3, 1, 2, 2, 2, 2, 2, 2, 0, 1, 2],
            [2, 2, 2, 2, 0, 1, 2, 2, 0, 0, 0, 0, 2, 3, 2, 1, 2, 3, 3, 1, 5],
            [1, 1, 3, 3, 1, 2, 3, 1, 2, 4, 4, 2, 1]
        ]
        var input:LZ77.DeflatorIn<LZ77.MRC32> = .init()
        var window:LZ77.DeflatorWindow = .init(exponent: 4)
        var output:[[UInt8]] = []
        for (s, segment):(Int, [UInt8]) in segments.enumerated()
        {
            input.enqueue(contentsOf: segment[...])

            let lookahead:Int = (s == segments.count - 1 ? 0 : 10)
            while window.endIndex < 0, input.count > lookahead
            {
                window.initialize(with: input.dequeue())
            }
            while input.count > lookahead
            {
                let head:(index:Int, next:UInt16?) = window.update(with: input.dequeue())
                if  let match:(run:Int, distance:Int) = window.match(from: head,
                        lookahead: input,
                        attempts: .max,
                        goal: .max)
                {
                    var run:[UInt8] = [window.literal]
                    for _:Int in 1 ..< match.run
                    {
                        window.update(with: input.dequeue())
                        run.append(window.literal)
                    }
                    output.append(run)
                }
                else
                {
                    output.append([window.literal])
                }
            }

            guard s == segments.count - 1
            else
            {
                continue
            }

            // epilogue: get the matches still sitting in the pipeline
            let epilogue:Int = -3 - min(0, window.endIndex)
            while input.count > epilogue
            {
                window.update(with: input.dequeue())
                output.append([window.literal])
            }
        }
        #expect(output == [
                [1],
                [2],
                [3],
                [3],
                [1, 2, 3, 3, 1, 2, 3],
                [1],
                [2], [2], [2], [2], [2], [2],
                [0],
                [1, 2, 2, 2, 2, 2],
                [0],
                [1],
                [2], [2],
                [0], [0], [0], [0],
                [2],
                [3],
                [2],
                [1],
                [2],
                [3], [3],
                [1],
                [5],
                [1], [1],
                [3], [3],
                [1],
                [2],
                [3],
                [1],
                [2],
                [4], [4],
                [2],
                [1]
            ])
    }
}
#endif
