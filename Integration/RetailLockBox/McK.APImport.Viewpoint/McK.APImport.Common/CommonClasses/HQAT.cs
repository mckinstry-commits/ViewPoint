using System;
using System.Collections.Generic;

namespace McK.APImport.Common
{
    public class HQAT
    {
        public byte HQCo { get; set; }

        public string FormName { get; set; }

        public string KeyField { get; set; }

        public string Description { get; set; }

        public string AddedBy { get; set; }

        public DateTime? AddDate { get; set; }

        public string DocName { get; set; }

        public int AttachmentID { get; set; }

        public string TableName { get; set; }

        public Guid? UniqueAttchID { get; set; }

        public string OrigFileName { get; set; }

        public string DocAttchYN { get; set; }

        public string CurrentState { get; set; }

        public int? AttachmentTypeID { get; set; }

        public string IsEmail { get; set; }

        public long KeyID { get; set; }
    }
}
