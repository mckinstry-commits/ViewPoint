using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileDownload
{
    /// <summary>
    /// Application settings class
    /// </summary>
    internal class Settings
    {
        /// <summary>
        /// Initialize and test settings in constructor
        /// </summary>
        internal Settings()
        {
            remoteDownloadPath = ConfigurationHelper.GetAppSettingsValue("RemoteDownloadPath");
            localDownloadPath = ConfigurationHelper.GetAppSettingsValue("LocalDownloadPath");
            downloadFileCount = ConfigurationHelper.GetAppSettingsValue("DownloadFileCount");
            logFilePath = ConfigurationHelper.GetAppSettingsValue("LogFilePath");
            logFileName = ConfigurationHelper.GetAppSettingsValue("LogFileName");
            sendNotificationEmail = ConfigurationHelper.GetAppSettingsValue("SendNotificationEmail");
            emailSubject = ConfigurationHelper.GetAppSettingsValue("EmailSubject");
            noDownloadEmailSubject = ConfigurationHelper.GetAppSettingsValue("NoDownloadEmailSubject");
            fromEmail = ConfigurationHelper.GetAppSettingsValue("FromEmail");
            fromEmailDisplayName = ConfigurationHelper.GetAppSettingsValue("FromEmailDisplayName");
            toEmail = ConfigurationHelper.GetAppSettingsValue("ToEmail");
            ccEmail = ConfigurationHelper.GetAppSettingsValueNoException("CcEmail");
        }       

        private static string remoteDownloadPath;
        internal static string RemoteDownloadPath
        {
            get
            {
                return remoteDownloadPath;
            }
        }

        private static string localDownloadPath;
        internal static string LocalDownloadPath
        {
            get
            {
                return localDownloadPath;
            }
        }

        private static string downloadFileCount;
        internal static int DownloadFileCount
        {
            get
            {
                int count;
                Int32.TryParse(downloadFileCount, out count);
                return count > 0 ? count : 1;
            }
        }

        private static string logFilePath;
        internal static string LogFilePath
        {
            get
            {
                return logFilePath;
            }
        }

        private static string logFileName;
        internal static string LogFileName
        {
            get
            {
                return logFileName;
            }
        }

        private static string sendNotificationEmail;
        internal static bool SendNotificationEmail
        {
            get
            {
                bool notify;
                Boolean.TryParse(sendNotificationEmail, out notify);
                return notify;
            }
        }

        private static string emailSubject;
        internal static string EmailSubject
        {
            get
            {
                return emailSubject;
            }
        }

        private static string noDownloadEmailSubject;
        internal static string NoDownloadEmailSubject
        {
            get
            {
                return noDownloadEmailSubject;
            }
        }

        private static string fromEmail;
        internal static string FromEmail
        {
            get
            {
                return fromEmail;
            }
        }

        private static string fromEmailDisplayName;
        internal static string FromEmailDisplayName
        {
            get
            {
                return fromEmailDisplayName;
            }
        }

        private static string toEmail;
        internal static string ToEmail
        {
            get
            {
                return toEmail;
            }
        }

        private static string ccEmail;
        internal static string CcEmail
        {
            get
            {
                return ccEmail;
            }
        }
    }
}
