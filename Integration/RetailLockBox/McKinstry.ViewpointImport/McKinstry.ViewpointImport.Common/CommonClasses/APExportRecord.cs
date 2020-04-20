using System;
using LINQtoCSV;

namespace McKinstry.ViewpointImport.Common
{
    public class APExportRecord
    {
        [CsvColumn(CanBeNull = true)]
        public string RecordType { get; set; }
        [CsvColumn(CanBeNull = true)]
        public byte? Company { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string Number { get; set; }
        [CsvColumn(CanBeNull = true)]
        public byte? VendorGroup { get; set; }
        [CsvColumn(CanBeNull = true)]
        public int? Vendor { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string VendorName { get; set; }
        [CsvColumn(CanBeNull = true)]
        public DateTime? TransactionDate { get; set; }
        [CsvColumn(CanBeNull = true)]
        public byte? JCCo { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string Job { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string JobDescription { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string Description { get; set; }
        [CsvColumn(CanBeNull = true)]
        public int? DetailLineCount { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? TotalOrigCost { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? TotalOrigTax { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? RemainingAmount { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? RemainingTax { get; set; }
    }
}
