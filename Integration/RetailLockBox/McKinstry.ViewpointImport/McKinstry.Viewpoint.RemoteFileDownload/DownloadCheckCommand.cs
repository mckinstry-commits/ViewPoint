using System;
using log4net;
using System.Collections.Generic;
using System.Threading.Tasks;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileDownload
{
    internal class DownloadCheckCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Download Check Command";
            }
        }

        public string Description
        {
            get
            {
                return "Checks if files have been downloaded previously.";
            }
        }

        public void RunWith(ILog log, List<SftpFile> files)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.InfoFormat("Files to check: {0}.", files.Count);
            foreach (var file in files)
            {
                log.InfoFormat("Checking file '{0}'.", file.FileName);
                file.PreviouslyDownloaded = MckIntegrationDb.FileWasDownloaded(file);
            }
            log.Info("Done with download check.");
            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
