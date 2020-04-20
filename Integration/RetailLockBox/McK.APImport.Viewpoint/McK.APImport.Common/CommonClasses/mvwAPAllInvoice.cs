using System;
using System.Collections.Generic;

namespace McK.APImport.Common
{
    public partial class mvwAPAllInvoice
    {
        public string Type { get; set; }
        public byte APCo { get; set; }
        public System.DateTime Mth { get; set; }
        public int APTrans { get; set; }
        public byte VendorGroup { get; set; }
        public Nullable<int> Vendor { get; set; }
        public string APRef { get; set; }
        public Nullable<System.DateTime> InvDate { get; set; }
        public string Description { get; set; }
        public Nullable<System.DateTime> DueDate { get; set; }
        public decimal InvTotal { get; set; }
    }
}
