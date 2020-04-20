using McK.APImport.Common;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McK.Data.Viewpoint;

namespace McK.APImport.Viewpoint
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                MckIntegrationDb mckIntegrationDb = new MckIntegrationDb();

                // get unprocessed batches
                List<RLBImportBatch> batches = MckIntegrationDb.GetUnprocessedAPBatches();

                // process batches
                foreach (var batch in batches)
                {
                    //string importID = "219";// String.Empty;
                    APImport import = new APImport(batch.RLBImportBatchID);
                    import.RunImport();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}
