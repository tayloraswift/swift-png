extension PNG
{
    /// An image modification time.
    ///
    /// This type models the information stored in a ``Chunk/tIME`` chunk.
    /// This type is time-zone agnostic, and so all time values are assumed
    /// to be in universal time (UTC).
    public
    struct TimeModified
    {
        /// The complete [gregorian](https://en.wikipedia.org/wiki/Gregorian_calendar) year.
        public
        let year:Int
        /// The calendar month, expressed as a 1-indexed integer.
        public
        let month:Int
        /// The calendar day, expressed as a 1-indexed integer.
        public
        let day:Int
        /// The hour, in 24-hour time, expressed as a 0-indexed integer.
        public
        let hour:Int
        /// The minute, expressed as a 0-indexed integer.
        public
        let minute:Int
        /// The second, expressed as a 0-indexed integer.
        public
        let second:Int

        /// Creates an image modification time.
        ///
        /// The time is time-zone agnostic, and so all time parameters are
        /// assumed to be in universal time (UTC). Passing out-of-range
        /// time parameters will result in a precondition failure.
        /// -   Parameter year:
        ///     The complete [gregorian](https://en.wikipedia.org/wiki/Gregorian_calendar)
        ///     year. It must be in the range `0 ..< 1 << 16`. It can be
        ///     reasonably expected to have four decimal digits.
        /// -   Parameter month:
        ///     The calendar month, expressed as a 1-indexed integer. It must
        ///     be in the range `1 ... 12`.
        /// -   Parameter day:
        ///     The calendar day, expressed as a 1-indexed integer.
        ///     It must be in the range `1 ... 31`.
        /// -   Parameter hour:
        ///     The hour, in 24-hour time, expressed as a 0-indexed integer.
        ///     It must be in the range `0 ... 23`.
        /// -   Parameter minute:
        ///     The minute, expressed as a 0-indexed integer.
        ///     It must be in the range `0 ... 59`.
        /// -   Parameter second:
        ///     The second, expressed as a 0-indexed integer.
        ///     It must be in the range `0 ... 60`, where the value `60` is
        ///     used to represent leap seconds.
        public
        init(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Int)
        {
            guard   0 ..< 1 << 16   ~= year,
                    1 ... 12        ~= month,
                    1 ... 31        ~= day,
                    0 ... 23        ~= hour,
                    0 ... 59        ~= minute,
                    0 ... 60        ~= second
            else
            {
                PNG.ParsingError.invalidTimeModifiedTime(
                    year:   year,
                    month:  month,
                    day:    day,
                    hour:   hour,
                    minute: minute,
                    second: second).fatal
            }

            self.year   = year
            self.month  = month
            self.day    = day
            self.hour   = hour
            self.minute = minute
            self.second = second
        }
    }
}
extension PNG.TimeModified
{
    /// Creates an image modification time by parsing the given chunk data.
    /// -   Parameter data:
    ///     The contents of a ``Chunk/tIME`` chunk to parse.
    public
    init(parsing data:[UInt8]) throws
    {
        guard data.count == 7
        else
        {
            throw PNG.ParsingError.invalidTimeModifiedChunkLength(data.count)
        }

        self.year   = data.load(bigEndian: UInt16.self, as: Int.self, at: 0)
        self.month  = .init(data[2])
        self.day    = .init(data[3])
        self.hour   = .init(data[4])
        self.minute = .init(data[5])
        self.second = .init(data[6])

        guard   0 ..< 1 << 16   ~= self.year,
                1 ... 12        ~= self.month,
                1 ... 31        ~= self.day,
                0 ... 23        ~= self.hour,
                0 ... 59        ~= self.minute,
                0 ... 60        ~= self.second
        else
        {
            throw PNG.ParsingError.invalidTimeModifiedTime(
                year:   self.year,
                month:  self.month,
                day:    self.day,
                hour:   self.hour,
                minute: self.minute,
                second: self.second)
        }
    }
    /// Encodes this image modification time as the contents of a ``Chunk/tIME`` chunk.
    public
    var serialized:[UInt8]
    {
        .init(unsafeUninitializedCapacity: 7)
        {
            $0.store(self.year, asBigEndian: UInt16.self, at: 0)
            $0[2] = .init(self.month)
            $0[3] = .init(self.day)
            $0[4] = .init(self.hour)
            $0[5] = .init(self.minute)
            $0[6] = .init(self.second)
            $1 = $0.count
        }
    }
}
extension PNG.TimeModified:CustomStringConvertible
{
    public
    var description:String
    {
        """
        PNG.\(Self.self) (\(PNG.Chunk.tIME))
        {
            year        : \(self.year)
            month       : \(self.month)
            day         : \(self.day)
            hour        : \(self.hour)
            minute      : \(self.minute)
            second      : \(self.second)
        }
        """
    }
}
