using System;
using System.Linq;
using System.IO;
using log4net;
using System.Net.Mail;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewoint.CompanyMove
{
    class Program
    {
        public static string Name
        {
            get
            {
                return "McKinstry Viewpoint Company Move";
            }
        }

        static void Main(string[] args)
        {
            // Intialize settings
            Settings settings = new Settings();
            // Initialize logger
            ILog log = LoggingHelper.CreateLogger(typeof(Program), Settings.LogFileFolderLocation, Settings.LogFileName);
            try
            {
                log.Info(string.Format("--Begin {0}--", Program.Name));

                CommandInvoker cmd = new CommandInvoker();
                cmd.GetCommand(typeof(CompanyMove.APCompanyMoveCommand)).RunWith(log);
                cmd.GetCommand(typeof(CompanyMove.APErrorEmailCommand)).RunWith(log);

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
