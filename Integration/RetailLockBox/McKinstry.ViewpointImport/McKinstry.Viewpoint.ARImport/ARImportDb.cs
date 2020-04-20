using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity.Core.Objects;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class ARImportDb : Db
    {
        public static int CreateARImportDetail(int importBatchID, FileInfo dataFile, ARRecord record)
        {
            RLBARImportDetail detail;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                detail = ctx.RLBARImportDetails.Add(
                    new RLBARImportDetail
                    {
                        RLBImportBatchID = importBatchID,
                        FileName = dataFile.Name,
                        LastWriteTime = dataFile.LastWriteTime,
                        Length = dataFile.Length,
                        RLBImportDetailStatusCode = "UNP",
                        RLBProcessNotesID = null,
                        Created = DateTime.Now,
                        Modified = DateTime.Now,
                        Company = record.Company,
                        InvoiceNumber = record.InvoiceNumber,
                        CustGroup = record.CustGroup,
                        Customer = record.Customer,
                        CustomerName = record.CustomerName,
                        TransactionDate = record.TransactionDate,
                        InvoiceDescription = record.InvoiceDescription,
                        DetailLineCount = record.DetailLineCount,
                        AmountDue = record.AmountDue,
                        OriginalAmount = record.OriginalAmount,
                        Tax = record.Tax,
                        CollectedCheckDate = record.CollectedCheckDate,
                        CollectedCheckNumber = record.CollectedCheckNumber,
                        CollectedCheckAmount = record.CollectedCheckAmount,
                        CollectedImage = record.CollectedImage,
                        Notes = record.Notes
                    });
                ctx.SaveChanges();
            }
            return detail.RLBARImportDetailID;
        }

        public static int CreaeARImportRecord(int importDetailID, ARBH headerRecord, HQAT attachmentRecord, bool? fileCopied, int? processNotesID)
        {
            RLBARImportRecord record;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                record = ctx.RLBARImportRecords.Add(
                    new RLBARImportRecord
                    {
                        RLBARImportDetailID = importDetailID,
                        Co = (headerRecord.Co == 0) ? null : (byte?)headerRecord.Co,
                        Mth = (headerRecord.Mth == DateTime.MinValue) ? null : (DateTime?)headerRecord.Mth,
                        BatchId = (headerRecord.BatchId == 0) ? null : (int?)headerRecord.BatchId,
                        BatchSeq = (headerRecord.BatchSeq == 0) ? null : (int?)headerRecord.BatchSeq,
                        CMDeposit = headerRecord.CMDeposit,
                        CheckNo = headerRecord.CheckNo,
                        CheckDate = headerRecord.oldCheckDate,
                        TransDate = headerRecord.TransDate,
                        CreditAmt = headerRecord.CreditAmt,
                        HeaderKeyID = (headerRecord.KeyID == 0) ? null : (long?)headerRecord.KeyID,
                        DocName = attachmentRecord.DocName,
                        AttachmentID = (attachmentRecord.AttachmentID == 0) ? null : (int?)attachmentRecord.AttachmentID,
                        UniqueAttchID = attachmentRecord.UniqueAttchID,
                        OrigFileName = attachmentRecord.OrigFileName,
                        FileCopied = fileCopied,
                        RLBProcessNotesID = processNotesID,
                        Created = DateTime.Now,
                        Modified = DateTime.Now
                    });
                ctx.SaveChanges();
            }
            return record.RLBARImportRecordID;
        }

        public static bool UpdateARImportDetail(int importDetailID, string statusCode, int? processNotesID)
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var existing = (from b in ctx.RLBARImportDetails
                                where b.RLBARImportDetailID == importDetailID
                                select b).FirstOrDefault();

                if (existing == default(RLBARImportDetail))
                {
                    return false;
                }

                existing.RLBProcessNotesID = processNotesID;
                existing.RLBImportDetailStatusCode = statusCode;
                existing.Modified = DateTime.Now;
                ctx.SaveChanges();
                return true;
            }
        }

        public static bool UpdateARImportDetail(int importDetailID, string statusCode, string processNote)
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int? processNotesID = null;
                if (!string.IsNullOrEmpty(processNote))
                {
                    processNotesID = MckIntegrationDb.CreateProcessNote(processNote);
                }
                return UpdateARImportDetail(importDetailID, statusCode, processNotesID);
            }
        }

        public static List<RLBARImportDetail> GetUnprocessedARDetailRecords(int batchID)
        {
            List<RLBARImportDetail> list = default(List<RLBARImportDetail>);
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                list = ctx.RLBARImportDetails.AsNoTracking()
                    .Where(r => (r.RLBImportBatchID == batchID) && (r.RLBImportDetailStatusCode == "UNP"))
                    .Select(r => r)
                    .ToList<RLBARImportDetail>();
            }
            return list;
        }

        public static List<RecordSummary> GetARDetailRecordCounts(int recordCount, int batchID)
        {
            List<RecordSummary> list = new List<RecordSummary>();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var detailItems = ctx.RLBARImportDetails
                    .Where(r => r.RLBImportBatchID == batchID)
                    .Select(r => r)
                    .ToList<RLBARImportDetail>();

                int detailCount = detailItems.Count();

                var items = detailItems.GroupBy(r => r.RLBImportDetailStatusCode)
                    .Select(g => new
                    {
                        StatusCode = g.Key,
                        Status = ctx.RLBImportDetailStatus.Where(s => s.StatusCode == g.Key).Select(s => s.Status).FirstOrDefault<string>(),
                        Count = g.Count()
                    });
                items = items.OrderBy(i => i.Status);
                int count = items.Count();
                foreach (var item in items)
                {
                    list.Add(new RecordSummary { Count = item.Count, Status = item.Status });
                }
                if (recordCount > detailCount)
                {
                    list.Add(new RecordSummary { Count = recordCount - detailCount, Status = "Missing Records" });
                }
            }
            return list;
        }

        public static List<RecordSummary> GetARProcessingCounts(int recordCount, int batchID)
        {
            List<RecordSummary> list = new List<RecordSummary>();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var detailItems = ctx.RLBARImportDetails
                    .Where(r => r.RLBImportBatchID == batchID)
                    .Select(r => r).ToArray<RLBARImportDetail>();

                int errorItems = detailItems.Where(r => r.RLBImportDetailStatusCode == "ERR")
                   .Select(r => r)
                   .Count();

                int unprocessedItems = detailItems.Where(r => r.RLBImportDetailStatusCode == "UNP")
                   .Select(r => r)
                   .Count();

                var recordItems = ctx.mckvwRLBARImportRecords
                    .Where(r => r.RLBImportBatchID == batchID)
                    .Select(r => r).ToArray<mckvwRLBARImportRecord>();

                int filesNotCopied = recordItems.Where(r => Convert.ToBoolean(r.FileCopied) == false)
                   .Select(r => r)
                   .Count();

                int missingAttachments = recordItems.Where(r => (r.AttachmentID == null) || (r.AttachmentID == 0))
                   .Select(r => r)
                   .Count();

                list.Add(new RecordSummary { Status = "Files Not Copied", Count = filesNotCopied });
                list.Add(new RecordSummary { Status = "Missing Attachments", Count = missingAttachments });
                list.Add(new RecordSummary { Status = "Missing Records", Count = recordCount - detailItems.Length });
                list.Add(new RecordSummary { Status = "Errors", Count = errorItems });
                list.Add(new RecordSummary { Status = "Unprocessed Records", Count = unprocessedItems });
            }
            return list;
        }

        public static ARBH GetARHeaderRecord(long? headerID)
        {
            ARBH header = new ARBH();
            if (headerID.HasValue)
            {
                using (var ctx = new ViewpointEntities(ViewpointConnectionString))
                {
                    var existing = (from h in ctx.ARBHs
                                    where h.KeyID == headerID
                                    select h).FirstOrDefault();
                    if (existing != default(ARBH))
                    {
                        return existing;
                    }
                }
            }
            return header;
        }

        public static bool AddARRecord(DateTime transactionDate, string module, string form, string userAccount, 
            RLBARImportDetail record, out ARDetailUploadResults results)
        {
            try
            {
                using (var ctx = new ViewpointEntities(ViewpointConnectionString))
                {
                    // Turn off transactions from entity framework perspective.  Our procs use db transactions internally.
                    ctx.Configuration.EnsureTransactionsForFunctionsAndCommands = false;

                    ObjectParameter batchID = new ObjectParameter("batchId", typeof(long));
                    ObjectParameter headerKeyID = new ObjectParameter("headerKeyID", typeof(long));
                    ObjectParameter attachmentID = new ObjectParameter("attachmentID", typeof(int));
                    ObjectParameter message = new ObjectParameter("message", typeof(string));
                    ObjectParameter retVal = new ObjectParameter("retVal", typeof(int));

                    ctx.mckspARBHAddItemWithFile(record.Company, transactionDate, record.Customer, record.CustGroup, record.CollectedCheckAmount,
                        module, form, record.InvoiceNumber, record.CollectedCheckNumber, record.CollectedCheckDate,
                        record.CollectedImage, userAccount, batchID, headerKeyID, attachmentID, message, retVal);

                    results = new ARDetailUploadResults
                    {
                        BatchID = (batchID.Value == DBNull.Value) ? default(int?) : Convert.ToInt32(batchID.Value),
                        HeaderKeyID = (headerKeyID.Value == DBNull.Value) ? default(long?) : Convert.ToInt64(headerKeyID.Value),
                        AttachmentID = (attachmentID.Value == DBNull.Value) ? default(int?) : Convert.ToInt32(attachmentID.Value),
                        Message = message.Value == DBNull.Value ? null : message.Value.ToString(),
                        RetVal = (retVal.Value == DBNull.Value) ? -1 : Convert.ToInt32(retVal.Value)
                    };
                }
                return true;
            }
            catch (Exception ex)
            {
                results = new ARDetailUploadResults();
                results.Message = string.Format("Execution Exception: {0}.", ex.GetBaseException().Message);
                return false;
            }
        }
    }
}
