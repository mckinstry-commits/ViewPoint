using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessMissingImagesCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Missing Image Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AP records with missing images.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP missing image detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            var missingImages = records.Where(r => ImportFileHelper.RecordImageIsMissing(file.ProcessExtractPath, r.CollectedImage))
                        .Select(r => r)
                        .ToList<RLBAPImportDetail>();
            log.InfoFormat("Finding missing images. Found: {0}.", missingImages.Count());

            foreach (var missingImage in missingImages)
            {
                bool updated = MckIntegrationDb.UpdateAPImportDetail(missingImage.RLBAPImportDetailID, "MIS", default(int?));
                log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", missingImage.RLBAPImportDetailID, "MIS", updated);
            }

            log.Info("Done processing AP missing image detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
