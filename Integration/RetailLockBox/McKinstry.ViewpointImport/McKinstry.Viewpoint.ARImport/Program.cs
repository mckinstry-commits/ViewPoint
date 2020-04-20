using System;
using System.Linq;
using System.IO;
using log4net;
using System.Net.Mail;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

[assembly: log4net.Config.XmlConfigurator(Watch = true)]

namespace McKinstry.Viewpoint.ARImport
{
    class Program
    {
        public static string Name
        {
            get
            {
                return "McKinstry Viewpoint AR Import";
            }
        }

        static void Main(string[] args)
        {
            // Intialize settings
            Settings settings = new Settings();
            // Initialize logger
            ILog log = LoggingHelper.CreateLogger(typeof(Program), Settings.LogFileFolderLocation, Settings.LogFileName);
            RLBImportBatch batch = new RLBImportBatch();
            string importFile = args.Length > 0 ? args[0] : null;

            try
            {
                log.Info(string.Format("--Begin {0}--", Program.Name));

                // Check command arguments
                log.Info("Checking command input for AR import file.");
                if (string.IsNullOrEmpty(importFile))
                {
                    log.Info("Missing command argument. Import file name is required.");
                    goto EndProcess;
                }

                log.Info("Create data structures required by CommandInvoker.");
                ARImportFile file = new ARImportFile(importFile);
                batch = new RLBImportBatch
                {
                    FileName = file.FileName,
                    LastWriteTime = file.LastWriteTime,
                    Length = file.Length,
                    Type = "AR",
                    RLBImportBatchStatusCode = "PRO",
                    StartTime = DateTime.Now,
                    CompleteTime = null,
                    ArchiveFolderName = file.ArchivePath,
                    Created = DateTime.Now,
                    Modified = DateTime.Now
                };
                log.Info("Finished data structures.");

                CommandInvoker cmd = new CommandInvoker();

                cmd.GetCommand(typeof(ARImport.CheckImportFileCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.CheckBatchExistsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.LogBatchCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.ExtractFilesCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.CheckImagesFolderCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.ArchiveFilesCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.AddDetailRecordsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.ProcessDetailRecordsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.AddRecordsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.UpdateBatchCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.DeleteImportFileCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ARImport.EmailCommand)).RunWith(log, importFile, batch, file);

                EndProcess:

                log.Info(string.Format("--End {0}--", Program.Name));
            }
            catch (Exception ex)
            {
                // Log exception
                log.Error("An error has occurred.", ex);
                log.Info(string.Format("--End {0}--", Program.Name));
                batch.RLBImportBatchStatusCode = "ERR";
                MckIntegrationDb.UpdateImportBatch(batch);
                // Send process file to junk folder
                if (File.Exists(importFile))
                {
                    bool moved = ImportFileHelper.MoveFileToProcessJunkFolder(importFile);
                    log.InfoFormat("Move import file to the process junk folder.  Moved: {0}", moved);
                }
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
