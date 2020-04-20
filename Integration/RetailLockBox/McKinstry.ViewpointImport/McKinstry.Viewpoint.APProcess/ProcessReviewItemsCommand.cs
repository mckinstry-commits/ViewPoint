using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessReviewItemsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Review Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Moves unprocessed review AP detail records to Review folder.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP review detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            var reviewItems = records.Where(r => APProcessHelper.RecordIsMatched(r))
                        .Select(r => r)
                        .ToList<RLBAPImportDetail>();

            log.InfoFormat("Finding review items. Found: {0}.", reviewItems.Count());

            ImportFileHelper.EnsureDirectory(file.ReviewPath);

            foreach (var item in reviewItems)
            {
                string imageName = Path.GetFileName(item.CollectedImage);
                bool copied = ImportFileHelper.CopyImageFile(Path.Combine(file.ProcessExtractPath, item.CollectedImage), Path.Combine(file.ReviewPath, imageName));
                log.InfoFormat("Copying file '{0}' to {1} folder. Success: {2}", imageName, file.ReviewFolder, copied);
            }

            log.Info("Done processing AP review detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
