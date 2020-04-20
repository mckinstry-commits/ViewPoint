using System.Configuration;

namespace McK.Data.Viewpoint
{
    public static class HelperData
    {
        public static AppSettingsReader _config => new AppSettingsReader();

        public static string VPuser { get; set; }

        public static string VSTO_Version { get; set; }

        public static string _conn_string => (string)_config.GetValue("ViewpointConnection", typeof(string));
    }

}
