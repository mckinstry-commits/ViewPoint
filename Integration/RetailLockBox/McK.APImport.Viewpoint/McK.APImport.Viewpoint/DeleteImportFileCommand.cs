using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McK.APImport.Common;
using McK.Data.Viewpoint;

namespace McK.APImport.Viewpoint
{
    internal class DeleteImportFileCommand : ICommand
    {
        public string Name => "Delete Import File Command";

        public string Description => "Removes source input file from file system.";

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
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
                    throw new ApplicationException(string.Format("Unable to delete AP import file: '{0}'.", fileName));
                }
            }

            log.Info("Removing process files.");

            string processFile = Path.Combine(APSettings.APProcessFolderLocation, file.FileName);
            log.InfoFormat("Deteling process file '{0}'.", processFile);
            bool processFileDeleted = ImportFileHelper.DeleteFile(processFile);
            log.InfoFormat("File delete success: {0}.", processFileDeleted);
            if (!processFileDeleted)
            {
                throw new ApplicationException(string.Format("Unable to delete process file '{0}'.", processFile));
            }

            log.Info("Done removing process files.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
