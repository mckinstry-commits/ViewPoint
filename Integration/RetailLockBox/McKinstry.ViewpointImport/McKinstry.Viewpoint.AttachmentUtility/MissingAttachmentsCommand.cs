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
    internal class MissingAttachmentsCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Missing Attachments Command";
            }
        }

        public string Description
        {
            get
            {
                return "Fetches HQAT records with missing attachments on file system and logs them to a database.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Logging all HQAT records not on file system to database.");
            AttachmentUtilityHelper.LogMissingAttachments(log);
                        
            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
