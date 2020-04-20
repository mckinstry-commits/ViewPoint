using System;
using System.IO;
using System.Configuration;

namespace McKinstry.ViewpointImport.Common
{
    public static class Settings
    {
        private static ExeConfigurationFileMap configFileMap; 
        private static Configuration config;

        private static Configuration GetConfiguration()
        {
            configFileMap = new ExeConfigurationFileMap();
            string configFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CommonSettings.config");
            configFileMap.ExeConfigFilename = configFile;
            config = ConfigurationManager.OpenMappedExeConfiguration(configFileMap, ConfigurationUserLevel.None);
            if (!config.HasFile)
            {
                throw new Exception(string.Format("Cannot open application configuaration file {0}.", configFile));
            }
            if (config.AppSettings.Settings.Count <= 0)
            {
                throw new Exception(string.Format("Missing common application settings in settings file {0}.", configFile));
            }
            return config;
        }

        internal static string FetchSetting(string key)
        {
            if (config == null)
            {
                config = GetConfiguration();
            }
            if (config.AppSettings.Settings[key] != null)
            {
                return config.AppSettings.Settings[key].Value;
            }
            return null;
        }

    }
}
