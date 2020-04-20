using System;
using log4net;
using System.Linq;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport 
{
    internal class CheckImagesFolderCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Check Images Folder Command";
            }
        }

        public string Description
        {
            get
            {
                return "Checks extracted zip folder for image files.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Checking if images folder exists.");
            var folder = Directory.EnumerateDirectories(file.ProcessExtractPath).FirstOrDefault();
            var folderInfo = folder == null ? new { FolderName = "", FolderPath = "" } : new { FolderName = Path.GetFileName(folder), FolderPath = folder };
            bool folderExists = (folderInfo.FolderName.ToLower() == "images");

            log.InfoFormat("Completed images folder check. Folder exists: {0}.", folderExists);
            if (!folderExists)
            {
                throw new ApplicationException(string.Format("Unable to find images folder in extracted AR data file '{0}'.", file.FileName));
            }

            log.InfoFormat("Checking image count in folder '{0}'.", folderInfo.FolderPath);
            int imageCount = Directory.GetFiles(folderInfo.FolderPath, "*.pdf", SearchOption.TopDirectoryOnly).Length;
            log.InfoFormat("Images found: {0}.", imageCount);
            if (imageCount <= 0)
            {
                throw new ApplicationException(string.Format("Unable to find images in images folder '{0}'.  Count: {1}.", folderInfo.FolderPath, imageCount));
            }

            log.Info("Fetching transaction date from image file dates.");
            var directory = new DirectoryInfo(folderInfo.FolderPath);
            var latestFile = directory.GetFiles("*.pdf", SearchOption.TopDirectoryOnly)
                .OrderByDescending(f => f.LastWriteTime)
                .First();
            log.InfoFormat("Found latest write date for image files: {0}. Setting transaction date.", latestFile.LastWriteTime);
            file.TransactionDate = latestFile.LastWriteTime;

            log.Info("Finished image folder check.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
