namespace Church.BLL.Abstractions.Caching
{
    /// <summary>
    /// Provides a CacheContext for the current execution context (usually an HTTP request).
    /// Implemented in the API host so BLL stays free of HttpContext.
    /// </summary>
    public interface ICacheContextAccessor
    {
        CacheContext? TryGet();
    }
}

