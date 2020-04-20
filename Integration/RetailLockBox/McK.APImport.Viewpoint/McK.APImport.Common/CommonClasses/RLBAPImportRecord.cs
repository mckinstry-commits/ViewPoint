using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.APImport.Common
{
    public partial class RLBAPImportRecord
    {
        public int RLBAPImportRecordID { get; set; }
        public int RLBAPImportDetailID { get; set; }
        public Nullable<byte> Co { get; set; }
        public Nullable<System.DateTime> Mth { get; set; }
        public Nullable<short> UISeq { get; set; }
        public Nullable<int> Vendor { get; set; }
        public string APRef { get; set; }
        public Nullable<System.DateTime> InvDate { get; set; }
        public Nullable<decimal> InvTotal { get; set; }
        public Nullable<long> HeaderKeyID { get; set; }
        public Nullable<long> FooterKeyID { get; set; }
        public string DocName { get; set; }
        public Nullable<int> AttachmentID { get; set; }
        public Nullable<System.Guid> UniqueAttchID { get; set; }
        public string OrigFileName { get; set; }
        public Nullable<bool> FileCopied { get; set; }
        public Nullable<int> RLBProcessNotesID { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> Modified { get; set; }

        public virtual RLBAPImportDetail RLBAPImportDetail { get; set; }
        //public virtual RLBProcessNote RLBProcessNote { get; set; }
    }
}
