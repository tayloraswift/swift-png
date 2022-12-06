/// protocol PNG.Error 
/// :   Swift.Error 
///     Functionality common to all library error types.
/// # [Propogating errors](error-propogation)
/// # [See also](error-handling)
/// ## (error-handling)
public 
protocol _PNGError:Error 
{
    /// static var PNG.Error.namespace : Swift.String { get }
    /// required 
    ///     A human-readable namespace for this error type.
    static 
    var namespace:String
    {
        get 
    }
    /// var PNG.Error.message : Swift.String { get }
    /// required 
    ///     A human-readable summary of this error.
    /// ## ()
    var message:String 
    {
        get 
    }
    /// var PNG.Error.details : Swift.String? { get }
    /// required 
    ///     An optional human-readable string providing additional details 
    ///     about this error.
    /// ## ()
    var details:String? 
    {
        get 
    }
}
extension PNG.Error 
{
    /// var PNG.Error.fatal : Swift.Never 
    ///     Halts execution by converting this error into a fatal error.
    /// ## (error-propogation)
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
