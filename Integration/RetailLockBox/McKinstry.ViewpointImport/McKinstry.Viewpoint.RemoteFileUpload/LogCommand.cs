using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileUpload
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
                return "Logs uploaded file information to database.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.InfoFormat("Logging file '{0}' to database.", Settings.UploadFileName);
            string uploadFile = Path.Combine(Settings.LogFilePath, Settings.UploadFileName);
            FileInfo info = new FileInfo(uploadFile);
            bool logged = MckIntegrationDb.LogRemoteUpload(Settings.UploadFileName, info.LastWriteTime, info.Length, DateTime.Now);
            log.InfoFormat("File logging complete. Success: {0}.", logged);
            log.InfoFormat("--Completed {0}--", this.Name);
            // Throw exception if logging was not successful
            if (!logged)
            {
                throw new ApplicationException("Database logging not successful. MckIntegrationDb.LogRemoteUpload returned false.");
            }
        }

    }
}
