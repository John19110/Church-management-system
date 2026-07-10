namespace Church.BLL.Abstractions.Caching
{
    /// <summary>
    /// Central TTL policy. Kept in BLL so business-side caching uses consistent expirations.
    /// </summary>
    public static class CacheTtls
    {
        public static readonly TimeSpan Settings = TimeSpan.FromMinutes(30);
        public static readonly TimeSpan Dashboard = TimeSpan.FromMinutes(5);
        public static readonly TimeSpan Announcements = TimeSpan.FromMinutes(5);
        public static readonly TimeSpan Events = TimeSpan.FromMinutes(5);
        public static readonly TimeSpan Ministries = TimeSpan.FromMinutes(15);
        public static readonly TimeSpan Sermons = TimeSpan.FromMinutes(10);
        public static readonly TimeSpan Statistics = TimeSpan.FromMinutes(2);
        public static readonly TimeSpan UserProfile = TimeSpan.FromMinutes(10);
        public static readonly TimeSpan Notifications = TimeSpan.FromMinutes(2);
    }
}

