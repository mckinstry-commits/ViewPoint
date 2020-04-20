using System.Configuration;

namespace McK.Data.Viewpoint
{
    public static class HelperData
    {
        private static AppSettingsReader _config => new AppSettingsReader();

        public static string TargetEnvironment = "TargetEnvironment";

        public static string _conn_string => (string)_config.GetValue(ReadSetting(TargetEnvironment), typeof(string));

        private static string ReadSetting(string key)
        {
            try
            {
                var appSettings = ConfigurationManager.AppSettings;
                return appSettings[key] ?? "Not Found";
            }
            catch (ConfigurationErrorsException ex)
            {
                throw ex; // ("Error reading app settings");
            }
        }

        public static void AddUpdateAppSettings(string key, string value)
        {
            try
            {
                var configFile = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
                var settings = configFile.AppSettings.Settings;
                if (settings[key] == null)
                {
                    settings.Add(key, value);
                }
                else
                {
                    settings[key].Value = value;
                }
                configFile.Save(ConfigurationSaveMode.Modified);
                ConfigurationManager.RefreshSection(configFile.AppSettings.SectionInformation.Name);
            }
            catch (ConfigurationErrorsException ex)
            {
                throw ex; // ("Error writting app settings");
            }
        }
    }
}
