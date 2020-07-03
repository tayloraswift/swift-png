//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/. 

extension LZ77.Huffman 
{
    struct Codeword 
    {
        let bits:UInt16 
        @General.Storage<UInt8> 
        var length:Int 
    }
}
extension LZ77.Huffman where Symbol:BinaryInteger 
{
    func codewords(initializing destination:UnsafeMutablePointer<Codeword>, count:Int) 
    {
        // initialize all entries to 0, as symbols with frequency 0 are omitted 
        // from self.symbols 
        destination.initialize(repeating: .init(bits: 0, length: 0), count: count)
        
        var counter:UInt16  = 0
        for (length, level):(Int, Range<Int>) in zip(1 ... 15, self.levels) 
        {
            for symbol:Symbol in self.symbols[level]
            {
                destination[.init(symbol)]  = .init(bits: counter, length: length)
                counter                    += 1
            }
            
            counter <<= 1
        }
    }
    
    init(frequencies:[Int]) 
    {
        // sort non-zero symbols by (decreasing) frequency
        let symbols:[Symbol] = frequencies.indices.compactMap 
        {
            frequencies[$0] > 0 ? .init($0) : nil 
        }.sorted
        {
            frequencies[.init($0)] > frequencies[.init($1)]
        }
        
        // cover 0-symbol and 1-symbol cases 
        guard let first:Symbol = symbols.first 
        else 
        {
            self.init(symbols: [], 
                levels:             .init(repeating: 0 ..< 0, count: 15))
            return 
        }
        guard symbols.count > 1 
        else 
        {
            self.init(symbols: [first, first], 
                levels: [0 ..< 2] + .init(repeating: 2 ..< 2, count: 14))
            return 
        }
        
        // reversing (to get canonically sorted array) gets the heapify below 
        // to its best-case O(n) time, not that O matters for n = 256 
        var heap:General.Heap<Int, [Int]> = .init(symbols.reversed().map  
        {
            (frequencies[.init($0)], [1])
        })
        
        // standard huffman tree construction algorithm. builds a list of leaf-level 
        // counts, with the root count at the end 
        while let first:(key:Int, value:[Int]) = heap.dequeue() 
        {
            if let second:(key:Int, value:[Int]) = heap.dequeue() 
            {
                var merged:[Int] 
                let mergee:[Int]
                if first.value.count > second.value.count 
                {
                    merged = first.value 
                    mergee = second.value 
                }
                else 
                {
                    merged = second.value 
                    mergee = first.value 
                }
                for (i, k):(Int, Int) in zip(merged.indices.reversed(), mergee)
                {
                    merged[i] += k
                }
                merged.append(0)
                heap.enqueue(key: first.key + second.key, value: merged)
                continue 
            }
            
            // drop the first (last) level count, since it corresponds to 
            // the tree root, and convert level counts to codeword assignments 
            let leaves:[Int] = Self.limitHeight(first.value.dropLast().reversed(), to: 15)
            // split symbols list into levels 
            let levels:[Range<Int>] = .init(unsafeUninitializedCapacity: 15) 
            {
                var base:Int = symbols.startIndex 
                for (i, count):(Int, Int) in zip($0.indices, leaves)
                {
                    $0[i] = base ..< base + count 
                    base += count 
                }
                // symbols array must have length exactly equal to 16
                for i:Int in $0.indices.dropFirst(leaves.count) 
                {
                    $0[i] = base ..< base
                }
                $1 = $0.count 
            }
            
            self.init(symbols: symbols, levels: levels)
            return  
        }
        
        fatalError("unreachable")
    }
    
    // limit the height of the generated tree to the given height
    private static 
    func limitHeight<S>(_ uncompacted:S, to height:Int) -> [Int] 
        where S:Sequence, S.Element == Int
    {
        var levels:[Int] = .init(uncompacted)
        guard levels.count > height
        else 
        {
            return levels 
        }
        
        // collect unhoused nodes: from the bottom to level 17, we gather up 
        // node pairs (since huffman trees are always full trees). one of the 
        // child nodes gets promoted to the level above, the other node goes 
        // into a pool of unhoused nodes 
        var unhoused:Int = 0 
        for l:Int in (height ..< levels.endIndex).reversed() 
        {
            assert(levels[l] & 1 == 0)
            
            let pairs:Int  = levels[l] >> 1
            unhoused      += pairs 
            levels[l - 1] += pairs 
        }
        levels.removeLast(levels.count - height)
        
        // for the remaining unhoused nodes, our strategy is to look for a level 
        // at least 1 step above the bottom (meaning, indices 0 ..< 15) and split 
        // one of its leaves, reducing the leaf count of that level by 1, and 
        // increasing the leaf count of the level below it by 2
        var split:Int = height - 2
        while unhoused > 0 
        {
            guard levels[split] > 0 
            else 
            {
                split -= 1
                // traversal pattern should make it impossible to go below 0 so 
                // long as total leaf population is less than 2^16 (it can never 
                // be greater than 300 anyway)
                assert(split > 0)
                continue 
            }
            
            let resettled:Int  = min(levels[split], unhoused)
            unhoused          -=     resettled 
            levels[split]     -=     resettled 
            levels[split + 1] += 2 * resettled 
            
            if split < height - 2 
            {
                // since we have added new leaves to this level
                split += 1
            } 
        }
        
        return levels
    }
}

extension LZ77.Deflator 
{
    struct In 
    {
        private 
        let window:Int 
        private 
        var currentIndex:Int, 
            endIndex:Int 
        
        private 
        var capacity:Int
        private 
        var storage:ManagedBuffer<Void, UInt8>
    }
}
extension LZ77.Deflator.In 
{
    var count:Int 
    {
        self.endIndex
    }
    
    init(window:Int) 
    {
        self.window         = window 
        self.currentIndex   = 0 
        self.endIndex       = 0 
        
        var capacity:Int    = 0
        self.storage = .create(minimumCapacity: 0)
        {
            capacity = $0.capacity 
            return ()
        }
        self.capacity       = capacity
    }
}

extension LZ77 
{
    struct Deflator 
    {
    }
}
