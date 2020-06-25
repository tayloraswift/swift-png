# swift optimization notes

As part of version 4.0 of Swift *PNG*, i’ve replaced the system *libz* dependency with a native Swift implementation. Because Swift is often percieved in the software industry as being a higher-level, and therefore, less efficient language compared to C and C++, it is important to ensure that switching to a native implementation does not degrade performance for users. 

Reasonably well-written Swift code can easily achieve down to a 2–2.5x run time compared to a bare-metal C implementation. (Lower is better.) However, with careful measurement and optimization, Swift *PNG* with a pure Swift LZ77 implementation is now (as of [`075c9f7`](https://github.com/kelvin13/png/commit/075c9f7df0c7bef224f8ca9a020dc009ac3ddd2c)) running within 15% of its former performance. Given that *libz* is a decades-old C library with a number of hardware specific optimizations, this is significant.

This page documents several techniques i found effective for improving the run time performance of Swift applications without resorting to “writing C in `.swift` files”. (That is, without resorting to C-like idioms and design patterns.) It also highlights a few pitfalls that often afflict Swift programmers trying to optimize Swift code.

These tips are relevant as of version 5.2 of the Swift compiler. (The only reason i say this is because a few of the classical boogeymen in the Swift world, like “““objective-c bridging””” and “““reference counting overhead””” are no longer as important as they once were.)

## 1. use `UnmanagedBuffer` instead of `UnsafeMutableBufferPointer`

Many Swift programmers try to make `Array`s faster by switching to `UnsafeBufferMutablePointer` and related APIs, and performing manual memory management, as you would in C or C++. Of course, this often causes problems when integrated into a larger Swift codebase since the language is geared around value semantics and automated memory management. A commonly-perscribed remedy is to wrap the buffer pointer in a `class`, which lets you do cleanup using the class’s `deinit` method. But this has the performance drawback of placing the buffer’s storage behind two layers of heap indirection (one for the `class`, and one for the unsafe buffer.)

A better solution is to use `UnmanagedBuffer<Header, Element>`, which allows you to store buffer elements inline in the allocation of the `class`.

## 2. don’t put `count` and `capacity` in the buffer header

In general, `Array` bounds checks are *not* what causes `Array`s to be slower than `UnmanagedBuffer`s, but rather the accesses to the `count` and `capacity` properties stored in the header of the `Array`. It follows that attempting to reimplement an `Array` using an `UnmanagedBuffer` with the buffer parameters in the inline `Header` will not improve performance over the original `Array`. In fact, moving additional properties that would have otherwise gone into a wrapping `struct` containing an array into the `Header` can actually worsen performance. 

The reason this happens has to do with the memory access pattern of buffer reads and writes compared to typical memory access patterns when using dynamic arrays in general. Buffer reads and writes almost always form a streaming pattern where accesses move away from the front of the buffer over time. However, because `count` and `capacity` live inline at the front of the buffer, this forces the processor to switch back and forth between increasingly distant memory locations. To fix this, set the buffer’s `Header` type to `Void`, and store the `count` and `capacity` in a `struct` that also contains the `UnmanagedBuffer`. Now, the `count`, `capacity`, and pointer to the buffer head (the `class` reference) all live on the stack. As long as you have implemented the wrapping structure’s copy-on-write functionality correctly, doing this will have no effect on the buffer’s semantics.

This is especially important if you are storing sub-buffers at dynamic offsets within your buffer. Storing sub-buffer offsets inline within an `UnmanagedBuffer` is no better than wrapping an `UnsafeMutableBufferPointer` in a `class`.

Why is `Array` not implemented like this? One reason is that the `Array` type would now have a footprint of three words (one for the storage pointer, one for the `count`, and one for the `capacity`.) In addition, the standard library assumes that element reads and writes are uniformly distributed across the array, or even clustered near the beginning. And in most cases, `Array`s being used as buffers are much, much larger than a ‘typical’ `Array`. This means that normally, accessing `count` and `capacity` is not a problem, and an `Array` is better off represented with just a single word — the storage pointer.

## 3. avoid `@inline(__always)`

Many people treat `@inline(__always)` as a magical *make this faster* keyword that you can just sprinkle around the hot paths of your code. This is not the case. Blindly adding `@inline(__always)` annotations can actually slow your code down. The reason for this is that inlining functions increases code size, meaning that the processor now needs additional cache space just to load its instructions. Remember that cache-friendliness as a concept applies to code, as well as data! While inlining can improve performance, the compiler almost always makes better inlining decisions than you will, so you’re better off avoiding this attribute. 

For that matter, while there’s rarely a reason to use it directly, `@inline(never)` can be a useful tool for determining how inlining is impacting the performance of your code. The compiler can also be a little over-aggressive when it comes to inlining, so in rare cases, explicitly adding this annotation can actually help performance.

> Note: `@inline(__always)` is not the same as `@inlinable`, which almost always *does* improve performance (for downstream module users), and absolutely *should* be used when ABI considerations allow for it.

## 4. don’t use capture lists if you don’t need to

Some people coming from a C background hear the word *closure context* and immediately start imagining horrifying scenarios where every variable access from the enclosing scope is doubly reference-counted and hidden behind twelve layers of indirection. As such, people will try to “localize” enclosed variables by adding them to the closure’s capture list. Of course, this is not how the vast majority of closures in Swift work.

As long as the closure is a “simple” closure (meaning, it’s non `@escaping`), it will execute just like a normal function call. For a closure, accessing enclosed variables, including `self`, is just a matter of accessing values in the stack frame immediately below the closure’s own frame, which is rarely more than a few bytes away.

Adding enclosed variables to the closure’s capture list will often harm performance because now, the captured variables have to be pushed onto the stack whenever the closure is called, just so that it has a fresh copy for itself. So in effect, captured variables are just additional function arguments which will incur function call overhead. The upshot here is don’t use capture lists unless they are actually meaningful to the semantics of the closure.

## 5. don’t manually vectorize loops

Swift is very good at automatically vectorizing vectorizable loops. Sometimes it will even vectorize things you never thought could be vectorized. Naturally, this means trying to do it yourself with the various standard library `SIMD` constructs is just going to get in the way, and can often make your code slower, not faster.

If you want to make sure a loop gets vectorized, just make sure the loop body is vectorizable, so that the compiler can do what it does best. For example, make sure arithmetic accumulations in the loop body don’t trap (use `&+` and not `+`).

## 6. avoid wrapping arithmetic and truncating integers

Some people think of the `&`’d operations as magical “fast math” operators. (In some respects, it’s a lot like `@inline(__always)`.) This is not true. In terms of speed, `&+` and friends are about as fast as `+` and friends. The reason for this is that the overflow check that comes with `+` always takes the same branch (the non-trapping path), so this branch is effectively free. At the same time, unwise usage of `&+` can actually inhibit other compiler optimizations. For example, adding two positive `Int`s with `+` can never produce a negative result, but adding two positive `Int`s with `&+` can. This means that, for example, a subsequent `Array` bounds check could have skipped its routine “is this index negative” sanity check if you had stuck with `+` instead of using `&+`.

In general, only use the wrapping operators if you actually intend to use their wrapping semantics. (This includes satisfying vectorization conditions.) Important exceptions to this rule-of-thumb are the masking shift operators (`&<<` and `&>>`), which usually *do* run faster than the non-masking operators (`<<` and `>>`). This is because, unlike the other arithmetic operators, the branches in `<<` and `>>` are often poorly-predicted. The remedy for this is to perform the shift using a wider integer type and a masking shift.

All of the above advice also applies to the integer conversion APIs: `init(_:)` and `init(truncatingIfNeeded:)`.

> Note: don’t bother using `&<<` and `&>>` if the shift argument is a literal value. The compiler obviously won’t emit a branch if the shift is a compile-time constant.

## 7. use shorter integer types for buffer elements 

Philosophically, Swift encourages you to exclusively use `Int` for modeling numerical values, and avoid width-specific types like `Int32`, `Int16`, etc. For most integer properties, this is good advice. But for large *N*, it’s worthwhile to use the shorter integer types as backing storage, to improve memory locality, especially for arrays used as lookup tables. In general, for a/an:

* Property in a `class`:

  Use an `Int`. (The `class` is already heap-allocated anyway.)
  
* Property in a `struct` not used as an array element:

  Use an `Int`. 
  
* Property in a `struct` used as an array element:

  Use an `Int` with a property wrapper backed by a shorter integer type.

* Array element:

  Use a shorter integer type, and cast at the usage site.

## 8. don’t use `Dictionary.init(grouping:by:)` 

This is probably more of a bug in the standard library than an inherent language issue, but as of Swift 5.2, `Dictionary.init(grouping:by:)` seems to exhibit exceptionally poor performance, compared to a naive two-pass bucketing algorithm. (One pass to determine the sub-array counts, and one pass to populate the sub-arrays.) 

Only use `Dictionary.init(grouping:by)` if you have a single-pass `Sequence` and absolutely need the `[Key: [Element]]` output format.

## 9. some C/C++ advice still applies 

Some advice for optimizing C or C++ code still applies to Swift, namely:

* A consolidated storage array combined with an array of `Range<Int>` intervals is faster than a nested array, due to improved memory locality.

* Properly-aligned consolidated lookup tables are faster than separately-allocated lookup tables, due to improved memory locality.

* Bit shifting by a multiple of 8 is faster than shifting by a non-multiple of 8, since the first case translates into a simple byte-level load and store. This means it is faster to first build a wide integer out of component bytes, and then shift the wide integer, than to shift the components individually.

* Bit twiddling isn’t free. It is faster to read from a small lookup table (less than 512 bytes) living in the L1 cache than it is to execute a sequence of more than 5 or 6 arithmetic/logic instructions.
