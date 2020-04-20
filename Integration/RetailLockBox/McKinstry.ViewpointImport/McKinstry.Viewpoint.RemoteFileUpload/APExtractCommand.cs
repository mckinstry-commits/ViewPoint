using System;
using log4net;
using LINQtoCSV;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.RemoteFileUpload
{
    internal class APExtractCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "AP Data Extract Command";
            }
        }

        public string Description
        {
            get
            {
                return "Fetches latest AP data for upload. Data file is saved to log directory.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            Console.WriteLine("Fetching AP data for upload.");

            List<mvwRLBAPExport> exportItems = ViewpointDb.GetAPExportItems();

            IEnumerable<APExportRecord> exportRecords = from r in exportItems
                                                        select new APExportRecord
                                                        {
                                                            RecordType = r.RecordType,
                                                            Company = r.Company,
                                                            Number = r.Number,
                                                            VendorGroup = r.VendorGroup,
                                                            Vendor = r.Vendor,
                                                            VendorName = r.VendorName,
                                                            TransactionDate = r.TransactionDate,
                                                            JCCo = r.JCCo,
                                                            Job = r.Job,
                                                            JobDescription = r.JobDescription,
                                                            Description = r.Description,
                                                            DetailLineCount = r.DetailLineCount,
                                                            TotalOrigCost = r.TotalOrigCost,
                                                            TotalOrigTax = r.TotalOrigTax,
                                                            RemainingAmount = r.RemainingAmount,
                                                            RemainingTax = r.RemainingTax
                                                        };

            if (exportRecords.Count() <= 0)
            {
                throw new ApplicationException("AP data extract returned zero results.");
            }

            // Create CSV file from extracted data
            CsvFileDescription inputFileDescription = new CsvFileDescription
            {
                SeparatorChar = '|',
                FirstLineHasColumnNames = true
            };
            CsvContext cc = new CsvContext();
            cc.Write(exportRecords, Path.Combine(Settings.LogFilePath, Settings.UploadFileName), inputFileDescription);

            Console.WriteLine("AP data fetched and saved.");
            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
