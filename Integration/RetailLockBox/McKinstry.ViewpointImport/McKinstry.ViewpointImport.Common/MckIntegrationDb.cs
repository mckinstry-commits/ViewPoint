using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.ViewpointImport.Common
{
    public static class MckIntegrationDb
    {
        private static string connectionString;
        private static string ConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(connectionString))
                {
                    connectionString = CommonSettings.MckIntegrationConnectionString;
                }
                return connectionString;
            }
        }

        public static int CreateProcessNote(string processNote)
        {
            RLBProcessNote note;
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                note = ctx.RLBProcessNotes.Add(
                    new RLBProcessNote
                    {
                        ProcessNotes = processNote,
                        Created = DateTime.Now
                    });
                ctx.SaveChanges();
            }
            return note.RLBProcessNotesID;
        }

        public static bool LogRemoteDownload(string fileName, DateTime lastWriteTime, long length, DateTime completeTime)
        {
            try
            {
                using (var ctx = new MckIntegrationEntities(ConnectionString))
                {
                    ctx.RLBRemoteDownloads.Add(
                        new RLBRemoteDownload
                        {
                            FileName = fileName,
                            LastWriteTime = lastWriteTime,
                            Length = length,
                            CompleteTime = completeTime,
                        }
                    );
                    ctx.SaveChanges();
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static bool LogRemoteUpload(string fileName, DateTime lastWriteTime, long length, DateTime completeTime)
        {
            try
            {
                using (var ctx = new MckIntegrationEntities(ConnectionString))
                {
                    ctx.RLBRemoteUploads.Add(
                        new RLBRemoteUpload
                        {
                            FileName = fileName,
                            LastWriteTime = lastWriteTime,
                            Length = length,
                            CompleteTime = completeTime,
                        }
                    );
                    ctx.SaveChanges();
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static bool CreateImportBatch(RLBImportBatch batch)
        {
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                RLBImportBatch newBatch = ctx.RLBImportBatches.Add(batch);
                ctx.SaveChanges();
                batch = newBatch;
            }
            return true;
        }

        /// <summary>
        /// Updates status, complete time if set.  Updates modified.
        /// </summary>
        public static bool UpdateImportBatch(RLBImportBatch batch)
        {
            try
            {
                using (var ctx = new MckIntegrationEntities(ConnectionString))
                {
                    var existing = (from b in ctx.RLBImportBatches
                                    where b.RLBImportBatchID == batch.RLBImportBatchID
                        select b).FirstOrDefault();                            

                    if (existing == default(RLBImportBatch))
                    {
                        return false;
                    }
                    existing.CompleteTime = batch.CompleteTime;
                    existing.RLBImportBatchStatusCode = batch.RLBImportBatchStatusCode;
                    existing.Modified = DateTime.Now;
                    ctx.SaveChanges();
                    batch.Modified = existing.Modified;
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static bool ImportBatchComplete(RLBImportBatch batch)
        {
            try
            {
                using (var ctx = new MckIntegrationEntities(ConnectionString))
                {
                    bool complete = ctx.RLBImportBatches.Any(b => (b.FileName == batch.FileName) 
                        && ((b.Length - batch.Length) == 0) && (b.CompleteTime.HasValue));
                    return complete;
                }
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static bool ImportBatchManualState(RLBImportBatch batch)
        {
            try
            {
                using (var ctx = new MckIntegrationEntities(ConnectionString))
                {
                    bool manual = ctx.RLBImportBatches.Any(b => (b.FileName == batch.FileName) 
                        && ((b.Length - batch.Length) == 0) && (b.RLBImportBatchStatusCode == "MAN"));
                    return manual;
                }
            }
            catch (Exception)
            {
                return false;
            }
        }

        public static RLBImportBatch GetImportBatch(int batchID)
        {
            RLBImportBatch batch = default(RLBImportBatch);
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                batch = ctx.RLBImportBatches.Where(b => (b.RLBImportBatchID == batchID))
                    .FirstOrDefault<RLBImportBatch>();
            }
            return batch;
        }

        public static bool FileWasDownloaded(SftpFile file)
        {
            var results = from f in GetDownloadLogItems()
                          where ((f.Length - file.Length == 0) && (f.FileName == file.FileName) && (f.LastWriteTime == file.LastWriteTime))
                select f;
            return results.Count() > 0;
        }

        public static List<RLBDownloadFile> GetDownloadLogItems()
        {
            List<RLBDownloadFile> list = default(List<RLBDownloadFile>);
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                list = (from s in ctx.RLBRemoteDownloads.AsNoTracking()
                            select new RLBDownloadFile { 
                                FileName = s.FileName,
                                LastWriteTime = s.LastWriteTime,
                                Length = s.Length,
                                DownloadCompleteTime = s.CompleteTime
                            }
                       ).ToList();
            }
            return list;
        }

        public static List<RLBAPImportDetail> GetUnprocessedAPDetailRecords(int batchID)
        {
            List<RLBAPImportDetail> list = new List<RLBAPImportDetail>();
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                list = ctx.RLBAPImportDetails.AsNoTracking()
                    .Where(r => (r.RLBImportBatchID == batchID) && (r.RLBImportDetailStatusCode == "UNP"))
                    .Select(r => r)
                    .ToList<RLBAPImportDetail>();
            }
            return list;
        }

        public static List<RLBAPImportDetail> GetAPDetailRecords(int batchID)
        {
            List<RLBAPImportDetail> list =  new List<RLBAPImportDetail>();
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                list = ctx.RLBAPImportDetails.AsNoTracking()
                    .Where(r => (r.RLBImportBatchID == batchID))
                    .Select(r => r)
                    .ToList<RLBAPImportDetail>();
            }
            return list;
        }

        public static bool UpdateAPImportDetail(int importDetailID, string statusCode, int? noteID)
        {
            using (var ctx = new MckIntegrationEntities(ConnectionString))
            {
                var existing = (from b in ctx.RLBAPImportDetails
                                where b.RLBAPImportDetailID == importDetailID
                                select b).FirstOrDefault();

                if (existing == default(RLBAPImportDetail))
                {
                    return false;
                }

                existing.RLBProcessNotesID = noteID.HasValue ? noteID : null;
                existing.RLBImportDetailStatusCode = statusCode;
                existing.Modified = DateTime.Now;
                ctx.SaveChanges();
                return true;
            }
        }
    }
}
