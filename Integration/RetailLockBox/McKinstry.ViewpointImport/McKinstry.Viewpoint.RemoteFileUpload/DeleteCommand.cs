using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileUpload
{
    internal class DeleteCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Delete File Command";
            }
        }

        public string Description
        {
            get
            {
                return "Deletes upload file.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.InfoFormat("Deleting file '{0}'.", Settings.UploadFileName);
            string uploadFile = Path.Combine(Settings.LogFilePath, Settings.UploadFileName);
            bool deleted = ImportFileHelper.DeleteFile(uploadFile);
            log.InfoFormat("File delete complete. Success: {0}.", deleted);
            log.InfoFormat("--Completed {0}--", this.Name);
            // Throw exception if logging was not successful
            if (!deleted)
            {
                throw new ApplicationException("File delete not successful. ImportFileHelper.DeleteFile returned false.");
            }
        }

    }
}
