using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.SMInvoice.Viewpoint
{
    public static class Phone
    {
        public static string GetBillingPhone(List<dynamic> tblRecipients, string invoiceNumber)
        {
            string phone = "";

            foreach (var r in tblRecipients)
            {
                var recipient = (IDictionary<string, object>)r;

                if (recipient.TryGetValue("Invoice Number", out object invoice))
                {
                    var i = (KeyValuePair<string, object>)invoice;

                    if (i.Value.ToString().Trim() == invoiceNumber)
                    {
                        if (recipient.TryGetValue("Billing Phone", out object _phone))
                        {
                            phone = ((KeyValuePair<string, object>)_phone).Value.ToString();
                            break;
                        }
                    }
                }
            }
            return phone;
        }
    }
}
