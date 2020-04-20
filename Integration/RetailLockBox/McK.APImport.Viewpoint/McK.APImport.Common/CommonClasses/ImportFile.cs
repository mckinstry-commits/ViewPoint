using System;
using System.IO;
using System.Globalization;


namespace McK.APImport.Common
{
    public abstract class ImportFile
    {
        private string fullFileName;
        private string fileName;
        private DateTime fileDateTime;
        private string baseFileName;
        private string fileDateString;
        private string filePrefix;
        private DateTime lastWriteTime;
        private long length;
        private string processExtractPath;
        private string archivePath;
        private DateTime transactionDate;

        public ImportFile(string fileName, string filePrefix, string processFolder, string archiveFolder)
        {
            VaidateInput(fileName, filePrefix, processFolder, archiveFolder);
            this.filePrefix = filePrefix;
            this.fullFileName = fileName;
            this.fileName = Path.GetFileName(fileName);
            this.baseFileName = Path.GetFileNameWithoutExtension(fileName);
            this.fileDateString = FetchDateTimeString(baseFileName, filePrefix);
            this.fileDateTime = FetchFileDateTime(fileDateString);
            FileInfo info = new FileInfo(fileName);
            this.lastWriteTime = info.LastWriteTime;
            this.length = info.Length;
            this.processExtractPath = Path.Combine(processFolder, this.baseFileName);
            this.archivePath = Path.Combine(archiveFolder, this.baseFileName);
            this.transactionDate = DateTime.Now;
            VaidateFile();
        }

        public string ProcessExtractPath
        {
            get
            {
                return this.processExtractPath;
            }
        }

        public string ArchivePath
        {
            get
            {
                return this.archivePath;
            }
        }

        public string FileName
        {
            get
            {
                return this.fileName;
            }
        }

        public string FullFileName
        {
            get
            {
                return this.fullFileName;
            }
        }

        public string BaseFileName
        {
            get
            {
                return this.baseFileName;
            }
        }

        public DateTime FileDateTime
        {
            get
            {
                return this.fileDateTime;
            }
        }

        public string FileMonth
        {
            get
            {
                return this.fileDateTime.ToString("MM");
            }
        }

        public string FileDay
        {
            get
            {
                return this.fileDateTime.ToString("dd");
            }
        }

        public string FileYear
        {
            get
            {
                return this.fileDateTime.ToString("yyyy");
            }
        }

        public string FilePrefix
        {
            get
            {
                return this.filePrefix;
            }
        }

        public DateTime LastWriteTime
        {
            get
            {
                return this.lastWriteTime;
            }
        }

        public long Length
        {
            get
            {
                return this.length;
            }
        }

        public int RecordCount
        {
            get;
            set;
        }

        public string DataFileName
        {
            get;
            set;
        }

        public DateTime TransactionDate
        {
            get
            {
                if (this.transactionDate == DateTime.MinValue)
                {
                    return DateTime.Now;
                }
                return this.transactionDate;
            }
            set
            {
                this.transactionDate = value;
            }
        }

        private void VaidateInput(string fileName, string filePrefix, string processFolder, string archiveFolder)
        {
            if (string.IsNullOrEmpty(fileName))
            {
                throw new ApplicationException("Unable to create import batch. Missing file name.");
            }
            if (string.IsNullOrEmpty(filePrefix))
            {
                throw new ApplicationException("Unable to create import batch. Missing file prefix.");
            }
            if (string.IsNullOrEmpty(processFolder))
            {
                throw new ApplicationException("Unable to create import batch. Missing process folder.");
            }
            if (string.IsNullOrEmpty(archiveFolder))
            {
                throw new ApplicationException("Unable to create import batch. Missing archive folder.");
            }
        }

        private void VaidateFile()
        {
            if (Path.GetExtension(this.fullFileName).ToLower() != ".zip")
            {
                throw new ApplicationException("Import file is not a valid zip file.");
            }
            if (!this.baseFileName.StartsWith(this.filePrefix))
            {
                throw new ApplicationException(string.Format("Import file is not a valid import file.  Must start with prefix '{0}'.", this.filePrefix));
            }
        }

        private string FetchDateTimeString(string baseFileName, string filePrefix)
        {
            string baseNameNoPrefix = this.baseFileName.Replace(filePrefix, "");
            if (baseNameNoPrefix.Length < 8)
            {
                throw new ApplicationException(string.Format("Unable to create date from input file name: '{0}'", baseFileName));
            }
            string date = baseNameNoPrefix.Substring(0, 8);
            int result;
            Int32.TryParse(date, out result);
            if (result == 0)
            {
                throw new ApplicationException(string.Format("Unable to create date from input file name: '{0}'", baseFileName));
            }
            return date;
        }

        private DateTime FetchFileDateTime(string date)
        {
            DateTime result;
            DateTime.TryParseExact(date, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.NoCurrentDateDefault, out result);
            if (result == DateTime.MinValue)
            {
                throw new ApplicationException(string.Format("Unable to create datetime value from input file name.  Date string: '{0}'", date));
            }
            return result;
        }
    }
}
