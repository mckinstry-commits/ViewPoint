using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APProcess
{
    internal class APProcessDb : Db
    {
        public static int CreateAPImportDetail(int importBatchID, FileInfo dataFile, APRecord record)
        {
            RLBAPImportDetail detail = default(RLBAPImportDetail);
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                detail = ctx.RLBAPImportDetails.Add(
                    new RLBAPImportDetail
                    {
                        RLBImportBatchID = importBatchID,
                        FileName = dataFile.Name,
                        LastWriteTime = dataFile.LastWriteTime,
                        Length = dataFile.Length,
                        RLBImportDetailStatusCode = "UNP",
                        Created = DateTime.Now,
                        Modified = DateTime.Now,
                        UnmatchedNumber = TrimString(record.UnmatchedNumber, 30),
                        RecordType = record.RecordType,
                        Company = record.Company,
                        Number = TrimString(record.Number, 30),
                        VendorGroup = record.VendorGroup,
                        Vendor = record.Vendor,
                        VendorName = TrimString(record.VendorName, 60),
                        TransactionDate = record.TransactionDate,
                        JCCo = record.JCCo,
                        Job = TrimString(record.Job, 10),
                        JobDescription = TrimString(record.JobDescription, 60),
                        Description = TrimString(record.Description, 30),
                        DetailLineCount = record.DetailLineCount,
                        TotalOrigCost = record.TotalOrigCost,
                        TotalOrigTax = record.TotalOrigTax,
                        RemainingAmount = record.RemainingAmount,
                        RemainingTax = record.RemainingTax,
                        CollectedInvoiceDate = record.CollectedInvoiceDate,
                        CollectedInvoiceNumber = TrimString(record.CollectedInvoiceNumber, 50),
                        CollectedTaxAmount = record.CollectedTaxAmount,
                        CollectedShippingAmount = record.CollectedShippingAmount,
                        CollectedInvoiceAmount = record.CollectedInvoiceAmount,
                        CollectedImage = record.CollectedImage
                    }
                    );
                ctx.SaveChanges();

            }
            return detail.RLBAPImportDetailID;
        }

        public static bool UpdateAPImportDetailSecondMatch(RLBAPImportDetail record)
        {
            using (var ctx = new MckIntegrationEntities(IntegrationConnectionString))
            {
                var existing = (from b in ctx.RLBAPImportDetails
                                where b.RLBAPImportDetailID == record.RLBAPImportDetailID
                                select b).FirstOrDefault();

                if (existing == default(RLBAPImportDetail))
                {
                    return false;
                }

                existing.UnmatchedNumber = TrimString(record.UnmatchedNumber, 30);
                existing.RecordType = record.RecordType;
                existing.Company = record.Company;
                existing.Number = TrimString(record.Number, 30);
                existing.VendorGroup = record.VendorGroup;
                existing.Vendor = record.Vendor;
                existing.VendorName = TrimString(record.VendorName, 60);
                existing.TransactionDate = record.TransactionDate;
                existing.JCCo = record.JCCo;
                existing.Job = TrimString(record.Job, 10);
                existing.JobDescription = TrimString(record.JobDescription, 60);
                existing.Description = TrimString(record.Description, 30);
                existing.DetailLineCount = record.DetailLineCount;
                existing.TotalOrigCost = record.TotalOrigCost;
                existing.TotalOrigTax = record.TotalOrigTax;
                existing.RemainingAmount = record.RemainingAmount;
                existing.RemainingTax = record.RemainingTax;
                existing.Modified = DateTime.Now;
                ctx.SaveChanges();
                return true;
            }
        }
    }
}
