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
    internal class ARExtractCommand : ICommand
    {
        public string Name
        {
            get
            {
                return "AR Data Extract Command";
            }
        }

        public string Description
        {
            get
            {
                return "Fetches latest AR data for upload. Data file is saved to log directory.";
            }
        }

        public void RunWith(ILog log)
        {
            log.InfoFormat("--Starting {0}--", this.Name);
            log.Info(this.Description);
            log.Info("Fetching AR data for upload.");

            List<mvwRLBARExport> exportItems = ViewpointDb.GetARExportItems();

            IEnumerable<ARExportRecord> exportRecords = from r in exportItems
                                                        select new ARExportRecord
                                                        {
                                                            Company = r.Company,
                                                            InvoiceNumber = r.InvoiceNumber,
                                                            CustGroup = r.CustGroup,
                                                            Customer = r.Customer,
                                                            CustomerName = r.CustomerName,
                                                            TransactionDate = r.TransactionDate,
                                                            InvoiceDescription = r.InvoiceDescription,
                                                            DetailLineCount = r.DetailLineCount,
                                                            AmountDue = r.AmountDue,
                                                            OriginalAmount = r.OriginalAmount,
                                                            Tax = r.Tax
                                                        };
            if (exportRecords.Count() <= 0)
            {
                throw new ApplicationException("AR data extract returned zero results.");
            }

            // Create CSV file from extracted data
            CsvFileDescription inputFileDescription = new CsvFileDescription
            {
                SeparatorChar = '|',
                FirstLineHasColumnNames = true
            };
            CsvContext cc = new CsvContext();
            cc.Write(exportRecords, Path.Combine(Settings.LogFilePath, Settings.UploadFileName), inputFileDescription);

            log.Info("AR data fetched and saved.");
            log.InfoFormat("--Completed {0}--", this.Name);
        }
    }
}
