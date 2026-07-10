namespace Church.BLL.Abstractions.Caching
{
    /// <summary>
    /// Cache behavior options. These map cleanly to IMemoryCache now,
    /// and can later map to Redis/distributed caching without changing callers.
    /// </summary>
    public sealed record CacheEntryOptions(
        TimeSpan AbsoluteExpirationRelativeToNow);
}

