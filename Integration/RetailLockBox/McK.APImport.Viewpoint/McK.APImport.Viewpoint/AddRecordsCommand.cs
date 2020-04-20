using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using McK.APImport.Common;
using McK.Data.Viewpoint;

namespace McK.APImport.Viewpoint
{
    internal class AddRecordsCommand : ICommand
    {
        public string Name => "Add AP Records Command";

        public string Description => "Adds unprocessed AP records to the viewpoint database. Adds AP Upload record to the integration database.  Updates detail records";

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Adding unprocessed AP records to the database.");

            List<RLBAPImportDetail> records = MckIntegrationDb.GetUnprocessedAPDetailRecords(batch.RLBImportBatchID);

            foreach (var record in records)
            {
                APRecordUploadResults results = new APRecordUploadResults();
                int detailRecordID = record.RLBAPImportDetailID;

                try
                {
                    log.Info("----------------");
                    bool recordAdded = APImportDb.AddAPRecord(file.TransactionDate, record, out results);
                    log.InfoFormat("Adding AP Record to Viewpoint.  Success: {0}.  Return Value: {1}.", recordAdded, results.RetVal);
                    log.Info("AP record details:");
                    log.InfoFormat("  --> Header ID: {0}. Footer ID: {1}. Attach ID: {2}.", results.HeaderKeyID, results.FooterKeyID, results.AttachmentID);
                    log.InfoFormat("  --> Message: '{0}'", results.Message);
                    HQAT attachmentRecord = ViewpointDb.GetAttachmentRecord(results.AttachmentID);
                    APUI headerRecord = ViewpointDb.GetAPUIRecord(results.HeaderKeyID);
                    string sourceFile = Path.Combine(file.ProcessExtractPath, record.CollectedImage);
                    string destFile = attachmentRecord.DocName;
                    bool? fileCopied = ImportFileHelper.CopyImageFile(sourceFile, destFile);
                    log.InfoFormat("Copying image file.  Success: {0}.", fileCopied);
                    log.InfoFormat("Image source: '{0}'.", sourceFile);
                    log.InfoFormat("Image destination: '{0}'.", destFile);
                    dynamic processNoteID = MckIntegrationDb.CreateProcessNote(results.Message);
                    dynamic recordID = APImportDb.CreateAPImportRecord(detailRecordID, results, headerRecord, attachmentRecord, fileCopied, processNoteID);
                    log.InfoFormat("Adding AP Import Record to Integration.  Success: {0}. ID: {1}.", recordID != null, recordID);
                    string status = APImportDb.GetRLBImportDetailStatusCode(recordID);
                    status = recordAdded ? status : "ERR";
                    bool detailUpdated = MckIntegrationDb.UpdateAPImportDetail(detailRecordID, status, processNoteID);
                    log.InfoFormat("Updating AP Import Detail in Integration.  Success: {0}. Status: '{1}'.", detailUpdated, status);
                }
                //catch (DbEntityValidationException ex)
                //{
                //    var errorMessages = ex.EntityValidationErrors
                //    .SelectMany(x => x.ValidationErrors)
                //    .Select(x => x.ErrorMessage);

                //    int? processNoteRecordId = MckIntegrationDb.CreateProcessNote(errorMessages.First());
                //    MckIntegrationDb.UpdateAPImportDetail(detailRecordID, "ERR", processNoteRecordId);

                //    foreach (var message in errorMessages)
                //    {
                //        log.Error(string.Concat("Record add exception: ", message), ex);
                //    }
                //}
                catch (Exception ex)
                {
                    int? processNoteRecordId = MckIntegrationDb.CreateProcessNote(ex.Message);
                    MckIntegrationDb.UpdateAPImportDetail(detailRecordID, "ERR", processNoteRecordId);
                    log.Error("Record add exception.", ex);
                }
            }

            log.Info("----------------");
            log.Info("Done adding unprocessed records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
