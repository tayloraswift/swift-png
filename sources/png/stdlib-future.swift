// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// blocked by this: https://github.com/apple/swift/pull/22289
extension Sequence 
{
    @inlinable
    func count(where predicate:(Element) throws -> Bool) rethrows -> Int 
    {
        var count:Int = 0
        for e:Element in self where try predicate(e)   
        {
            count += 1
        }
        return count
    }
}
