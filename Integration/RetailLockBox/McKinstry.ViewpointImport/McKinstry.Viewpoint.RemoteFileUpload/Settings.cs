using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileUpload
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
            remoteUploadPath = ConfigurationHelper.GetAppSettingsValue("RemoteUploadPath");
            uploadFileName = ConfigurationHelper.GetAppSettingsValue("UploadFileName");
            logFilePath = ConfigurationHelper.GetAppSettingsValue("LogFilePath");
            logFileName = ConfigurationHelper.GetAppSettingsValue("LogFileName");
            sendNotificationEmail = ConfigurationHelper.GetAppSettingsValue("SendNotificationEmail");
            emailSubject = ConfigurationHelper.GetAppSettingsValue("EmailSubject");
            noUploadEmailSubject = ConfigurationHelper.GetAppSettingsValue("NoUploadEmailSubject");
            fromEmail = ConfigurationHelper.GetAppSettingsValue("FromEmail");
            fromEmailDisplayName = ConfigurationHelper.GetAppSettingsValue("FromEmailDisplayName");
            toEmail = ConfigurationHelper.GetAppSettingsValue("ToEmail");
            ccEmail = ConfigurationHelper.GetAppSettingsValueNoException("CcEmail");
        }

        private static string remoteUploadPath;
        internal static string RemoteUploadPath
        {
            get
            {
                return remoteUploadPath;
            }
        }

        private static string uploadFileName;
        internal static string UploadFileName
        {
            get
            {
                return uploadFileName;
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

        private static string noUploadEmailSubject;
        internal static string NoUploadEmailSubject
        {
            get
            {
                return noUploadEmailSubject;
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
