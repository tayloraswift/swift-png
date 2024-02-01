import LZ77

extension LZ77.StreamHeaderError:PNG.Error
{
    /// The string `"Stream header error"`.
    public static
    var namespace:String
    {
        "Stream header error"
    }

    /// A human-readable summary of this error.
    public
    var message:String
    {
        switch self
        {
        case .invalidCompressionMethod:
            "invalid rfc-1950 stream compression method code"
        case .invalidWindowSize:
            "invalid rfc-1950 stream window size"
        case .invalidCheckBits:
            "invalid rfc-1950 stream header check bits"
        case .unexpectedDictionary:
            "unexpected rfc-1950 stream dictionary"
        }
    }
    /// An optional human-readable string providing additional details about this error.
    public
    var details:String?
    {
        switch self
        {
        case .invalidCompressionMethod(let code):
            "(\(code)) is not a valid compression method code"
        case .invalidWindowSize(exponent: let exponent):
            "base-2 log of stream window size (\(exponent)) must be in the range 8 ... 15"
        case .invalidCheckBits:
            nil
        case .unexpectedDictionary:
            nil
        }
    }
}
