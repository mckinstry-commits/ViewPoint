using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APImport
{
    internal class ProcessNewExceptionsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process New AP Exceptions Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AP records with new exceptions added to Exceptions folder in AP manual processing.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing new AP exceptions.");

            string[] exceptionFiles = Directory.Exists(file.ExceptionsPath) ? Directory.GetFiles(file.ExceptionsPath, "*.pdf",
                    SearchOption.TopDirectoryOnly).Select(f => Path.GetFileName(f)).ToArray<string>() : new string[0];
            log.InfoFormat("Finding exception images in Exceptions folder. Found: {0}.", exceptionFiles.Length);

            List<RLBAPImportDetail> existingExceptions = APImportDb.GetExistingAPExceptions(batch.RLBImportBatchID);
            int existingCount = existingExceptions.Count;
            log.InfoFormat("Finding existing exception detail records. Found: {0}.", existingCount);

            List<RLBAPImportDetail> detailRecords = MckIntegrationDb.GetAPDetailRecords(batch.RLBImportBatchID);

            List<RLBAPImportDetail> newExceptions = detailRecords
                .Where(r => exceptionFiles.Where(e => e == Path.GetFileName(r.CollectedImage)).Any()).ToList<RLBAPImportDetail>();

            log.Info("Processing final exception detail records after AP manual processing.");
            log.InfoFormat("Final exceptions count: {0}. File count in Exceptions folder: {1}.", newExceptions.Count, exceptionFiles.Length);

            if (newExceptions.Count != exceptionFiles.Length)
            {
                throw new ApplicationException(string.Format("Unable to find detail records for all files in Exceptions folder. Detail records: {0}. Exception files: {1}.", newExceptions.Count, exceptionFiles.Length));
            }

            log.InfoFormat("Resetting existing exception detail records. Count: {0}.", existingCount);
            foreach (var exception in existingExceptions)
            {
                bool updated = MckIntegrationDb.UpdateAPImportDetail(exception.RLBAPImportDetailID, "UNP", default(int?));
                log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", exception.RLBAPImportDetailID, "UNP", updated);
            }

            log.InfoFormat("Adding final exception detail records. Count: {0}.", newExceptions.Count);
            foreach (var exception in newExceptions)
            {
                bool updated = MckIntegrationDb.UpdateAPImportDetail(exception.RLBAPImportDetailID, "EXC", default(int?));
                log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", exception.RLBAPImportDetailID, "EXC", updated);
            }

            log.Info("Done processing new AP exception records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
