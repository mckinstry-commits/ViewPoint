using Microsoft.SqlServer.Server;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.Models.Viewpoint
{
    public class InvoiceParam
    {
        public string InvoiceNumber { get; set; }

        public InvoiceParam(string invoiceNumber)
        {
            InvoiceNumber = invoiceNumber;
        }
    }
}
