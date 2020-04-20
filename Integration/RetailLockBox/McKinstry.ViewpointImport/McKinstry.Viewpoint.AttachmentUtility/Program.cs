using System;
using System.Linq;
using System.IO;
using log4net;
using System.Net.Mail;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.AttachmentUtility
{
    class Program
    {
        public static string Name
        {
            get
            {
                return "McKinstry Viewpoint Attachment Utility";
            }
        }

        static void Main(string[] args)
        {         
            // Intialize settings
            Settings settings = new Settings();

            // Initialize logger
            ILog log = LoggingHelper.CreateLogger(typeof(Program), Settings.LogFileFolderLocation, Settings.LogFileName);
            RLBImportBatch batch = new RLBImportBatch();
            string process = args.Length > 0 ? args[0].ToLower() : null;

            try
            {
                log.Info(string.Format("--Begin {0}--", Program.Name));

                // Check command arguments
                log.Info("Checking command input for process.");
                if (string.IsNullOrEmpty(process))
                {
                    log.Info("Missing command argument. Process is required: FullFileRefresh/PartialFileRefresh/MissingAttachments.");
                    goto EndProcess;
                }

                CommandInvoker cmd = new CommandInvoker();
                switch (process)
                {
                    case "fullfilerefresh":
                        cmd.GetCommand(typeof(AttachmentUtility.FullFileRefreshCommand)).RunWith(log);
                        break;
                    case "partialfilerefresh":
                        cmd.GetCommand(typeof(AttachmentUtility.PartialFileRefreshCommand)).RunWith(log);
                        break;
                    case "missingattachments":
                        cmd.GetCommand(typeof(AttachmentUtility.MissingAttachmentsCommand)).RunWith(log);
                        break;
                }

            EndProcess:

                log.Info(string.Format("--End {0}--", Program.Name));
            }
            catch (Exception ex)
            {
                // Log exception
                log.Error("An error has occurred.", ex);
                log.Info(string.Format("--End {0}--", Program.Name));

                if (Settings.SendNotificationEmail)
                {
                    // Send error email with log attached
                    string logFile = log4net.GlobalContext.Properties["FileName"].ToString();
                    MailHelper.SendErrorEmail(Program.Name, Settings.FromEmail, Settings.FromEmailDisplayName,
                        Settings.ToEmail, Settings.CcEmail, Settings.EmailSubject, new Attachment(logFile));
                }
            }
        }
    }
}
