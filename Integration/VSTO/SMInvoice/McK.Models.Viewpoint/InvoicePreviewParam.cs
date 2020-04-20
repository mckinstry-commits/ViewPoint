using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.Models.Viewpoint
{
    public class InvoicePreviewParam
    {

        public byte SMCo { get; set; }
        public Int64 SMInvoiceID { get; set; }
        public string InvoiceNumber { get; set; }
        public string WorkOrder { get; set; }

        public InvoicePreviewParam(byte smco, Int64 smInvoiceID, string invoiceNumber, string WorkOrder)
        {
            SMCo                = smco;
            SMInvoiceID         = smInvoiceID;
            InvoiceNumber       = invoiceNumber;
            WorkOrder    = WorkOrder;
        }
    }
}
