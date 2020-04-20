using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.APImport.Common
{
    public partial class RLBImportBatch
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public RLBImportBatch()
        {
            this.RLBAPImportDetails = new HashSet<RLBAPImportDetail>();
        }

        public int RLBImportBatchID { get; set; }
        public Nullable<int> RLBProcessNotesID { get; set; }
        public string FileName { get; set; }
        public System.DateTime LastWriteTime { get; set; }
        public long Length { get; set; }
        public string Type { get; set; }
        public string RLBImportBatchStatusCode { get; set; }
        public System.DateTime StartTime { get; set; }
        public Nullable<System.DateTime> CompleteTime { get; set; }
        public string ArchiveFolderName { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> Modified { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<RLBAPImportDetail> RLBAPImportDetails { get; set; }
    }
}
