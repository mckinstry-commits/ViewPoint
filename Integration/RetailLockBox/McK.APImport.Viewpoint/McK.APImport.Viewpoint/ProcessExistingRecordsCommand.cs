using System;
using log4net;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McK.APImport.Common;
using McK.Data.Viewpoint;

namespace McK.APImport.Viewpoint
{
    internal class ProcessExistingRecordsCommand : ICommand
    {
        public string Name => "Process AP Existing Detail Records Command";

        public string Description => "Updates unprocessed AP records with records existing in Viewpoint.";

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP existing detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);
            List<mvwAPAllInvoice> allInvoices = ViewpointDb.GetAllAPInvoices();

            var existing = records.Where(r => ViewpointDb.APRecordExitsInViewpoint(r, allInvoices)).Select(r => r);

            foreach (var record in existing)
            {
                bool updated = MckIntegrationDb.UpdateAPImportDetail(record.RLBAPImportDetailID, "DUR", null);
                log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", record.RLBAPImportDetailID, "DUR", updated);
            }

            log.Info("Done processing AP duplicate detail records in Viewpoint.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
