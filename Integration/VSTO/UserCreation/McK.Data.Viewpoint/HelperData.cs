using System.Configuration;

namespace McK.Data.Viewpoint
{
    public static class StringExtensions
    {
        public static bool Contains(this string source, string toCheck, System.StringComparison comp)
        {
            return source.IndexOf(toCheck, comp) >= 0;
        }
    }

    public static class HelperData
    {
        public static string AppName;

        public static AppSettingsReader _config
        {
            get { return new AppSettingsReader(); }
        }

        public static string _conn_string
        {
            get {
                if (AppName.Contains("-Stg", System.StringComparison.OrdinalIgnoreCase))
                {
                    return (string)_config.GetValue("ViewpointConnectionStg", typeof(string));
                }
                else if (AppName.Contains("-Trng", System.StringComparison.OrdinalIgnoreCase))
                {
                    return (string)_config.GetValue("ViewpointConnectionTrng", typeof(string));
                }
                else if (AppName.Contains("-Upg", System.StringComparison.OrdinalIgnoreCase))
                {
                    return (string)_config.GetValue("ViewpointConnectionUpg", typeof(string));
                }
                else
                {
                    return (string)_config.GetValue("ViewpointConnectionProd", typeof(string));
                }

            }
        }
    }
}
