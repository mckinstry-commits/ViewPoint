using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class ArchiveFilesCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Archive AP Files Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Archives AP data file.  Extracts images folder for future reference.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.InfoFormat("Checking existence of archive folder '{0}'.", file.ArchivePath);
            ImportFileHelper.EnsureDirectory(file.ArchivePath);

            string processFile = Path.Combine(APSettings.APProcessFolderLocation, file.FileName);
            string archiveFile = Path.Combine(file.ArchivePath, file.FileName);
            log.InfoFormat(string.Format("Copying AP file.  Source file: '{0}'.  Destination file: '{1}'", processFile, archiveFile));
            bool copied = ImportFileHelper.CopyFile(processFile, archiveFile);
            log.InfoFormat("Copy AP data file. Success: {0}", copied);
            if (!copied)
            {
                throw new ApplicationException(string.Format("File archiving failed.  Source file: '{0}'.  Destination file: '{1}'", processFile, archiveFile));
            }

            log.Info("Copying extracted folders to archive.");
            IEnumerable<string> folders = Directory.EnumerateDirectories(file.ProcessExtractPath);
            foreach (var folder in folders)
            {
                ImportFileHelper.CopyDirectory(folder, file.ArchivePath);
            }
            log.Info("Done copying extracted folders to archive.");

            log.Info("Done archiving files.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
