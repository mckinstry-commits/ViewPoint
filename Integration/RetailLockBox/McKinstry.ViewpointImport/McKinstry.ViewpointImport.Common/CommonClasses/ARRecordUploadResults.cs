using System;

namespace McKinstry.ViewpointImport.Common
{
    public struct ARDetailUploadResults
    {
        private long? batchID;
        public long? BatchID
        {
            get
            {
                return batchID;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value > 0 ? value : null;
                }
                batchID = value;
            }
        }

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

        public string Message { get; set; }

        public int RetVal { get; set; }
    }
}
