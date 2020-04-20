using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.Entity.Core.Objects;

namespace McKinstry.ViewpointImport.Common
{
    public class ViewpointDb
    {
        private static string connectionString;
        private static string ConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(connectionString))
                {
                    connectionString = CommonSettings.ViewpointConnectionString;
                }
                return connectionString;
            }
        }

        public static List<mvwAPAllInvoice> GetAllAPInvoices()
        {
            List<mvwAPAllInvoice> list = default(List<mvwAPAllInvoice>);
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                list = ctx.mvwAPAllInvoices.ToList<mvwAPAllInvoice>();
            }
            return list;
        }

        public static bool CreateHQATRecord(byte? company, long? headerKeyID, DateTime? transactionDate, string description, string module, string formName,
            int? attachmentTypeID, string tableName, string imageFileName, string addedBy, out HQATUploadResults results)
        {
            bool returnVal = false;
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                // Turn off transactions from entity framework perspective.  Our procs use db transactions internally.
                ctx.Configuration.EnsureTransactionsForFunctionsAndCommands = false;

                ObjectParameter keyID = new ObjectParameter("keyID", typeof(int));
                ObjectParameter uniqueAttchID = new ObjectParameter("uniqueAttchID", typeof(Guid));
                ObjectParameter attachmentFilePath = new ObjectParameter("attachmentFilePath", typeof(string));
                ObjectParameter message = new ObjectParameter("message", typeof(string));
                ObjectParameter retVal = new ObjectParameter("retVal", typeof(int));

                ctx.mckspHQATAdd(company, headerKeyID, transactionDate, description, module, formName, tableName,
                    attachmentTypeID, imageFileName, addedBy, keyID, uniqueAttchID, attachmentFilePath, message, retVal);

                results = new HQATUploadResults
                {
                    KeyID = (keyID.Value == DBNull.Value) ? default(int?) : Convert.ToInt32(keyID.Value),
                    UniqueAttachmentID = uniqueAttchID.Value == DBNull.Value ? default(Guid?) : (Guid?)uniqueAttchID.Value,
                    AttachmentFilePath = attachmentFilePath.Value == DBNull.Value ? null : attachmentFilePath.Value.ToString(),
                    Message = message.Value == DBNull.Value ? null : message.Value.ToString(),
                    RetVal = (retVal.Value == DBNull.Value) ? -1 : Convert.ToInt32(retVal.Value)
                };
                returnVal = results.KeyID > 0;
            }
            return returnVal;
        }

        public static bool CreateAPUIRecord(byte? company, DateTime? uiMonth, byte? vendorGroup, int? vendor, string apRef, string description, 
            string notes, DateTime? invoiceDate, decimal? invoiceTotal, decimal? freightCost, out APUIUploadResults results)
        {
            bool returnVal = false;
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                // Turn off transactions from entity framework perspective.  Our procs use db transactions internally.
                ctx.Configuration.EnsureTransactionsForFunctionsAndCommands = false;

                ObjectParameter headerKeyID = new ObjectParameter("headerKeyID", typeof(long));
                ObjectParameter uISeq = new ObjectParameter("uISeq", typeof(short));

                ctx.mckspAPUIAdd(company, uiMonth, vendorGroup, vendor, apRef, description, notes, invoiceDate, invoiceTotal, freightCost, headerKeyID, uISeq);

                results = new APUIUploadResults
                {
                    HeaderKeyID = (headerKeyID.Value == DBNull.Value) ? default(long?) : Convert.ToInt64(headerKeyID.Value),
                    UISeq = (uISeq.Value == DBNull.Value) ? default(short?) : Convert.ToInt16(uISeq.Value),
                };
                returnVal = headerKeyID != null;
            }
            return returnVal;
        }

        public static bool DeleteAPUIRecord(long keyID, out DBResults results)
        {
            bool deleted = false;
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                // Turn off transactions from entity framework perspective.  Our procs use db transactions internally.
                ctx.Configuration.EnsureTransactionsForFunctionsAndCommands = false;

                ObjectParameter message = new ObjectParameter("message", typeof(string));
                ObjectParameter retVal = new ObjectParameter("retVal", typeof(int));

                ctx.mckspAPUIDelete(keyID, message, retVal);

                results = new DBResults
                {
                    Message = message.Value == DBNull.Value ? null : message.Value.ToString(),
                    RetVal = (retVal.Value == DBNull.Value) ? -1 : Convert.ToInt32(retVal.Value)
                };
                deleted = (results.RetVal == 0);
            }
            return deleted;
        }

        public static bool DeleteHQATRecord(int attachmentID, out DBResults results)
        {
            bool deleted = false;
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                // Turn off transactions from entity framework perspective.  Our procs use db transactions internally.
                ctx.Configuration.EnsureTransactionsForFunctionsAndCommands = false;

                ObjectParameter message = new ObjectParameter("message", typeof(string));
                ObjectParameter retVal = new ObjectParameter("retVal", typeof(int));

                ctx.mckspHQATDelete(attachmentID, message, retVal);

                results = new DBResults
                {
                    Message = message.Value == DBNull.Value ? null : message.Value.ToString(),
                    RetVal = (retVal.Value == DBNull.Value) ? -1 : Convert.ToInt32(retVal.Value)
                };
                deleted = (results.RetVal == 0);
            }
            return deleted;
        }

        public static HQAT GetAttachmentRecord(int? attachmentID)
        {
            HQAT attachment = new HQAT();
            if (attachmentID.HasValue)
            {
                using (var ctx = new ViewpointEntities(ConnectionString))
                {
                    var existing = (from a in ctx.HQATs
                                    where a.AttachmentID == attachmentID
                                    select a).FirstOrDefault();
                    if (existing != default(HQAT))
                    {
                        return existing;
                    }
                }
            }
            return attachment;
        }

        public static APUI GetAPUIRecord(long? keyID)
        {
            APUI header = new APUI();
            if (keyID.HasValue)
            {
                using (var ctx = new ViewpointEntities(ConnectionString))
                {
                    var existing = (from a in ctx.APUIs
                                    where a.KeyID == keyID
                                    select a).FirstOrDefault();
                    if (existing != default(APUI))
                    {
                        return existing;
                    }
                }
            }
            return header;
        }

        public static List<HQAT> GetAttachmentRecords(Guid? uniqueAttachmentID)
        {
            List<HQAT> attachments = new List<HQAT>();
            if (uniqueAttachmentID.HasValue)
            {
                using (var ctx = new ViewpointEntities(ConnectionString))
                {
                    attachments = (from a in ctx.HQATs
                        where a.UniqueAttchID == uniqueAttachmentID
                        select a).ToList<HQAT>();
                }
            }
            return attachments;
        }

        public static List<APUI> GetAPHeaderItems()
        {
            List<APUI> list = default(List<APUI>);
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                list = ctx.APUIs.AsNoTracking().ToList<APUI>();
            }
            return list;
        }

        public static List<mvwRLBAPExport> GetAPExportItems()
        {
            List<mvwRLBAPExport> list = default(List<mvwRLBAPExport>);
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                list = ctx.mvwRLBAPExports.AsNoTracking()
                    .OrderBy(r => r.RecordType)
                    .ThenBy(r => r.Company)
                    .ThenBy(r => r.Number)
                    .ToList<mvwRLBAPExport>();
            }
            return list;
        }

        public static List<mvwRLBARExport> GetARExportItems()
        {
            List<mvwRLBARExport> list = default(List<mvwRLBARExport>);
            using (var ctx = new ViewpointEntities(ConnectionString))
            {
                list = ctx.mvwRLBARExports.AsNoTracking()
                    .OrderBy(r => r.Company)
                    .ThenBy(r => r.InvoiceNumber)
                    .ToList<mvwRLBARExport>();
            }
            return list;
        }

        public static bool APRecordExitsInViewpoint(RLBAPImportDetail record, List<mvwAPAllInvoice> allInvoices)
        {
            bool exists = false;
            if (!string.IsNullOrEmpty(record.CollectedInvoiceNumber))
            {
                exists = allInvoices.Any(h => (h.APRef == record.CollectedInvoiceNumber)
                    && ((h.InvTotal - record.CollectedInvoiceAmount) == 0));
            }
            return exists;
        }
    }
}
