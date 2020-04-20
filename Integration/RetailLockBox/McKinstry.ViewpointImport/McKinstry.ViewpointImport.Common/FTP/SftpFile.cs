using System;

namespace McKinstry.ViewpointImport.Common
{
    public class SftpFile
    {
        public string FileName { get; set; }
        public DateTime LastWriteTime { get; set; }
        public long Length { get; set; }
        public bool? PreviouslyDownloaded { get; set; }
    }
}
