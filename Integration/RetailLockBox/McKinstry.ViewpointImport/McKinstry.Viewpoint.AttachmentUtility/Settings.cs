using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.AttachmentUtility
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
            productionAttachmentDirectory = ConfigurationHelper.GetAppSettingsValue("ProductionAttachmentDirectory");
            stagingAttachmentDirectory = ConfigurationHelper.GetAppSettingsValue("StagingAttachmentDirectory");
            includeStagingDirectory = ConfigurationHelper.GetAppSettingsValue("IncludeStagingDirectory");
            logFileFolderLocation = ConfigurationHelper.GetAppSettingsValue("LogFileFolderLocation");
            logFileName = ConfigurationHelper.GetAppSettingsValue("LogFileName");
            sendNotificationEmail = ConfigurationHelper.GetAppSettingsValue("SendNotificationEmail");
            emailSubject = ConfigurationHelper.GetAppSettingsValue("EmailSubject");
            fromEmail = ConfigurationHelper.GetAppSettingsValue("FromEmail");
            fromEmailDisplayName = ConfigurationHelper.GetAppSettingsValue("FromEmailDisplayName");
            toEmail = ConfigurationHelper.GetAppSettingsValue("ToEmail");
            ccEmail = ConfigurationHelper.GetAppSettingsValueNoException("CcEmail");
        }

        public static string ProductionEnvironmentName
        {
            get
            {
                return "Production";
            }
        }

        public static string StagingEnvironmentName
        {
            get
            {
                return "Staging";
            }
        }

        private static string productionAttachmentDirectory;
        public static string ProductionAttachmentDirectory
        {
            get
            {
                return productionAttachmentDirectory;
            }
        }

        private static string stagingAttachmentDirectory;
        public static string StagingAttachmentDirectory
        {
            get
            {
                return stagingAttachmentDirectory;
            }
        }

        private static string includeStagingDirectory;
        public static bool IncludeStagingDirectory
        {
            get
            {
                bool include;
                Boolean.TryParse(includeStagingDirectory, out include);
                return include;
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
    }
}
