using System;
using log4net;
using System.IO;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileUpload
{
    internal class UploadCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Upload File Command";
            }
        }

        public string Description
        {
            get
            {
                return "Uploads file to remote FTP location.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.InfoFormat("Attempting to upload file: '{0}'.", Settings.UploadFileName);
            bool uploaded = RlbSftpHelper.UploadFileToRemotePath(Path.Combine(Settings.LogFilePath, Settings.UploadFileName), Settings.RemoteUploadPath);
            log.InfoFormat("File uploaded. Success: {0}.", uploaded);
            log.InfoFormat("--Completed {0}--", this.Name);
            // Throw exception if upload was not successful
            if (!uploaded)
            {
                throw new ApplicationException("File upload was not successful. RlbSftpHelper.UploadFileToRemotePath returned false.");
            }
        }
    }
}
