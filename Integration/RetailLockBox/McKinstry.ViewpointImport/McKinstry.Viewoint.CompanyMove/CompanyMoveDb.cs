using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewoint.CompanyMove
{
    public class CompanyMoveDb : Db
    {

        public static List<mckfnAPCompanyMove_Result> GetAPCompanyMoveItems()
        {
            List<mckfnAPCompanyMove_Result> results = default(List<mckfnAPCompanyMove_Result>);
            using (var ctx = new ViewpointEntities(ViewpointConnectionString))
            {
                results = ctx.mckfnAPCompanyMove().ToList<mckfnAPCompanyMove_Result>();
            }
            return results;
        }

        public static List<APCompanyMoveErrorRecord> GetAPCompanyMoveItems(string logFileName)
        {
            List<APCompanyMoveErrorRecord> results = default(List<APCompanyMoveErrorRecord>);
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                results = ctx.mckfnAPCompanyMoveError(logFileName)
                    .Select(r => new APCompanyMoveErrorRecord
                    {
                        HeaderMoved = r.HeaderMoved,
                        AttachmentsMoved = r.AttachmentsMoved,
                        AttachmentsCopied = r.AttachmentsCopied,
                        Co = r.Co,
                        Mth = r.Mth,
                        UISeq = r.UISeq,
                        Vendor = r.Vendor,
                        APRef = r.APRef,
                        InvTotal = r.InvTotal,
                        Notes = r.Notes
                    }).ToList<APCompanyMoveErrorRecord>();
            }
            return results;
        }

        public static bool UpdateAPCompanyMove(int APCompanyMoveID, bool? headerSuccess, bool? attachSuccess, bool? attachCopySuccess, Guid? destUniqueAttchID,
    string processNote)
        {
            bool updated = false;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int? processNotesID = null;
                if (!string.IsNullOrEmpty(processNote))
                {
                    processNotesID = MckIntegrationDb.CreateProcessNote(processNote);
                }

                var existing = (from m in ctx.APCompanyMoves
                                where m.APCompanyMoveID == APCompanyMoveID
                                select m).FirstOrDefault();

                if (existing == default(APCompanyMove))
                {
                    return false;
                }

                existing.HeaderSuccess = headerSuccess.HasValue ? headerSuccess : null;
                existing.AttachSuccess = attachSuccess.HasValue ? attachSuccess : null;
                existing.AttachCopySuccess = attachCopySuccess.HasValue ? attachCopySuccess : null;
                existing.DestUniqueAttchID = destUniqueAttchID == Guid.Empty ? default(Guid?) : destUniqueAttchID;
                existing.RLBProcessNotesID = processNotesID.HasValue ? processNotesID : null;
                existing.Modified = DateTime.Now;
                ctx.SaveChanges();
                updated = true;
            }
            return updated;
        }

        public static bool UpdateAPCompanyMoveError(int APCompanyMoveID, string errorMessage)
        {
            bool updated = false;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int? processNotesID = null;
                if (!string.IsNullOrEmpty(errorMessage))
                {
                    processNotesID = MckIntegrationDb.CreateProcessNote(errorMessage);
                }

                var existing = (from m in ctx.APCompanyMoves
                                where m.APCompanyMoveID == APCompanyMoveID
                                select m).FirstOrDefault();

                if (existing == default(APCompanyMove))
                {
                    return false;
                }

                existing.RLBProcessNotesID = processNotesID.HasValue ? processNotesID : null;
                existing.Modified = DateTime.Now;
                ctx.SaveChanges();
                updated = true;
            }
            return updated;
        }

        public static int CreateAPCompanyMove(string logFileName, bool? headerSuccess, bool? attachSuccess, bool? attachCopySuccess, DateTime? mth, int? vendor, string apRef, decimal? invTotal,
            byte? co, short? uISeq, Guid? uniqueAttchID, long? keyID, byte? destCo, short? destUISeq, Guid? destUniqueAttchID, long? destKeyID, string processNote)
        {
            APCompanyMove move;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int? processNotesID = null;
                if (!string.IsNullOrEmpty(processNote))
                {
                    processNotesID = MckIntegrationDb.CreateProcessNote(processNote);
                }
                move = ctx.APCompanyMoves.Add(
                    new APCompanyMove
                    {
                        LogFileName = logFileName,
                        HeaderSuccess = headerSuccess,
                        AttachSuccess = attachSuccess,
                        AttachCopySuccess = attachCopySuccess,
                        Mth = mth,
                        Vendor = vendor,
                        APRef = apRef,
                        InvTotal = invTotal,
                        Co = co,
                        UISeq = uISeq,
                        UniqueAttchID = uniqueAttchID,
                        KeyID = keyID,
                        DestCo = destCo,
                        DestUISeq = destUISeq,
                        DestUniqueAttchID = destUniqueAttchID,
                        DestKeyID = destKeyID,
                        RLBProcessNotesID = processNotesID,
                        Created = DateTime.Now,
                        Modified = DateTime.Now
                    });
                ctx.SaveChanges();
            }
            return move.APCompanyMoveID;
        }

        public static int CreateAttachmentCompanyMove(int companyMoveID, bool? keepOldAttach, bool? oldAttachDeleted, bool? fileCopied,
            string origFileName, string formName, string tableName, string docName, int? attachID, Guid? uniqueAttchID, string destDocName,
            int? destAttachID, Guid? destUniqueAttchID, string processNote)
        {
            AttachCompanyMove move;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                int? processNotesID = null;
                if (!string.IsNullOrEmpty(processNote))
                {
                    processNotesID = MckIntegrationDb.CreateProcessNote(processNote);
                }

                move = ctx.AttachCompanyMoves.Add(
                    new AttachCompanyMove
                    {
                        CompanyMoveID = companyMoveID,
                        KeepOldAttach = keepOldAttach,
                        OldAttachDeleted = oldAttachDeleted,
                        FileCopied = fileCopied,
                        OrigFileName = origFileName,
                        FormName = formName,
                        TableName = tableName,
                        DocName = docName,
                        AttachmentID = attachID,
                        UniqueAttchID = uniqueAttchID,
                        DestDocName = destDocName,
                        DestAttachmentID = destAttachID,
                        DestUniqueAttchID = destUniqueAttchID,
                        RLBProcessNotesID = processNotesID,
                        Created = DateTime.Now,
                        Modified = DateTime.Now
                    });
                ctx.SaveChanges();
            }
            return move.AttachCompanyMoveID;
        }

        public static CompanyMoveMetric GetCompanyMoveMetric(string applicationKey)
        {
            CompanyMoveMetric metric;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                metric = ctx.CompanyMoveMetrics
                    .Where(m => m.ApplicationKey == applicationKey)
                    .Select(m => m)
                    .FirstOrDefault<CompanyMoveMetric>();
            }
            return metric == default(CompanyMoveMetric) ? new CompanyMoveMetric() { LastNotifyDate = null } : metric;
        }

        public static bool UpdateCompanyMoveMetric(string applicationKey, DateTime lastNotifyDate, string logFileName)
        {
            bool updated = false;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var existing = ctx.CompanyMoveMetrics
                                .Where(m => m.ApplicationKey == applicationKey)
                                .Select(m => m)
                                .FirstOrDefault<CompanyMoveMetric>();

                if (existing == default(CompanyMoveMetric))
                {
                    return false;
                }

                existing.LastNotifyDate = lastNotifyDate;
                existing.LastNotifyLogFileName = logFileName;
                existing.Modified = DateTime.Now;
                ctx.SaveChanges();
                updated = true;
            }
            return updated;
        }

        public static int CreateCompanyMoveMetric(string applicationKey, string logFileName)
        {
            CompanyMoveMetric metric;
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                DateTime now = DateTime.Now;
                metric = ctx.CompanyMoveMetrics.Add(
                    new CompanyMoveMetric
                    {
                        ApplicationKey = applicationKey,
                        LastNotifyDate = new DateTime(now.Year, now.Month, now.Day, now.Hour, 0, 0),
                        LastNotifyLogFileName = logFileName,
                        Created = DateTime.Now,
                        Modified = null
                    });
                ctx.SaveChanges();
            }
            return metric.CompanyMoveMetricsID;
        }

    }
}
