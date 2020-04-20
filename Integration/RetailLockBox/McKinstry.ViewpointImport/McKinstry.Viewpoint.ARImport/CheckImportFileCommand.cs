using System;
using log4net;
using System.IO;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class CheckImportFileCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "Check Import File Command";
            }
        }

        public string Description
        {
            get
            {
                return "Checks command input for valid import file.";
            }
        }

        public void RunWith(ILog log, string fileName, RLBImportBatch batch, ARImportFile file)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);

            log.Info("Checking if AR import file exists.");
            log.InfoFormat("Checking file '{0}'.", fileName);
            bool importFileExists = File.Exists(fileName);
            log.InfoFormat("File exists: {0}.", importFileExists);
            if (!importFileExists)
            {
                throw new ApplicationException(string.Format("Cannot find AR import file: '{0}'.", fileName));
            }

            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
