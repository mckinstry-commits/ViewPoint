using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class UpdateBatchCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Update AR Import Batch Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Updates AR Viewpoint import batch information in database.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Updating AR Viewpoint import batch in database.");
            batch.RLBImportBatchStatusCode = "COM";
            batch.CompleteTime = DateTime.Now;
            bool batchUpdated = MckIntegrationDb.UpdateImportBatch(batch);
            log.InfoFormat("AR Viewpoint import batch updated in database.  Success: {0}.", batchUpdated);
            if (!batchUpdated)
            {
                throw new ApplicationException(string.Format("Unable update AR import batch in database for AR import batch file: '{0}'.", batch.FileName));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
