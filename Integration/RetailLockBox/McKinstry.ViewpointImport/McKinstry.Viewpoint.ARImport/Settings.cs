using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
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
            archiveFolderLocation = ConfigurationHelper.GetAppSettingsValue("ArchiveFolderLocation");
            logFileFolderLocation = ConfigurationHelper.GetAppSettingsValue("LogFileFolderLocation");
            logFileName = ConfigurationHelper.GetAppSettingsValue("LogFileName");
            sendNotificationEmail = ConfigurationHelper.GetAppSettingsValue("SendNotificationEmail");
            userAccount = ConfigurationHelper.GetAppSettingsValue("UserAccount");
            module = ConfigurationHelper.GetAppSettingsValue("Module");
            form = ConfigurationHelper.GetAppSettingsValue("Form");
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

        private static string archiveFolderLocation;
        public static string ArchiveFolderLocation
        {
            get
            {
                return archiveFolderLocation;
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

        private static string userAccount;
        public static string UserAccount
        {
            get
            {
                return userAccount;
            }
        }

        private static string module;
        public static string Module
        {
            get
            {
                return module;
            }
        }

        private static string form;
        public static string Form
        {
            get
            {
                return form;
            }
        }
    }
}
