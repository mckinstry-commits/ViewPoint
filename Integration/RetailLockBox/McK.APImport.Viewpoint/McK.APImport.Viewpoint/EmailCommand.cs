using System;
using log4net;
using System.IO;
using System.Net.Mail;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using McK.APImport.Common;

namespace McK.APImport.Viewpoint
{
    internal class EmailCommand : ICommand
    {
        public string Name => "Email Notification Command";

        public string Description => "Sends notification email of AP upload to Viewpoint.";

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
            List<RecordSummary> detailRecordCounts = APImportDb.GetAPDetailRecordCounts(file.RecordCount, batch.RLBImportBatchID);
            XElement recordCountList = new XElement("div");
            foreach (var count in detailRecordCounts)
            {
                recordCountList.Add(new XElement("div",
                    new XElement("span", string.Format("\u00A0\u00A0\u00A0{0}:\u00A0", count.Status)),
                    new XElement("span", count.Count)
                    ));
            }

            List<RecordSummary> processCheckCounts = APImportDb.GetAPProcessingCounts(file.RecordCount, batch.RLBImportBatchID);
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
                    new XElement("div", string.Format("The '{0}' RLB batch has been uploaded to Viewpoint.  A complete summary of upload activity can be found in the attached log file.",
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
            List<Attachment> attachments = new List<Attachment>
            {
                new Attachment(logFile)
            };

            MailHelper.SendMail(Settings.FromEmail, Settings.FromEmailDisplayName, Settings.ToEmail,
                Settings.CcEmail, Settings.EmailSubject, bodyHtml.FirstNode, attachments);
        }
    }
}
