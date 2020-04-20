using System;
using log4net;
using System.Net.Mail;
using System.Collections.Generic;
using System.Xml.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileDownload
{
    internal static class Emailer
    {
        /// <summary>
        /// Email notification for no downloaded files
        /// </summary>
        internal static void SendEmailNotificationNoFiles(ILog log, string appName)
        {
            XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", "An attempt was made to download files from Retail Lock Box but no files were returned.",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "Details of download attempt are in the attached log file.  The VP Dev Team will respond to this alert and report back status.",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "VP Dev Team"))
            );

            log.Info("No files were downloaded.  Sending notification of no files returned.");
            log.InfoFormat("Emailing To Recipients '{0}'.", Settings.ToEmail);
            log.InfoFormat("Emailing Cc Recipients '{0}'.", Settings.CcEmail);
            log.Info("Done with email notifications.");
            log.InfoFormat("--Completed {0}--", appName);

            string logFile = log4net.GlobalContext.Properties["FileName"].ToString();
            List<Attachment> attachments = new List<Attachment>();
            attachments.Add(new Attachment(logFile));

            MailHelper.SendMail(Settings.FromEmail, Settings.FromEmailDisplayName, Settings.ToEmail,
                Settings.CcEmail, Settings.NoDownloadEmailSubject, bodyHtml.FirstNode, attachments);
        }

        /// <summary>
        /// Sends successful download email notification
        /// </summary>
        internal static void SendEmailNotification(List<SftpFile> files, ILog log, string appName)
        {
            log.InfoFormat("Emailing To Recipients '{0}'.", Settings.ToEmail);
            log.InfoFormat("Emailing Cc Recipients '{0}'.", Settings.CcEmail);
            log.Info("Done with email notifications.");
            log.InfoFormat("--Completed {0}--", appName);

            XElement filesList = new XElement("ul");
            foreach (var file in files)
            {
                string asterisk = file.PreviouslyDownloaded == true ? "*" : "";
                filesList.Add(new XElement("li", asterisk + file.FileName));
            }
            XDocument bodyHtml = new XDocument(
                new XElement("div",
                    new XElement("div", "The following files have been downloaded from Retail Lock Box to the download directory:",
                        new XElement("br"),
                        new XElement("br"), new XElement("a",
                            new XAttribute("href", Settings.LocalDownloadPath),
                        Settings.LocalDownloadPath),
                        new XElement("br"),
                        filesList),
                    new XElement("div",
                        new XElement("i", "* Files marked with an asterisk (*) have been downloaded previously."),
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div",
                        "Please verify the downloaded file(s) are as expected. If correct, move the downloaded file(s) to the RLB drop folder location ",
                        new XElement("a",
                        new XAttribute("href", CommonSettings.RlbDownloadFileDrop), CommonSettings.RlbDownloadFileDrop),
                        ". This action will start the Viewpoint upload process for the file(s).",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div",
                        new XElement("div", "Reasons for not seeing the download file(s) you are expecting:",
                        new XElement("ul",
                        new XElement("li", "File download occurred on a bank holiday (no new download file(s) produced)"),
                        new XElement("li", "File download occurred on a RLB process holiday (no new download file(s) produced)"),
                        new XElement("li", "Download file is late. In this case, contact IT Dev Team and RLB to investigate.  When confirmed by RLB, IT Dev Team will manually start the download process a second time to fetch missing file(s)."),
                        new XElement("li", "Excected file(s) not latest RLB file(s). In this case, contact IT Dev Team to investigate. The IT Dev Team can manually download the expected file(s).")))),
                    new XElement("div", "Thanks!",
                        new XElement("br"),
                        new XElement("br")),
                    new XElement("div", "VP Dev Team"))
            );

            string logFile = log4net.GlobalContext.Properties["FileName"].ToString();
            List<Attachment> attachments = new List<Attachment>();
            attachments.Add(new Attachment(logFile));

            MailHelper.SendMail(Settings.FromEmail, Settings.FromEmailDisplayName, Settings.ToEmail,
                Settings.CcEmail, Settings.EmailSubject, bodyHtml.FirstNode, attachments);
        }
    }
}
