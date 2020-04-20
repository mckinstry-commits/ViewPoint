using System;
using LINQtoCSV;

namespace McKinstry.ViewpointImport.Common
{
    public class ARExportRecord
    {
        [CsvColumn(CanBeNull = true)]
        public byte? Company { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string InvoiceNumber { get; set; }
        [CsvColumn(CanBeNull = true)]
        public byte? CustGroup { get; set; }
        [CsvColumn(CanBeNull = true)]
        public int? Customer { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string CustomerName { get; set; }
        [CsvColumn(CanBeNull = true)]
        public DateTime? TransactionDate { get; set; }
        [CsvColumn(CanBeNull = true)]
        public string InvoiceDescription { get; set; }
        [CsvColumn(CanBeNull = true)]
        public int? DetailLineCount { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? AmountDue { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? OriginalAmount { get; set; }
        [CsvColumn(CanBeNull = true)]
        public decimal? Tax { get; set; }
    }
}
