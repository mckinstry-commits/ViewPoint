using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APImport
{
    internal class UpdateBatchCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Update AP Import Batch Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates AP Viewpoint import batch information in database.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Updating AP Viewpoint import batch in database.");
            batch.RLBImportBatchStatusCode = "COM";
            batch.CompleteTime = DateTime.Now;
            bool batchUpdated = MckIntegrationDb.UpdateImportBatch(batch);
            log.InfoFormat("AP Viewpoint import batch updated in database.  Success: {0}.", batchUpdated);
            if (!batchUpdated)
            {
                throw new ApplicationException(string.Format("Unable update AP import batch in database for AP import batch file: '{0}'.", batch.FileName));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
