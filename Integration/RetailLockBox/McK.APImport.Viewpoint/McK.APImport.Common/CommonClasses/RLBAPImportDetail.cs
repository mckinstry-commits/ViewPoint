using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.APImport.Common
{
    public partial class RLBAPImportDetail
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public RLBAPImportDetail()
        {
            this.RLBAPImportRecords = new HashSet<RLBAPImportRecord>();
        }

        public int RLBAPImportDetailID { get; set; }
        public int RLBImportBatchID { get; set; }
        public string FileName { get; set; }
        public System.DateTime LastWriteTime { get; set; }
        public long Length { get; set; }
        public string RLBImportDetailStatusCode { get; set; }
        public Nullable<int> RLBProcessNotesID { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> Modified { get; set; }
        public string RecordType { get; set; }
        public Nullable<byte> Company { get; set; }
        public string Number { get; set; }
        public Nullable<byte> VendorGroup { get; set; }
        public Nullable<int> Vendor { get; set; }
        public string VendorName { get; set; }
        public Nullable<System.DateTime> TransactionDate { get; set; }
        public Nullable<byte> JCCo { get; set; }
        public string Job { get; set; }
        public string JobDescription { get; set; }
        public string Description { get; set; }
        public Nullable<int> DetailLineCount { get; set; }
        public Nullable<decimal> TotalOrigCost { get; set; }
        public Nullable<decimal> TotalOrigTax { get; set; }
        public Nullable<decimal> RemainingAmount { get; set; }
        public Nullable<decimal> RemainingTax { get; set; }
        public Nullable<System.DateTime> CollectedInvoiceDate { get; set; }
        public string CollectedInvoiceNumber { get; set; }
        public Nullable<decimal> CollectedTaxAmount { get; set; }
        public Nullable<decimal> CollectedShippingAmount { get; set; }
        public Nullable<decimal> CollectedInvoiceAmount { get; set; }
        public string CollectedImage { get; set; }
        public string UnmatchedNumber { get; set; }

        public virtual RLBImportBatch RLBImportBatch { get; set; }

        //public virtual RLBProcessNote RLBProcessNote { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<RLBAPImportRecord> RLBAPImportRecords { get; set; }
    }
}
