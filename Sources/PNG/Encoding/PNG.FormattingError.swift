extension PNG
{
    /// A formatting error.
    public
    enum FormattingError
    {
        /// The formatter failed to write to a destination bytestream.
        case invalidDestination
    }
}
extension PNG.FormattingError:PNG.Error
{
    /// The string `"formatting error"`.
    public static
    var namespace:String
    {
        "formatting error"
    }
    public
    var message:String
    {
        switch self
        {
        case .invalidDestination:
            return "failed to write to destination bytestream"
        }
    }
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
