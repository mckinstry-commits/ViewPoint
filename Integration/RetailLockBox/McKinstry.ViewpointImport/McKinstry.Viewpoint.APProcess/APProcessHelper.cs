using System;
using System.Linq;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal static class APProcessHelper
    {
        public static RLBAPImportDetail FetchSecondMatch(RLBAPImportDetail unmatchedRecord, List<mvwRLBAPExport> exportItems)
        {
            RLBAPImportDetail matched = null;
            if (!string.IsNullOrEmpty(unmatchedRecord.Number))
            {
                string[] numbers = unmatchedRecord.Number.Split(new[] { '-' }, StringSplitOptions.RemoveEmptyEntries);

                var existing = exportItems.Where(r => numbers
                .Where(n => n.Trim() == r.Number.Trim())
                .Any())
                .FirstOrDefault<mvwRLBAPExport>();

                if (existing != null)
                {
                    matched = unmatchedRecord;
                    matched.UnmatchedNumber = unmatchedRecord.Number;
                    matched.RecordType = existing.RecordType;
                    matched.Company = existing.Company;
                    matched.Number = existing.Number;
                    matched.VendorGroup = existing.VendorGroup;
                    matched.Vendor = existing.Vendor;
                    matched.VendorName = existing.VendorName;
                    matched.TransactionDate = existing.TransactionDate;
                    matched.JCCo = existing.JCCo;
                    matched.Job = existing.Job;
                    matched.JobDescription = existing.JobDescription;
                    matched.Description = existing.Description;
                    matched.DetailLineCount = existing.DetailLineCount;
                    matched.TotalOrigCost = existing.TotalOrigCost;
                    matched.TotalOrigTax = existing.TotalOrigTax;
                    matched.RemainingAmount = existing.RemainingAmount;
                    matched.RemainingTax = existing.RemainingTax;
                }
            }
            return matched;
        }

        public static bool RecordIsMatched(RLBAPImportDetail record)
        {
            return ((record.RecordType != null) && (record.Company != null));
        }

        public static bool RecordIsUnmatched(RLBAPImportDetail record)
        {
            return ((record.RecordType == null) && (record.Company == null));
        }

        public static bool RecordIsStatement(RLBAPImportDetail record)
        {
            if (!string.IsNullOrEmpty(record.Number))
            {
                return record.Number.ToLower().Contains("statement");
            }
            return false;
        }

        public static bool RecordIsException(RLBAPImportDetail record)
        {
            return InvoiceIsEmpty(record.CollectedInvoiceNumber) || InvoiceIsSubContract(record.RecordType);
        }

        private static bool InvoiceIsEmpty(string invoiceNumber)
        {
            return string.IsNullOrEmpty(invoiceNumber);
        }

        private static bool InvoiceIsSubContract(string recordType)
        {
            if (!string.IsNullOrEmpty(recordType))
            {
                return recordType.ToLower().Contains("sc");
            }
            return false;
        }

    }
}
