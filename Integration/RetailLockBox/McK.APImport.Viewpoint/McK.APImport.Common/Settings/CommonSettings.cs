using System;

namespace McK.APImport.Common
{
    public static class CommonSettings
    {
        public static string RlbDownloadFileDrop => Settings.FetchSetting("RlbDownloadFileDrop");

        public static string RlbDownloadJunkFolder => Settings.FetchSetting("RlbDownloadJunkFolder");

        public static string MailSmtpHost => Settings.FetchSetting("MailSmtpHost");

        public static string RlbHostName => Settings.FetchSetting("RlbHostName");

        public static string RlbUserName => Settings.FetchSetting("RlbUserName");

        public static string RlbPassword => Settings.FetchSetting("RlbPassword");

        public static string RlbHostkeyFingerprint => Settings.FetchSetting("RlbHostkeyFingerprint");

        public static string MckIntegrationConnectionString => Settings.FetchConnectionString("MckIntegrationConnectionString");

        public static string ViewpointConnectionString => Settings.FetchConnectionString("ViewpointConnectionString");
    }
}
