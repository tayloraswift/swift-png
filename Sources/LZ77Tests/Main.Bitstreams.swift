#if DEBUG
@testable
import LZ77
import Testing

extension Main
{
    enum Bitstreams
    {
    }
}
extension Main.Bitstreams:TestBattery
{
    static
    func run(tests:TestGroup)
    {
        if  let tests:TestGroup = tests / "Decode"
        {
            var bits:LZ77.InflatorIn =
            [
                0b1001_1110,
                0b1111_0110,
                0b0010_0011,
            ]
            tests.expect(bits[ 0] ==? 0b1111_0110_1001_1110)
            tests.expect(bits[ 1] ==? 0b1_1111_0110_1001_111)
            tests.expect(bits[ 2] ==? 0b11_1111_0110_1001_11)
            tests.expect(bits[ 3] ==? 0b011_1111_0110_1001_1)
            tests.expect(bits[ 4] ==? 0b0011_1111_0110_1001)
            tests.expect(bits[ 5] ==? 0b0_0011_1111_0110_100)
            tests.expect(bits[ 6] ==? 0b10_0011_1111_0110_10)
            tests.expect(bits[ 7] ==? 0b010_0011_1111_0110_1)
            tests.expect(bits[ 8] ==? 0b0010_0011_1111_0110)
            tests.expect(bits[ 9] ==? 0b0_0010_0011_1111_011)
            tests.expect(bits[23] ==? 0b0000_0000_0000_0000)

            tests.expect(bits[0, count:  4, as: Int.self] ==?                   0b1110)
            tests.expect(bits[1, count:  4, as: Int.self] ==?                 0b1_111)
            tests.expect(bits[1, count:  6, as: Int.self] ==?               0b001_111)
            tests.expect(bits[2, count:  6, as: Int.self] ==?              0b1001_11)
            tests.expect(bits[2, count: 16, as: Int.self] ==? 0b11_1111_0110_1001_11)

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

            tests.expect(bits[b    ] ==? 0b1000_1010_1101_0010)
            tests.expect(bits[b + 1] ==? 0b1_1000_1010_1101_001)

            // test rebase
            //                       { 0001_1000, 1010_1101, 0010_0011 }
            //                                                  ^
            //                                                b = 4
            // { 1111_1100, 0011_1111, 0001_1000, 1010_1101, 0010_0011 }
            bits.rebase([0b0011_1111, 0b1111_1100], pointer: &b)

            tests.expect(bits[b    ] ==? 0b1000_1010_1101_0010)
            tests.expect(bits[b + 8] ==? 0b1111_0001_1000_1010)
        }
        if  let tests:TestGroup = tests / "Encode"
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

            tests.expect(encoded ..?
            [
                0b1101_1011,
                0b1011_1111,
                0b1010_1010,
                0b1000_1010,
                0b1110_1101,
                0b0000_0000,
                0b0000_0001
            ])
        }
    }
}
#endif
