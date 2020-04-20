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
    internal class PartialFileRefreshCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Partial Attachment File Refresh Command";
            }
        }

        public string Description
        {
            get
            {
                return "Performs partial attachment file refresh.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Logging attachment files added to production file system since last run time to database.");
            AttachmentUtilityHelper.LogServerAttachmentFilesPartial(log, Settings.ProductionAttachmentDirectory, Settings.ProductionEnvironmentName);

            log.InfoFormat("Include staging attachment files : {0}.", Settings.IncludeStagingDirectory);
            if (Settings.IncludeStagingDirectory)
            {
                log.Info("Logging attachment files added to staging file system since last run time to database.");
                AttachmentUtilityHelper.LogServerAttachmentFilesPartial(log, Settings.StagingAttachmentDirectory, Settings.StagingEnvironmentName);
            }
            
            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
