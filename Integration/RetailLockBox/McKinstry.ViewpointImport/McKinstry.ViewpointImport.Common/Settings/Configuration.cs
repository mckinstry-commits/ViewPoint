using System;
using System.Configuration;

namespace McKinstry.ViewpointImport.Common
{
    public static class ConfigurationHelper
    {
        public static string GetAppSettingsValue(string key)
        {
            string val = ConfigurationManager.AppSettings[key];
            if (string.IsNullOrEmpty(val))
            {
                throw new ApplicationException(string.Format("Missing Application Setting '{0}'.", key));
            }
            return val;
        }

        public static string GetAppSettingsValueNoException(string key)
        {
            return ConfigurationManager.AppSettings[key];
        }
    }
}
