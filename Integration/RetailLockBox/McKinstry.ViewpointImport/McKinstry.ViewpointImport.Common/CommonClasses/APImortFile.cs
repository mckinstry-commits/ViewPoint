using System;
using System.IO;

namespace McKinstry.ViewpointImport.Common
{
    public class APImportFile : ImportFile
    {
        // Pass values to base class
        public APImportFile(string fileName) : base(fileName, APSettings.APFilePrefix, 
            APSettings.APProcessFolderLocation, APSettings.APArchiveFolderLocation) {}

        public string ExceptionsFolder
        {
            get
            {
                return "Exceptions";
            }
        }

        public string ReviewFolder
        {
            get
            {
                return "Matched_To_Review";
            }
        }

        public string StatementsFolder
        {
            get
            {
                return "Statements";
            }
        }

        public string ExceptionsPath
        {
            get
            {
                return Path.Combine(ProcessExtractPath, ExceptionsFolder);
            }
        }

        public string ReviewPath
        {
            get
            {
                return Path.Combine(ProcessExtractPath, ReviewFolder);
            }
        }

        public string StatementsPath
        {
            get
            {
                return Path.Combine(ProcessExtractPath, StatementsFolder);
            }
        }
    }
}
