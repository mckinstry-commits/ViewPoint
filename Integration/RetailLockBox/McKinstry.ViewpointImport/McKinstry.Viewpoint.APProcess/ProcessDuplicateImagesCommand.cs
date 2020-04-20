using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessDuplicateImagesCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Duplicate Image Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AP records with duplicate images.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP duplicate image detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            var dupImages = records.Where(r => !string.IsNullOrEmpty(r.CollectedImage))
                    .GroupBy(r => new { r.CollectedImage })
                    .Where(g => g.Count() > 1)
                    .Select(g => g.Key);

            log.InfoFormat("Finding duplicate images. Found: {0}.", dupImages.Count());

            foreach (var dup in dupImages)
            {
                // Fetch duplicate records from records list matching invoice number and amount, sort by record type
                var foundDupes = records
                    .Where(r => r.CollectedImage == dup.CollectedImage)
                    .OrderByDescending(r => r.RecordType)
                    .Select(r => r)
                    .ToArray<RLBAPImportDetail>();

                if (foundDupes.Length > 0)
                {
                    for (int i = 1; i < foundDupes.Length; i++)
                    {
                        bool updated = MckIntegrationDb.UpdateAPImportDetail(foundDupes[i].RLBAPImportDetailID, "DUI", default(int?));
                        log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", foundDupes[i].RLBAPImportDetailID, "DUI", updated);
                    }
                }
            }

            log.Info("Done processing AP missing image detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
