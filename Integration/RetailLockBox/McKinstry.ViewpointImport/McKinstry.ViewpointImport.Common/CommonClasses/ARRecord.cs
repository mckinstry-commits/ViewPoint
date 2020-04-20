using System;
using LINQtoCSV;

namespace McKinstry.ViewpointImport.Common
{
    public class ARRecord
    {
        [CsvColumn(FieldIndex = 1, CanBeNull = true)]
        public byte? Company { get; set; }
        [CsvColumn(FieldIndex = 2, CanBeNull = true)]
        public string InvoiceNumber { get; set; }
        [CsvColumn(FieldIndex = 3, CanBeNull = true)]
        public byte? CustGroup { get; set; }
        [CsvColumn(FieldIndex = 4, CanBeNull = true)]
        public int? Customer { get; set; }
        [CsvColumn(FieldIndex = 5, CanBeNull = true)]
        public string CustomerName { get; set; }
        [CsvColumn(FieldIndex = 6, CanBeNull = true)]
        public DateTime? TransactionDate { get; set; }
        [CsvColumn(FieldIndex = 7, CanBeNull = true)]
        public string InvoiceDescription { get; set; }
        [CsvColumn(FieldIndex = 8, CanBeNull = true)]
        public int? DetailLineCount { get; set; }
        [CsvColumn(FieldIndex = 9, CanBeNull = true)]
        public decimal? AmountDue { get; set; }
        [CsvColumn(FieldIndex = 10, CanBeNull = true)]
        public decimal? OriginalAmount { get; set; }
        [CsvColumn(FieldIndex = 11, CanBeNull = true)]
        public decimal? Tax { get; set; }
        [CsvColumn(FieldIndex = 12, CanBeNull = true)]
        public DateTime? CollectedCheckDate { get; set; }
        [CsvColumn(FieldIndex = 13, CanBeNull = true)]
        public string CollectedCheckNumber { get; set; }
        [CsvColumn(FieldIndex = 14, CanBeNull = true)]
        public decimal? CollectedCheckAmount { get; set; }
        [CsvColumn(FieldIndex = 15, CanBeNull = true)]
        public string CollectedImage { get; set; }
        [CsvColumn(FieldIndex = 16, CanBeNull = true)]
        public string Notes { get; set; }
    }
}
