using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity.Core.Objects;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APImport
{
    internal class APImportDb : Db
    {
        public static new List<RLBAPImportDetail> GetExistingAPExceptions(int batchID)
        {
            List<RLBAPImportDetail> exceptions = new List<RLBAPImportDetail>();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                exceptions = ctx.RLBAPImportDetails.AsNoTracking()
                    .Where(r => (r.RLBImportBatchID == batchID) && (r.RLBImportDetailStatusCode == "EXC"))
                    .Select(r => r)
                    .ToList<RLBAPImportDetail>();
            }
            return exceptions;
        }

        public static bool AddAPRecord(DateTime transactionDate, RLBAPImportDetail record, out APRecordUploadResults results)
        {
            try
            {
                using (var ctx = new ViewpointEntities(ViewpointConnectionString))
                {
                    // Turn off transactions from entity framework perspective.  Our procs use db transactions internally.
                    ctx.Configuration.EnsureTransactionsForFunctionsAndCommands = false;

                    ObjectParameter attachmentID = new ObjectParameter("attachmentID", typeof(Int32));
                    ObjectParameter uniqueAttachmentID = new ObjectParameter("uniqueAttachmentID", typeof(Guid));
                    ObjectParameter attachmentFilePath = new ObjectParameter("attachmentFilePath", typeof(string));
                    ObjectParameter headerKeyID = new ObjectParameter("headerKeyID", typeof(long));
                    ObjectParameter footerKeyID = new ObjectParameter("footerKeyID", typeof(long));
                    ObjectParameter message = new ObjectParameter("message", typeof(string));
                    ObjectParameter retVal = new ObjectParameter("retVal", typeof(Int32));

                    ctx.mckspAPUIAddItemWithFile(record.RecordType, record.Company, transactionDate, record.Number,
                        record.VendorGroup, record.Vendor, record.CollectedInvoiceNumber, record.Description, record.CollectedInvoiceDate,
                        record.CollectedInvoiceAmount, record.CollectedTaxAmount, record.CollectedShippingAmount, APSettings.APModule,
                        APSettings.APForm, record.CollectedImage, APSettings.APUserAccount, APSettings.APUnmatchedCompany,
                        APSettings.APUnmatchedVendorGroup, APSettings.APUnmatchedVendor,
                        attachmentID, uniqueAttachmentID, attachmentFilePath, headerKeyID, footerKeyID, message, retVal);

                    results = new APRecordUploadResults
                    {
                        AttachmentID = (attachmentID.Value == DBNull.Value) ? default(int?) : Convert.ToInt32(attachmentID.Value),
                        UniqueAttachmentID = (uniqueAttachmentID.Value == DBNull.Value) ? default(Guid?) : Guid.Parse(uniqueAttachmentID.Value.ToString()),
                        AttachmentFilePath = attachmentFilePath.Value == DBNull.Value ? null : attachmentFilePath.Value.ToString(),
                        HeaderKeyID = (headerKeyID.Value == DBNull.Value) ? default(long?) : Convert.ToInt64(headerKeyID.Value),
                        FooterKeyID = (footerKeyID.Value == DBNull.Value) ? default(long?) : Convert.ToInt64(footerKeyID.Value),
                        Message = message.Value == DBNull.Value ? null : message.Value.ToString(),
                        RetVal = (retVal.Value == DBNull.Value) ? -1 : Convert.ToInt32(retVal.Value)
                    };
                }
                return true;
            }
            catch (Exception ex)
            {
                results = new APRecordUploadResults();
                results.Message = string.Format("Execution Exception: {0}.", ex.GetBaseException().Message);
                return false;
            }
        }

        public static string GetRLBImportDetailStatusCode(int importRecordID)
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                RLBAPImportRecord record = ctx.RLBAPImportRecords.AsNoTracking()
                    .Where(r => (r.RLBAPImportRecordID == importRecordID))
                    .Select(r => r)
                    .FirstOrDefault<RLBAPImportRecord>();
                if (record == default(RLBAPImportRecord))
                {
                    return "UNP";
                }
                if (record.HeaderKeyID.HasValue && record.FooterKeyID.HasValue && record.AttachmentID.HasValue)
                {
                    return "MAT";
                }
                if (record.HeaderKeyID.HasValue && !record.FooterKeyID.HasValue && record.AttachmentID.HasValue)
                {
                    return "UNM";
                }
                if (!record.HeaderKeyID.HasValue && !record.FooterKeyID.HasValue && record.AttachmentID.HasValue)
                {
                    return "STN";
                }
            }
            return "UNP";
        }

        public static int CreateAPImportRecord(int importDetailID, APRecordUploadResults results, APUI headerRecord, HQAT attachmentRecord, bool? fileCopied, int? processNotesID)
        {
            RLBAPImportRecord record;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                record = ctx.RLBAPImportRecords.Add(
                    new RLBAPImportRecord
                    {
                        RLBAPImportDetailID = importDetailID,
                        Co = (headerRecord.APCo == 0) ? null : (byte?)headerRecord.APCo,
                        Mth = (headerRecord.UIMth == DateTime.MinValue) ? null : (DateTime?)headerRecord.UIMth,
                        UISeq = (headerRecord.UISeq == 0) ? null : (short?)headerRecord.UISeq,
                        Vendor = (headerRecord.Vendor == 0) ? null : (int?)headerRecord.Vendor,
                        APRef = headerRecord.APRef,
                        InvDate = (headerRecord.InvDate == DateTime.MinValue) ? null : (DateTime?)headerRecord.InvDate,
                        InvTotal = headerRecord.InvTotal,
                        HeaderKeyID = (headerRecord.KeyID == 0) ? null : (long?)headerRecord.KeyID,
                        FooterKeyID = (results.FooterKeyID == 0) ? null : (long?)results.FooterKeyID,
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
            return record.RLBAPImportRecordID;
        }

        public static List<RecordSummary> GetAPDetailRecordCounts(int recordCount, int batchID)
        {
            List<RecordSummary> list = new List<RecordSummary>();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var detailItems = ctx.RLBAPImportDetails
                    .Where(r => r.RLBImportBatchID == batchID)
                    .Select(r => r)
                    .ToList<RLBAPImportDetail>();

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

        public static List<RecordSummary> GetAPProcessingCounts(int recordCount, int batchID)
        {
            List<RecordSummary> list = new List<RecordSummary>();
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var detailItems = ctx.RLBAPImportDetails
                    .Where(r => r.RLBImportBatchID == batchID)
                    .Select(r => r).ToArray<RLBAPImportDetail>();

                int errorItems = detailItems.Where(r => r.RLBImportDetailStatusCode == "ERR")
                   .Select(r => r)
                   .Count();

                int unprocessedItems = detailItems.Where(r => r.RLBImportDetailStatusCode == "UNP")
                   .Select(r => r)
                   .Count();

                var recordItems = ctx.mckvwRLBAPImportRecords
                    .Where(r => r.RLBImportBatchID == batchID)
                    .Select(r => r).ToArray<mckvwRLBAPImportRecord>();

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
    }
}
