using System;
using System.IO;
using log4net;
using LINQtoCSV;
using System.Linq;
using System.Xml.Linq;
using System.Net.Mail;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewoint.CompanyMove
{
    internal class APErrorEmailCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "AP Company Move Error Email Command";
            }
        }

        public string Description
        {
            get
            {
                return "Sends an email to specified users if error records are created.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Begin AP company move error email.");

            string logFile = Path.GetFileName(log4net.GlobalContext.Properties["FileName"].ToString());

            CompanyMoveMetric applicationData = CompanyMoveDb.GetCompanyMoveMetric(Settings.ApplicationKey);
            log.InfoFormat("Fetching application metrics. Last notification date: {0}.", applicationData.LastNotifyDate.HasValue ? applicationData.LastNotifyDate : null);

            if (!applicationData.LastNotifyDate.HasValue)
            {
                log.InfoFormat("Creating metrics for application.  Application Key: '{0}'.", Settings.ApplicationKey);
                CompanyMoveDb.CreateCompanyMoveMetric(Settings.ApplicationKey, logFile);
                goto FinishedProcessing;
            }

            DateTime notifyTrigger = applicationData.LastNotifyDate.Value.AddHours(Settings.NotificationHourInterval);
            DateTime now = DateTime.Now;
            log.InfoFormat("Next email notification time: {0}.  Current time: {1}. Trigger notificaton: {2}.", notifyTrigger, now, now > notifyTrigger);
            if (now.ToUniversalTime() > notifyTrigger.ToUniversalTime())
            {
                log.Info("Notification triggered");
                log.InfoFormat("Email notifications turned on: {0}.", Settings.SendNotificationEmail);
                if (Settings.SendNotificationEmail)
                {
                    SendErrorEmail(log, logFile);
                }

                // If there is a large gap in last time recorded (say, scheduled task stopped), add more time to catch up
                while (now.ToUniversalTime().Subtract(notifyTrigger.ToUniversalTime()) > TimeSpan.FromHours(Settings.NotificationHourInterval))
                {
                    notifyTrigger = notifyTrigger.AddHours(Settings.NotificationHourInterval);
                }

                bool updated = CompanyMoveDb.UpdateCompanyMoveMetric(Settings.ApplicationKey, notifyTrigger, logFile);
                log.InfoFormat("Updating application metrics. Updated: {0}. New last notified date: {1}.", updated, notifyTrigger);
            }

            FinishedProcessing:

            log.Info("Done AP with company move error email.");

            log.InfoFormat("--Completed {0}--", this.Name);
        }

        private void SendErrorEmail(ILog log, string logFile)
        {
            List<APCompanyMoveErrorRecord> errors = CompanyMoveDb.GetAPCompanyMoveItems(logFile);

            log.InfoFormat("Checking for errors to notify.  Count: {0}.", errors.Count);

            if (errors.Count == 0)
            {
                log.Info("No notification email will be sent.");
            }

            if (errors.Count > 0)
            {
                log.Info("Sending error email.");
                // Create CSV file from errors
                CsvFileDescription inputFileDescription = new CsvFileDescription
                {
                    SeparatorChar = ',',
                    FirstLineHasColumnNames = true
                };
                string csvFileFullPath = Path.Combine(Settings.LogFileFolderLocation, string.Concat(Settings.LogFileName, "_Errors.csv"));
                if (File.Exists(csvFileFullPath))
                {
                    ImportFileHelper.DeleteFile(csvFileFullPath);
                }
                CsvContext cc = new CsvContext();
                cc.Write(errors, csvFileFullPath);

                List<Attachment> attachments = new List<Attachment>();
                attachments.Add(new Attachment(csvFileFullPath));

                XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", "The AP compamy move process has completed with errors.  A list of records not moved is included in the attached file.",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "Thanks,",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "VP Dev Team"))
                );

                MailHelper.SendMail(Settings.FromEmail, Settings.FromEmailDisplayName, Settings.ToEmail,
                Settings.CcEmail, Settings.EmailSubject, bodyHtml.FirstNode, attachments);
            }
        }
    }
}
