result of running benchmarks with zlib-based INFLATE (lower is better):

```
$ .build/release/benchmarks
ARGB32* (structured,  internal): 468,698
ARGB32* (structured,  public  ): 467,803
RGBA8   (structured,  internal): 405,611
RGBA8   (structured,  public  ): 404,847
RGBA8   (planar,      internal): 570,818
RGBA8   (planar,      public  ): 570,788
RGBA8   (interleaved, internal): 526,526
RGBA8   (interleaved, public  ): 520,973
  VA8   (structured,  internal): 393,267
  VA8   (structured,  public  ): 390,430
  VA8   (planar,      internal): 444,420
  VA8   (planar,      public  ): 450,915
  VA8   (interleaved, internal): 488,684
  VA8   (interleaved, public  ): 491,076
   V8   (interleaved, internal): 391,113
   V8   (interleaved, public  ): 390,454
RGBA8   (encode,      internal): 10,828,378
RGBA8   (encode,      public  ): 10,729,231
```

result of running benchmarks with swift INFLATE (lower is better):

```
$ .build/release/benchmarks
ARGB32* (structured,  internal): 1,001,899
ARGB32* (structured,  public  ): 999,789
RGBA8   (structured,  internal): 946,876
RGBA8   (structured,  public  ): 952,408
RGBA8   (planar,      internal): 1,103,230
RGBA8   (planar,      public  ): 1,103,527
RGBA8   (interleaved, internal): 1,062,639
RGBA8   (interleaved, public  ): 1,057,035
  VA8   (structured,  internal): 929,430
  VA8   (structured,  public  ): 937,318
  VA8   (planar,      internal): 984,125
  VA8   (planar,      public  ): 988,722
  VA8   (interleaved, internal): 1,024,587
  VA8   (interleaved, public  ): 1,037,420
   V8   (interleaved, internal): 936,374
   V8   (interleaved, public  ): 932,438
RGBA8   (encode,      internal): 10,672,385
RGBA8   (encode,      public  ): 10,659,090
```

new measurements from jun 23 
measured with 1 google and 2 plain text firefox tabs open, 4-6 atom tabs, and paused spotify

```
$ .build/release/benchmarks
ARGB32* (structured,  internal): 675,555
ARGB32* (structured,  public  ): 655,488
RGBA8   (structured,  internal): 596,695
RGBA8   (structured,  public  ): 598,074
RGBA8   (planar,      internal): 765,345
RGBA8   (planar,      public  ): 751,493
RGBA8   (interleaved, internal): 713,077
RGBA8   (interleaved, public  ): 705,241
  VA8   (structured,  internal): 582,071
  VA8   (structured,  public  ): 579,289
  VA8   (planar,      internal): 640,236
  VA8   (planar,      public  ): 637,968
  VA8   (interleaved, internal): 675,133
  VA8   (interleaved, public  ): 682,644
   V8   (interleaved, internal): 583,853
   V8   (interleaved, public  ): 576,992
```
