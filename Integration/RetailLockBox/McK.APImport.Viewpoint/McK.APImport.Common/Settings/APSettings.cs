using System;

namespace McK.APImport.Common
{
    public static class APSettings
    {

        public static string APArchiveFolderLocation => Settings.FetchSetting("APArchiveFolderLocation");

        public static string APProcessFolderLocation => Settings.FetchSetting("APProcessFolderLocation");

        public static string APLogFileFolderLocation => Settings.FetchSetting("APLogFileFolderLocation");

        public static string APUserAccount => Settings.FetchSetting("APUserAccount");

        public static string APModule => Settings.FetchSetting("APModule");

        public static string APForm => Settings.FetchSetting("APForm");

        public static string APFilePrefix => Settings.FetchSetting("APFilePrefix");

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

        //public static string MckIntegrationConnectionString => Settings.FetchSetting("MckIntegrationConnectionString");

        //public static string ViewpointConnectionString => Settings.FetchSetting("ViewpointConnectionString");
    }
}
