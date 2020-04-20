using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessSecondMatchCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Second Match Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Finds second AP match items in unprocessed AP detail records.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP second match records from unprocessed unmatched records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            var unmatched = records.Where(r => APProcessHelper.RecordIsUnmatched(r))
                        .Select(r => r)
                        .ToList<RLBAPImportDetail>();

            log.InfoFormat("Finding additional matched items in unmatched records. Unmatched count: {0}.", unmatched.Count());

            if (unmatched.Count() > 0)
            {
                List<mvwRLBAPExport> exportItems = ViewpointDb.GetAPExportItems();

                foreach (var record in unmatched)
                {
                    RLBAPImportDetail secondMatchRecord = APProcessHelper.FetchSecondMatch(record, exportItems);
                    if (secondMatchRecord != null)
                    {
                        // Do second exception check for good measure
                        if (APProcessHelper.RecordIsException(secondMatchRecord))
                        {
                            bool updated = MckIntegrationDb.UpdateAPImportDetail(record.RLBAPImportDetailID, "EXC", default(int?));
                            log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", record.RLBAPImportDetailID, "EXC", updated);
                            string imageName = Path.GetFileName(secondMatchRecord.CollectedImage);
                            bool copied = ImportFileHelper.CopyImageFile(Path.Combine(file.ProcessExtractPath, secondMatchRecord.CollectedImage), Path.Combine(file.ExceptionsPath, imageName));
                            log.InfoFormat("Copying file '{0}' to {1} folder. Success: {2}", imageName, file.ExceptionsFolder, copied);
                            continue;
                        }
                        bool matchUpated = APProcessDb.UpdateAPImportDetailSecondMatch(record);
                        log.InfoFormat("Updating unmatched record as matched. ID: {0}. Success: {1}", record.RLBAPImportDetailID, matchUpated);
                    }
                }
            }

            log.Info("Done processing AP second match records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
