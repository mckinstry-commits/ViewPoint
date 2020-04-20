using System;

namespace McKinstry.ViewpointImport.Common
{
    public static class APSettings 
    {

        public static string APArchiveFolderLocation
        {
            get
            {
                return Settings.FetchSetting("APArchiveFolderLocation");
            }
        }

        public static string APProcessFolderLocation
        {
            get
            {
                return Settings.FetchSetting("APProcessFolderLocation");
            }
        }

        public static string APLogFileFolderLocation
        {
            get
            {
                return Settings.FetchSetting("APLogFileFolderLocation");
            }
        }

        public static string APUserAccount
        {
            get
            {
                return Settings.FetchSetting("APUserAccount");
            }
        }

        public static string APModule
        {
            get
            {
                return Settings.FetchSetting("APModule");
            }
        }

        public static string APForm
        {
            get
            {
                return Settings.FetchSetting("APForm");
            }
        }

        public static string APFilePrefix
        {
            get
            {
                return Settings.FetchSetting("APFilePrefix");
            }
        }

        public static byte APUnmatchedCompany
        {
            get
            {
                byte result;
                Byte.TryParse(Settings.FetchSetting("APUnmatchedCompany"), out result);
                return result > 0 ? result : (byte)1;
            }
        }

        public static byte APUnmatchedVendorGroup
        {
            get
            {
                byte result;
                Byte.TryParse(Settings.FetchSetting("APUnmatchedVendorGroup"), out result);
                return result > 0 ? result : (byte)1;
            }
        }

        public static Int32 APUnmatchedVendor
        {
            get
            {
                int count;
                Int32.TryParse(Settings.FetchSetting("APUnmatchedVendor"), out count);
                return count > 0 ? count : 9;
            }
        }
    }
}
