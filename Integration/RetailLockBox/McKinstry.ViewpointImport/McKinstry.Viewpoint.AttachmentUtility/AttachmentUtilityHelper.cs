using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.AttachmentUtility
{
    public class AttachmentUtilityHelper
    {
        internal static void LogServerAttachmentFilesPartial(ILog log, string path, string environment)
        {
            DateTime? attachDate = AttachmentUtilityDb.GetLatestAttachmentFileDate(environment);
            DateTime date = attachDate.HasValue ? attachDate.Value : DateTime.MinValue;
            FileInfo[] files = GetAttachmentFiles(path, date);
            LogAttachmentFiles(log, files, path, environment);
        }

        internal static void LogServerAttachmentFiles(ILog log, string path, string environment)
        {
            FileInfo[] files = GetAttachmentFiles(path);
            LogAttachmentFiles(log, files, path, environment);
        }

        internal static void LogMissingAttachments(ILog log)
        {
            List<MissingAttachment> missingAttachments = new List<MissingAttachment>();

            log.Info("Fetching attachment records from HQAT table.");
            HQAT[] attachments = AttachmentUtilityDb.GetAttachments();
            log.InfoFormat("HQAT Records. Count: {0}.", attachments.Length);

            log.Info("Finding missing attachments...");

            missingAttachments = attachments.Where(a => File.Exists(a.DocName) == false)
                .Select(a => new MissingAttachment()
                {
                    Company = a.HQCo,
                    FormName = a.FormName,
                    TableName = a.TableName,
                    KeyID = ParseKeyID(a.KeyField),
                    AttachmentID = a.AttachmentID,
                    UniqueAttchID = a.UniqueAttchID,
                    AddedBy = a.AddedBy,
                    AddDate = a.AddDate,
                    DocName = a.DocName,
                    OrigFileName = a.OrigFileName,
                    CurrentState = a.CurrentState,
                    FileExists = false,
                    Created = DateTime.Now
                }).ToList<MissingAttachment>();

            log.InfoFormat("Found HQAT records with missing attachments to log. Count: {0}.", missingAttachments.Count);

            log.Info("Truncating attachment files table 'MissingAttachments'.");
            AttachmentUtilityDb.TruncateMissingAttachTable();

            log.Info("Logging results in database.");

            foreach (var attachment in missingAttachments)
            {
                AttachmentUtilityDb.AddMissingAttachment(attachment);
            }
        }

        private static long? ParseKeyID(string keyID)
        {
            if (string.IsNullOrEmpty(keyID))
            {
                return default(long);
            }
            long key;
            string keyString = keyID.Replace(" ", "").Replace("KeyID=", "");
            bool results = Int64.TryParse(keyString, out key);
            return results ? key : default(long);
        }

        private static void LogAttachmentFiles(ILog log, FileInfo[] files, string path, string environment)
        {
            log.InfoFormat("Found files under '{0}' to log. Count: {1}.", path, files.Length);
            foreach (var file in files)
            {
                DirectoryInfo info = new DirectoryInfo(file.FullName);
                string[] parts = info.FullName.Replace(info.Root.ToString(), "").Split(new char[] { '\\' }, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length != 5)
                {
                    AttachmentUtilityDb.AddAttachFile(new ViewpointAttachFile { Environment = environment, FileName = file.Name, FullFilePath = file.FullName, FileCreationTime = file.CreationTime, Created = DateTime.Now });
                    continue;
                }
                AttachmentUtilityDb.AddAttachFile(
                    new ViewpointAttachFile
                    {
                        Environment = environment,
                        FileName = parts[4],
                        Company = parts[0],
                        Module = parts[1],
                        FormName = parts[2],
                        Month = parts[3],
                        FullFilePath = file.FullName,
                        FileCreationTime = file.CreationTime,
                        Created = DateTime.Now
                    });
            }
        }

        private static FileInfo[] GetAttachmentFiles(string path)
        {
            FileInfo[] files = new DirectoryInfo(path)
             .EnumerateFiles("*", SearchOption.AllDirectories)
             .Select(x =>
             {
                 x.Refresh();
                 return x;
             })
             .ToArray();

            return files;
        }

        private static FileInfo[] GetAttachmentFiles(string path, DateTime startDate)
        {
            FileInfo[] files = new DirectoryInfo(path)
                         .EnumerateFiles("*", SearchOption.AllDirectories)
                         .Select(x =>
                         {
                             x.Refresh();
                             return x;
                         })
                         .Where(x => x.CreationTime.ToUniversalTime() > startDate.ToUniversalTime())
                         .ToArray();

            return files;
        }
    }
}
