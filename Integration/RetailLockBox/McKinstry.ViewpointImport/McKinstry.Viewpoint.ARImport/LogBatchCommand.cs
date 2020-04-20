using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class LogBatchCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Log AR Import Batch Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Logs AR Viewpoint import batch to database.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Logging new AR Viewpoint import batch to database.");
            bool batchLogged = MckIntegrationDb.CreateImportBatch(batch);
            log.InfoFormat("AR Viewpoint import batch logged to database.  Success: {0}.", batchLogged);
            if (!batchLogged)
            {
                throw new ApplicationException(string.Format("Unable to create database log entry for AR import batch file: '{0}'.", batch.FileName));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
