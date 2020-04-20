using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class ProcessDetailRecordsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AR Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AR detail records.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AR detail records.");

            List<RLBARImportDetail> records = ARImportDb.GetUnprocessedARDetailRecords(batch.RLBImportBatchID);
            int count = records.Count();

            if (count <= 0)
            {
                throw new ApplicationException(string.Format("Did not find unprocessed detail records for batch. Count: {0}.  Batch file: '{1}'.", count, batch.FileName));
            }

            var missingImages = records.Where(r => ImportFileHelper.RecordImageIsMissing(file.ProcessExtractPath, r.CollectedImage))
                        .Select(r => r)
                        .ToList<RLBARImportDetail>();
            log.InfoFormat("Finding missing images. Found: {0}.", missingImages.Count());

            foreach (var missingImage in missingImages)
            {
                ARImportDb.UpdateARImportDetail(missingImage.RLBARImportDetailID, "MIS", default(int?));
            }

            log.Info("Done processing AR detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
