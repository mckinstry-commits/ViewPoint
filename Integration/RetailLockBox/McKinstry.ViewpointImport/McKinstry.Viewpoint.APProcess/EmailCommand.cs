using System;
using log4net;
using System.IO;
using System.Net.Mail;
using System.Xml.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
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
                return "Sends notification AP upload file is ready for manual processing.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            if (!Settings.SendNotificationEmail)
            {
                log.Info("Email notifications settings set to false. No email sent.");
                log.InfoFormat("--Completed {0}--", this.Name);
                return;
            }

            SendEmailNotification(batch, file);

            log.InfoFormat("--Completed {0}--", this.Name);
        }

        private void SendEmailNotification(RLBImportBatch batch, APImportFile file)
        {
            XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", string.Format("The {0}/{1} AP file is ready for processing:", file.FileMonth, file.FileDay),
                        new XElement("br"), new XElement("a",
                            new XAttribute("href", file.ProcessExtractPath),
                        file.ProcessExtractPath),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", string.Format("The RLB AP records are in file '{0}' for your reference.  They have been scrubbed for exceptions and the exception images have been moved to the '{1}' folder.", file.DataFileName, file.ExceptionsFolder),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", string.Format("All matched AP record images have been copied to the '{0}' folder.  Please review these images for any exceptions.  If you find any exceptions, copy or move these to the '{1}' folder.", file.ReviewFolder, file.ExceptionsFolder),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "When you are done, use the AP Unapproved Invoice Import program to upload the records to Viewpoint.",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "Thanks!",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "VP Dev Team"))
            );

            // Attach log file
            string logFile = log4net.GlobalContext.Properties["FileName"].ToString();
            List<Attachment> attachments = new List<Attachment>();
            attachments.Add(new Attachment(logFile));

            // Attach any data files created in processing
            IEnumerable<string> csvFiles = ImportFileHelper.FetchFiles(APSettings.APProcessFolderLocation, ".csv");
            foreach (var csvFile in csvFiles)
            {
                if (Path.GetFileName(csvFile).StartsWith(file.BaseFileName))
                {
                    attachments.Add(new Attachment(csvFile));
                }
            }

            MailHelper.SendMail(Settings.FromEmail, Settings.FromEmailDisplayName, Settings.ToEmail,
                Settings.CcEmail, Settings.EmailSubject, bodyHtml.FirstNode, attachments);
        }
    }
}
