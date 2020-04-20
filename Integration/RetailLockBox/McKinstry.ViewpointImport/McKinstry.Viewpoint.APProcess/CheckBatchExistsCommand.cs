using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class CheckBatchExistsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Check AP Batch Exists Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Checks if AP Viewpoint import batch is matched or complete.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Checking if completed AP import batch exists.");
            bool batchComplete = MckIntegrationDb.ImportBatchComplete(batch);
            log.InfoFormat("Completed AP import batch check. Batch already complete: {0}.", batchComplete);
            if (batchComplete)
            {
                throw new ApplicationException(string.Format("A completed AP batch mathing file '{0}' (size '{1}', last write time '{2}') exists.", 
                    batch.FileName, batch.Length, batch.LastWriteTime));
            }

            log.Info("Checking if manual AP import batch in manual state.");
            bool batchManual = MckIntegrationDb.ImportBatchManualState(batch);
            log.InfoFormat("Manual AP import batch check. Batch already in manual state: {0}.", batchManual);
            if (batchManual)
            {
                throw new ApplicationException(string.Format("An AP batch mathing file '{0}' (size '{1}', last write time '{2}') in a manual process state already exists.",
                    batch.FileName, batch.Length, batch.LastWriteTime));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
