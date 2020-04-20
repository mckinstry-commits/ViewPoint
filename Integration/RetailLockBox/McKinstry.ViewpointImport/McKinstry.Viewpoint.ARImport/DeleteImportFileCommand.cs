using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class DeleteImportFileCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Delete Import File Command";
            }
        }

        public string Description
        {
            get
            {
                return "Removes source input file from file system.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Checking if import file exists.");
            log.InfoFormat("Checking file '{0}'.", fileName);
            bool importFileExists = File.Exists(fileName);
            log.InfoFormat("File exists: {0}.", importFileExists);
            if (importFileExists)
            {
                log.InfoFormat("Removing file '{0}'.", fileName);
                bool deleted = ImportFileHelper.DeleteFile(fileName);
                log.InfoFormat("File removal success: {0}.", deleted);
                if (!deleted)
                {
                    throw new ApplicationException(string.Format("Unable to delete AR import file: '{0}'.", fileName));
                }
            }

            log.Info("Removing process files and folders.");

            string processFile = Path.Combine(ARSettings.ARProcessFolderLocation, file.FileName);
            log.InfoFormat("Deteling process file '{0}'.", processFile);
            bool processFileDeleted = ImportFileHelper.DeleteFile(processFile);
            log.InfoFormat("File delete success: {0}.", processFileDeleted);
            if (!processFileDeleted)
            {
                throw new ApplicationException(string.Format("Unable to delete process file '{0}'.", processFile));
            }

            log.InfoFormat("Deleting extracted file folder '{0}'.", file.ProcessExtractPath);
            bool exractFolderDeleted = ImportFileHelper.DeleteDirectory(file.ProcessExtractPath);
            log.InfoFormat("Folder delete success: {0}.", exractFolderDeleted);
            if (!exractFolderDeleted)
            {
                throw new ApplicationException(string.Format("Unable to delete process folder '{0}'.", file.ProcessExtractPath));
            }

            log.Info("Done removing process files and folders.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
