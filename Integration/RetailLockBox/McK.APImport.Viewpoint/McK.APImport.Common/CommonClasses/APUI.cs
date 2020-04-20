using System;
using System.Collections.Generic;


namespace McK.APImport.Common
{
    public partial class APUI
    {
        public byte APCo { get; set; }

        public DateTime UIMth { get; set; }

        public short UISeq { get; set; }

        public byte VendorGroup { get; set; }

        public int? Vendor { get; set; }

        public string APRef { get; set; }

        public string Description { get; set; }

        public DateTime? InvDate { get; set; }

        public DateTime? DiscDate { get; set; }

        public DateTime? DueDate { get; set; }

        public decimal InvTotal { get; set; }

        public string HoldCode { get; set; }

        public string PayControl { get; set; }

        public string PayMethod { get; set; }

        public byte CMCo { get; set; }

        public short? CMAcct { get; set; }

        public string V1099YN { get; set; }

        public string V1099Type { get; set; }

        public byte? V1099Box { get; set; }

        public string PayOverrideYN { get; set; }

        public string PayName { get; set; }

        public string PayAddress { get; set; }

        public string PayCity { get; set; }

        public string PayState { get; set; }

        public string PayZip { get; set; }

        public DateTime? InUseMth { get; set; }

        public int? InUseBatchId { get; set; }

        public string PayAddInfo { get; set; }

        public string DocName { get; set; }

        public string SeparatePayYN { get; set; }

        public string Notes { get; set; }

        public Guid? UniqueAttchID { get; set; }

        public byte? AddressSeq { get; set; }

        public long KeyID { get; set; }

        public string ReviewerGroup { get; set; }

        public long? SLKeyID { get; set; }

        public string PayCountry { get; set; }

        public decimal? udFreightCost { get; set; }

        public string udAPBatchProcessedYN { get; set; }

        public byte? udDestAPCo { get; set; }

        public byte InvStatus { get; set; }
    }
}
