using System;

namespace McKinstry.ViewpointImport.Common
{
    public static class ARSettings
    {
        public static string ARFilePrefix
        {
            get
            {
                return Settings.FetchSetting("ARFilePrefix");
            }
        }

        public static string ARProcessFolderLocation
        {
            get
            {
                return Settings.FetchSetting("ARProcessFolderLocation");
            }
        }
    }
}

