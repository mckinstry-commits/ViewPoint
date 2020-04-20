using System;

namespace McK.APImport.Common
{
    public struct APRecordUploadResults
    {
        private int? attachmentID;
        public int? AttachmentID
        {
            get
            {
                return attachmentID;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value > 0 ? value : null;
                }
                attachmentID = value;
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

        private long? headerKeyID;
        public long? HeaderKeyID
        {
            get
            {
                return headerKeyID;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value > 0 ? value : null;
                }
                headerKeyID = value;
            }
        }

        private long? footerKeyID;
        public long? FooterKeyID
        {
            get
            {
                return footerKeyID;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value > 0 ? value : null;
                }
                footerKeyID = value;
            }
        }


        public string Message { get; set; }

        public int RetVal { get; set; }
    }
}
