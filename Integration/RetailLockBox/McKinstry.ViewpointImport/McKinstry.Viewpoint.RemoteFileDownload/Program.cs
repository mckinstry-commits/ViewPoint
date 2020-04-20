using System;
using log4net;
using System.Net.Mail;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

[assembly: log4net.Config.XmlConfigurator(Watch = true)]

namespace McKinstry.Viewpoint.RemoteFileDownload
{
    /// <summary>
    /// McKinstry Viewpoint Remote File Download Application
    /// </summary>
    class Program
    {
        public static string Name
        {
            get
            {
                return "McKinstry Viewpoint Remote File Download";
            }
        }

        static void Main(string[] args)
        {
            // Intialize settings
            Settings settings = new Settings();
            // Initialize logger
            ILog log = LoggingHelper.CreateLogger(typeof(Program), Settings.LogFilePath, Settings.LogFileName);
            // Files list used in commands
            List<SftpFile> downloadFiles = new List<SftpFile>();

            try
            {
                log.Info(string.Format("--Begin {0}--", Program.Name));

                // Manual file download scenario - user passes in file name as command argument
                string fileName = args.Length > 0 ? args[0] : null;
                if (!string.IsNullOrEmpty(fileName))
                {
                    SftpFile file;
                    bool fileExists = RlbSftpHelper.RemoteFileExists(fileName, Settings.RemoteDownloadPath, out file);
                    if (!fileExists)
                    {
                        log.Info(string.Format("Cannot find file '{0}' at remote FTP location '{1}'.", fileName, Settings.RemoteDownloadPath));
                        log.Info(string.Format("--End {0}--", Program.Name));
                        return;
                    }
                    downloadFiles.Add(file);
                    goto Commands;
                }

                // Standard scenario based on designated file count
                downloadFiles = RlbSftpHelper.GetLatestFileInfoFromRemotePath(Settings.DownloadFileCount, Settings.RemoteDownloadPath);

            Commands:

                CommandInvoker cmd = new CommandInvoker();
                cmd.GetCommand(typeof(RemoteFileDownload.DownloadCheckCommand)).RunWith(log, downloadFiles);
                cmd.GetCommand(typeof(RemoteFileDownload.DownloadCommand)).RunWith(log, downloadFiles);
                cmd.GetCommand(typeof(RemoteFileDownload.LogCommand)).RunWith(log, downloadFiles);
                cmd.GetCommand(typeof(RemoteFileDownload.EmailCommand)).RunWith(log, downloadFiles);

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
