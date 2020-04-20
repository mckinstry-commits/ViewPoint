using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessExceptionsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Exception Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AP exception records and moves images to exceptions folder.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP exception detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            var exceptions = records.Where(r => APProcessHelper.RecordIsException(r))
                        .Select(r => r)
                        .ToList<RLBAPImportDetail>();

            log.InfoFormat("Finding exceptions. Found: {0}.", exceptions.Count());

            ImportFileHelper.EnsureDirectory(file.ExceptionsPath);

            foreach (var exception in exceptions)
            {
                bool updated = MckIntegrationDb.UpdateAPImportDetail(exception.RLBAPImportDetailID, "EXC", default(int?));
                log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", exception.RLBAPImportDetailID, "EXC", updated);
                string imageName = Path.GetFileName(exception.CollectedImage);
                bool copied = ImportFileHelper.CopyImageFile(Path.Combine(file.ProcessExtractPath, exception.CollectedImage), Path.Combine(file.ExceptionsPath, imageName));
                log.InfoFormat("Copying file '{0}' to {1} folder. Success: {2}", imageName, file.ExceptionsFolder, copied);
            }

            log.Info("Done processing AP exception detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
