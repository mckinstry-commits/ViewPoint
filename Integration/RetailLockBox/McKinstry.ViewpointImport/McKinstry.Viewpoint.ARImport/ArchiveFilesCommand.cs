using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class ArchiveFilesCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Archive AR Files Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Archives AR data file.  Extracts images folder for future reference.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.InfoFormat("Checking existence of archive folder '{0}'.", file.ArchivePath);
            ImportFileHelper.EnsureDirectory(file.ArchivePath);

            string processFile = Path.Combine(ARSettings.ARProcessFolderLocation, file.FileName);
            string archiveFile = Path.Combine(file.ArchivePath, file.FileName);
            log.InfoFormat(string.Format("Copying AR file.  Source file: '{0}'.  Destination file: '{1}'", processFile, archiveFile));
            bool copied = ImportFileHelper.CopyFile(processFile, archiveFile);
            log.InfoFormat("Copy AR data file. Success: {0}", copied);
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
