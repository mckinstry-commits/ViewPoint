using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.AttachmentUtility
{
    internal class FullFileRefreshCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Full Attachment File Refresh Command";
            }
        }

        public string Description
        {
            get
            {
                return "Performs full attachment file refresh.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Truncating attachment files table 'ViewpointAttachFiles'.");
            AttachmentUtilityDb.TruncateViewpointAttachFilesTable();

            log.Info("Logging all attachment files in production file system to database.");
            AttachmentUtilityHelper.LogServerAttachmentFiles(log, Settings.ProductionAttachmentDirectory, Settings.ProductionEnvironmentName);

            log.InfoFormat("Include staging attachment files : {0}.", Settings.IncludeStagingDirectory);
            if (Settings.IncludeStagingDirectory)
            {
                log.Info("Logging all attachment files in staging file system to database.");
                AttachmentUtilityHelper.LogServerAttachmentFiles(log, Settings.StagingAttachmentDirectory, Settings.StagingEnvironmentName);
            }
                        
            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
