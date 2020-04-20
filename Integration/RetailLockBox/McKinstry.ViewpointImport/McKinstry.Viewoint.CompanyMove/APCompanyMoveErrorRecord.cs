using System;
using LINQtoCSV;

namespace McKinstry.Viewoint.CompanyMove
{
    public class APCompanyMoveErrorRecord
    {
        [CsvColumn(FieldIndex = 1, CanBeNull = true)]
        public bool? HeaderMoved { get; set; }
        [CsvColumn(FieldIndex = 2, CanBeNull = true)]
        public bool? AttachmentsMoved { get; set; }
        [CsvColumn(FieldIndex = 3, CanBeNull = true)]
        public bool? AttachmentsCopied { get; set; }
        [CsvColumn(FieldIndex = 4, CanBeNull = true)]
        public byte? Co { get; set; }
        [CsvColumn(FieldIndex = 5, CanBeNull = true)]
        public DateTime? Mth { get; set; }
        [CsvColumn(FieldIndex = 6, CanBeNull = true)]
        public short? UISeq { get; set; }
        [CsvColumn(FieldIndex = 7, CanBeNull = true)]
        public int? Vendor { get; set; }
        [CsvColumn(FieldIndex = 8, CanBeNull = true)]
        public string APRef { get; set; }
        [CsvColumn(FieldIndex = 9, CanBeNull = true)]
        public decimal? InvTotal { get; set; }
        [CsvColumn(FieldIndex = 10, CanBeNull = true)]
        public string Notes { get; set; }
    }
}

