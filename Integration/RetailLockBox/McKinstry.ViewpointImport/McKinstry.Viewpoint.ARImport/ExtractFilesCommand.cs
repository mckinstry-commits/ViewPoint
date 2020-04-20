using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class ExtractFilesCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Extract Files Command";
            }
        }

        public string Description
        {
            get
            {
                return "Copies source file to process folder and extracts files.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.InfoFormat("Ensuring process folder '{0}'.", ARSettings.ARProcessFolderLocation);
            ImportFileHelper.EnsureDirectory(ARSettings.ARProcessFolderLocation);

            string processFile = Path.Combine(ARSettings.ARProcessFolderLocation, Path.GetFileName(fileName));
            log.InfoFormat("Copying file '{0}' to '{1}'.", fileName, processFile);
            bool copied = ImportFileHelper.CopyFile(fileName, processFile);
            log.InfoFormat("File copy successful: {0}.", copied);
            if (!copied)
            {
                throw new ApplicationException(string.Format("Unable to copy AR import file to process folder. Source: '{0}'. Destination: '{1}'.", fileName, processFile));
            }

            log.InfoFormat("Extracting zip file '{0}' to '{1}'.", processFile, file.ProcessExtractPath);
            if (Directory.Exists(file.ProcessExtractPath))
            {
                bool directoryDeleted = ImportFileHelper.DeleteDirectory(file.ProcessExtractPath);
                log.InfoFormat("Found directory exists at '{0}'.  Deleting directory.  Success: {1}.", file.ProcessExtractPath, directoryDeleted);
            }

            bool extracted = ImportFileHelper.ExtractZip(processFile, file.ProcessExtractPath);
            log.InfoFormat("File extract successful: {0}.", extracted);
            if (!extracted)
            {
                throw new ApplicationException("Unable to extract AR import file in AR process folder.");
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
