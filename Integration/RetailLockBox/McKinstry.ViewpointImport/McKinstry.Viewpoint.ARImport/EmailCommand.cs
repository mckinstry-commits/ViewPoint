using System;
using log4net;
using System.IO;
using System.Net.Mail;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
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
                return "Sends notification email of AR upload to Viewpoint.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
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

        private void SendEmailNotification(RLBImportBatch batch, ARImportFile file)
        {
            List<RecordSummary> detailRecordCounts = ARImportDb.GetARDetailRecordCounts(file.RecordCount, batch.RLBImportBatchID);
            XElement recordCountList = new XElement("div");
            foreach (var count in detailRecordCounts)
            {
                recordCountList.Add(new XElement("div",
                    new XElement("span", string.Format("\u00A0\u00A0\u00A0{0}:\u00A0", count.Status)),
                    new XElement("span", count.Count)
                    ));
            }

            List<RecordSummary> processCheckCounts = ARImportDb.GetARProcessingCounts(file.RecordCount, batch.RLBImportBatchID);
            XElement processCountList = new XElement("div");
            foreach (var count in processCheckCounts)
            {
                processCountList.Add(new XElement("div",
                    new XElement("span", string.Format("\u00A0\u00A0\u00A0{0}:\u00A0", count.Status)),
                    new XElement("span", count.Count)
                    ));
            }

            XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", string.Format("The '{0}' RLB batch has been uploaded to Viewpoint.  A complete summary of processing activity can be found in the attached process log file.", 
                        Path.GetFileNameWithoutExtension(batch.FileName)),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "Record Counts"),
                        recordCountList,
                    new XElement("div", string.Format("Total RLB: {0}", file.RecordCount),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "Processing Checks"),
                        processCountList,
                        new XElement("br"),
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
            IEnumerable<string> csvFiles = ImportFileHelper.FetchFiles(ARSettings.ARProcessFolderLocation, ".csv");
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
