using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewoint.CompanyMove
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
            emailSubject = ConfigurationHelper.GetAppSettingsValue("EmailSubject");
            fromEmail = ConfigurationHelper.GetAppSettingsValue("FromEmail");
            fromEmailDisplayName = ConfigurationHelper.GetAppSettingsValue("FromEmailDisplayName");
            toEmail = ConfigurationHelper.GetAppSettingsValue("ToEmail");
            ccEmail = ConfigurationHelper.GetAppSettingsValueNoException("CcEmail");
            logFileFolderLocation = ConfigurationHelper.GetAppSettingsValue("LogFileFolderLocation");
            logFileName = ConfigurationHelper.GetAppSettingsValue("LogFileName");
            sendNotificationEmail = ConfigurationHelper.GetAppSettingsValue("SendNotificationEmail");
            applicationKey = ConfigurationHelper.GetAppSettingsValue("ApplicationKey");
            notificationHourInterval = ConfigurationHelper.GetAppSettingsValue("NotificationHourInterval");
        }

        private static string emailSubject;
        public static string EmailSubject
        {
            get
            {
                return emailSubject;
            }
        }

        private static string fromEmail;
        public static string FromEmail
        {
            get
            {
                return fromEmail;
            }
        }

        private static string fromEmailDisplayName;
        public static string FromEmailDisplayName
        {
            get
            {
                return fromEmailDisplayName;
            }
        }

        private static string toEmail;
        public static string ToEmail
        {
            get
            {
                return toEmail;
            }
        }

        private static string ccEmail;
        public static string CcEmail
        {
            get
            {
                return ccEmail;
            }
        }

        private static string logFileFolderLocation;
        public static string LogFileFolderLocation
        {
            get
            {
                return logFileFolderLocation;
            }
        }

        private static string logFileName;
        public static string LogFileName
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

        private static string applicationKey;
        public static string ApplicationKey
        {
            get
            {
                return applicationKey;
            }
        }

        private static string notificationHourInterval;
        internal static int NotificationHourInterval
        {
            get
            {
                int interval;
                bool intervalValid = Int32.TryParse(notificationHourInterval, out interval);
                if (intervalValid)
                {
                    return interval;
                }
                return 24;
            }
        }

    }
}
