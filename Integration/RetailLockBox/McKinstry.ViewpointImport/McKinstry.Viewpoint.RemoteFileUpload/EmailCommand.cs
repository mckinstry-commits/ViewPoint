using System;
using log4net;
using System.IO;
using System.Net.Mail;
using System.Collections.Generic;
using System.Xml.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileUpload
{
    internal class EmailCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Email Notification Command";
            }
        }

        public string Description
        {
            get
            {
                return "Sends notification email of upload.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.Info("Sending email notification.");
            if (!Settings.SendNotificationEmail)
            {
                log.Info("Email notifications settings set to false. No email sent.");
                log.InfoFormat("--Completed {0}--", this.Name);
                return;
            }
            SendEmailNotification(log);
        }

        /// <summary>
        /// Sends successful upload email notification
        /// </summary>
        private void SendEmailNotification(ILog log)
        {
            log.InfoFormat("Emailing To Recipients '{0}'.", Settings.ToEmail);
            log.InfoFormat("Emailing Cc Recipients '{0}'.", Settings.CcEmail);
            log.InfoFormat("--Completed {0}--", this.Name);

            List<Attachment> attachments = new List<Attachment>();
            string uploadFilePath = Path.Combine(Settings.LogFilePath, Settings.UploadFileName);
            bool fileExists = File.Exists(uploadFilePath);
            if (fileExists)
            {
                attachments.Add(new Attachment(uploadFilePath));
            }
            string logFile = log4net.GlobalContext.Properties["FileName"].ToString();
            string logFilePath = Path.Combine(Settings.LogFilePath, logFile);
            fileExists = File.Exists(logFilePath);
            if (fileExists)
            {
                attachments.Add(new Attachment(logFilePath));
            }
            XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", "The following files (attached) have been uploaded to Retail Lock Box:",
                        new XElement("ul",
                            new XElement("li"), Settings.UploadFileName)),
                    new XElement("div", "Thanks!",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "VP Dev Team"))
            );
            
            MailHelper.SendMail(Settings.FromEmail, Settings.FromEmailDisplayName, Settings.ToEmail,
                Settings.CcEmail, Settings.EmailSubject, bodyHtml.FirstNode, attachments);
        }
    }
}
