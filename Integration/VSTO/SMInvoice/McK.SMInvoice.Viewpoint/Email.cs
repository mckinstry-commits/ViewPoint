using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.SMInvoice.Viewpoint
{
    public static class Email
    {
        public static string GetSendFromEmail(List<dynamic> tblRecipients, string invoiceNumber)
        {
            string email = "";

            foreach (var r in tblRecipients)
            {
                var recipient = (IDictionary<string, object>)r;

                if (recipient.TryGetValue("Invoice Number", out object invoice))
                {
                    var i = (KeyValuePair<string, object>)invoice;

                    if (i.Value.ToString().Trim() == invoiceNumber)
                    {
                        if (recipient.TryGetValue("Send From", out object _email))
                        {
                            email = ((KeyValuePair<string, object>)_email).Value.ToString();
                            break;
                        }
                    }
                }
            }
            return email;
        }
    }
}
