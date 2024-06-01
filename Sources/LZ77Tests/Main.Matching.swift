#if DEBUG
@testable
import LZ77
import Testing_

extension Main
{
    enum Matching
    {
    }
}
extension Main.Matching:TestBattery
{
    static
    func run(tests:TestGroup)
    {
        let segments:[[UInt8]] =
        [
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
        tests.expect(output ..?
        [
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
