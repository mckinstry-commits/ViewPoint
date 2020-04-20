using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class CheckBatchExistsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Check AR Batch Exists Command";
            }
        }

        public string Description 
        {
            get
            {
                return "Checks if a completed AR Viewpoint import batch exists.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Checking if completed AR import batch exists.");
            bool batchExists = MckIntegrationDb.ImportBatchComplete(batch);
            log.InfoFormat("Completed AR import batch check. Batch exists: {0}.", batchExists);
            if (batchExists)
            {
                throw new ApplicationException(string.Format("A completed AR batch mathing file '{0}' (size '{1}', last write time '{2}') exists.", 
                    batch.FileName, batch.Length, batch.LastWriteTime));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
