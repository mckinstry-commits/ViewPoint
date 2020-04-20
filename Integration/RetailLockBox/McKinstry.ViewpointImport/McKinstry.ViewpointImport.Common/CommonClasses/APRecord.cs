using System;
using LINQtoCSV;

namespace McKinstry.ViewpointImport.Common
{
    public class APRecord
    {
        [CsvColumn(FieldIndex = 1, CanBeNull = true)]
        public string UnmatchedNumber { get; set; }
        [CsvColumn(FieldIndex = 2, CanBeNull = true)]
        public string RecordType { get; set; }
        [CsvColumn(FieldIndex = 3, CanBeNull = true)]
        public byte? Company { get; set; }
        [CsvColumn(FieldIndex = 4, CanBeNull = true)]
        public string Number { get; set; }
        [CsvColumn(FieldIndex = 5, CanBeNull = true)]
        public byte? VendorGroup { get; set; }
        [CsvColumn(FieldIndex = 6, CanBeNull = true)]
        public int? Vendor { get; set; }
        [CsvColumn(FieldIndex = 7, CanBeNull = true)]
        public string VendorName { get; set; }
        [CsvColumn(FieldIndex = 8, CanBeNull = true)]
        public DateTime? TransactionDate { get; set; }
        [CsvColumn(FieldIndex = 9, CanBeNull = true)]
        public byte? JCCo { get; set; }
        [CsvColumn(FieldIndex = 10, CanBeNull = true)]
        public string Job { get; set; }
        [CsvColumn(FieldIndex = 11, CanBeNull = true)]
        public string JobDescription { get; set; }
        [CsvColumn(FieldIndex = 12, CanBeNull = true)]
        public string Description { get; set; }
        [CsvColumn(FieldIndex = 13, CanBeNull = true)]
        public int? DetailLineCount { get; set; }
        [CsvColumn(FieldIndex = 14, CanBeNull = true)]
        public decimal? TotalOrigCost { get; set; }
        [CsvColumn(FieldIndex = 15, CanBeNull = true)]
        public decimal? TotalOrigTax { get; set; }
        [CsvColumn(FieldIndex = 16, CanBeNull = true)]
        public decimal? RemainingAmount { get; set; }
        [CsvColumn(FieldIndex = 17, CanBeNull = true)]
        public decimal? RemainingTax { get; set; }
        [CsvColumn(FieldIndex = 18, CanBeNull = true)]
        public DateTime? CollectedInvoiceDate { get; set; }
        [CsvColumn(FieldIndex = 19, CanBeNull = true)]
        public string CollectedInvoiceNumber { get; set; }
        [CsvColumn(FieldIndex = 20, CanBeNull = true)]
        public decimal? CollectedTaxAmount { get; set; }
        [CsvColumn(FieldIndex = 21, CanBeNull = true)]
        public decimal? CollectedShippingAmount { get; set; }
        [CsvColumn(FieldIndex = 22, CanBeNull = true)]
        public decimal? CollectedInvoiceAmount { get; set; }
        [CsvColumn(FieldIndex = 23, CanBeNull = true)]
        public string CollectedImage { get; set; }
    }
}
