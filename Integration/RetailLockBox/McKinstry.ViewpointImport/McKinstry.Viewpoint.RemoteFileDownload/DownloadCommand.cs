using System;
using log4net;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileDownload
{
    internal class DownloadCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Download Files Command";
            }
        }

        public string Description
        {
            get
            {
                return "Downloads files in file collection from remote location.";
            }
        }

        public void RunWith(ILog log, List<SftpFile> files)
        {
            List<bool> downloadResults = new List<bool>();
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.InfoFormat("Ensuring download folder location '{0}.'", Settings.LocalDownloadPath);
            ImportFileHelper.EnsureDirectory(Settings.LocalDownloadPath);
            foreach (var file in files)
            {
                log.InfoFormat("Attempting to download file: '{0}'.", file.FileName);
                bool downloaded = RlbSftpHelper.GetFileFromRemotePath(file.FileName, Settings.RemoteDownloadPath, Settings.LocalDownloadPath);
                downloadResults.Add(downloaded);
                log.InfoFormat("File downloaded. Success: {0}.", downloaded);
            }
            log.Info("Done with file downloading.");
            log.InfoFormat("--Completed {0}--", this.Name);
            // Throw exception if any download was not successful
            var failures = (downloadResults.Where(r => r == false).Select(r => r)).Count();
            if (failures > 0)
            {
                throw new ApplicationException(string.Format("File download was not successful. Count: {0}. RlbSftpHelper.GetFileFromRemotePath returned false.", failures));
            }
        }
    }
}
