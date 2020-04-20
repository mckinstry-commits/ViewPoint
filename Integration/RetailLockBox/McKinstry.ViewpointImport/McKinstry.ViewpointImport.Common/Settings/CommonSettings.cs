using System;

namespace McKinstry.ViewpointImport.Common
{
    public static class CommonSettings
    {
        public static string RlbDownloadFileDrop
        {
            get
            {
                return Settings.FetchSetting("RlbDownloadFileDrop");
            }
        }

        public static string RlbDownloadJunkFolder
        {
            get
            {
                return Settings.FetchSetting("RlbDownloadJunkFolder");
            }
        }

        public static string MailSmtpHost
        {
            get
            {
                return Settings.FetchSetting("MailSmtpHost");
            }
        }

        public static string RlbHostName
        {
            get
            {
                return Settings.FetchSetting("RlbHostName");
            }
        }

        public static string RlbUserName
        {
            get
            {
                return Settings.FetchSetting("RlbUserName");
            }
        }

        public static string RlbPassword
        {
            get
            {
                return Settings.FetchSetting("RlbPassword");
            }
        }

        public static string RlbHostkeyFingerprint
        {
            get
            {
                return Settings.FetchSetting("RlbHostkeyFingerprint");
            }
        }

        public static string MckIntegrationConnectionString
        {
            get
            {
                return Settings.FetchSetting("MckIntegrationConnectionString");
            }
        }

        public static string ViewpointConnectionString
        {
            get
            {
                return Settings.FetchSetting("ViewpointConnectionString");
            }
        }
    }
}
