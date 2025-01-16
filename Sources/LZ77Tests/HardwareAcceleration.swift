#if DEBUG
@testable
import LZ77
import Testing

@Suite
enum HardwareAcceleration
{
    @Test
    static func DictionarySemantics()
    {
        let dictionary:F14.HashTable = .init(exponent: 10)

        #expect(nil == dictionary.update(key: 0, value: 1))
        #expect(nil == dictionary.update(key: 1, value: 2))
        #expect(dictionary.update(key: 0, value: 3) == 1)
        #expect(nil == dictionary.update(key: 2, value: 4))
        #expect(nil != dictionary.remove(key: 1, value: 5))
        #expect(dictionary.update(key: 1, value: 6) == 2)
        #expect(nil != dictionary.remove(key: 1, value: 6))
        #expect(nil == dictionary.update(key: 1, value: 7))

        var a:F14.HashTable    = .init(exponent: 15),
            b:[UInt32: UInt16]      = [:]
        for i:UInt16 in ((0 ... .max).map{ $0 & 0x00ff })
        {
            let key:UInt32 = .random(in: 0 ... 1000)

            #expect(a.update(key: key, value: i) == b.updateValue(i, forKey: key))
        }
        for i:UInt16 in ((0 ... .max).map{ $0 & 0x00ff })
        {
            let key:UInt32 = .random(in: 0 ... 1000)

            if  b[key] == i
            {
                b[key] = nil
            }

            a.remove(key: key, value: i)
        }
        for i:UInt16 in ((0 ... .max).map{ $0 & 0x00ff })
        {
            let key:UInt32 = .random(in: 0 ... 1000)

            #expect(a.update(key: key, value: i) == b.updateValue(i, forKey: key))
        }
    }
}
#endif
