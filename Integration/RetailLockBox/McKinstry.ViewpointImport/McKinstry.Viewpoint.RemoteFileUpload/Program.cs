using System;
using log4net;
using System.Net.Mail;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

[assembly: log4net.Config.XmlConfigurator(Watch = true)]

namespace McKinstry.Viewpoint.RemoteFileUpload
{
    /// <summary>
    /// McKinstry Viewpoint Remote File Upload Application
    /// </summary>
    class Program
    {
        public static string Name
        {
            get
            {
                return "McKinstry Viewpoint Remote File Upload";
            }
        }


        static void Main(string[] args)
        {
            // Intialize settings
            Settings settings = new Settings();
            // Initialize logger
            ILog log = LoggingHelper.CreateLogger(typeof(Program), Settings.LogFilePath, Settings.LogFileName);
            // Initialize command invoker
            CommandInvoker cmd = new CommandInvoker();

            try
            {
                log.Info(string.Format("--Begin {0}--", Program.Name));

                // Get command arguments
                string process = args.Length > 0 ? args[0].ToLower() : null;
                switch (process)
                {
                    case "ap":
                        cmd.GetCommand(typeof(RemoteFileUpload.APExtractCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.UploadCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.LogCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.EmailCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.DeleteCommand)).RunWith(log);
                        break;
                    case "ar":
                        cmd.GetCommand(typeof(RemoteFileUpload.ARExtractCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.UploadCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.LogCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.EmailCommand)).RunWith(log);
                        cmd.GetCommand(typeof(RemoteFileUpload.DeleteCommand)).RunWith(log);
                        break;
                    default:
                        log.Info("Missing command argument. 'AP' or 'AR' is required.");
                        break;
                }

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
