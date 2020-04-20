using System;
using log4net;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileDownload
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
                return "Sends notification email of download.";
            }
        }

        public void RunWith(ILog log, List<SftpFile> files)
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
            if (files.Count <= 0)
            {
                Emailer.SendEmailNotificationNoFiles(log, this.Name);
                return;
            }
            Emailer.SendEmailNotification(files, log, this.Name);
        }
    }
}
