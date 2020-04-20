using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.ARImport
{
    internal class ARImportFile : ImportFile
    {
        // Pass values to base class
        public ARImportFile(string fileName) : base(fileName, ARSettings.ARFilePrefix, 
            ARSettings.ARProcessFolderLocation, Settings.ArchiveFolderLocation) {}
    }
}
