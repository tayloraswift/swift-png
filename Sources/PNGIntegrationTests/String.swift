// import PNG

// extension String
// {
//     // prints an image using terminal colors 
//     static 
//     func terminal<T>(image rgb:[PNG.RGBA<T>], size:(x:Int, y:Int)) -> String
//         where T:FixedWidthInteger & UnsignedInteger
//     {
//         let downsample:Int = Swift.min(Swift.max(1, size.x / 16), Swift.max(1, size.y / 16))
//         return stride(from: 0, to: size.y, by: downsample).map
//         {
//             (i:Int) -> String in 
//             stride(from: 0, to: size.x, by: downsample).map 
//             {
//                 (j:Int) in 
                
//                 // downsampling 
//                 var r:Int = 0, 
//                     g:Int = 0, 
//                     b:Int = 0 
//                 for y:Int in i ..< Swift.min(i + downsample, size.y) 
//                 {
//                     for x:Int in j ..< Swift.min(j + downsample, size.x)
//                     {
//                         let c:PNG.RGBA<T> = rgb[x + y * size.x]
//                         r += .init(c.r)
//                         g += .init(c.g)
//                         b += .init(c.b)
//                     }
//                 }
                
//                 let count:Int = 
//                     (Swift.min(i + downsample, size.y) - i) * 
//                     (Swift.min(j + downsample, size.x) - j)
//                 let color:(r:Double, g:Double, b:Double) = 
//                 (
//                     .init(r) / (.init(T.max) * .init(count)),
//                     .init(g) / (.init(T.max) * .init(count)),
//                     .init(b) / (.init(T.max) * .init(count))
//                 )
//                 return .highlight("  ", bg: color)
//             }.joined()
//         }.joined(separator: "\n")
//     }
// }
