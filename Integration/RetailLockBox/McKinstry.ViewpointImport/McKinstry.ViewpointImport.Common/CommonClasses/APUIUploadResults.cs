using System;

namespace McKinstry.ViewpointImport.Common
{
    public struct APUIUploadResults
    {

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

        private short? uISeq;
        public short? UISeq
        {
            get
            {
                return uISeq;
            }
            set
            {
                if (value.HasValue)
                {
                    value = value > 0 ? value : null;
                }
                uISeq = value;
            }
        }
    }
}
