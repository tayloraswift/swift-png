extension PNG 
{
    /// enum PNG.FormattingError 
    /// :   Error 
    ///     A formatting error.
    /// # [See also](error-handling)
    /// ## (error-handling)
    public 
    enum FormattingError
    {
        /// case PNG.FormattingError.invalidDestination 
        ///     The formatter failed to write to a destination bytestream.
        case invalidDestination
    }
}
extension PNG.FormattingError:PNG.Error 
{
    /// static var PNG.FormattingError.namespace : Swift.String { get }
    /// ?:  Error 
    ///     The string `"formatting error"`.
    public static 
    var namespace:String 
    {
        "formatting error"
    }
    /// var PNG.FormattingError.message : Swift.String { get }
    /// ?:  Error 
    ///     A human-readable summary of this error.
    /// ## ()
    public 
    var message:String 
    {
        switch self 
        {
        case .invalidDestination: 
            return "failed to write to destination bytestream"
        }
    }
    /// var PNG.FormattingError.details : Swift.String? { get }
    /// ?:  Error 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
    public 
    var details:String?
    {
        switch self 
        {
        case .invalidDestination:
            return nil
        }
    }
}
