#if DEBUG
@testable
import LZ77
import Testing

extension Main
{
    enum F14
    {
    }
}
extension Main.F14:TestBattery
{
    static
    func run(tests:TestGroup)
    {
        let dictionary:F14.HashTable = .init(exponent: 10)

        tests.expect(nil: dictionary.update(key: 0, value: 1))
        tests.expect(nil: dictionary.update(key: 1, value: 2))
        tests.expect(dictionary.update(key: 0, value: 3) ==? 1)
        tests.expect(nil: dictionary.update(key: 2, value: 4))
        tests.expect(value: dictionary.remove(key: 1, value: 5))
        tests.expect(dictionary.update(key: 1, value: 6) ==? 2)
        tests.expect(value: dictionary.remove(key: 1, value: 6))
        tests.expect(nil: dictionary.update(key: 1, value: 7))

        var a:F14.HashTable    = .init(exponent: 15),
            b:[UInt32: UInt16]      = [:]
        for i:UInt16 in ((0 ... .max).map{ $0 & 0x00ff })
        {
            let key:UInt32 = .random(in: 0 ... 1000)

            tests.expect(a.update(key: key, value: i) ==? b.updateValue(i, forKey: key))
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

            tests.expect(a.update(key: key, value: i) ==? b.updateValue(i, forKey: key))
        }
    }
}
#endif
