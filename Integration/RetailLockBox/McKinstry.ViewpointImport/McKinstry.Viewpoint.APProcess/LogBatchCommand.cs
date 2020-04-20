using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class LogBatchCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Log AP Import Batch Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Logs AP Viewpoint import batch to database.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Logging new AP Viewpoint import batch to database.");
            bool batchLogged = MckIntegrationDb.CreateImportBatch(batch);
            log.InfoFormat("AP Viewpoint import batch logged to database.  Success: {0}.", batchLogged);
            if (!batchLogged)
            {
                throw new ApplicationException(string.Format("Unable to create database log entry for AP import batch file: '{0}'.", batch.FileName));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
