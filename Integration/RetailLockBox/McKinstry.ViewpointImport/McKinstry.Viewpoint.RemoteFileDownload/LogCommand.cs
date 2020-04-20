using System;
using log4net;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileDownload
{
    internal class LogCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Database Log Command";
            }
        }

        public string Description
        {
            get
            {
                return "Logs downloaded file information to database.";
            }
        }

        public void RunWith(ILog log, List<SftpFile> files)
        {
            List<bool> loggingResults = new List<bool>();
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            foreach (var file in files)
            {
                log.InfoFormat("Logging file '{0}' to database.", file.FileName);
                bool logged = MckIntegrationDb.LogRemoteDownload(file.FileName, file.LastWriteTime, file.Length, DateTime.Now);
                loggingResults.Add(logged);
                log.InfoFormat("File logging complete. Success: {0}.", logged);
            }
            log.Info("Done with file logging.");
            log.InfoFormat("--Completed {0}--", this.Name);
            // Throw exception if logging was not successful
            var failures = (loggingResults.Where(r => r == false).Select(r => r)).Count();
            if (failures > 0)
            {
                throw new ApplicationException(string.Format("Database logging not successful. Count: {0}. MckIntegrationDb.LogRemoteDownload returned false.", failures));
            }
        }

    }
}
