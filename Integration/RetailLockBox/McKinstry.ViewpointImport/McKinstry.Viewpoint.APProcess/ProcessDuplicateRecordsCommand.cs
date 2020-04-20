using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ProcessDuplicateRecordsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Process AP Duplicate Detail Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates unprocessed AP records with duplicates.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Processing AP duplicate detail records.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            // Fetch duplicate invoice numbers and invoice amounts from records
            var duplicates = records.Where(r => !string.IsNullOrEmpty(r.CollectedInvoiceNumber))
                .GroupBy(r => new { r.CollectedInvoiceNumber, r.CollectedInvoiceAmount })
                .Where(g => g.Count() > 1)
                .Select(g => g.Key);

            log.InfoFormat("Finding duplicate records in batch. Found: {0}.", duplicates.Count());

            // Select duplicate records, keep the first of each, handle the rest as duplicate records in separate folders
            foreach (var dup in duplicates)
            {
                // Fetch duplicate records from records list matching invoice number and amount, sort by record type
                var foundDupes = records
                    .Where(r => (r.CollectedInvoiceNumber == dup.CollectedInvoiceNumber) &&
                        (r.CollectedInvoiceAmount == dup.CollectedInvoiceAmount))
                    .OrderByDescending(r => r.RecordType)
                    .Select(r => r)
                    .ToArray<RLBAPImportDetail>();

                if (foundDupes.Length > 0)
                {
                    for (int i = 1; i < foundDupes.Length; i++)
                    {
                        bool updated = MckIntegrationDb.UpdateAPImportDetail(foundDupes[i].RLBAPImportDetailID, "DUR", default(int?));
                        log.InfoFormat("Updating record ID: {0}, Status: '{1}', Success: {2}", foundDupes[i].RLBAPImportDetailID, "DUR", updated);
                    }
                }
            }

            log.Info("Done processing AP duplicate detail records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
