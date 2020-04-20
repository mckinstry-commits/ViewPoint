using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessStatementsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Statement Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AP statement records.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP statement detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            var statements = records.Where(r => APProcessHelper.RecordIsStatement(r))
                        .Select(r => r)
                        .ToList<RLBAPImportDetail>();

            log.InfoFormat("Finding statements. Found: {0}.", statements.Count());

            ImportFileHelper.EnsureDirectory(file.StatementsPath);

            foreach (var statement in statements)
            {
                bool updated = MckIntegrationDb.UpdateAPImportDetail(statement.RLBAPImportDetailID, "STA", default(int?));
                log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", statement.RLBAPImportDetailID, "STA", updated);
                string imageName = Path.GetFileName(statement.CollectedImage);
                bool copied = ImportFileHelper.CopyImageFile(Path.Combine(file.ProcessExtractPath, statement.CollectedImage), Path.Combine(file.StatementsPath, imageName));
                log.InfoFormat("Copying file '{0}' to {1} folder. Success: {2}", imageName, file.StatementsFolder, copied);
            }

            log.Info("Done processing AP statement detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
