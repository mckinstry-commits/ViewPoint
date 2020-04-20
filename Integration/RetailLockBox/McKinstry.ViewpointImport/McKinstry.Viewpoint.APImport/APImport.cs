using System;
using LINQtoCSV;
using log4net;
using System.Net.Mail;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APImport
{
    internal class APImport
    {
        int batchID = 0;
        string importBatchID = null;
        string importFile = null;

        public string Name
        {
            get
            {
                return "McKinstry Viewpoint AP Import";
            }
        }

        // Hide default constructor
        private APImport() { }

        /// <summary>
        /// Create APImport class.  Set import batch ID.
        /// </summary>
        public APImport(string importBatchID) 
        {
            this.importBatchID = importBatchID;
            Settings settings = new Settings();
        }

        /// <summary>
        /// Run AP import commands.
        /// </summary>
        public void RunImport()
        {
            // Initialize logger
            ILog log = LoggingHelper.CreateLogger(typeof(Program), APSettings.APLogFileFolderLocation, Settings.LogFileName);
            RLBImportBatch batch = new RLBImportBatch();

            try
            {

                log.Info(string.Format("--Begin {0}--", this.Name));

                log.Info("Checking for valid AP import file.");

                // Validate import file ID
                bool batchIDValid = Int32.TryParse(importBatchID, out batchID);
                if (!batchIDValid)
                {
                    throw new ApplicationException("Selected import file missing ID. Must be a valid integer.");
                }

                // Validate AP import batch
                batch = MckIntegrationDb.GetImportBatch(batchID);
                if (batch == default(RLBImportBatch))
                {
                    throw new ApplicationException("Selected import file not valid. Cannot create AP import batch.");
                }

                // Create AP file
                log.Info("Create data structures required by CommandInvoker.");
                importFile = Path.Combine(CommonSettings.RlbDownloadFileDrop, batch.FileName);
                APImportFile file = new APImportFile(importFile);

                // Set transaction date (current date for AP)
                log.Info("Set import file transaction date.");
                file.TransactionDate = DateTime.Now;

                // Fetch record count from RLB data file
                IEnumerable<string> dataFiles = ImportFileHelper.FetchFiles(file.ProcessExtractPath, ".csv");
                var dataFile = dataFiles.FirstOrDefault<string>();
                if (string.IsNullOrEmpty(dataFile))
                {
                    throw new ApplicationException(string.Format("Unable to find extracted AP data file in folder '{0}'.", file.ProcessExtractPath));
                }
                FileInfo dataFileInfo = new FileInfo(dataFile);
                file.DataFileName = dataFileInfo.Name;

                CsvContext cc = new CsvContext();
                CsvFileDescription inputFileDescription = new CsvFileDescription
                {
                    SeparatorChar = ',',
                    FirstLineHasColumnNames = true
                };

                List<APRecord> records = cc.Read<APRecord>(dataFile, inputFileDescription).ToList<APRecord>();
                int count = records.Count();

                file.RecordCount = count;
                log.InfoFormat("Setting file record count from data file '{0}'.  Found records: {1}.", file.DataFileName, count);

                log.Info("Finished data structures and check.");

                // Check exception file counts.  Report to user if totals are the same.
                string[] exceptionFiles = Directory.Exists(file.ExceptionsPath) ? Directory.GetFiles(file.ExceptionsPath, "*.pdf",
                    SearchOption.TopDirectoryOnly).Select(f => Path.GetFileName(f)).ToArray<string>() : new string[0];
                log.InfoFormat("Finding exception images in {0} folder. Found: {1}.", file.ExceptionsFolder, exceptionFiles.Length);

                List<RLBAPImportDetail> existingExceptions = APImportDb.GetExistingAPExceptions(batch.RLBImportBatchID);
                int existingCount = existingExceptions.Count;
                log.InfoFormat("Finding existing exception detail records. Found: {0}.", existingCount);

                if (exceptionFiles.Length <= existingCount)
                {
                    StringBuilder sb = new StringBuilder();
                    sb.AppendLine(string.Format("No new exceptions have been found. Exception file total in {0} folder is less than or equal to the exceptions total before AP manual processing.", file.ExceptionsFolder));
                    sb.AppendLine("");
                    sb.AppendLine(string.Format("Exception files: {0}.  Exceptions prior to AP manual processing: {1}.", exceptionFiles.Length, existingCount));
                    sb.AppendLine("");
                    sb.AppendLine("Do you want to continue processing?");

                    DialogResult dialogResult = MessageBox.Show(sb.ToString(), "No New Exceptions Found", MessageBoxButtons.YesNo);
                    if (dialogResult == DialogResult.No)
                    {
                        goto EndProcess;
                    }
                }

                // Begin final AP file processing 
                CommandInvoker cmd = new CommandInvoker();

                cmd.GetCommand(typeof(ProcessExistingRecordsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(ProcessNewExceptionsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(AddRecordsCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(UpdateBatchCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(DeleteImportFileCommand)).RunWith(log, importFile, batch, file);
                cmd.GetCommand(typeof(EmailCommand)).RunWith(log, importFile, batch, file);

            EndProcess:

                log.Info(string.Format("--End {0}--", this.Name));
            }
            catch (Exception ex)
            {
                // Log exception
                log.Error("An error has occurred.", ex);
                log.Info(string.Format("--End {0}--", this.Name));
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
                    MailHelper.SendErrorEmail(this.Name, Settings.FromEmail, Settings.FromEmailDisplayName,
                        Settings.ToEmail, Settings.CcEmail, Settings.EmailSubject, new Attachment(logFile));
                }
            }
        }
    }
}
