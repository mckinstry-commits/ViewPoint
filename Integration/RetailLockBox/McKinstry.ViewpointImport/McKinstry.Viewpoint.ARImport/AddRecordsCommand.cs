using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Data.Entity.Validation;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class AddRecordsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Add AR Records Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Adds unprocessed AR records to the viewpoint database. Adds AR Upload record to the integration database.  Updates detail records";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Adding unprocessed AR records to the database.");

            List<RLBARImportDetail> records = ARImportDb.GetUnprocessedARDetailRecords(batch.RLBImportBatchID);

            foreach (var record in records)
            {
                ARDetailUploadResults results = new ARDetailUploadResults();
                int detailRecordID = record.RLBARImportDetailID;

                try
                {
                    log.Info("----------------");
                    bool recordAdded = ARImportDb.AddARRecord(file.TransactionDate, Settings.Module, Settings.Form, Settings.UserAccount, record, out results);
                    log.InfoFormat("Adding AR Record to Viewpoint.  Success: {0}.  Return Value: {1}.", recordAdded, results.RetVal);
                    log.Info("AR record details:");
                    log.InfoFormat("  --> Batch ID: {0}. Header ID: {1}. Attach ID: {2}.", results.BatchID, results.HeaderKeyID, results.AttachmentID);
                    log.InfoFormat("  --> Message: '{0}'", results.Message);
                    ARBH headerRecord = ARImportDb.GetARHeaderRecord(results.HeaderKeyID);
                    HQAT attachmentRecord = ViewpointDb.GetAttachmentRecord(results.AttachmentID);
                    string sourceFile = Path.Combine(file.ProcessExtractPath, record.CollectedImage);
                    string destFile = attachmentRecord.DocName;
                    bool? fileCopied = ImportFileHelper.CopyImageFile(sourceFile, destFile);
                    log.InfoFormat("Copying image file.  Success: {0}.", fileCopied);
                    log.InfoFormat("Image source: '{0}.'", sourceFile);
                    log.InfoFormat("Image destination: '{0}.'", destFile);
                    int processNoteID = MckIntegrationDb.CreateProcessNote(results.Message);
                    int recordID = ARImportDb.CreaeARImportRecord(detailRecordID, headerRecord, attachmentRecord, fileCopied, processNoteID);
                    log.InfoFormat("Adding AR Import Record to Integration.  Success: {0}. ID: {1}.", recordID > 0, recordID);
                    string status = (results.HeaderKeyID > 0) ? "MAT" : "STN";
                    status = recordAdded ? status : "ERR";
                    bool detailUpdated = ARImportDb.UpdateARImportDetail(detailRecordID, status, processNoteID);
                    log.InfoFormat("Updating AR Import Detail in Integration.  Success: {0}. Status: '{1}'.", detailUpdated, status);
                }
                catch (DbEntityValidationException ex)
                {
                    var errorMessages = ex.EntityValidationErrors
                    .SelectMany(x => x.ValidationErrors)
                    .Select(x => x.ErrorMessage);

                    int? processNoteRecordId = MckIntegrationDb.CreateProcessNote(errorMessages.First());
                    ARImportDb.UpdateARImportDetail(detailRecordID, "ERR", processNoteRecordId);

                    foreach (var message in errorMessages)
                    {
                        log.Error(string.Concat("Record add exception: ", message), ex);
                    }
                }
                catch (Exception ex)
                {
                    int? processNoteRecordId = MckIntegrationDb.CreateProcessNote(ex.Message);
                    ARImportDb.UpdateARImportDetail(detailRecordID, "ERR", processNoteRecordId);
                    log.Error("Record add exception.", ex);
                }
            }

            log.Info("----------------");
            log.Info("Done adding unprocessed records.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
