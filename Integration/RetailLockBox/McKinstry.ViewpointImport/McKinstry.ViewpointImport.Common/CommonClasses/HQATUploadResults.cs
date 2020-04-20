using System;

namespace McKinstry.ViewpointImport.Common
{
    public struct HQATUploadResults
    {
        private int? keyID;
        public int? KeyID
        {
            get
            {
                return keyID;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value > 0 ? value : null;
                }
                keyID = value;
            }
        }

        private Guid? uniqueAttachmentID;
        public Guid? UniqueAttachmentID
        {
            get
            {
                return uniqueAttachmentID;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value == Guid.Empty ? null : value;
                }
                uniqueAttachmentID = value;
            }
        }

        public string AttachmentFilePath { get; set; }

        public string Message { get; set; }

        public int RetVal { get; set; }
    }
}
