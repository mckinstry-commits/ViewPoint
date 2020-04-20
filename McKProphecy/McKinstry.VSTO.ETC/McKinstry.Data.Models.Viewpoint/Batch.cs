using System;

namespace McKinstry.Data.Models.Viewpoint
{
    public class Batch
    {
        public Batch(string contractOrjob, uint batchId, DateTime projectionMonth, string type, byte jcco) 
        {
            ContractOrJob = contractOrjob;
            BatchId = batchId;
            ProjectionMonth = projectionMonth;
            Type = type;
            JCCo = jcco;
        }

        public string ContractOrJob { get; set; }

        public uint BatchId { get; set; }

        public DateTime ProjectionMonth { get; set; }

        public string Type { get; set; }

        public byte JCCo { get; set; }
    }
}
