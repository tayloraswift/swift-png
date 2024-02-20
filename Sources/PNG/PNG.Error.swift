/// Functionality common to all library error types.
public
protocol _PNGError:Error
{
    /// A human-readable namespace for this error type.
    static
    var namespace:String
    {
        get
    }
    /// A human-readable summary of this error.
    var message:String
    {
        get
    }
    /// An optional human-readable string providing additional details
    /// about this error.
    var details:String?
    {
        get
    }
}
extension PNG.Error
{
    /// Halts execution by converting this error into a fatal error.
    public
    var fatal:Never
    {
        fatalError("\(self)")
    }
}

// TODO: replace with `TraceableErrors` from `swift-mongodb`
extension PNG
{
    public
    typealias Error = _PNGError
}
