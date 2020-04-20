using System;
using System.Collections.Generic;

namespace McK.APImport.Common
{
    public partial class RLBProcessNote
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public RLBProcessNote()
        {
            this.RLBAPImportDetails = new HashSet<RLBAPImportDetail>();
            this.RLBAPImportRecords = new HashSet<RLBAPImportRecord>();
            //this.RLBARImportDetails = new HashSet<RLBARImportDetail>();
            //this.RLBARImportRecords = new HashSet<RLBARImportRecord>();
            //this.AttachCompanyMoves = new HashSet<AttachCompanyMove>();
            //this.APCompanyMoves = new HashSet<APCompanyMove>();
            //this.RLBDropFolderWatchers = new HashSet<RLBDropFolderWatcher>();
        }

        public int RLBProcessNotesID { get; set; }
        public string ProcessNotes { get; set; }
        public Nullable<System.DateTime> Created { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<RLBAPImportDetail> RLBAPImportDetails { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<RLBAPImportRecord> RLBAPImportRecords { get; set; }
        //[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        //public virtual ICollection<RLBARImportDetail> RLBARImportDetails { get; set; }
        //[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        //public virtual ICollection<RLBARImportRecord> RLBARImportRecords { get; set; }
        //[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        //public virtual ICollection<AttachCompanyMove> AttachCompanyMoves { get; set; }
        //[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        //public virtual ICollection<APCompanyMove> APCompanyMoves { get; set; }
        //[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        //public virtual ICollection<RLBDropFolderWatcher> RLBDropFolderWatchers { get; set; }
    }
}
