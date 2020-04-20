using System;
using System.Net;
using System.Net.Mail;
using System.Net.Mime;
using System.Threading;
using System.Threading.Tasks;
using System.ComponentModel;
using System.Configuration;
using System.Collections.Generic;
using System.Xml.Linq;

namespace McK.APImport.Common
{
    public static class MailHelper
    {
        public static void SendMail(string fromEmail, string fromEmailDisplayName, string toEmails,
            string ccEmails, string subject, XNode bodyInnerHtml, List<Attachment> attachments)
        {
            SendMail(fromEmail, fromEmailDisplayName, toEmails, ccEmails, subject, bodyInnerHtml, attachments, false);
        }

        public static void SendMail(string fromEmail, string fromEmailDisplayName, string toEmails,
            string ccEmails, string subject, XNode bodyInnerHtml, List<Attachment> attachments, bool isPriority)
        {
            using (SmtpClient client = new SmtpClient(CommonSettings.MailSmtpHost))
            {

                using (MailMessage message = new MailMessage())
                {
                    message.From = new MailAddress(fromEmail, fromEmailDisplayName);

                    message.Priority = isPriority ? MailPriority.High : MailPriority.Normal;

                    message.To.Add(toEmails);
                    if (!string.IsNullOrEmpty(ccEmails))
                    {
                        message.CC.Add(ccEmails);
                    }

                    message.SubjectEncoding = System.Text.Encoding.UTF8;
                    message.Subject = subject;

                    message.IsBodyHtml = true;
                    message.BodyEncoding = System.Text.Encoding.UTF8;
                    XDocument doc = new XDocument(
                        new XElement("body",
                            new XElement("div",
                                new XAttribute("style", "font-family:Tahoma; color:#000000; font-size:10pt"),
                                bodyInnerHtml)));
                    message.Body = doc.ToString();

                    if (attachments != null)
                    {
                        foreach (var attachment in attachments)
                        {
                            message.Attachments.Add(attachment);
                        }
                    }
                    client.Send(message);
                }
            }
        }

        public static void SendErrorEmail(string applicationName, string fromEmail, string fromEmailDisplayName, string toEmails,
            string ccEmails, string subject, Attachment attachment)
        {
            List<Attachment> attachments = new List<Attachment>();
            attachments.Add(attachment);

            XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", string.Format("An error has occurred in RLB Viewpoint application: {0}.", applicationName),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "Error details are included in the attached log file.  The VP Dev Team will respond to this alert and report back status.",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "VP Dev Team")));

            SendMail(fromEmail, fromEmailDisplayName, toEmails, ccEmails, subject, bodyHtml.FirstNode, attachments, true);
        }
    }
}
