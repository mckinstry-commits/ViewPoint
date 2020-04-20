using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.POReport.Viewpoint
{
    public class DetailRow
    {
        public byte JCCo { get; set; }

        public string udMCKPONumber_POHD { get; set; }
        public DateTime OrderDate_POHD { get; set; }

        // seller
        public string Name_APVM { get; set; }
        public string Address_APVM { get; set; }
        public string City_APVM { get; set; }
        public string State_APVM { get; set; }
        public string Zip_APVM { get; set; }

        public string Attention_POHD { get; set; }
        
        public string Vendor_POHD { get; set; }

        public string PayTerms_HQPT { get; set; }

        public string Description_udFOB { get; set; }
        public string Description_udShipMethod { get; set; }

        public DateTime ReqDate_POIT { get; set; }

        public string ServiceSite_SMWorkOrder { get; set; }
        public string Description_SMServiceSite { get; set; }

        //	-- Ship To
        public string Address_POHD { get; set; }
        public string City_POHD { get; set; }
        public string State_POHD { get; set; }
        public string Zip_POHD { get; set; }
        public string Country_POHD { get; set; }


        public string ShipIns_POHD { get; set; }

        //	-- Invoice To
        public string Name_HQCO { get; set; }
        public string Address_HQCO { get; set; }
        public string City_HQCO { get; set; }
        public string State_HQCO { get; set; }
        public string Zip_HQCO { get; set; }
        
        // PO ITEMS
        public Int16 POItem_POIT { get; set; }
        public string UM_POIT { get; set; }
        public string Description_POIT { get; set; }
        public string Notes_POIT { get; set; }
        public string Notes_POHD { get; set; }

        public decimal OrigCost_POIT { get; set; }
        public int SMWorkOrder_POIT { get; set; }
        public string Job_POIT { get; set; }
        public string Phase_POIT { get; set; }
        public decimal OrigTax_POIT { get; set; }
    }
}
